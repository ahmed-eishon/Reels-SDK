#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================"
echo "🍎 Reels SDK - iOS Client Initialization"
echo "============================================"
echo ""

# Check if SDK path is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: SDK path required${NC}"
    echo ""
    echo "Usage: ./init-ios.sh <path-to-reels-sdk> [path-to-your-podfile-directory]"
    echo "Example: ./init-ios.sh /Users/yourname/Rakuten/reels-sdk /Users/yourname/your-ios-app"
    exit 1
fi

SDK_PATH="$1"
PODFILE_DIR="${2:-.}"

# Verify SDK path exists
if [ ! -d "$SDK_PATH" ]; then
    echo -e "${RED}❌ Error: SDK path not found: $SDK_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}📁 SDK Path: $SDK_PATH${NC}"
if [ "$PODFILE_DIR" != "." ]; then
    echo -e "${BLUE}📁 Podfile Directory: $PODFILE_DIR${NC}"
fi
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

# Step 4: Verify .ios directory was created
echo "4️⃣  Verifying iOS platform files..."
if [ ! -f "$SDK_PATH/reels_flutter/.ios/Flutter/podhelper.rb" ]; then
    echo -e "${RED}❌ iOS platform files not generated${NC}"
    exit 1
fi
echo -e "${GREEN}✅ iOS platform files generated${NC}"
echo ""

# Step 5: Check flutter_export_environment.sh
echo "5️⃣  Checking Flutter environment configuration..."
if [ -f "$SDK_PATH/reels_flutter/.ios/Flutter/flutter_export_environment.sh" ]; then
    FLUTTER_APP_PATH=$(grep "FLUTTER_APPLICATION_PATH=" "$SDK_PATH/reels_flutter/.ios/Flutter/flutter_export_environment.sh" | cut -d'=' -f2 | tr -d '"')
    if [ "$FLUTTER_APP_PATH" == "$SDK_PATH/reels_flutter" ]; then
        echo -e "${GREEN}✅ Flutter environment correctly configured${NC}"
    else
        echo -e "${YELLOW}⚠️  Flutter path in environment: $FLUTTER_APP_PATH${NC}"
        echo -e "${YELLOW}   Expected: $SDK_PATH/reels_flutter${NC}"
        echo "   This will be corrected when you run 'pod install' in your project"
    fi
else
    echo -e "${YELLOW}⚠️  flutter_export_environment.sh not found${NC}"
fi
echo ""

# Step 6: Verify reels_ios module
echo "6️⃣  Verifying iOS module..."
if [ ! -f "$SDK_PATH/reels_ios/Package.swift" ]; then
    echo -e "${RED}❌ iOS module not found at $SDK_PATH/reels_ios${NC}"
    exit 1
fi
echo -e "${GREEN}✅ iOS module found${NC}"
echo ""

# Step 7: Check Pigeon files
echo "7️⃣  Checking Pigeon generated files..."
if [ ! -f "$SDK_PATH/reels_ios/Sources/ReelsIOS/PigeonGenerated.swift" ]; then
    echo -e "${YELLOW}⚠️  PigeonGenerated.swift not found${NC}"
    echo "   If you need to regenerate Pigeon files, run:"
    echo "   cd $SDK_PATH/reels_flutter"
    echo "   flutter pub run pigeon --input pigeons/messages.dart"
else
    echo -e "${GREEN}✅ Pigeon files present${NC}"
fi
echo ""

# Step 8: Check CocoaPods
echo "8️⃣  Checking CocoaPods installation..."
if ! command -v pod &> /dev/null; then
    echo -e "${YELLOW}⚠️  CocoaPods not found${NC}"
    echo "   Install with: sudo gem install cocoapods"
else
    POD_VERSION=$(pod --version)
    echo -e "${GREEN}✅ CocoaPods $POD_VERSION${NC}"
fi
echo ""

# Success summary
echo "============================================"
echo "✅ iOS Client Initialization Complete!"
echo "============================================"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1️⃣  Update your Podfile:"
echo ""
echo -e "${BLUE}# Flutter module integration - External folder import"
echo "flutter_application_path = '$SDK_PATH/reels_flutter'"
echo "load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')"
echo ""
echo "target 'YourApp' do"
echo "  # Your existing pods..."
echo "  "
echo "  # Install Flutter pods"
echo "  install_all_flutter_pods(flutter_application_path)"
echo "end"
echo ""
echo "post_install do |installer|"
echo "  # Flutter post install"
echo "  flutter_post_install(installer)"
echo "  "
echo "  # Your existing post_install code..."
echo "end${NC}"
echo ""
echo "2️⃣  Update your Xcode project to reference reels_ios:"
echo ""
echo "   - In Xcode, remove any local reels_ios group if it exists"
echo "   - Add files from external location:"
echo "     Right-click project → Add Files → Navigate to:"
echo "     $SDK_PATH/reels_ios/Sources/ReelsIOS"
echo "   - Select 'Create groups' and ensure target is checked"
echo ""
echo "3️⃣  Run pod install:"
echo ""
if [ "$PODFILE_DIR" != "." ]; then
    echo -e "${BLUE}cd $PODFILE_DIR"
    echo "pod install${NC}"
else
    echo -e "${BLUE}pod install${NC}"
fi
echo ""
echo "4️⃣  Open the .xcworkspace file (not .xcodeproj)"
echo ""
echo "⚠️  Important Note:"
echo ""
echo "   If you ever run 'flutter clean' in the reels_flutter module,"
echo "   you must re-run 'flutter pub get' to regenerate the .ios directory:"
echo ""
echo -e "${BLUE}cd $SDK_PATH/reels_flutter"
echo "flutter pub get${NC}"
echo ""
echo -e "${GREEN}🎉 Ready to integrate Reels SDK!${NC}"
echo ""
