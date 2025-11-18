#!/bin/bash

# ReelsSDK Android - Local Release Testing Script
#
# This script simulates the GitHub Actions workflow locally,
# allowing you to test AAR building before pushing tags.
#
# Usage:
#   ./scripts/sdk/android/test-release-locally.sh           # Test both Debug and Release
#   ./scripts/sdk/android/test-release-locally.sh debug     # Test Debug only
#   ./scripts/sdk/android/test-release-locally.sh release   # Test Release only

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  ReelsSDK Android - Local Release Test${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Change to root directory
cd "$ROOT_DIR"

# Read version
if [ ! -f "VERSION" ]; then
    echo -e "${RED}ERROR: VERSION file not found${NC}"
    exit 1
fi

VERSION=$(cat VERSION | tr -d '[:space:]')
echo -e "${GREEN}Version: ${VERSION}${NC}"
echo ""

# Determine which builds to test
BUILD_DEBUG=true
BUILD_RELEASE=true

if [ "$1" == "debug" ]; then
    BUILD_RELEASE=false
    echo -e "${YELLOW}Testing Debug build only${NC}"
elif [ "$1" == "release" ]; then
    BUILD_DEBUG=false
    echo -e "${YELLOW}Testing Release build only${NC}"
else
    echo -e "${YELLOW}Testing both Debug and Release builds${NC}"
fi
echo ""

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}ERROR: Flutter not found${NC}"
    echo "Install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo -e "${GREEN}✓ Flutter installed: $(flutter --version | head -n 1)${NC}"

# Check Java
if ! command -v java &> /dev/null; then
    echo -e "${RED}ERROR: Java not found${NC}"
    echo "Install Java 17: https://adoptium.net/"
    exit 1
fi
echo -e "${GREEN}✓ Java installed: $(java -version 2>&1 | head -n 1)${NC}"

# Check Gradle wrapper
if [ ! -f "gradlew" ]; then
    echo -e "${RED}ERROR: gradlew not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Gradle wrapper found${NC}"
echo ""

# Function to build Flutter AAR
build_flutter_aar() {
    local BUILD_MODE=$1
    echo -e "${BLUE}Building Flutter AAR (${BUILD_MODE})...${NC}"

    cd "$ROOT_DIR/reels_flutter"

    # Get dependencies
    echo "Running flutter pub get..."
    flutter pub get

    # Run Pigeon
    echo "Running Pigeon code generation..."
    flutter pub run pigeon --input pigeons/messages.dart

    # Build AAR
    if [ "$BUILD_MODE" == "Release" ]; then
        echo "Building Flutter AAR in Release mode..."
        flutter build aar --release --no-debug --no-profile
    else
        echo "Building Flutter AAR in Debug mode..."
        flutter build aar --debug --no-release --no-profile
    fi

    cd "$ROOT_DIR"
    echo -e "${GREEN}✓ Flutter AAR built successfully${NC}"
    echo ""
}

# Function to build reels_android AAR
build_reels_android_aar() {
    local BUILD_MODE=$1
    echo -e "${BLUE}Building reels_android AAR (${BUILD_MODE})...${NC}"

    cd "$ROOT_DIR/reels_android"

    if [ "$BUILD_MODE" == "Release" ]; then
        ../gradlew assembleRelease --no-daemon --stacktrace \
            -Pandroid.enableJetifier=false \
            -Dorg.gradle.jvmargs="-Xmx4096m -Dfile.encoding=UTF-8"
    else
        ../gradlew assembleDebug --no-daemon --stacktrace \
            -Pandroid.enableJetifier=false \
            -Dorg.gradle.jvmargs="-Xmx4096m -Dfile.encoding=UTF-8"
    fi

    cd "$ROOT_DIR"
    echo -e "${GREEN}✓ reels_android AAR built successfully${NC}"
    echo ""
}

