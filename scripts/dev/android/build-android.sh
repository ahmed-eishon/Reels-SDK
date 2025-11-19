#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================"
echo "🚀 Reels SDK - Build Android"
echo "============================================"
echo ""

# Get script directory and SDK root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo -e "${BLUE}📁 SDK Root: $SDK_ROOT${NC}"
echo ""

# Step 1: Check Flutter installation
echo "1️⃣  Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found in PATH${NC}"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✅ $FLUTTER_VERSION${NC}"
echo ""

# Step 2: Verify Flutter module exists
echo "2️⃣  Verifying Flutter module..."
if [ ! -f "$SDK_ROOT/reels_flutter/pubspec.yaml" ]; then
    echo -e "${RED}❌ Flutter module not found at $SDK_ROOT/reels_flutter${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flutter module found${NC}"
echo ""

# Step 3: Clean Flutter build artifacts
echo "3️⃣  Cleaning Flutter build artifacts..."
cd "$SDK_ROOT/reels_flutter"
if flutter clean; then
    echo -e "${GREEN}✅ Flutter clean completed${NC}"
else
    echo -e "${RED}❌ Flutter clean failed${NC}"
    exit 1
fi
echo ""

# Step 4: Remove .android directory
echo "4️⃣  Removing .android directory..."
if [ -d "$SDK_ROOT/reels_flutter/.android" ]; then
    rm -rf "$SDK_ROOT/reels_flutter/.android"
    echo -e "${GREEN}✅ .android directory removed${NC}"
else
    echo -e "${YELLOW}ℹ️  .android directory already clean${NC}"
fi
echo ""

# Step 5: Run flutter pub get
echo "5️⃣  Running flutter pub get..."
cd "$SDK_ROOT/reels_flutter"
if flutter pub get; then
    echo -e "${GREEN}✅ Flutter dependencies resolved${NC}"
else
    echo -e "${RED}❌ Failed to get Flutter dependencies${NC}"
    exit 1
fi
echo ""

# Step 6: Verify .android directory was created
echo "6️⃣  Verifying Android platform files..."
if [ ! -f "$SDK_ROOT/reels_flutter/.android/include_flutter.groovy" ]; then
    echo -e "${RED}❌ Android platform files not generated${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Android platform files generated${NC}"
echo ""

# Step 7: Regenerate Pigeon files
echo "7️⃣  Regenerating Pigeon platform channel code..."
cd "$SDK_ROOT/reels_flutter"
if flutter pub run pigeon --input pigeons/messages.dart; then
    echo -e "${GREEN}✅ Pigeon code generated${NC}"
else
    echo -e "${RED}❌ Failed to generate Pigeon code${NC}"
    exit 1
fi
echo ""

# Step 8: Verify Pigeon generated files for Android
echo "8️⃣  Verifying Pigeon files for Android..."
PIGEON_ERRORS=0

# Check Flutter pigeon_generated.dart
if [ ! -f "$SDK_ROOT/reels_flutter/lib/core/pigeon_generated.dart" ]; then
    echo -e "${RED}❌ lib/core/pigeon_generated.dart not found${NC}"
    PIGEON_ERRORS=$((PIGEON_ERRORS + 1))
else
    echo -e "${GREEN}✅ lib/core/pigeon_generated.dart${NC}"
fi

# Check Android PigeonGenerated.kt
if [ ! -f "$SDK_ROOT/reels_android/src/main/java/com/rakuten/room/reels/pigeon/PigeonGenerated.kt" ]; then
    echo -e "${RED}❌ reels_android/.../PigeonGenerated.kt not found${NC}"
    PIGEON_ERRORS=$((PIGEON_ERRORS + 1))
else
    echo -e "${GREEN}✅ reels_android/src/main/java/com/rakuten/room/reels/pigeon/PigeonGenerated.kt${NC}"
fi

