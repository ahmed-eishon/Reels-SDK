#!/bin/bash
set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Determine build variant (default to debug if not specified)
BUILD_VARIANT="${1:-debug}"

if [ "$BUILD_VARIANT" != "debug" ] && [ "$BUILD_VARIANT" != "release" ]; then
    log_error "Invalid build variant: $BUILD_VARIANT"
    echo "Usage: $0 [debug|release]"
    exit 1
fi

# Get SDK root
SDK_ROOT=$(get_sdk_root "$0")
cd "$SDK_ROOT"

log_header "Building ReelsSDK Android AARs - $BUILD_VARIANT"
log_info "SDK Root: $SDK_ROOT"
track_script_start

# Step 1: Build Flutter AAR
log_step "1" "Building Flutter AAR ($BUILD_VARIANT)"
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")

cd "$FLUTTER_DIR"
if ! flutter_pub_get "$FLUTTER_DIR"; then
    exit 1
fi

if ! regenerate_pigeon "$FLUTTER_DIR"; then
    exit 1
fi

log_command "flutter build aar --$BUILD_VARIANT"
if [ "$BUILD_VARIANT" = "debug" ]; then
    flutter build aar --debug --no-release --no-profile
else
    flutter build aar --release --no-debug --no-profile
fi

log_success "Flutter AAR built successfully"

# Step 2: Setup Maven repository path
log_step "2" "Maven Repository Setup"
cd "$SDK_ROOT"
MAVEN_REPO="$FLUTTER_DIR/build/host/outputs/repo"
log_info "Maven repo location: $MAVEN_REPO"

# Verify Flutter AAR was built
if ! verify_directory_exists "$MAVEN_REPO" "Maven repository"; then
    exit 1
fi

log_info "Flutter AAR files:"
find "$MAVEN_REPO" -name "*.aar" | head -5

# Step 3: Prepare helper project
log_step "3" "Preparing helper-reels-android"
cd "$SDK_ROOT/helper-reels-android"

# Create settings.gradle from template
cp settings.gradle.template settings.gradle

# Substitute Maven repo path
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|MAVEN_REPO_PLACEHOLDER|${MAVEN_REPO}|g" settings.gradle
else
    sed -i "s|MAVEN_REPO_PLACEHOLDER|${MAVEN_REPO}|g" settings.gradle
fi

# Create local.properties from template with ANDROID_HOME
if [ -z "$ANDROID_HOME" ]; then
    log_error "ANDROID_HOME environment variable not set"
    exit 1
fi

cp local.properties.template local.properties
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|ANDROID_SDK_PLACEHOLDER|${ANDROID_HOME}|g" local.properties
else
    sed -i "s|ANDROID_SDK_PLACEHOLDER|${ANDROID_HOME}|g" local.properties
fi

log_success "Helper project prepared"
log_info "settings.gradle (Maven repo section):"
grep -A 2 "maven {" settings.gradle | grep -A 2 "file://"

# Step 4: Build reels_android AAR
log_step "4" "Building reels_android AAR ($BUILD_VARIANT)"

if [ "$BUILD_VARIANT" = "debug" ]; then
    log_command "./gradlew :reels_android:clean :reels_android:assembleDebug"
    ./gradlew :reels_android:clean :reels_android:assembleDebug --stacktrace
else
    log_command "./gradlew :reels_android:clean :reels_android:assembleRelease"
    ./gradlew :reels_android:clean :reels_android:assembleRelease --stacktrace
fi

log_success "reels_android AAR built successfully"

# Step 5: Show build outputs
log_step "5" "Build Outputs"
cd "$SDK_ROOT"

log_info "reels_android AAR files:"
find reels_android/build/outputs -name "*.aar" -type f

# Cleanup
log_step "6" "Cleanup"
cd "$SDK_ROOT/helper-reels-android"
rm -f settings.gradle local.properties
log_success "Cleaned up generated files (settings.gradle, local.properties)"

track_script_end
log_footer "✅ Build Completed Successfully!"

echo "Summary:"
log_info "Flutter AAR: $MAVEN_REPO"
log_info "reels_android AAR: $SDK_ROOT/reels_android/build/outputs/aar/"
