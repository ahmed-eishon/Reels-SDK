#!/bin/bash
set -e

# ============================================
# Build Flutter Frameworks for iOS
# ============================================
# Pure SDK operation - No app dependencies
# Builds Debug, Profile, and Release frameworks

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Start time tracking
track_script_start

# Header
log_header "Build Flutter Frameworks for iOS"

# Get SDK paths
SDK_ROOT=$(get_sdk_root "$0")
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")

log_info "SDK Root: $SDK_ROOT"
log_info "SDK Version: $(get_sdk_version "$SDK_ROOT")"
log_info "Flutter Module: $FLUTTER_DIR"
echo ""

# Parse arguments
CLEAN_BUILD=false
if [ "$1" = "--clean" ] || [ "$1" = "-c" ]; then
    CLEAN_BUILD=true
fi

# Check Flutter installation
log_step "1" "Checking Flutter installation"
track_step_start
if ! check_flutter_installed; then
    exit 1
fi
log_info "Flutter Version: $(get_flutter_version)"
track_step_end

# Verify Flutter module exists
log_step "2" "Verifying Flutter module"
track_step_start
if ! verify_directory_exists "$FLUTTER_DIR" "Flutter module"; then
    exit 1
fi
if ! verify_file_exists "$FLUTTER_DIR/pubspec.yaml" "pubspec.yaml"; then
    exit 1
fi
log_success "Flutter module verified"
track_step_end

# Build frameworks
log_step "3" "Building Flutter frameworks"
track_step_start
if ! build_flutter_frameworks "$FLUTTER_DIR" $CLEAN_BUILD; then
    log_error "Failed to build Flutter frameworks"
    exit 1
fi
track_step_end

# Success
log_footer "Flutter Frameworks Built Successfully!"
track_script_end

echo ""
log_info "Frameworks are ready for use"
log_info "Next steps:"
echo "  • iOS: Frameworks are in $FLUTTER_DIR/.ios/Flutter/"
echo "  • Use with CocoaPods via install_all_flutter_pods()"
echo "  • Or copy frameworks to your Xcode project manually"
echo ""
