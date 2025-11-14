#!/bin/bash

# ============================================
# Reels SDK - Common Utilities Library
# ============================================
# Shared functions and utilities for all scripts
# Source this file: source "$(dirname "$0")/../lib/common.sh"

# ============================================
# Colors
# ============================================
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export MAGENTA='\033[0;35m'
export NC='\033[0m' # No Color

# ============================================
# Logging Functions
# ============================================

# Log informational message
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Log success message
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Log error message
log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

# Log warning message
log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Log step header
log_step() {
    local step_num=$1
    local step_desc=$2
    echo ""
    echo -e "${CYAN}[$step_num] ${step_desc}${NC}"
}

# Log section header
log_header() {
    local header=$1
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$header${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

# Log section footer
log_footer() {
    local message=$1
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}$message${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
}

# Log command execution
log_command() {
    echo -e "${CYAN}→ Running: ${NC}$1"
}

# ============================================
# Time Tracking
# ============================================

# Global variables for time tracking
_SCRIPT_START_TIME=""
_STEP_START_TIME=""

# Start tracking script execution time
track_script_start() {
    _SCRIPT_START_TIME=$(date +%s)
}

# End tracking and display total script time
track_script_end() {
    if [ -n "$_SCRIPT_START_TIME" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - _SCRIPT_START_TIME))
        local minutes=$((duration / 60))
        local seconds=$((duration % 60))

        if [ $minutes -gt 0 ]; then
            log_info "Total time: ${minutes}m ${seconds}s"
        else
            log_info "Total time: ${seconds}s"
        fi
    fi
}

# Start tracking step execution time
track_step_start() {
    _STEP_START_TIME=$(date +%s)
}

# End tracking and display step time
track_step_end() {
    if [ -n "$_STEP_START_TIME" ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - _STEP_START_TIME))
        echo -e "${CYAN}  (${duration}s)${NC}"
        _STEP_START_TIME=""
    fi
}

# ============================================
# Validation Functions
# ============================================

# Check if Flutter is installed
check_flutter_installed() {
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter not found in PATH"
        log_info "Install Flutter from: https://flutter.dev/docs/get-started/install"
        return 1
    fi
    return 0
}

# Check if CocoaPods is installed
check_cocoapods_installed() {
    if ! command -v pod &> /dev/null; then
        log_warning "CocoaPods not found in PATH"
        log_info "Install with: sudo gem install cocoapods"
        return 1
    fi
    return 0
}

# Check if a directory exists
verify_directory_exists() {
    local dir_path=$1
    local dir_name=${2:-"Directory"}

    if [ ! -d "$dir_path" ]; then
        log_error "$dir_name not found at: $dir_path"
        return 1
    fi
    return 0
}

# Check if a file exists
verify_file_exists() {
    local file_path=$1
    local file_name=${2:-"File"}

    if [ ! -f "$file_path" ]; then
        log_error "$file_name not found at: $file_path"
        return 1
    fi
    return 0
}

# ============================================
# Path Resolution
# ============================================

# Get SDK root directory
# Usage: SDK_ROOT=$(get_sdk_root "$0")
get_sdk_root() {
    local script_path=$1
    local script_dir="$(cd "$(dirname "$script_path")" && pwd)"

    # Go up directories until we find the SDK root
    # SDK root contains VERSION file and reels_flutter directory
    local current_dir="$script_dir"
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/VERSION" ] && [ -d "$current_dir/reels_flutter" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    log_error "Could not find SDK root directory"
    return 1
}

# Get Flutter module directory
get_flutter_module_dir() {
    local sdk_root=$1
    echo "$sdk_root/reels_flutter"
}

# Get iOS module directory
get_ios_module_dir() {
    local sdk_root=$1
    echo "$sdk_root/reels_ios"
}

# Get Android module directory
get_android_module_dir() {
    local sdk_root=$1
    echo "$sdk_root/reels_android"
}

# ============================================
# Version Functions
# ============================================

# Get SDK version from VERSION file
get_sdk_version() {
    local sdk_root=$1
    if [ -f "$sdk_root/VERSION" ]; then
        cat "$sdk_root/VERSION"
    else
        echo "unknown"
    fi
}

# Get Flutter version
get_flutter_version() {
    if command -v flutter &> /dev/null; then
        flutter --version | head -n 1 | sed 's/Flutter //'
    else
        echo "not installed"
    fi
}

# Get CocoaPods version
get_cocoapods_version() {
    if command -v pod &> /dev/null; then
        pod --version
    else
        echo "not installed"
    fi
}

# ============================================
# Configuration Functions
# ============================================