# Function to package AAR
package_aar() {
    local BUILD_MODE=$1
    echo -e "${BLUE}Packaging ${BUILD_MODE} AAR...${NC}"

    if [ "$BUILD_MODE" == "Release" ]; then
        PACKAGE_DIR="ReelsSDK-Android-${VERSION}"
        AAR_NAME="reels-sdk-${VERSION}.aar"
        FLUTTER_AAR_NAME="flutter-release-${VERSION}.aar"
        FLUTTER_SOURCE="reels_flutter/build/host/outputs/repo/com/example/reels_flutter/flutter_release/1.0/flutter_release-1.0.aar"
        ANDROID_SOURCE="reels_android/build/outputs/aar/reels_android-release.aar"
    else
        PACKAGE_DIR="ReelsSDK-Android-Debug-${VERSION}"
        AAR_NAME="reels-sdk-debug-${VERSION}.aar"
        FLUTTER_AAR_NAME="flutter-debug-${VERSION}.aar"
        FLUTTER_SOURCE="reels_flutter/build/host/outputs/repo/com/example/reels_flutter/flutter_debug/1.0/flutter_debug-1.0.aar"
        ANDROID_SOURCE="reels_android/build/outputs/aar/reels_android-debug.aar"
    fi

    # Create package directory
    mkdir -p "$PACKAGE_DIR"

    # Copy AARs
    echo "Copying reels_android AAR..."
    if [ ! -f "$ANDROID_SOURCE" ]; then
        echo -e "${RED}ERROR: $ANDROID_SOURCE not found${NC}"
        exit 1
    fi
    cp "$ANDROID_SOURCE" "$PACKAGE_DIR/$AAR_NAME"

    echo "Copying Flutter AAR..."
    if [ ! -f "$FLUTTER_SOURCE" ]; then
        echo -e "${RED}ERROR: $FLUTTER_SOURCE not found${NC}"
        exit 1
    fi
    cp "$FLUTTER_SOURCE" "$PACKAGE_DIR/$FLUTTER_AAR_NAME"

    # Create README
    cat > "$PACKAGE_DIR/README.md" <<EOF
# ReelsSDK Android - ${BUILD_MODE} Build

Version: ${VERSION}
Build: ${BUILD_MODE}

## Contents

- \`${AAR_NAME}\` - Main SDK AAR (${BUILD_MODE} build)
- \`${FLUTTER_AAR_NAME}\` - Flutter dependencies (${BUILD_MODE})

## Integration

1. Copy both AAR files to your \`app/libs/\` directory

2. Add to your \`app/build.gradle\`:

\`\`\`gradle
android {
    ...
}

repositories {
    flatDir {
        dirs 'libs'
    }
}

dependencies {
    implementation(name: '${AAR_NAME%.aar}', ext: 'aar')
    implementation(name: '${FLUTTER_AAR_NAME%.aar}', ext: 'aar')

    // Required dependencies
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.google.android.material:material:1.11.0'
}
\`\`\`

3. Sync Gradle and build

## Documentation

See: https://github.com/ahmed-eishon/Reels-SDK/blob/master/docs/02-Integration/02-Android-Integration-Guide.md
EOF

    # Create zip
    ZIP_NAME="${PACKAGE_DIR}.zip"
    zip -r "$ZIP_NAME" "$PACKAGE_DIR"

    # Calculate checksum
    shasum -a 256 "$ZIP_NAME" > "${ZIP_NAME}.sha256"

    echo -e "${GREEN}✓ Package created: ${ZIP_NAME}${NC}"
    echo ""

    # Show contents
    echo -e "${BLUE}Package contents:${NC}"
    ls -lh "$PACKAGE_DIR"
    echo ""
    echo -e "${BLUE}Package size:${NC}"
    du -h "$ZIP_NAME"
    echo ""
}

# Build and package Release
if [ "$BUILD_RELEASE" = true ]; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  Building Release AAR${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""

    build_flutter_aar "Release"
    build_reels_android_aar "Release"
    package_aar "Release"

    echo -e "${GREEN}✅ Release build completed successfully!${NC}"
    echo ""
fi

# Build and package Debug
if [ "$BUILD_DEBUG" = true ]; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  Building Debug AAR${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""

    build_flutter_aar "Debug"
    build_reels_android_aar "Debug"
    package_aar "Debug"

    echo -e "${GREEN}✅ Debug build completed successfully!${NC}"
    echo ""
fi

# Summary
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Build Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${GREEN}Version: ${VERSION}${NC}"
echo ""

if [ "$BUILD_RELEASE" = true ]; then
    echo -e "${GREEN}✓ Release AAR:${NC} ReelsSDK-Android-${VERSION}.zip"
fi

if [ "$BUILD_DEBUG" = true ]; then
    echo -e "${GREEN}✓ Debug AAR:${NC} ReelsSDK-Android-Debug-${VERSION}.zip"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test the AAR files locally with your Android app"
echo "2. If everything works, push tags to trigger GitHub Actions:"
echo ""

if [ "$BUILD_RELEASE" = true ]; then
    echo -e "   ${BLUE}git tag v${VERSION}-android${NC}"
    echo -e "   ${BLUE}git push origin v${VERSION}-android${NC}"
fi

if [ "$BUILD_DEBUG" = true ]; then
    echo -e "   ${BLUE}git tag v${VERSION}-android-debug${NC}"
    echo -e "   ${BLUE}git push origin v${VERSION}-android-debug${NC}"
fi

echo ""
echo -e "${GREEN}✅ Local release test completed successfully!${NC}"
