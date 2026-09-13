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
  echo "💡 To build the APK manually with the Python dependencies included, run:"
  echo '   SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/build/site-packages flutter build apk'
  echo ""
  echo "👉 Or simply run this script with 'apk':"
  echo "   ./tool/build_python.sh Android apk"
fi
