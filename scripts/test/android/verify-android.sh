#!/bin/bash
set -e

echo "============================================"
echo "🤖 Android SDK Verification Script"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📁 SDK Root: $SDK_ROOT"
echo ""

# Step 1: Verify VERSION file
echo "1️⃣  Checking VERSION file..."
if [ ! -f "$SDK_ROOT/VERSION" ]; then
    echo -e "${RED}❌ VERSION file not found${NC}"
    exit 1
fi
VERSION=$(cat "$SDK_ROOT/VERSION")
echo -e "${GREEN}✅ VERSION: $VERSION${NC}"
echo ""

# Step 2: Verify Android module structure
echo "2️⃣  Checking Android module structure..."
if [ ! -f "$SDK_ROOT/reels_android/build.gradle" ]; then
    echo -e "${RED}❌ build.gradle not found${NC}"
    exit 1
fi
echo -e "${GREEN}✅ build.gradle found${NC}"
echo ""

# Step 3: Verify Kotlin source files
echo "3️⃣  Checking Kotlin source files..."
KOTLIN_FILES=$(find "$SDK_ROOT/reels_android/src" -name "*.kt" 2>/dev/null | wc -l | tr -d ' ')
if [ "$KOTLIN_FILES" -eq 0 ]; then
    echo -e "${RED}❌ No Kotlin files found${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Found $KOTLIN_FILES Kotlin files${NC}"
echo ""

# Step 4: Verify Flutter module
echo "4️⃣  Checking Flutter module..."
if [ ! -f "$SDK_ROOT/reels_flutter/pubspec.yaml" ]; then
    echo -e "${RED}❌ Flutter pubspec.yaml not found${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flutter module found${NC}"
echo ""

# Step 5: Check Pigeon generated files
echo "5️⃣  Checking Pigeon generated files..."
if [ ! -f "$SDK_ROOT/reels_android/src/main/java/com/rakuten/room/reels/pigeon/PigeonGenerated.kt" ]; then
    echo -e "${RED}❌ PigeonGenerated.kt not found${NC}"
    exit 1
fi
if [ ! -f "$SDK_ROOT/reels_flutter/lib/core/pigeon_generated.dart" ]; then
    echo -e "${RED}❌ pigeon_generated.dart not found${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Pigeon generated files present${NC}"
echo ""

# Step 6: Verify Android Manifest
echo "6️⃣  Checking AndroidManifest.xml..."
if [ ! -f "$SDK_ROOT/reels_android/src/main/AndroidManifest.xml" ]; then
    echo -e "${RED}❌ AndroidManifest.xml not found${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AndroidManifest.xml found${NC}"
echo ""

# Step 7: Check Maven publishing configuration
echo "7️⃣  Checking Maven publishing configuration..."
if grep -q "maven-publish" "$SDK_ROOT/reels_android/build.gradle"; then
    echo -e "${GREEN}✅ Maven publishing configured (Git-based, private)${NC}"
else
    echo -e "${YELLOW}⚠️  Maven publishing not configured${NC}"
fi
echo ""

# Summary
echo "============================================"
echo "📊 Android SDK Verification Summary"
echo "============================================"
echo -e "Version: ${GREEN}$VERSION${NC}"
echo -e "Gradle Module: ${GREEN}✓${NC}"
echo -e "Kotlin Files: ${GREEN}✓ ($KOTLIN_FILES files)${NC}"
echo -e "Flutter Module: ${GREEN}✓${NC}"
echo -e "Pigeon Files: ${GREEN}✓${NC}"
echo ""
echo -e "${GREEN}✅ Android SDK verification completed!${NC}"
echo ""
echo "📦 To integrate in your Android project:"
echo ""
echo "  # Step 1: Add to settings.gradle:"
echo "  sourceControl {"
echo "      gitRepository(uri(\"https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git\")) {"
echo "          producesModule(\"com.rakuten.room:reels-sdk\")"
echo "      }"
echo "  }"
echo ""
echo "  # Step 2: Add to app/build.gradle:"
echo "  dependencies {"
echo "      implementation 'com.rakuten.room:reels-sdk:$VERSION'"
echo "  }"
echo ""
