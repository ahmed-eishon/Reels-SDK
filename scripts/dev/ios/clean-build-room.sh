#!/bin/bash
set -e

# ============================================
# Clean Build Room-iOS with ReelsSDK
# ============================================
# Development workflow - Complete clean build
# Performs full clean + rebuild of room-ios

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Default configuration
DEFAULT_SCHEME="D_Development Staging"
DEFAULT_SIMULATOR="iPhone 16 Pro"
SHOW_FULL_LOG=false

# Parse arguments
SCHEME="$DEFAULT_SCHEME"
SIMULATOR="$DEFAULT_SIMULATOR"

while [[ $# -gt 0 ]]; do
    case $1 in
        --scheme|-s)
            SCHEME="$2"
            shift 2
            ;;
        --simulator|-d)
            SIMULATOR="$2"
            shift 2
            ;;
        --full-log|-f)
            SHOW_FULL_LOG=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --scheme, -s SCHEME         Xcode scheme (default: '$DEFAULT_SCHEME')"
            echo "  --simulator, -d DEVICE      Simulator name (default: '$DEFAULT_SIMULATOR')"
            echo "  --full-log, -f              Show full build log"
            echo "  --help, -h                  Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  ROOM_IOS_DIR                Path to room-ios/ROOM directory"
            echo ""
            echo "Examples:"
            echo "  $0                          # Use defaults"
            echo "  $0 --simulator 'iPhone 15 Pro'"
            echo "  $0 --scheme 'D_Development Production'"
            echo "  ROOM_IOS_DIR=/custom/path $0"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Start time tracking
track_script_start

# Header
log_header "Clean Build: Room-iOS + ReelsSDK"

# Get SDK paths
SDK_ROOT=$(get_sdk_root "$0")
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")
ROOM_IOS_DIR=$(get_room_ios_dir "$SDK_ROOT")

# Mark as local development mode (for pod install)
touch "$SDK_ROOT/.reelsdk-dev"

log_info "SDK Root: $SDK_ROOT"
log_info "Flutter Module: $FLUTTER_DIR"
log_info "Room-iOS: $ROOM_IOS_DIR"
log_info "Scheme: $SCHEME"
log_info "Simulator: $SIMULATOR"
echo ""

# Verify room-ios directory exists
if ! verify_directory_exists "$ROOM_IOS_DIR" "room-ios"; then
    log_error "room-ios directory not found at: $ROOM_IOS_DIR"
    log_info "Set ROOM_IOS_DIR environment variable:"
    log_info "  export ROOM_IOS_DIR=/path/to/room-ios/ROOM"
    exit 1
fi

# Step 1: Clean and build Flutter frameworks
log_step "1/4" "Cleaning and building Flutter frameworks"
track_step_start
log_command "flutter clean && flutter build ios-framework"
cd "$FLUTTER_DIR"
flutter clean
flutter build ios-framework --debug --output=.ios/Flutter
log_success "Flutter frameworks built"
track_step_end

# Step 2: Update CocoaPods in room-ios
log_step "2/4" "Updating CocoaPods dependencies"
track_step_start
cd "$ROOM_IOS_DIR"
log_command "pod install"
pod install
log_success "CocoaPods updated"
track_step_end

# Step 3: Clean Xcode build
log_step "3/4" "Cleaning Xcode build"
track_step_start
log_command "xcodebuild clean"
xcodebuild -workspace ROOM.xcworkspace \
    -scheme "$SCHEME" \
    -configuration "$SCHEME" \
    clean
log_success "Xcode build cleaned"
track_step_end

# Step 4: Build room-ios app
log_step "4/4" "Building room-ios app"
track_step_start
log_command "xcodebuild build"
log_info "This may take a few minutes..."
echo ""

if [ "$SHOW_FULL_LOG" = true ]; then
    xcodebuild -workspace ROOM.xcworkspace \
        -scheme "$SCHEME" \
        -configuration "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR" \
        build
else
    xcodebuild -workspace ROOM.xcworkspace \
        -scheme "$SCHEME" \
        -configuration "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR" \
        build | tail -30
fi
track_step_end

# Success
log_footer "Clean Build Completed Successfully!"
track_script_end

echo ""
log_info "Next steps:"
echo "  1. Open Xcode: open $ROOM_IOS_DIR/ROOM.xcworkspace"
echo "  2. Select scheme: '$SCHEME'"
echo "  3. Select simulator: '$SIMULATOR'"
echo "  4. Run the app (Cmd+R)"
echo "  5. Tap any collect item to open reels"
echo ""
log_info "Troubleshooting:"
echo "  • If videos don't play: Check plugin registration in RRAppDelegate.swift"
echo "  • If debug menu missing: Verify debug=true in ReelsModule.initialize()"
echo "  • For more help: See docs/Build-Process.md"
echo ""
