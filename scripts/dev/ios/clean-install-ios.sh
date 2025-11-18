#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================"
echo "🧹 Reels SDK - iOS Clean Install"
echo "============================================"
echo ""

# Get script directory and SDK root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# Step 4: Remove .ios directory
echo "4️⃣  Removing .ios directory..."
if [ -d "$SDK_ROOT/reels_flutter/.ios" ]; then
    rm -rf "$SDK_ROOT/reels_flutter/.ios"
    echo -e "${GREEN}✅ .ios directory removed${NC}"
else
    echo -e "${YELLOW}ℹ️  .ios directory already clean${NC}"
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

# Step 6: Verify .ios directory was created
echo "6️⃣  Verifying iOS platform files..."
if [ ! -f "$SDK_ROOT/reels_flutter/.ios/Flutter/podhelper.rb" ]; then
    echo -e "${RED}❌ iOS platform files not generated${NC}"
    exit 1
fi
echo -e "${GREEN}✅ iOS platform files generated${NC}"
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

# Step 8: Verify Pigeon generated files for iOS
echo "8️⃣  Verifying Pigeon files for iOS..."
PIGEON_ERRORS=0

# Check Flutter pigeon_generated.dart
if [ ! -f "$SDK_ROOT/reels_flutter/lib/core/pigeon_generated.dart" ]; then
    echo -e "${RED}❌ lib/core/pigeon_generated.dart not found${NC}"
    PIGEON_ERRORS=$((PIGEON_ERRORS + 1))
else
    echo -e "${GREEN}✅ lib/core/pigeon_generated.dart${NC}"
fi

# Check iOS PigeonGenerated.swift
if [ ! -f "$SDK_ROOT/reels_ios/Sources/ReelsIOS/PigeonGenerated.swift" ]; then
    echo -e "${RED}❌ reels_ios/Sources/ReelsIOS/PigeonGenerated.swift not found${NC}"
    PIGEON_ERRORS=$((PIGEON_ERRORS + 1))
else
    echo -e "${GREEN}✅ reels_ios/Sources/ReelsIOS/PigeonGenerated.swift${NC}"
fi

if [ $PIGEON_ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Pigeon file verification failed${NC}"
    exit 1
fi
echo ""

# Step 9: Verify iOS module structure
echo "9️⃣  Verifying iOS module structure..."
if [ ! -f "$SDK_ROOT/reels_ios/Package.swift" ]; then
    echo -e "${RED}❌ reels_ios/Package.swift not found${NC}"
    exit 1
fi

SWIFT_FILES=$(find "$SDK_ROOT/reels_ios/Sources/ReelsIOS" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SWIFT_FILES" -eq 0 ]; then
    echo -e "${RED}❌ No Swift files found in reels_ios${NC}"
    exit 1
fi
echo -e "${GREEN}✅ iOS module structure verified ($SWIFT_FILES Swift files)${NC}"
echo ""

# Step 10: Check CocoaPods
echo "🔟  Checking CocoaPods installation..."
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
echo "✅ iOS Clean Install Complete!"
echo "============================================"
echo ""
echo "📊 Summary:"
echo -e "  ${GREEN}✓${NC} Flutter clean & pub get"
echo -e "  ${GREEN}✓${NC} iOS platform files regenerated"
echo -e "  ${GREEN}✓${NC} Pigeon code regenerated"
echo -e "  ${GREEN}✓${NC} All files verified"
echo ""
echo "📝 Next Steps for Client Integration:"
echo ""
echo "1️⃣  If you have an iOS app that needs to integrate this SDK:"
echo ""
echo "   Update your Podfile with:"
echo -e "   ${BLUE}flutter_application_path = '$SDK_ROOT/reels_flutter'"
echo "   load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')"
echo ""
echo "   target 'YourApp' do"
echo "     install_all_flutter_pods(flutter_application_path)"
echo "   end"
echo ""
echo "   post_install do |installer|"
echo "     flutter_post_install(installer)"
echo "   end${NC}"
echo ""
echo "2️⃣  Run pod install in your iOS project"
echo ""
echo "3️⃣  Add reels_ios Swift files to your Xcode project"
echo ""
echo -e "${GREEN}🎉 Ready for iOS integration!${NC}"
echo ""
