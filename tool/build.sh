#!/bin/bash
# Builds the Android APK with the Python runtime: stages the runtime, exports the
# SeriousPython variables with absolute paths and runs `flutter build apk` in the
# same shell, then verifies that the runtime assets ended up inside the APK.
#
# Usage: ./tool/build.sh [debug|release]

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")
cd "$ROOT_DIR"

MODE=${1:-}
case "$MODE" in
  debug | release) ;;
  *)
    echo "❌ Error: missing or invalid build mode '${MODE}'."
    echo "   Usage: ./tool/build.sh [debug|release]"
    exit 1
    ;;
esac

export SERIOUS_PYTHON_APP="$ROOT_DIR/build/python-app"
export SERIOUS_PYTHON_SITE_PACKAGES="$ROOT_DIR/build/site-packages"

"$ROOT_DIR/tool/stage_python.sh" Android

echo "=================================================="
echo "Checking the staged runtime"
echo "=================================================="
if [ ! -s "build/python-app/main.py" ] \
  || [ -z "$(ls -A build/site-packages 2>/dev/null)" ]; then
  echo "❌ Error: staging produced no usable runtime (build/python-app, build/site-packages)."
  exit 1
fi

echo "=================================================="
echo "Building the $MODE APK with SeriousPython"
echo "=================================================="
flutter build apk "--$MODE"

APK="build/app/outputs/flutter-apk/app-$MODE.apk"
if [ ! -s "$APK" ]; then
  echo "❌ Error: expected APK not found at $APK."
  exit 1
fi

echo "=================================================="
echo "Verifying the runtime assets inside the APK"
echo "=================================================="
MISSING_ASSETS=()
for ASSET in assets/app.zip assets/sitepackages.zip; do
  SIZE=$(unzip -l "$APK" | awk -v name="$ASSET" '$4 == name { print $1 }')
  if [ -z "$SIZE" ] || [ "$SIZE" -eq 0 ]; then
    MISSING_ASSETS+=("$ASSET")
  else
    echo "   $ASSET: $SIZE B"
  fi
done
if [ ${#MISSING_ASSETS[@]} -gt 0 ]; then
  echo "❌ Error: the APK does not embed the Python runtime (${MISSING_ASSETS[*]})."
  exit 1
fi

echo "=================================================="
echo "✅ $MODE APK built successfully"
echo "=================================================="
echo "   Path: $(realpath "$APK")"
echo "   Size: $(du -h "$APK" | cut -f1)"
