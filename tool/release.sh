#!/bin/bash
# Release pipeline for the Android app: preflight checks, keystore gate, staging +
# build, APK gates (badging, signature), checksum and — only with --publish — the
# git tag and the stable GitHub release.
#
# The version is read from pubspec.yaml (`version: x.y.z+n`); the tag is derived
# as `v<version>` (e.g. v1.0.0+2).
#
# Usage: ./tool/release.sh [--skip-checks] [--bump patch|minor|major] [--publish]
#                          [--notes <text> | --notes-file <path>] [--no-push-branch]
#   --skip-checks     skip `flutter analyze` and `flutter test`
#   --bump            bump pubspec.yaml (and commit it) before building
#   --publish         create and push the tag, publish the GitHub release and push
#                     the branch; without it the script is a dry run (nothing is
#                     tagged, pushed or published)
#   --notes           release body as inline text (empty text is rejected)
#   --notes-file      release body read from a file (an empty file is rejected)
#   --no-push-branch  with --publish, leave the branch out of the push
#
# Without --notes/--notes-file the release body stays the historical one:
# "MusicAre <version> (build <n>)."

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")
cd "$ROOT_DIR"

SKIP_CHECKS=false
PUBLISH=false
BUMP=""
PUSH_BRANCH=true
NOTES=""
NOTES_FILE=""
NOTES_INPUT="" # "inline" | "file" | "" (default body)

usage() {
  echo "Usage: ./tool/release.sh [--skip-checks] [--bump patch|minor|major] [--publish]"
  echo "                         [--notes <text> | --notes-file <path>] [--no-push-branch]"
}

fail() {
  echo "❌ Error: $*"
  exit 1
}

step() {
  echo "=================================================="
  echo "$*"
  echo "=================================================="
}

notes_source() {
  case "$NOTES_INPUT" in
    file) echo "file: $NOTES_FILE" ;;
    inline) echo "inline text" ;;
    *) echo "default body" ;;
  esac
}

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-checks) SKIP_CHECKS=true ;;
    --publish) PUBLISH=true ;;
    --no-push-branch) PUSH_BRANCH=false ;;
    --notes)
      [ -z "$NOTES_INPUT" ] || fail "use either --notes or --notes-file, not both."
      [ $# -ge 2 ] || fail "--notes expects the release body as its argument."
      NOTES=${2:-}
      NOTES_INPUT=inline
      shift
      ;;
    --notes-file)
      [ -z "$NOTES_INPUT" ] || fail "use either --notes or --notes-file, not both."
      [ $# -ge 2 ] || fail "--notes-file expects a path as its argument."
      NOTES_FILE=${2:-}
      NOTES_INPUT=file
      shift
      ;;
    --bump)
      BUMP=${2:-}
      case "$BUMP" in
        patch | minor | major) ;;
        *)
          echo "❌ Error: --bump expects patch, minor or major."
          usage
          exit 1
          ;;
      esac
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "❌ Error: unknown argument '$1'."
      usage
      exit 1
      ;;
  esac
  shift
done

case "$NOTES_INPUT" in
  inline)
    case "$NOTES" in
      *[![:space:]]*) ;;
      *) fail "the release notes are empty (--notes)." ;;
    esac
    ;;
  file)
    [ -f "$NOTES_FILE" ] || fail "--notes-file '$NOTES_FILE' is not an existing file."
    [ -r "$NOTES_FILE" ] || fail "--notes-file '$NOTES_FILE' is not readable."
    [ -n "$(tr -d '[:space:]' <"$NOTES_FILE")" ] ||
      fail "--notes-file '$NOTES_FILE' is empty (blank content)."
    ;;
  *) ;;
esac

read_version() {
  VERSION=$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -n 1)
  case "$VERSION" in
    *+*) ;;
    *) fail "pubspec.yaml version must be 'x.y.z+n' (found '$VERSION')." ;;
  esac
  VERSION_NAME=${VERSION%%+*}
  VERSION_CODE=${VERSION##*+}
  case "$VERSION_CODE" in
    '' | *[!0-9]*) fail "invalid versionCode '$VERSION_CODE' in pubspec.yaml." ;;
  esac
}

step "1. Preflight"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
[ "$BRANCH" = "main" ] || fail "releases are cut from 'main' (current branch: '$BRANCH')."
[ -z "$(git status --porcelain)" ] || fail "the working tree is not clean; commit or stash first."

read_version

if [ -z "$NOTES_INPUT" ]; then
  NOTES="MusicAre $VERSION_NAME (build $VERSION_CODE)."
fi

if [ -n "$BUMP" ]; then
  step "2. Bumping the version ($BUMP)"
  IFS=. read -r MAJOR MINOR PATCH <<< "$VERSION_NAME"
  case "$BUMP" in
    major)
      MAJOR=$((MAJOR + 1))
      MINOR=0
      PATCH=0
      ;;
    minor)
      MINOR=$((MINOR + 1))
      PATCH=0
      ;;
    patch) PATCH=$((PATCH + 1)) ;;
  esac
  VERSION="$MAJOR.$MINOR.$PATCH+$((VERSION_CODE + 1))"
  sed -i "s/^version: .*/version: $VERSION/" pubspec.yaml
  read_version
  git add pubspec.yaml
  git commit -m "chore(release): bump version to $VERSION"
  echo "Version bumped to $VERSION"
