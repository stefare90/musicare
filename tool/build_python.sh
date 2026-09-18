#!/bin/bash
set -e

PLATFORM=${1:-Android}
ACTION=${2:-}

echo "=================================================="
echo "1. Resolving SDK Location"
echo "=================================================="

# 1. Check local sibling directory first
if [ -d "../musicare_audiosource_sdk" ]; then
  SDK_DIR=$(realpath "../musicare_audiosource_sdk")
elif [ -d "../../musicare_audiosource_sdk" ]; then
  SDK_DIR=$(realpath "../../musicare_audiosource_sdk")
else
  # 2. Fallback to pub-cache git clone
  SDK_DIR=$(find "$HOME/.pub-cache/git" -maxdepth 2 -type d -name "musicare_audiosource_sdk*" 2>/dev/null | head -n 1)
fi

if [ -z "$SDK_DIR" ] || [ ! -d "$SDK_DIR" ]; then
  echo "❌ Error: Could not locate 'musicare_audiosource_sdk' repository."
  echo "Expected it at ../musicare_audiosource_sdk or in ~/.pub-cache/git/"
  exit 1
fi

echo "Found SDK at: $SDK_DIR"

echo "=================================================="
echo "2. Staging SeriousPython Host Runtime ($PLATFORM)"
echo "=================================================="
rm -rf build/python-app build/site-packages build/host_staging
mkdir -p build/python-app build/site-packages build/host_staging

# Copy host_runtime and plugin_sdk into host_staging
cp -r "$SDK_DIR/python/host_runtime/"* build/host_staging/
cp -r "$SDK_DIR/python/plugin_sdk/musicare_plugin_sdk" build/host_staging/

export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/build/site-packages
export SERIOUS_PYTHON_APP=$(pwd)/build/python-app

# SeriousPython packages host daemon and downloads Flask automatically
dart run serious_python:main package build/host_staging \
  -p "$PLATFORM" \
  -r flask \
  --compile-packages \
  --cleanup-packages

# serious_python packaging is silent on failure: `dart run serious_python:main
# package` swallows the missing SERIOUS_PYTHON_APP exception and exits 0
# (<pub-cache>/serious_python-4.7.0/bin/package_command.dart), and the Gradle
# packageApp task returns early when the variable is null or blank
# (serious_python_android-4.7.0/android/build.gradle.kts). Verify the artifacts,
# not the exit code, otherwise an APK without the Python runtime looks valid.
STAGING_ERRORS=()

if [ ! -s build/python-app/main.py ]; then
  STAGING_ERRORS+=("build/python-app/main.py is missing or empty")
fi

if [ ! -d build/python-app/musicare_plugin_sdk ] \
  || [ -z "$(ls -A build/python-app/musicare_plugin_sdk 2>/dev/null)" ]; then
  STAGING_ERRORS+=("build/python-app/musicare_plugin_sdk/ is missing or empty")
fi

for ABI in arm64-v8a armeabi-v7a x86_64; do
  if [ ! -d "build/site-packages/$ABI/flask" ] \
    || [ -z "$(ls -A "build/site-packages/$ABI/flask" 2>/dev/null)" ]; then
    STAGING_ERRORS+=("build/site-packages/$ABI/flask/ is missing or empty")
  fi
done

if [ ${#STAGING_ERRORS[@]} -gt 0 ]; then
  echo "=================================================="
  echo "❌ Error: SeriousPython staging is incomplete for $PLATFORM"
  echo "=================================================="
  for STAGING_ERROR in "${STAGING_ERRORS[@]}"; do
    echo "   - $STAGING_ERROR"
  done
  echo ""
  echo "The packaging command reported success, but it produces nothing when"
  echo "SERIOUS_PYTHON_APP is unset: it is swallowed by the serious_python CLI"
  echo "(exit 0) and skipped by its Gradle task. Without those artifacts the"
  echo "APK contains no app.zip and no sitepackages.zip, i.e. no Python runtime."
  echo ""
  echo "Re-run the staging from the project root (it exports both variables):"
  echo "   ./tool/build_python.sh $PLATFORM"
  exit 1
fi

echo "=================================================="
echo "✅ SeriousPython Host Runtime staged successfully for $PLATFORM!"
echo "=================================================="

# If requested, compile the Flutter build directly while environment variables are preserved
if [ "$ACTION" == "apk" ] || [ "$ACTION" == "--build" ]; then
  echo "=================================================="
  echo "3. Building Flutter Release APK with SeriousPython"
  echo "=================================================="
  flutter build apk
  echo "=================================================="
  echo "🎉 Release APK built successfully with Flask included!"
  echo "=================================================="
else
  echo ""
  echo "💡 To build the APK with the Python runtime included, run:"
  echo "   ./tool/build_python.sh $PLATFORM apk"
fi
