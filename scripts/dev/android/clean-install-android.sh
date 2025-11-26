#!/bin/bash
set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Get SDK root
SDK_ROOT=$(get_sdk_root "$0")

log_header "🚀 Reels SDK - Android Development Setup"
log_info "SDK Root: $SDK_ROOT"
track_script_start

# Step 1: Check Flutter installation
log_step "1" "Checking Flutter installation"
if ! check_flutter_installed; then
    exit 1
fi
FLUTTER_VERSION=$(get_flutter_version)
log_success "Flutter $FLUTTER_VERSION"

# Step 2: Verify Flutter module exists
log_step "2" "Verifying Flutter module"
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")
if ! verify_file_exists "$FLUTTER_DIR/pubspec.yaml" "Flutter module pubspec.yaml"; then
    exit 1
fi
log_success "Flutter module found"

# Step 3: Clean Flutter build artifacts
log_step "3" "Cleaning Flutter build artifacts"
if ! clean_flutter_build "$FLUTTER_DIR"; then
    exit 1
fi

# Step 4: Remove .android directory and Flutter build cache
log_step "4" "Removing .android directory and Flutter build cache"
if [ -d "$FLUTTER_DIR/.android" ]; then
    rm -rf "$FLUTTER_DIR/.android"
    log_success ".android directory removed"
else
    log_info ".android directory already clean"
fi

# Also remove Flutter's Dart build cache to force complete rebuild
if [ -d "$FLUTTER_DIR/.dart_tool/flutter_build" ]; then
    rm -rf "$FLUTTER_DIR/.dart_tool/flutter_build"
    log_success "Flutter build cache cleared"
fi

if [ -d "$FLUTTER_DIR/build" ]; then
    rm -rf "$FLUTTER_DIR/build"
    log_success "Flutter build directory cleared"
fi

# Step 5: Run flutter pub get
log_step "5" "Running flutter pub get"
if ! flutter_pub_get "$FLUTTER_DIR"; then
    exit 1
fi

# Step 6: Verify .android directory was created
log_step "6" "Verifying Android platform files"
if ! verify_file_exists "$FLUTTER_DIR/.android/include_flutter.groovy" "include_flutter.groovy"; then
    exit 1
fi
log_success "Android platform files generated"

# Step 7: Regenerate Pigeon files
log_step "7" "Regenerating Pigeon platform channel code"
if ! regenerate_pigeon "$FLUTTER_DIR"; then
    exit 1
fi

# Step 8: Verify Pigeon generated files for Android
log_step "8" "Verifying Pigeon files for Android"
if ! verify_pigeon_files "$SDK_ROOT"; then
    exit 1
fi

# Step 9: Verify reels_android module
log_step "9" "Verifying reels_android module"
ANDROID_DIR=$(get_android_module_dir "$SDK_ROOT")
if ! verify_file_exists "$ANDROID_DIR/build.gradle" "reels_android build.gradle"; then
    exit 1
fi

KOTLIN_FILES=$(find "$ANDROID_DIR/src/main/java" -name "*.kt" 2>/dev/null | wc -l | tr -d ' ')
if [ "$KOTLIN_FILES" -eq 0 ]; then
    log_error "No Kotlin files found in reels_android"
    exit 1
fi
log_success "reels_android module verified ($KOTLIN_FILES Kotlin files)"

# Step 10: Setup local.properties for .android build
log_step "10" "Setting up local.properties for build"
LOCAL_PROPS="$FLUTTER_DIR/.android/local.properties"

# Find Android SDK location
if [ -n "$ANDROID_HOME" ]; then
    SDK_DIR="$ANDROID_HOME"
elif [ -n "$ANDROID_SDK_ROOT" ]; then
    SDK_DIR="$ANDROID_SDK_ROOT"
elif [ -d "$HOME/Library/Android/sdk" ]; then
    SDK_DIR="$HOME/Library/Android/sdk"
elif [ -d "$HOME/Android/Sdk" ]; then
    SDK_DIR="$HOME/Android/Sdk"
else
    log_error "Android SDK not found"
    log_info "Please set ANDROID_HOME or ANDROID_SDK_ROOT environment variable"
    exit 1
fi

# Find Flutter SDK location
if [ -n "$FLUTTER_ROOT" ]; then
    FLUTTER_SDK_DIR="$FLUTTER_ROOT"
else
    # Get Flutter SDK path from flutter command
    FLUTTER_SDK_DIR=$(which flutter | xargs dirname | xargs dirname)
fi

# Create local.properties
echo "sdk.dir=$SDK_DIR" > "$LOCAL_PROPS"
echo "flutter.sdk=$FLUTTER_SDK_DIR" >> "$LOCAL_PROPS"
log_success "local.properties configured"
log_info "sdk.dir=$SDK_DIR"
log_info "flutter.sdk=$FLUTTER_SDK_DIR"

# Step 11: Clean ROOM Android app build cache (if it exists)
log_step "11" "Cleaning ROOM Android app build cache"
ROOM_ANDROID_DIR="$(dirname "$(dirname "$(dirname "$SDK_ROOT")")")/room-android"
if [ -d "$ROOM_ANDROID_DIR" ]; then
    log_info "Found ROOM Android app at: $ROOM_ANDROID_DIR"

    # Stop Gradle daemon first
    if command -v cd >/dev/null 2>&1; then
        cd "$ROOM_ANDROID_DIR" 2>/dev/null && ./gradlew --stop 2>/dev/null || true
        log_success "Stopped Gradle daemon"
    fi

    # Remove build directories
    if [ -d "$ROOM_ANDROID_DIR/app/build" ]; then
        rm -rf "$ROOM_ANDROID_DIR/app/build"
        log_success "Removed app/build"
    fi

    if [ -d "$ROOM_ANDROID_DIR/build" ]; then
        rm -rf "$ROOM_ANDROID_DIR/build"
        log_success "Removed build"
    fi

    # Remove Gradle cache
    if [ -d "$ROOM_ANDROID_DIR/.gradle" ]; then
        rm -rf "$ROOM_ANDROID_DIR/.gradle"
        log_success "Removed .gradle cache"
    fi

    log_success "ROOM Android app build cache cleaned"
else
    log_info "ROOM Android app not found at expected location, skipping"
fi

# Success summary
track_script_end
log_footer "✅ Android Development Setup Complete!"

echo "📊 Summary:"
log_success "Flutter clean & pub get"
log_success "Android platform files regenerated"
log_success "Pigeon code regenerated"
log_success "All files verified"
log_success "ROOM Android build cache cleaned"
echo ""

echo "📝 Integration Instructions for Your Android App:"
echo ""
echo "1️⃣  Add to your project's settings.gradle:"
echo ""
echo -e "${BLUE}// ReelsSDK - Local folder integration"
echo "include ':reels_android'"
echo "project(':reels_android').projectDir = new File('$SDK_ROOT/reels_android')"
echo ""
echo "// Flutter module from reels_flutter"
echo "setBinding(new Binding([gradle: this]))"
echo "evaluate(new File("
echo "    '$SDK_ROOT/reels_flutter/.android/include_flutter.groovy'"
echo "))${NC}"
echo ""
echo "2️⃣  Add to your app/build.gradle dependencies:"
echo ""
echo -e "${BLUE}dependencies {"
echo "    implementation project(':reels_android')"
echo "}${NC}"
echo ""
echo "3️⃣  Sync Gradle and build your project:"
echo ""
echo -e "${BLUE}./gradlew clean assembleDebug${NC}"
echo ""
log_success "🎉 Ready for local Android development!"