else
  step "2. Version"
  echo "pubspec.yaml version: $VERSION (no --bump: no file is modified)"
fi

TAG="v$VERSION"

if [ "$SKIP_CHECKS" = true ]; then
  step "3. Static analysis and tests (skipped: --skip-checks)"
else
  step "3. Static analysis and tests"
  flutter analyze
  flutter test
fi

step "4. Keystore gate"
if [ ! -f android/key.properties ]; then
  echo "❌ Error: android/key.properties is missing."
  echo ""
  echo "The release APK must be signed with the release keystore, never with the"
  echo "Android debug key. Create the keystore, write android/key.properties"
  echo "(storeFile, storePassword, keyAlias, keyPassword) and re-run this script."
  exit 1
fi
echo "Found android/key.properties for the release signing config."

step "5. Tag and version checks"
if git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
  fail "tag $TAG already exists locally."
fi
REMOTE_TAG=$(git ls-remote --tags origin "refs/tags/$TAG" 2>/dev/null || true)
[ -z "$REMOTE_TAG" ] || fail "tag $TAG already exists on origin."

REPO_SLUG=$(git remote get-url origin |
  sed -E 's#^(git@github.com:|https://github.com/)##; s#\.git$##')
[ -n "$REPO_SLUG" ] || fail "could not derive the GitHub repository from 'origin'."

LATEST_TAG=""
if ! LATEST_TAG=$(gh api "repos/$REPO_SLUG/releases/latest" --jq .tag_name 2>/dev/null); then
  LATEST_TAG=""
fi
[ "$LATEST_TAG" = "null" ] && LATEST_TAG=""
if [ -z "$LATEST_TAG" ]; then
  echo "No published release found: $TAG will be the first one."
else
  echo "Latest published release: $LATEST_TAG"
  LATEST_CODE=${LATEST_TAG##*+}
  case "$LATEST_CODE" in
    '' | *[!0-9]*) fail "cannot parse the versionCode of the latest release ($LATEST_TAG)." ;;
  esac
  [ "$VERSION_CODE" -gt "$LATEST_CODE" ] ||
    fail "pubspec versionCode ($VERSION_CODE) must be greater than the latest published one ($LATEST_CODE)."
fi

step "6. Building the release APK"
"$ROOT_DIR/tool/build.sh" release
APK="build/app/outputs/flutter-apk/app-release.apk"
[ -s "$APK" ] || fail "expected APK not found at $APK."

