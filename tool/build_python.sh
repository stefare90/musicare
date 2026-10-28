#!/bin/bash
# Stages the flat Python app (both engines + the shared plugin_runtime package + both
# plugin SDKs + the unified main.py) from the musicare_plugin_sdk repository and packages
# it into the Flutter asset that serious_python runs on the device.
#
# Usage: ./tool/build_python.sh [Android | Linux] [apk]
set -e

PLATFORM=${1:-Android}
ACTION=${2:-}

echo "=================================================="
echo "1. Resolving the plugin platform repository"
echo "=================================================="

# The staging sources live in the musicare_plugin_sdk repository (the pubspec git
# dependency). Prefer the workspace checkout, then fall back to the pub-cache clone.
PLATFORM_DIR=""
for CANDIDATE in "../musicare_plugin_sdk" "../../musicare_plugin_sdk"; do
  if [ -f "$CANDIDATE/python/main.py" ]; then
    PLATFORM_DIR=$(realpath "$CANDIDATE")
    break
  fi
done

if [ -z "$PLATFORM_DIR" ]; then
  PUB_CACHE_DIR=$(find "$HOME/.pub-cache/git" -maxdepth 1 -type d \
    -name "musicare_plugin_sdk-*" 2>/dev/null | head -n 1)
  if [ -n "$PUB_CACHE_DIR" ] && [ -f "$PUB_CACHE_DIR/python/main.py" ]; then
    PLATFORM_DIR="$PUB_CACHE_DIR"
  fi
fi

if [ -z "$PLATFORM_DIR" ]; then
  echo "❌ Error: could not locate the 'musicare_plugin_sdk' repository."
  echo "Expected it at ../musicare_plugin_sdk (workspace) or in ~/.pub-cache/git/"
  exit 1
fi

echo "Found plugin platform at: $PLATFORM_DIR"

echo "=================================================="
echo "2. Staging the SeriousPython host runtime ($PLATFORM)"
echo "=================================================="
rm -rf build/python-app build/site-packages build/host_staging
mkdir -p build/python-app build/site-packages build/host_staging

cp "$PLATFORM_DIR/python/main.py" build/host_staging/main.py
cp -r "$PLATFORM_DIR/python/plugin_runtime" build/host_staging/plugin_runtime
cp "$PLATFORM_DIR/python/audio/host_runtime/audio_engine.py" \
  build/host_staging/audio_engine.py
cp "$PLATFORM_DIR/python/metadata/host_runtime/metadata_engine.py" \
  build/host_staging/metadata_engine.py
cp -r "$PLATFORM_DIR/python/audio/plugin_sdk/musicare_audio_plugin_sdk" \
  build/host_staging/
cp -r "$PLATFORM_DIR/python/metadata/plugin_sdk/musicare_metadata_plugin_sdk" \
  build/host_staging/

export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/build/site-packages
export SERIOUS_PYTHON_APP=$(pwd)/build/python-app

# `--requirements` values go straight to `pip install`, so `-r <file>` is how a
# requirements file is passed (the `=` form keeps the leading dash unambiguous).
dart run serious_python:main package build/host_staging \
  -p "$PLATFORM" \
  --requirements=-r \
  --requirements="$PLATFORM_DIR/python/metadata/host_runtime/requirements.txt" \
  --compile-packages \
  --cleanup-packages

# serious_python packaging is silent on failure: `dart run serious_python:main
# package` swallows the missing SERIOUS_PYTHON_APP exception and exits 0
# (<pub-cache>/serious_python-4.7.0/bin/package_command.dart), and the Gradle
# packageApp task returns early when the variable is null or blank
# (serious_python_android-4.7.0/android/build.gradle.kts). Verify the artifacts,
# not the exit code, otherwise an APK without the Python runtime looks valid.
STAGING_ERRORS=()

MAIN_FILES=(main.py audio_engine.py metadata_engine.py)
for FILE in "${MAIN_FILES[@]}"; do
  if [ ! -s "build/python-app/$FILE" ]; then
    STAGING_ERRORS+=("build/python-app/$FILE is missing or empty")
  fi
done

SDK_DIRS=(musicare_audio_plugin_sdk musicare_metadata_plugin_sdk)
for SDK in "${SDK_DIRS[@]}"; do
  if [ ! -d "build/python-app/$SDK" ] \
    || [ -z "$(ls -A "build/python-app/$SDK" 2>/dev/null)" ]; then
    STAGING_ERRORS+=("build/python-app/$SDK/ is missing or empty")
  fi
done

RUNTIME_FILES=(plugin_runtime/__init__.py plugin_runtime/loader.py plugin_runtime/http.py)
for FILE in "${RUNTIME_FILES[@]}"; do
  if [ ! -s "build/python-app/$FILE" ]; then
    STAGING_ERRORS+=("build/python-app/$FILE is missing or empty")
  fi
done

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