if [ $PIGEON_ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Pigeon file verification failed${NC}"
    exit 1
fi
echo ""

# Step 9: Verify reels_android module
echo "9️⃣  Verifying reels_android module..."
if [ ! -f "$SDK_ROOT/reels_android/build.gradle" ]; then
    echo -e "${RED}❌ reels_android/build.gradle not found${NC}"
    exit 1
fi

KOTLIN_FILES=$(find "$SDK_ROOT/reels_android/src/main/java" -name "*.kt" 2>/dev/null | wc -l | tr -d ' ')
if [ "$KOTLIN_FILES" -eq 0 ]; then
    echo -e "${RED}❌ No Kotlin files found in reels_android${NC}"
    exit 1
fi
echo -e "${GREEN}✅ reels_android module verified ($KOTLIN_FILES Kotlin files)${NC}"
echo ""

# Step 10: Setup local.properties for .android build
echo "🔟  Setting up local.properties for build..."
LOCAL_PROPS="$SDK_ROOT/reels_flutter/.android/local.properties"

# Find Android SDK location
if [ -n "$ANDROID_HOME" ]; then
    SDK_DIR="$ANDROID_HOME"
elif [ -n "$ANDROID_SDK_ROOT" ]; then
    SDK_DIR="$ANDROID_SDK_ROOT"
elif [ -d "$HOME/Library/Android/sdk" ]; then
    SDK_DIR="$HOME/Library/Android/sdk"
elif [ -d "$HOME/Android/Sdk" ]; then
    SDK_DIR="$HOME/Android/Sdk"
else
    echo -e "${RED}❌ Android SDK not found${NC}"
    echo "Please set ANDROID_HOME or ANDROID_SDK_ROOT environment variable"
    exit 1
fi

# Find Flutter SDK location
if [ -n "$FLUTTER_ROOT" ]; then
    FLUTTER_SDK_DIR="$FLUTTER_ROOT"
else
    # Get Flutter SDK path from flutter command
    FLUTTER_SDK_DIR=$(which flutter | xargs dirname | xargs dirname)
fi

# Create local.properties
echo "sdk.dir=$SDK_DIR" > "$LOCAL_PROPS"
echo "flutter.sdk=$FLUTTER_SDK_DIR" >> "$LOCAL_PROPS"
echo -e "${GREEN}✅ local.properties configured${NC}"
echo -e "   ${BLUE}sdk.dir=$SDK_DIR${NC}"
echo -e "   ${BLUE}flutter.sdk=$FLUTTER_SDK_DIR${NC}"
echo ""

# Step 11: Build AAR using Flutter command
echo "1️⃣1️⃣  Building Flutter AAR..."
cd "$SDK_ROOT/reels_flutter"

# Determine build variant (default to debug if not specified)
BUILD_VARIANT="${1:-debug}"

echo -e "${BLUE}Building variant: $BUILD_VARIANT${NC}"
echo ""

# Build AAR using Flutter's build command
# This will build all necessary dependencies properly
if [ "$BUILD_VARIANT" = "debug" ]; then
    if flutter build aar --debug --no-release --no-profile; then
        echo -e "${GREEN}✅ Flutter AAR build completed${NC}"
    else
        echo -e "${RED}❌ Flutter AAR build failed${NC}"
        exit 1
    fi
else
    if flutter build aar --release --no-debug --no-profile; then
        echo -e "${GREEN}✅ Flutter AAR build completed${NC}"
    else
        echo -e "${RED}❌ Flutter AAR build failed${NC}"
        exit 1
    fi
fi
echo ""

# Step 12: Verify AAR output
echo "1️⃣2️⃣  Verifying AAR output..."
AAR_DIR="$SDK_ROOT/reels_flutter/build/host/outputs/repo"
AAR_FILE="$AAR_DIR/com/example/reels_flutter/flutter_${BUILD_VARIANT}/1.0/flutter_${BUILD_VARIANT}-1.0.aar"

if [ ! -f "$AAR_FILE" ]; then
    echo -e "${RED}❌ AAR file not found: $AAR_FILE${NC}"
    echo "Available files in $AAR_DIR:"
    ls -la "$AAR_DIR" 2>/dev/null || echo "Directory not found"
    exit 1
fi

AAR_SIZE=$(du -h "$AAR_FILE" | cut -f1)
echo -e "${GREEN}✅ AAR file built: reels_android-${BUILD_VARIANT}.aar ($AAR_SIZE)${NC}"
echo ""

# Success summary
echo "============================================"
echo "✅ Build Complete!"
echo "============================================"
echo ""
echo "📊 Summary:"
echo -e "  ${GREEN}✓${NC} Flutter clean & pub get"
echo -e "  ${GREEN}✓${NC} Pigeon code regenerated"
echo -e "  ${GREEN}✓${NC} Flutter AAR built (${BUILD_VARIANT})"
echo ""
echo "📁 Output Location:"
echo -e "   ${BLUE}$AAR_DIR${NC}"
echo ""
echo "📝 Flutter AAR Output:"
echo -e "   Flutter module AAR and all dependencies are in: ${BLUE}$AAR_DIR${NC}"
echo ""
echo -e "${GREEN}🎉 Build complete!${NC}"
echo ""
