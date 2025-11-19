#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================"
echo "🧪 Testing Android Release Workflow Locally"
echo "============================================"
echo ""

# Get script directory and SDK root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SDK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}📁 SDK Root: $SDK_ROOT${NC}"
echo ""

# Simulate version extraction (use a test version)
VERSION="0.1.5-test"
echo -e "${BLUE}📌 Test Version: $VERSION${NC}"
echo ""

# Step 1: Check Flutter installation
echo "1️⃣  Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found in PATH${NC}"
    exit 1
fi
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✅ $FLUTTER_VERSION${NC}"
echo ""

# Step 2: Clean previous builds
echo "2️⃣  Cleaning previous builds..."
cd "$SDK_ROOT/reels_flutter"
flutter clean > /dev/null 2>&1
echo -e "${GREEN}✅ Flutter clean completed${NC}"
echo ""

# Step 3: Get Flutter dependencies
echo "3️⃣  Getting Flutter dependencies..."
cd "$SDK_ROOT/reels_flutter"
flutter pub get
echo -e "${GREEN}✅ Flutter dependencies resolved${NC}"
echo ""

# Step 4: Run Pigeon code generation
echo "4️⃣  Running Pigeon code generation..."
cd "$SDK_ROOT/reels_flutter"
flutter pub run pigeon --input pigeons/messages.dart
echo -e "${GREEN}✅ Pigeon code generated${NC}"
echo ""

# Step 5: Build Flutter AAR (Release)
echo "5️⃣  Building Flutter AAR (Release mode)..."
cd "$SDK_ROOT/reels_flutter"
flutter build aar --release --no-debug --no-profile
echo -e "${GREEN}✅ Flutter AAR build completed${NC}"
echo ""

# Step 6: List Flutter build outputs
echo "6️⃣  Listing Flutter build outputs..."
echo -e "${BLUE}=== Flutter AAR outputs ===${NC}"
find "$SDK_ROOT/reels_flutter/build/host/outputs/repo" -name "*.aar" -type f | head -10
echo ""
echo -e "${BLUE}=== Directory structure ===${NC}"
ls -lah "$SDK_ROOT/reels_flutter/build/host/outputs/repo/"
echo ""

# Step 7: Create release package (simulate workflow packaging)
echo "7️⃣  Creating release package..."
PACKAGE_DIR="ReelsSDK-Android-${VERSION}"
cd "$SDK_ROOT"

# Remove old test package if exists
rm -rf "$PACKAGE_DIR" "${PACKAGE_DIR}.zip" 2>/dev/null || true

mkdir -p "$PACKAGE_DIR"

# Copy entire Flutter AAR Maven repository
echo "Copying Flutter AAR Maven repository..."
cp -r reels_flutter/build/host/outputs/repo "$PACKAGE_DIR/maven-repo"

# Create README
cat > "$PACKAGE_DIR/README.md" <<EOF
# ReelsSDK Android - Release Build (Test)

Version: ${VERSION}
Build: Release

## Contents

- \`maven-repo/\` - Complete Maven repository with all Flutter SDK dependencies

## Integration

1. Extract the zip file

2. Add to your project's \`build.gradle\` or \`settings.gradle\`:

\`\`\`gradle
repositories {
    maven {
        url "file://\${rootProject.projectDir}/../ReelsSDK-Android-${VERSION}/maven-repo"
    }
    maven {
        url "https://storage.googleapis.com/download.flutter.io"
    }
}
\`\`\`

3. Add to your \`app/build.gradle\`:

\`\`\`gradle
dependencies {
    // ReelsSDK with all Flutter dependencies
    releaseImplementation 'com.example.reels_flutter:flutter_release:1.0'
}
\`\`\`

4. Sync Gradle and build

## Documentation

See: https://github.com/ahmed-eishon/Reels-SDK/blob/master/docs/02-Integration/02-Android-Integration-Guide.md
EOF

# Create zip
ZIP_NAME="ReelsSDK-Android-${VERSION}.zip"
zip -r "$ZIP_NAME" "$PACKAGE_DIR" > /dev/null
echo -e "${GREEN}✅ Package created: $ZIP_NAME${NC}"
echo ""

# Calculate checksum
shasum -a 256 "$ZIP_NAME" > "${ZIP_NAME}.sha256"
echo -e "${GREEN}✅ Checksum created${NC}"
echo ""

# Step 8: Show package contents
echo "8️⃣  Package Summary..."
echo -e "${BLUE}=== Package Contents ===${NC}"
du -h -d 2 "$PACKAGE_DIR" | head -20
echo ""
echo -e "${BLUE}=== AAR Files (first 10) ===${NC}"
find "$PACKAGE_DIR" -name "*.aar" | head -10
echo ""
echo -e "${BLUE}=== Package Size ===${NC}"
du -h "$ZIP_NAME"
echo ""

# Step 9: Verify key files exist
echo "9️⃣  Verifying key files..."
ERRORS=0

# Check for flutter_release AAR
if [ -f "$PACKAGE_DIR/maven-repo/com/example/reels_flutter/flutter_release/1.0/flutter_release-1.0.aar" ]; then
    echo -e "${GREEN}✅ flutter_release-1.0.aar found${NC}"
else
    echo -e "${RED}❌ flutter_release-1.0.aar NOT found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check for README
if [ -f "$PACKAGE_DIR/README.md" ]; then
    echo -e "${GREEN}✅ README.md found${NC}"
else
    echo -e "${RED}❌ README.md NOT found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check for checksum file
if [ -f "${ZIP_NAME}.sha256" ]; then
    echo -e "${GREEN}✅ Checksum file found${NC}"
else
    echo -e "${RED}❌ Checksum file NOT found${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Test failed with $ERRORS error(s)${NC}"
    exit 1
fi

# Success summary
echo "============================================"
echo "✅ Test Complete!"
echo "============================================"
echo ""
echo "📊 Summary:"
echo -e "  ${GREEN}✓${NC} Flutter AAR built successfully"
echo -e "  ${GREEN}✓${NC} Maven repository packaged"
echo -e "  ${GREEN}✓${NC} Release package created"
echo -e "  ${GREEN}✓${NC} All key files verified"
echo ""
echo "📁 Test Output Location:"
echo -e "   ${BLUE}$SDK_ROOT/$PACKAGE_DIR${NC}"
echo ""
echo "📦 Test Package:"
echo -e "   ${BLUE}$SDK_ROOT/$ZIP_NAME${NC}"
echo ""
echo -e "${GREEN}🎉 Workflow test successful!${NC}"
echo ""
echo "💡 To test integration:"
echo "   1. Extract the ZIP file"
echo "   2. Add the maven-repo path to your Android project"
echo "   3. Add the dependency and build"
echo ""
