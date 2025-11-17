#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================"
echo "🤖 Reels SDK - Android Client Initialization"
echo "============================================"
echo ""

# Check if SDK path is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: SDK path required${NC}"
    echo ""
    echo "Usage: ./init-android.sh <path-to-reels-sdk>"
    echo "Example: ./init-android.sh /Users/yourname/Rakuten/reels-sdk"
    exit 1
fi

SDK_PATH="$1"

# Verify SDK path exists
if [ ! -d "$SDK_PATH" ]; then
    echo -e "${RED}❌ Error: SDK path not found: $SDK_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}📁 SDK Path: $SDK_PATH${NC}"
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
if [ ! -f "$SDK_PATH/reels_flutter/pubspec.yaml" ]; then
    echo -e "${RED}❌ Flutter module not found at $SDK_PATH/reels_flutter${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flutter module found${NC}"
echo ""

# Step 3: Run flutter pub get
echo "3️⃣  Running flutter pub get..."
cd "$SDK_PATH/reels_flutter"
if flutter pub get; then
    echo -e "${GREEN}✅ Flutter dependencies resolved${NC}"
else
    echo -e "${RED}❌ Failed to get Flutter dependencies${NC}"
    exit 1
fi
echo ""

# Step 4: Verify .android directory was created
echo "4️⃣  Verifying Android platform files..."
if [ ! -f "$SDK_PATH/reels_flutter/.android/include_flutter.groovy" ]; then
    echo -e "${RED}❌ Android platform files not generated${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Android platform files generated${NC}"
echo ""

# Step 5: Verify reels_android module
echo "5️⃣  Verifying Android module..."
if [ ! -f "$SDK_PATH/reels_android/build.gradle" ]; then
    echo -e "${RED}❌ Android module not found at $SDK_PATH/reels_android${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Android module found${NC}"
echo ""

# Step 6: Check Pigeon files
echo "6️⃣  Checking Pigeon generated files..."
if [ ! -f "$SDK_PATH/reels_android/src/main/java/com/rakuten/room/reels/pigeon/PigeonGenerated.kt" ]; then
    echo -e "${YELLOW}⚠️  PigeonGenerated.kt not found${NC}"
    echo "   If you need to regenerate Pigeon files, run:"
    echo "   cd $SDK_PATH/reels_flutter"
    echo "   flutter pub run pigeon --input pigeons/messages.dart"
else
    echo -e "${GREEN}✅ Pigeon files present${NC}"
fi
echo ""

# Success summary
echo "============================================"
echo "✅ Android Client Initialization Complete!"
echo "============================================"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1️⃣  Add to your settings.gradle:"
echo ""
echo -e "${BLUE}rootProject.name = 'your-app'"
echo "include ':app'"
echo ""
echo "// Reels SDK - External folder import"
echo "include ':reels_android'"
echo "project(':reels_android').projectDir = new File('$SDK_PATH/reels_android')"
echo ""
echo "// Flutter module from reels-sdk"
echo "setBinding(new Binding([gradle: this]))"
echo "evaluate(new File("
echo "  '$SDK_PATH/reels_flutter/.android/include_flutter.groovy'"
echo "))${NC}"
echo ""
echo "2️⃣  Add to your app/build.gradle:"
echo ""
echo -e "${BLUE}dependencies {"
echo "    implementation project(':reels_android')"
echo "}${NC}"
echo ""
echo "3️⃣  Sync your project:"
echo ""
echo -e "${BLUE}./gradlew clean build${NC}"
echo ""
echo -e "${GREEN}🎉 Ready to integrate Reels SDK!${NC}"
echo ""
