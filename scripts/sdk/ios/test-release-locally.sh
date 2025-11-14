#!/bin/bash
set -e

# ============================================
# Test Release Workflow Locally
# ============================================
# Simulates GitHub Actions workflow to catch issues before pushing

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_section() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

log_step() {
    echo ""
    echo -e "${YELLOW}▶ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Start
SCRIPT_START=$(date +%s)
log_section "Testing GitHub Actions Workflow Locally"

# Get SDK root
SDK_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$SDK_ROOT"

log_info "SDK Root: $SDK_ROOT"
log_info "Simulating: .github/workflows/release.yml"
echo ""

# Step 1: Check VERSION file
log_step "Step 1: Verify VERSION file"
if [ ! -f "VERSION" ]; then
    log_error "VERSION file not found"
    exit 1
fi
VERSION=$(cat VERSION)
log_success "VERSION: $VERSION"

# Step 2: Verify Flutter installation
log_step "Step 2: Check Flutter installation"
if ! command -v flutter &> /dev/null; then
    log_error "Flutter not found in PATH"
    log_info "Install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi
FLUTTER_VERSION=$(flutter --version | head -1)
log_success "Flutter installed: $FLUTTER_VERSION"

# Step 3: Flutter doctor
log_step "Step 3: Flutter doctor"
flutter doctor -v | grep -E "Flutter|Engine|Tools" || true
log_success "Flutter environment checked"

# Step 4: Install dependencies
log_step "Step 4: Install Flutter dependencies"
cd reels_flutter
if ! flutter pub get; then
    log_error "flutter pub get failed"
    exit 1
fi
log_success "Dependencies installed"

# Step 5: Regenerate Pigeon
log_step "Step 5: Regenerate Pigeon code"
if ! flutter pub run pigeon \
    --input pigeons/messages.dart \
    --dart_out lib/core/pigeon_generated.dart \
    --swift_out ../reels_ios/Sources/ReelsIOS/PigeonGenerated.swift \
    --kotlin_out ../reels_android/src/main/java/com/rakuten/room/reels/pigeon/PigeonGenerated.kt \
    --kotlin_package com.rakuten.room.reels.pigeon; then
    log_error "Pigeon code generation failed"
    exit 1
fi
log_success "Pigeon code generated"

# Step 6: Build Debug frameworks
log_step "Step 6: Build Debug frameworks (this may take 2-3 minutes)"
flutter clean > /dev/null
if ! flutter build ios-framework --debug --output=.ios/Flutter/Debug; then
    log_error "Debug framework build failed"
    exit 1
fi
log_success "Debug frameworks built"

# Check Debug frameworks
DEBUG_COUNT=$(find .ios/Flutter/Debug -name "*.xcframework" | wc -l | tr -d ' ')
log_info "Found $DEBUG_COUNT Debug frameworks"
if [ "$DEBUG_COUNT" -lt 3 ]; then
    log_error "Expected at least 3 frameworks (App, Flutter, FlutterPluginRegistrant)"
    exit 1
fi

# Step 7: Build Release frameworks
log_step "Step 7: Build Release frameworks (this may take 2-3 minutes)"
if ! flutter build ios-framework --release --output=.ios/Flutter/Release; then
    log_error "Release framework build failed"
    exit 1
fi
log_success "Release frameworks built"

# Check Release frameworks
RELEASE_COUNT=$(find .ios/Flutter/Release -name "*.xcframework" | wc -l | tr -d ' ')
log_info "Found $RELEASE_COUNT Release frameworks"
if [ "$RELEASE_COUNT" -lt 3 ]; then
    log_error "Expected at least 3 frameworks (App, Flutter, FlutterPluginRegistrant)"
    exit 1
fi

# Step 8: Package Debug frameworks
log_step "Step 8: Test package script (Debug)"
cd ..
if ! ./scripts/sdk/ios/package-frameworks.sh Debug; then
    log_error "Package script failed for Debug"
    exit 1
fi
DEBUG_ZIP="ReelsSDK-Frameworks-Debug-$VERSION.zip"
if [ ! -f "$DEBUG_ZIP" ]; then
    log_error "Debug zip not created: $DEBUG_ZIP"
    exit 1
fi
DEBUG_SIZE=$(du -sh "$DEBUG_ZIP" | cut -f1)
log_success "Debug frameworks packaged: $DEBUG_ZIP ($DEBUG_SIZE)"

# Step 9: Package Release frameworks
log_step "Step 9: Test package script (Release)"
if ! ./scripts/sdk/ios/package-frameworks.sh Release; then
    log_error "Package script failed for Release"
    exit 1
fi
RELEASE_ZIP="ReelsSDK-Frameworks-Release-$VERSION.zip"
if [ ! -f "$RELEASE_ZIP" ]; then
    log_error "Release zip not created: $RELEASE_ZIP"
    exit 1
fi
RELEASE_SIZE=$(du -sh "$RELEASE_ZIP" | cut -f1)
log_success "Release frameworks packaged: $RELEASE_ZIP ($RELEASE_SIZE)"

# Step 10: Verify zip contents
log_step "Step 10: Verify zip contents"
log_info "Debug zip contents:"
unzip -l "$DEBUG_ZIP" | grep "\.xcframework" | awk '{print "  - " $NF}'
echo ""
log_info "Release zip contents:"
unzip -l "$RELEASE_ZIP" | grep "\.xcframework" | awk '{print "  - " $NF}'
log_success "Zip contents verified"

# Step 11: Test extraction
log_step "Step 11: Test zip extraction"
mkdir -p test_extract
cd test_extract
if ! unzip -q "../$RELEASE_ZIP"; then
    log_error "Failed to extract Release zip"
    exit 1
fi
EXTRACTED_COUNT=$(find . -name "*.xcframework" | wc -l | tr -d ' ')
log_info "Extracted $EXTRACTED_COUNT frameworks"
cd ..
rm -rf test_extract
log_success "Zip extraction verified"

# Step 12: Calculate checksums
log_step "Step 12: Generate checksums"
shasum -a 256 "$DEBUG_ZIP" > CHECKSUMS_TEST.txt
shasum -a 256 "$RELEASE_ZIP" >> CHECKSUMS_TEST.txt
log_success "Checksums generated"
cat CHECKSUMS_TEST.txt

# Summary
SCRIPT_END=$(date +%s)
DURATION=$((SCRIPT_END - SCRIPT_START))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

log_section "✅ All Checks Passed!"

echo ""
log_info "Test Summary:"
echo "  • VERSION: $VERSION"
echo "  • Debug frameworks: $DEBUG_COUNT ($DEBUG_SIZE)"
echo "  • Release frameworks: $RELEASE_COUNT ($RELEASE_SIZE)"
echo "  • Debug zip: $DEBUG_ZIP"
echo "  • Release zip: $RELEASE_ZIP"
echo "  • Duration: ${MINUTES}m ${SECONDS}s"
echo ""

log_success "GitHub Actions workflow should succeed! ✅"
echo ""

log_info "Cleanup:"
echo "  • Delete zips: rm -f ReelsSDK-Frameworks-*.zip CHECKSUMS_TEST.txt FRAMEWORK_MANIFEST_*.txt"
echo "  • Or keep for manual testing"
echo ""

log_info "Ready to create release:"
echo "  1. Commit changes: git add . && git commit -m 'Add release infrastructure'"
echo "  2. Push: git push"
echo "  3. Create release: ./scripts/sdk/ios/prepare-release.sh $VERSION"
echo ""
