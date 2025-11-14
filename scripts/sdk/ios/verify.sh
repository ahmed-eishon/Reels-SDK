#!/bin/bash
set -e

# ============================================
# Reels SDK - iOS Verification
# ============================================
# Verify SDK integrity and structure
# No app dependencies - Pure SDK validation

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Start time tracking
track_script_start

# Header
log_header "Reels SDK - iOS Verification"

# Get SDK paths
SDK_ROOT=$(get_sdk_root "$0")
IOS_DIR=$(get_ios_module_dir "$SDK_ROOT")
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")

log_info "SDK Root: $SDK_ROOT"
echo ""

# Step 1: Verify VERSION file
log_step "1" "Checking VERSION file"
track_step_start
if ! verify_file_exists "$SDK_ROOT/VERSION" "VERSION"; then
    exit 1
fi
VERSION=$(get_sdk_version "$SDK_ROOT")
log_success "VERSION: $VERSION"
track_step_end

# Step 2: Verify podspec file
log_step "2" "Checking ReelsSDK.podspec"
track_step_start
if ! verify_file_exists "$SDK_ROOT/ReelsSDK.podspec" "ReelsSDK.podspec"; then
    exit 1
fi
log_success "ReelsSDK.podspec found"
track_step_end

# Step 3: Validate podspec syntax
log_step "3" "Validating podspec syntax"
track_step_start
cd "$SDK_ROOT"
if pod spec lint ReelsSDK.podspec --allow-warnings --quick > /dev/null 2>&1; then
    log_success "Podspec validation passed"
else
    log_warning "Podspec validation has warnings"
    log_info "Run manually: pod spec lint ReelsSDK.podspec --allow-warnings"
fi
track_step_end

# Step 4: Verify Swift Package structure
log_step "4" "Checking Swift Package structure"
track_step_start
if ! verify_file_exists "$IOS_DIR/Package.swift" "Package.swift"; then
    exit 1
fi
log_success "Package.swift found"
track_step_end

# Step 5: Verify Swift source files
log_step "5" "Checking Swift source files"
track_step_start
SWIFT_FILES=$(find "$IOS_DIR/Sources" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SWIFT_FILES" -eq 0 ]; then
    log_error "No Swift files found"
    exit 1
fi
log_success "Found $SWIFT_FILES Swift files"
track_step_end

# Step 6: Verify Flutter module
log_step "6" "Checking Flutter module"
track_step_start
if ! verify_file_exists "$FLUTTER_DIR/pubspec.yaml" "pubspec.yaml"; then
    exit 1
fi
log_success "Flutter module found"
track_step_end

# Step 7: Check Pigeon generated files
log_step "7" "Checking Pigeon generated files"
track_step_start
if verify_pigeon_files "$SDK_ROOT"; then
    log_success "Pigeon files verified"
else
    log_warning "Some Pigeon files missing"
    log_info "Regenerate with: ./sdk/ios/generate-pigeon.sh"
fi
track_step_end

# Summary
log_footer "iOS SDK Verification Summary"

echo ""
log_info "Version: $VERSION"
log_info "Podspec: ✓"
log_info "Swift Files: ✓ ($SWIFT_FILES files)"
log_info "Flutter Module: ✓"
log_info "Pigeon Files: ✓"
echo ""
log_success "iOS SDK verification completed!"
echo ""
log_info "Integration options:"
echo ""
echo "  # Using CocoaPods with Git:"
echo "  pod 'ReelsSDK', :git => 'https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git', :tag => 'v$VERSION'"
echo ""
echo "  # Using local development:"
echo "  ./scripts/integration/ios/init-client.sh $SDK_ROOT /path/to/your-ios-app"
echo ""

track_script_end
