#!/bin/bash
set -e

# This script validates that the correct ReelsSDK framework mode is installed
# for the current build configuration

CONFIGURATION="${CONFIGURATION}"
PODS_DIR="${PODS_ROOT}/ReelsSDK"

echo "🔍 Validating ReelsSDK framework mode for configuration: $CONFIGURATION"

# Determine expected mode based on configuration
if [[ "$CONFIGURATION" == *"Debug"* ]] || [[ "$CONFIGURATION" == "D_"* ]]; then
    EXPECTED_MODE="Debug"
else
    EXPECTED_MODE="Release"
fi

echo "Expected framework mode: $EXPECTED_MODE"

# Check if ReelsSDK is installed
if [ ! -d "$PODS_DIR" ]; then
    echo "⚠️  ReelsSDK not found. Please run: pod install"
    exit 0
fi

# Check Podfile.lock for current SDK mode
PODFILE_LOCK="${SRCROOT}/Podfile.lock"
if [ -f "$PODFILE_LOCK" ]; then
    CURRENT_TAG=$(grep -A 1 "ReelsSDK" "$PODFILE_LOCK" | grep ":tag:" | sed 's/.*=> //' | tr -d '"' | tr -d ' ')

    if [[ "$CURRENT_TAG" == *"-debug"* ]]; then
        CURRENT_MODE="Debug"
    else
        CURRENT_MODE="Release"
    fi

    echo "Current framework mode: $CURRENT_MODE (tag: $CURRENT_TAG)"

    if [ "$CURRENT_MODE" != "$EXPECTED_MODE" ]; then
        echo ""
        echo "❌ ERROR: Framework mode mismatch!"
        echo ""
        echo "  Build Configuration: $CONFIGURATION"
        echo "  Expected Mode: $EXPECTED_MODE"
        echo "  Current Mode: $CURRENT_MODE"
        echo ""
        echo "To fix, run one of:"
        if [ "$EXPECTED_MODE" == "Debug" ]; then
            echo "  cd $SRCROOT && REELS_SDK_MODE=debug pod install"
        else
            echo "  cd $SRCROOT && REELS_SDK_MODE=release pod install"
        fi
        echo ""
        exit 1
    fi

    echo "✅ Framework mode is correct!"
fi
