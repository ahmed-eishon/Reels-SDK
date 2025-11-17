#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================"
echo "🧹 Reels SDK - Android Clean Install"
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

# Step 9: Verify Android module structure
echo "9️⃣  Verifying Android module structure..."
if [ ! -f "$SDK_ROOT/reels_android/build.gradle" ]; then
    echo -e "${RED}❌ reels_android/build.gradle not found${NC}"
    exit 1
fi

KOTLIN_FILES=$(find "$SDK_ROOT/reels_android/src/main/java" -name "*.kt" 2>/dev/null | wc -l | tr -d ' ')
if [ "$KOTLIN_FILES" -eq 0 ]; then
    echo -e "${RED}❌ No Kotlin files found in reels_android${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Android module structure verified ($KOTLIN_FILES Kotlin files)${NC}"
echo ""

# Step 10: Check Gradle
echo "🔟  Checking Android build tools..."
if command -v gradle &> /dev/null; then
    GRADLE_VERSION=$(gradle --version | grep "Gradle" | head -n 1)
    echo -e "${GREEN}✅ $GRADLE_VERSION${NC}"
else
    echo -e "${YELLOW}ℹ️  Gradle wrapper will be used from Android project${NC}"
fi
echo ""

# Success summary
echo "============================================"
echo "✅ Android Clean Install Complete!"
echo "============================================"
echo ""
echo "📊 Summary:"
echo -e "  ${GREEN}✓${NC} Flutter clean & pub get"
echo -e "  ${GREEN}✓${NC} Android platform files regenerated"
echo -e "  ${GREEN}✓${NC} Pigeon code regenerated"
echo -e "  ${GREEN}✓${NC} All files verified"
echo ""
echo "📝 Next Steps for Client Integration:"
echo ""
echo "1️⃣  If you have an Android app that needs to integrate this SDK:"
echo ""
echo "   Add to your settings.gradle:"
echo -e "   ${BLUE}// Reels SDK - External folder import"
echo "   include ':reels_android'"
echo "   project(':reels_android').projectDir = new File('$SDK_ROOT/reels_android')"
echo ""
echo "   // Flutter module from reels-sdk"
echo "   setBinding(new Binding([gradle: this]))"
echo "   evaluate(new File("
echo "     '$SDK_ROOT/reels_flutter/.android/include_flutter.groovy'"
echo "   ))${NC}"
echo ""
echo "2️⃣  Add to your app/build.gradle dependencies:"
echo -e "   ${BLUE}dependencies {"
echo "       implementation project(':reels_android')"
echo "   }${NC}"
echo ""
echo "3️⃣  Sync and build your Android project:"
echo -e "   ${BLUE}./gradlew clean build${NC}"
echo ""
echo -e "${GREEN}🎉 Ready for Android integration!${NC}"
echo ""
