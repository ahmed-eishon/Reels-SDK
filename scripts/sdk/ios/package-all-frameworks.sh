#!/bin/bash
set -e

# Script to package Flutter frameworks for iOS distribution
# Creates 3 packages:
# 1. Full package with ALL frameworks (*_Debug + *_Release)
# 2. Debug-only package (only *_Debug frameworks)
# 3. Release-only package (only *_Release frameworks)

VERSION="${1:-$(cat VERSION)}"

echo "========================================="
echo "Packaging ReelsSDK Frameworks v$VERSION"
echo "========================================="
echo ""

# Define paths
SDK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FLUTTER_DIR="$SDK_ROOT/reels_flutter"
DEBUG_FRAMEWORKS="$FLUTTER_DIR/.ios/Flutter/Debug"
RELEASE_FRAMEWORKS="$FLUTTER_DIR/.ios/Flutter/Release"

# Create temp packaging directories
FULL_DIR="packaging/full"
DEBUG_DIR="packaging/debug"
RELEASE_DIR="packaging/release"

mkdir -p "$FULL_DIR" "$DEBUG_DIR" "$RELEASE_DIR"

echo "📦 Packaging FULL package (all frameworks)..."
# Copy and rename Debug frameworks with _Debug suffix
for framework in "$DEBUG_FRAMEWORKS"/*.xcframework; do
  if [ -d "$framework" ]; then
    base_name=$(basename "$framework" .xcframework)
    cp -R "$framework" "$FULL_DIR/${base_name}_Debug.xcframework"
    echo "  ${base_name}_Debug.xcframework"
  fi
done

# Copy and rename Release frameworks with _Release suffix
for framework in "$RELEASE_FRAMEWORKS"/*.xcframework; do
  if [ -d "$framework" ]; then
    base_name=$(basename "$framework" .xcframework)
    cp -R "$framework" "$FULL_DIR/${base_name}_Release.xcframework"
    echo "  ${base_name}_Release.xcframework"
  fi
done

# Create zip with frameworks at root level (not in subdirectory)
(cd "$FULL_DIR" && zip -r -q "../../ReelsSDK-Frameworks-${VERSION}.zip" *.xcframework)
echo "[OK] Created: ReelsSDK-Frameworks-${VERSION}.zip"
echo ""

echo "📦 Packaging DEBUG-only package..."
# Copy and rename Debug frameworks with _Debug suffix
for framework in "$DEBUG_FRAMEWORKS"/*.xcframework; do
  if [ -d "$framework" ]; then
    base_name=$(basename "$framework" .xcframework)
    cp -R "$framework" "$DEBUG_DIR/${base_name}_Debug.xcframework"
    echo "  ${base_name}_Debug.xcframework"
  fi
done

# Create zip with frameworks at root level
(cd "$DEBUG_DIR" && zip -r -q "../../ReelsSDK-Frameworks-Debug-${VERSION}.zip" *.xcframework)
echo "[OK] Created: ReelsSDK-Frameworks-Debug-${VERSION}.zip"
echo ""

echo "📦 Packaging RELEASE-only package..."
# Copy and rename Release frameworks with _Release suffix
for framework in "$RELEASE_FRAMEWORKS"/*.xcframework; do
  if [ -d "$framework" ]; then
    base_name=$(basename "$framework" .xcframework)
    cp -R "$framework" "$RELEASE_DIR/${base_name}_Release.xcframework"
    echo "  ${base_name}_Release.xcframework"
  fi
done

# Create zip with frameworks at root level
(cd "$RELEASE_DIR" && zip -r -q "../../ReelsSDK-Frameworks-Release-${VERSION}.zip" *.xcframework)
echo "[OK] Created: ReelsSDK-Frameworks-Release-${VERSION}.zip"
echo ""

# Cleanup
rm -rf packaging

echo "========================================="
echo "Package Summary:"
echo "========================================="
ls -lh ReelsSDK-Frameworks-*.zip
echo ""
echo "[OK] All packages created successfully!"
