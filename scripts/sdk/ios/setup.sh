#!/bin/bash
set -e

# ============================================
# Reels SDK - iOS Setup & Verification
# ============================================
# Complete SDK setup and verification
# No app dependencies - Pure SDK validation

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Start time tracking
track_script_start

# Header
log_header "Reels SDK - iOS Setup & Verification"

# Get SDK paths
SDK_ROOT=$(get_sdk_root "$0")
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")
IOS_DIR=$(get_ios_module_dir "$SDK_ROOT")

log_info "SDK Root: $SDK_ROOT"
log_info "SDK Version: $(get_sdk_version "$SDK_ROOT")"
echo ""

# Step 1: Check Flutter installation
log_step "1" "Checking Flutter installation"
track_step_start
if ! check_flutter_installed; then
    exit 1
fi
FLUTTER_VERSION=$(get_flutter_version)
log_success "Flutter $FLUTTER_VERSION"
track_step_end

# Step 2: Verify Flutter module exists
log_step "2" "Verifying Flutter module structure"
track_step_start
if ! verify_file_exists "$FLUTTER_DIR/pubspec.yaml" "pubspec.yaml"; then
    exit 1
fi
log_success "Flutter module found"
track_step_end

# Step 3: Clean Flutter build artifacts
log_step "3" "Cleaning Flutter build artifacts"
track_step_start
if ! clean_flutter_build "$FLUTTER_DIR"; then
    exit 1
fi
track_step_end

# Step 4: Remove .ios directory
log_step "4" "Removing .ios directory"
track_step_start
if [ -d "$FLUTTER_DIR/.ios" ]; then
    rm -rf "$FLUTTER_DIR/.ios"
    log_success ".ios directory removed"
else
    log_info ".ios directory already clean"
fi
track_step_end

# Step 5: Run flutter pub get
log_step "5" "Running flutter pub get"
track_step_start
if ! flutter_pub_get "$FLUTTER_DIR"; then
    exit 1
fi
track_step_end

# Step 6: Verify .ios directory was created
log_step "6" "Verifying iOS platform files"
track_step_start
if ! verify_file_exists "$FLUTTER_DIR/.ios/Flutter/podhelper.rb" "podhelper.rb"; then
    log_error "iOS platform files not generated"
    exit 1
fi
log_success "iOS platform files generated"
track_step_end

# Step 7: Regenerate Pigeon files
log_step "7" "Regenerating Pigeon platform channel code"
track_step_start
if ! regenerate_pigeon "$FLUTTER_DIR"; then
    exit 1
fi
track_step_end

# Step 8: Verify Pigeon generated files
log_step "8" "Verifying Pigeon files"
track_step_start
if ! verify_pigeon_files "$SDK_ROOT"; then
    exit 1
fi
track_step_end

# Step 9: Verify iOS module structure
log_step "9" "Verifying iOS module structure"
track_step_start
if ! verify_file_exists "$IOS_DIR/Package.swift" "Package.swift"; then
    exit 1
fi

SWIFT_FILES=$(find "$IOS_DIR/Sources/ReelsIOS" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SWIFT_FILES" -eq 0 ]; then
    log_error "No Swift files found in reels_ios"
    exit 1
fi
log_success "iOS module structure verified ($SWIFT_FILES Swift files)"
track_step_end

# Step 10: Check CocoaPods
log_step "10" "Checking CocoaPods installation"
track_step_start
if check_cocoapods_installed; then
    POD_VERSION=$(get_cocoapods_version)
    log_success "CocoaPods $POD_VERSION"
else
    log_warning "CocoaPods not found"
    log_info "Install with: sudo gem install cocoapods"
fi
track_step_end

# Success summary
log_footer "iOS SDK Setup Complete!"
track_script_end

echo ""
log_info "Summary:"
echo "  ✓ Flutter clean & pub get"
echo "  ✓ iOS platform files regenerated"
echo "  ✓ Pigeon code regenerated"
echo "  ✓ All files verified"
echo ""
log_info "Next steps for client integration:"
echo ""
echo "  1. Update your Podfile with:"
echo ""
echo "     flutter_application_path = '$FLUTTER_DIR'"
echo "     load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')"
echo ""
echo "     target 'YourApp' do"
echo "       install_all_flutter_pods(flutter_application_path)"
echo "     end"
echo ""
echo "     post_install do |installer|"
echo "       flutter_post_install(installer)"
echo "     end"
echo ""
echo "  2. Run pod install in your iOS project"
echo ""
echo "  3. Add reels_ios Swift files to your Xcode project"
echo ""
log_success "Ready for iOS integration!"
echo ""
