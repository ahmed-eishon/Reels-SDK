#!/bin/bash

# Clean Build Room-iOS with ReelsSDK Integration
# This script performs a complete clean build of the room-ios app with ReelsSDK
# Usage: ./scripts/clean-build-room-ios.sh

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
echo -e "${BLUE}Clean Build: Room-iOS + ReelsSDK${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Step 1: Clean and build Flutter frameworks
echo -e "${YELLOW}[1/4] Cleaning and building Flutter frameworks...${NC}"
echo -e "${BLUE}→ Running: flutter clean && flutter build ios-framework${NC}"
cd "$FLUTTER_MODULE_DIR"
flutter clean
flutter build ios-framework --debug --output=.ios/Flutter
echo -e "${GREEN}✓ Flutter frameworks built${NC}"
echo ""

# Step 2: Update CocoaPods in room-ios
echo -e "${YELLOW}[2/4] Updating CocoaPods dependencies...${NC}"
cd "$ROOM_IOS_DIR"
echo -e "${BLUE}→ Running: pod install${NC}"
pod install
echo -e "${GREEN}✓ CocoaPods updated${NC}"
echo ""

# Step 3: Clean Xcode build
echo -e "${YELLOW}[3/4] Cleaning Xcode build...${NC}"
echo -e "${BLUE}→ Running: xcodebuild clean${NC}"
xcodebuild -workspace ROOM.xcworkspace \
    -scheme "D_Development Staging" \
    -configuration "D_Development Staging" \
    clean
echo -e "${GREEN}✓ Xcode build cleaned${NC}"
echo ""

# Step 4: Build room-ios app
echo -e "${YELLOW}[4/4] Building room-ios app...${NC}"
echo -e "${BLUE}→ Running: xcodebuild build${NC}"
echo -e "${BLUE}→ This may take a few minutes...${NC}"
echo ""

xcodebuild -workspace ROOM.xcworkspace \
    -scheme "D_Development Staging" \
    -configuration "D_Development Staging" \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    build | tail -30

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ Clean build completed successfully!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Open Xcode: ${YELLOW}open $ROOM_IOS_DIR/ROOM.xcworkspace${NC}"
echo -e "  2. Select 'D_Development Staging' scheme"
echo -e "  3. Select iPhone 16 Pro simulator"
echo -e "  4. Run the app (Cmd+R)"
echo -e "  5. Tap any collect item to open reels"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo -e "  • If videos don't play: Check plugin registration in RRAppDelegate.swift"
echo -e "  • If debug menu missing: Verify debug=true in ReelsModule.initialize()"
echo -e "  • For more help: See docs/Build-Process.md"
echo ""
