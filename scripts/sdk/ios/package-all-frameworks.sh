#!/bin/bash
set -e

# Script to package Flutter frameworks for iOS distribution
# Creates 2 simple packages (no renaming, no suffixes):
# 1. Debug package: ReelsSDK-Frameworks-Debug-{VERSION}.zip (6 frameworks)
# 2. Release package: ReelsSDK-Frameworks-{VERSION}.zip (6 frameworks)

VERSION="${1:-$(cat VERSION)}"

echo "========================================="
echo "Packaging ReelsSDK Frameworks v$VERSION"
echo "========================================="
echo ""

# Define paths
SDK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FLUTTER_DIR="$SDK_ROOT/reels_flutter"

# Check for frameworks in GitHub Actions location first, then local build location
if [ -d "$SDK_ROOT/Frameworks/Debug/Debug" ] && [ -d "$SDK_ROOT/Frameworks/Release/Release" ]; then
  # GitHub Actions build location
  DEBUG_FRAMEWORKS="$SDK_ROOT/Frameworks/Debug/Debug"
  RELEASE_FRAMEWORKS="$SDK_ROOT/Frameworks/Release/Release"
elif [ -d "$FLUTTER_DIR/.ios/Flutter/Debug" ] && [ -d "$FLUTTER_DIR/.ios/Flutter/Release" ]; then
  # Local build location
  DEBUG_FRAMEWORKS="$FLUTTER_DIR/.ios/Flutter/Debug"
  RELEASE_FRAMEWORKS="$FLUTTER_DIR/.ios/Flutter/Release"
else
  echo "❌ Error: Could not find frameworks in expected locations"
  echo "   Checked:"
  echo "   - $SDK_ROOT/Frameworks/Debug/Debug (GitHub Actions)"
  echo "   - $FLUTTER_DIR/.ios/Flutter/Debug (Local build)"
  exit 1
fi

# Create temp packaging directories
DEBUG_DIR="packaging/debug"
RELEASE_DIR="packaging/release"

mkdir -p "$DEBUG_DIR" "$RELEASE_DIR"

echo "📦 Packaging DEBUG package (6 frameworks, no suffixes)..."
# Copy Debug frameworks WITHOUT renaming
for framework in "$DEBUG_FRAMEWORKS"/*.xcframework; do
  if [ -d "$framework" ]; then
    base_name=$(basename "$framework")
    cp -R "$framework" "$DEBUG_DIR/$base_name"
    echo "  $base_name"
  fi
done

# Create zip with frameworks at root level
(cd "$DEBUG_DIR" && zip -r -q "../../ReelsSDK-Frameworks-Debug-${VERSION}.zip" *.xcframework)
echo "[OK] Created: ReelsSDK-Frameworks-Debug-${VERSION}.zip"
echo ""

echo "📦 Packaging RELEASE package (6 frameworks, no suffixes)..."
# Copy Release frameworks WITHOUT renaming
for framework in "$RELEASE_FRAMEWORKS"/*.xcframework; do
  if [ -d "$framework" ]; then
    base_name=$(basename "$framework")
    cp -R "$framework" "$RELEASE_DIR/$base_name"
    echo "  $base_name"
  fi
done

# Create zip with frameworks at root level
(cd "$RELEASE_DIR" && zip -r -q "../../ReelsSDK-Frameworks-${VERSION}.zip" *.xcframework)
echo "[OK] Created: ReelsSDK-Frameworks-${VERSION}.zip"
echo ""

# Cleanup
rm -rf packaging

echo "========================================="
echo "Package Summary:"
echo "========================================="
ls -lh ReelsSDK-Frameworks*.zip
echo ""
echo "[OK] All packages created successfully!"
