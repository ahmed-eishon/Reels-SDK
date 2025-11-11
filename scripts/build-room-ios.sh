#!/bin/bash

# Build Room-iOS with ReelsSDK Integration (Incremental)
# This script performs an incremental build without cleaning
# Usage: ./scripts/build-room-ios.sh

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
ROOM_IOS_DIR="/Users/ahmed.eishon/Rakuten/room-ios/ROOM"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Incremental Build: Room-iOS + ReelsSDK${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if Flutter frameworks exist
if [ ! -d "$FLUTTER_MODULE_DIR/.ios/Flutter/Debug" ]; then
    echo -e "${YELLOW}⚠ Flutter frameworks not found. Building them first...${NC}"
    cd "$FLUTTER_MODULE_DIR"
    flutter build ios-framework --debug --output=.ios/Flutter
    echo -e "${GREEN}✓ Flutter frameworks built${NC}"
    echo ""
fi

# Build room-ios app
echo -e "${YELLOW}→ Building room-ios app...${NC}"
cd "$ROOM_IOS_DIR"
echo -e "${BLUE}→ Running: xcodebuild build${NC}"
echo ""

xcodebuild -workspace ROOM.xcworkspace \
    -scheme "D_Development Staging" \
    -configuration "D_Development Staging" \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    build | tail -30

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ Build completed successfully!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}To run the app:${NC}"
echo -e "  1. Open Xcode: ${YELLOW}open $ROOM_IOS_DIR/ROOM.xcworkspace${NC}"
echo -e "  2. Press Cmd+R to run"
echo ""