# Get room-ios directory
# Checks ROOM_IOS_DIR env var, then falls back to default location
get_room_ios_dir() {
    local sdk_root=$1

    if [ -n "$ROOM_IOS_DIR" ]; then
        echo "$ROOM_IOS_DIR"
    else
        # Default: assume room-ios is sibling to reels-sdk
        echo "$(dirname "$sdk_root")/room-ios/ROOM"
    fi
}

# Get available iOS simulators
get_ios_simulators() {
    xcrun simctl list devices available | grep "iPhone" | sed 's/.*iPhone/iPhone/' | sed 's/ (.*//' | sort -u
}

# ============================================
# Build Functions
# ============================================

# Clean Flutter build artifacts
clean_flutter_build() {
    local flutter_dir=$1

    log_info "Cleaning Flutter build artifacts..."
    cd "$flutter_dir"

    if flutter clean; then
        log_success "Flutter clean completed"
        return 0
    else
        log_error "Flutter clean failed"
        return 1
    fi
}

# Run flutter pub get
flutter_pub_get() {
    local flutter_dir=$1

    log_info "Running flutter pub get..."
    cd "$flutter_dir"

    if flutter pub get; then
        log_success "Flutter dependencies resolved"
        return 0
    else
        log_error "Failed to get Flutter dependencies"
        return 1
    fi
}

# Build Flutter frameworks for iOS
build_flutter_frameworks() {
    local flutter_dir=$1
    local clean=${2:-false}

    cd "$flutter_dir"

    if [ "$clean" = true ]; then
        log_info "Cleaning before build..."
        flutter clean
    fi

    log_info "Building Flutter frameworks for iOS..."
    log_info "This will build Debug, Profile, and Release configurations"

    if flutter build ios-framework --debug --output=.ios/Flutter; then
        log_success "Flutter frameworks built successfully"
        log_info "Frameworks location:"
        log_info "  $flutter_dir/.ios/Flutter/Debug"
        log_info "  $flutter_dir/.ios/Flutter/Profile"
        log_info "  $flutter_dir/.ios/Flutter/Release"
        return 0
    else
        log_error "Failed to build Flutter frameworks"
        return 1
    fi
}

# ============================================
# Pigeon Functions
# ============================================

# Regenerate Pigeon platform channel code
regenerate_pigeon() {
    local flutter_dir=$1

    log_info "Regenerating Pigeon platform channel code..."
    cd "$flutter_dir"

    if flutter pub run pigeon --input pigeons/messages.dart; then
        log_success "Pigeon code generated"
        return 0
    else
        log_error "Failed to generate Pigeon code"
        return 1
    fi
}

# Verify Pigeon files exist
verify_pigeon_files() {
    local sdk_root=$1
    local errors=0

    log_info "Verifying Pigeon generated files..."

    # Check Flutter pigeon_generated.dart
    if [ ! -f "$sdk_root/reels_flutter/lib/core/pigeon_generated.dart" ]; then
        log_error "lib/core/pigeon_generated.dart not found"
        errors=$((errors + 1))
    else
        log_success "lib/core/pigeon_generated.dart"
    fi

    # Check iOS PigeonGenerated.swift
    if [ ! -f "$sdk_root/reels_ios/Sources/ReelsIOS/PigeonGenerated.swift" ]; then
        log_error "reels_ios/Sources/ReelsIOS/PigeonGenerated.swift not found"
        errors=$((errors + 1))
    else
        log_success "reels_ios/Sources/ReelsIOS/PigeonGenerated.swift"
    fi

    # Check Android PigeonGenerated.kt
    if [ ! -f "$sdk_root/reels_android/src/main/java/com/rakuten/room/reels/pigeon/PigeonGenerated.kt" ]; then
        log_error "reels_android PigeonGenerated.kt not found"
        errors=$((errors + 1))
    else
        log_success "reels_android/src/main/java/.../PigeonGenerated.kt"
    fi

    if [ $errors -gt 0 ]; then
        return 1
    fi

    return 0
}

# ============================================
# Interactive Functions
# ============================================

# Prompt for confirmation (y/n)
confirm() {
    local prompt=$1
    local default=${2:-n}

    if [ "$default" = "y" ]; then
        prompt="$prompt (Y/n): "
    else
        prompt="$prompt (y/N): "
    fi

    read -p "$prompt" -n 1 -r
    echo

    if [ "$default" = "y" ]; then
        [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# ============================================
# Initialization
# ============================================

# This function is called automatically when sourcing this file
_common_lib_init() {
    # Set errexit to exit on error (can be overridden by scripts)
    # set -e

    # Set up error handling to show which line failed
    trap 'log_error "Script failed at line $LINENO"' ERR
}

# Run initialization
_common_lib_init
