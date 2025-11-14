#!/bin/bash
set -e

# Test script for common.sh library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

log_header "Testing Reels SDK Common Library"

# Test logging functions
log_info "Testing info message"
log_success "Testing success message"
log_warning "Testing warning message"
log_error "Testing error message (this is expected)"

echo ""
log_step "1" "Testing path resolution"
SDK_ROOT=$(get_sdk_root "$0")
log_info "SDK Root: $SDK_ROOT"
log_info "SDK Version: $(get_sdk_version "$SDK_ROOT")"
log_info "Flutter Module: $(get_flutter_module_dir "$SDK_ROOT")"
log_info "iOS Module: $(get_ios_module_dir "$SDK_ROOT")"

echo ""
log_step "2" "Testing version functions"
log_info "Flutter Version: $(get_flutter_version)"
log_info "CocoaPods Version: $(get_cocoapods_version)"

echo ""
log_step "3" "Testing validation functions"
track_step_start
if check_flutter_installed; then
    log_success "Flutter is installed"
else
    log_warning "Flutter not installed"
fi

if check_cocoapods_installed; then
    log_success "CocoaPods is installed"
else
    log_warning "CocoaPods not installed"
fi
track_step_end

echo ""
log_step "4" "Testing time tracking"
track_script_start
log_info "Simulating work..."
sleep 2
track_script_end

echo ""
log_footer "All Tests Passed!"
