#!/bin/bash
set -e

# ============================================
# Regenerate Pigeon Platform Channel Code
# ============================================
# Pure SDK operation - No app dependencies
# Regenerates platform channel code for iOS, Android, and Flutter

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Start time tracking
track_script_start

# Header
log_header "Regenerate Pigeon Platform Channel Code"

# Get SDK paths
SDK_ROOT=$(get_sdk_root "$0")
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")

log_info "SDK Root: $SDK_ROOT"
log_info "Flutter Module: $FLUTTER_DIR"
echo ""

# Step 1: Check Flutter installation
log_step "1" "Checking Flutter installation"
track_step_start
if ! check_flutter_installed; then
    exit 1
fi
log_success "Flutter $(get_flutter_version)"
track_step_end

# Step 2: Verify messages.dart exists
log_step "2" "Verifying Pigeon input file"
track_step_start
if ! verify_file_exists "$FLUTTER_DIR/pigeons/messages.dart" "messages.dart"; then
    exit 1
fi
log_success "Pigeon input file found"
track_step_end

# Step 3: Regenerate Pigeon code
log_step "3" "Regenerating Pigeon code"
track_step_start
if ! regenerate_pigeon "$FLUTTER_DIR"; then
    exit 1
fi
track_step_end

# Step 4: Verify generated files
log_step "4" "Verifying generated files"
track_step_start
if ! verify_pigeon_files "$SDK_ROOT"; then
    log_error "Some Pigeon files were not generated correctly"
    exit 1
fi
track_step_end

# Success
log_footer "Pigeon Code Generated Successfully!"
track_script_end

echo ""
log_info "Generated files:"
echo "  • Flutter: reels_flutter/lib/core/pigeon_generated.dart"
echo "  • iOS:     reels_ios/Sources/ReelsIOS/PigeonGenerated.swift"
echo "  • Android: reels_android/src/main/java/.../PigeonGenerated.kt"
echo ""
log_success "Platform channels are up to date!"
echo ""
