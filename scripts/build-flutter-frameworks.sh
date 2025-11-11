#!/bin/bash

# Build Flutter Frameworks Script
# This script builds the Flutter frameworks for the reels_flutter module
# Usage: ./scripts/build-flutter-frameworks.sh [--clean]

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REELS_SDK_ROOT="$(dirname "$SCRIPT_DIR")"
FLUTTER_MODULE_DIR="$REELS_SDK_ROOT/reels_flutter"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Building Flutter Frameworks${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if --clean flag is provided
CLEAN_BUILD=false
if [ "$1" = "--clean" ]; then
    CLEAN_BUILD=true
fi

# Navigate to Flutter module directory
cd "$FLUTTER_MODULE_DIR"
echo -e "${BLUE}→ Working directory: $FLUTTER_MODULE_DIR${NC}"
echo ""

# Clean if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo -e "${YELLOW}→ Cleaning Flutter build...${NC}"
    flutter clean
    echo -e "${GREEN}✓ Clean completed${NC}"
    echo ""
fi

# Build Flutter frameworks for iOS
echo -e "${BLUE}→ Building Flutter frameworks for iOS...${NC}"
echo -e "${BLUE}  This will build Debug, Profile, and Release configurations${NC}"
echo ""

flutter build ios-framework --debug --output=.ios/Flutter

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ Flutter frameworks built successfully!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}Frameworks location:${NC}"
echo -e "  ${FLUTTER_MODULE_DIR}/.ios/Flutter/Debug"
echo -e "  ${FLUTTER_MODULE_DIR}/.ios/Flutter/Profile"
echo -e "  ${FLUTTER_MODULE_DIR}/.ios/Flutter/Release"
echo ""