SDK_ROOT="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
AAPT=$(ls "$SDK_ROOT"/build-tools/*/aapt 2>/dev/null | sort -V | tail -n 1 || true)
APKSIGNER=$(ls "$SDK_ROOT"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -n 1 || true)
[ -n "$AAPT" ] || fail "aapt not found under $SDK_ROOT/build-tools (set ANDROID_HOME)."
[ -n "$APKSIGNER" ] || fail "apksigner not found under $SDK_ROOT/build-tools (set ANDROID_HOME)."

step "7. Badging gate"
EXPECTED_PACKAGE=$(sed -n 's/^[[:space:]]*applicationId = "\([^"]*\)".*/\1/p' \
  android/app/build.gradle.kts | head -n 1)
[ -n "$EXPECTED_PACKAGE" ] || fail "could not read applicationId from android/app/build.gradle.kts."

BADGING=$("$AAPT" dump badging "$APK" 2>/dev/null | head -n 1)
APK_PACKAGE=$(echo "$BADGING" | sed -n "s/.*package: name='\([^']*\)'.*/\1/p")
APK_CODE=$(echo "$BADGING" | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p")
APK_NAME=$(echo "$BADGING" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")
echo "APK: package=$APK_PACKAGE versionName=$APK_NAME versionCode=$APK_CODE"
[ "$APK_PACKAGE" = "$EXPECTED_PACKAGE" ] ||
  fail "APK package '$APK_PACKAGE' does not match applicationId '$EXPECTED_PACKAGE'."
[ "$APK_NAME" = "$VERSION_NAME" ] ||
  fail "APK versionName '$APK_NAME' does not match pubspec versionName '$VERSION_NAME'."
[ "$APK_CODE" = "$VERSION_CODE" ] ||
  fail "APK versionCode '$APK_CODE' does not match pubspec versionCode '$VERSION_CODE'."

# Release APKs must be signed with the project release keystore: the fingerprint of
# its certificate is pinned here so a build signed with any other key (including
# the Android debug key) is rejected even when apksigner reports a valid signature.
EXPECTED_SIGNER_SHA256="651d7369e571187eff5e9c1a49ac49a1c424711d93db4aa0ec37d1d561846aa6"

step "8. Signature gate"
CERTS=$("$APKSIGNER" verify --print-certs "$APK" 2>&1) ||
  fail "apksigner could not verify the APK (unsigned or malformed)."
echo "$CERTS" | grep 'Signer #1 certificate DN:' || true
APK_SIGNER_SHA256=$(echo "$CERTS" |
  sed -n 's/^Signer #1 certificate SHA-256 digest:[[:space:]]*//p' |
  head -n 1 | tr -d '[:space:]:' | tr 'A-F' 'a-f')
[ -n "$APK_SIGNER_SHA256" ] ||
  fail "could not read the leaf certificate SHA-256 digest: the APK is not signed."
[ "$APK_SIGNER_SHA256" = "$EXPECTED_SIGNER_SHA256" ] ||
  fail "the APK is signed with the wrong key (expected SHA-256 $EXPECTED_SIGNER_SHA256, found $APK_SIGNER_SHA256). It was not signed with the release keystore: the debug key or an unsigned build would produce this."
echo "Signer SHA-256: $APK_SIGNER_SHA256 (release keystore)"

step "9. Checksum"
SHA256=$(sha256sum "$APK" | awk '{print $1}')
echo "APK: $(realpath "$APK")"
echo "SHA-256: $SHA256"

if [ "$PUBLISH" = false ]; then
  step "10. Dry run: nothing was published"
  echo "Checked:    main branch, clean tree, analyze/tests, keystore, tag availability, versionCode"
  echo "Built:      release APK signed with the release key, assets verified"
  echo "Not done:   the tag, the GitHub release and the branch push (dry run, no --publish)"
  echo ""
  echo "Notes:      $(notes_source)"
  echo "Publishing would run:"
  echo "   git tag -a $TAG -m 'MusicAre $VERSION_NAME (build $VERSION_CODE)' && git push origin $TAG"
  if [ "$NOTES_INPUT" = "file" ]; then
    echo "   gh release create $TAG MusicAre-$VERSION_NAME.apk --title 'MusicAre $VERSION_NAME' --notes-file '$NOTES_FILE' --latest"
  elif [ "$NOTES_INPUT" = "inline" ]; then
    echo "   gh release create $TAG MusicAre-$VERSION_NAME.apk --title 'MusicAre $VERSION_NAME' --notes '<the --notes text>' --latest"
  else
    echo "   gh release create $TAG MusicAre-$VERSION_NAME.apk --title 'MusicAre $VERSION_NAME' --notes '$NOTES' --latest"
  fi
  if [ "$PUSH_BRANCH" = true ]; then
    echo "   git push origin $BRANCH"
  else
    echo "   (branch push skipped: --no-push-branch)"
  fi
  echo ""
  echo "Re-run with --publish to publish."
  exit 0
fi

step "10. Publishing"
git tag -a "$TAG" -m "MusicAre $VERSION_NAME (build $VERSION_CODE)"
[ "$(git cat-file -t "$TAG")" = "tag" ] ||
  fail "tag $TAG is not annotated."
git push origin "$TAG"

# gh names the asset after the uploaded file (`path#label` only sets a label),
# so the APK is copied under its published name before uploading.
ASSET_DIR=$(mktemp -d)
ASSET="$ASSET_DIR/MusicAre-$VERSION_NAME.apk"
cp "$APK" "$ASSET"
if [ "$NOTES_INPUT" = "file" ]; then
  NOTES_ARGS=(--notes-file "$NOTES_FILE")
else
  NOTES_ARGS=(--notes "$NOTES")
fi
echo "Release notes: $(notes_source)"
gh release create "$TAG" "$ASSET" \
  --title "MusicAre $VERSION_NAME" \
  "${NOTES_ARGS[@]}" \
  --latest
rm -rf "$ASSET_DIR"

PUBLISHED_TAG=$(gh release view "$TAG" --json tagName --jq .tagName)
[ "$PUBLISHED_TAG" = "$TAG" ] ||
  fail "could not read back the release for tag $TAG (found '$PUBLISHED_TAG')."
PUBLISHED_ASSET=$(gh release view "$TAG" --json assets --jq '.assets[].name' | head -n 1)
[ "$PUBLISHED_ASSET" = "MusicAre-$VERSION_NAME.apk" ] ||
  fail "published asset is '$PUBLISHED_ASSET', expected 'MusicAre-$VERSION_NAME.apk'."

if [ "$PUSH_BRANCH" = true ]; then
  step "11. Pushing the branch"
  echo "Pushing $BRANCH to origin: the tag alone would leave the release commit off the branch."
  git push origin "$BRANCH"
else
  echo "Skipping the branch push (--no-push-branch): $BRANCH stays local."
fi

step "✅ Released $TAG"
echo "Tag:        $TAG"
echo "Release:    https://github.com/$REPO_SLUG/releases/tag/$TAG"
echo "APK:        MusicAre-$VERSION_NAME.apk"
echo "SHA-256:    $SHA256"
