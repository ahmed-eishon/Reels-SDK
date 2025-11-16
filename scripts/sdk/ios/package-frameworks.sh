#!/bin/bash
set -e

# ============================================
# Package Flutter Frameworks for Distribution
# ============================================
# Pure SDK operation - Packages frameworks into release-ready zips
# Used locally or by CI/CD for creating GitHub releases

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Configuration
BUILD_TYPE="${1:-Release}"  # Debug or Release
VALID_TYPES=("Debug" "Release")

# Show help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [BUILD_TYPE]"
    echo ""
    echo "Arguments:"
    echo "  BUILD_TYPE    Debug or Release (default: Release)"
    echo ""
    echo "Examples:"
    echo "  $0                # Package Release frameworks"
    echo "  $0 Debug          # Package Debug frameworks"
    echo "  $0 Release        # Package Release frameworks"
    echo ""
    echo "Output:"
    echo "  Creates ReelsSDK-Frameworks-{Debug|Release}-{VERSION}.zip"
    exit 0
fi

# Validate build type
if [[ ! " ${VALID_TYPES[@]} " =~ " ${BUILD_TYPE} " ]]; then
    log_error "Invalid build type: $BUILD_TYPE"
    log_info "Valid types: Debug, Release"
    exit 1
fi

# Start time tracking
track_script_start

# Header
log_header "Package Flutter Frameworks for Distribution"
log_info "Build Type: $BUILD_TYPE"
echo ""

# Get SDK paths
SDK_ROOT=$(get_sdk_root "$0")
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")
# Flutter creates subdirectories for each configuration (Debug, Profile, Release)
# We want the configuration that matches the build type
FRAMEWORKS_SOURCE="$FLUTTER_DIR/.ios/Flutter/$BUILD_TYPE/$BUILD_TYPE"
VERSION=$(cat "$SDK_ROOT/VERSION")
OUTPUT_ZIP="$SDK_ROOT/ReelsSDK-Frameworks-$BUILD_TYPE-$VERSION.zip"

log_info "SDK Root: $SDK_ROOT"
log_info "Version: $VERSION"
log_info "Source: $FRAMEWORKS_SOURCE"
log_info "Output: $(basename "$OUTPUT_ZIP")"
echo ""

# Step 1: Verify source frameworks exist
log_step "1/4" "Verifying source frameworks"
track_step_start

if [ ! -d "$FRAMEWORKS_SOURCE" ]; then
    log_error "Source frameworks not found at: $FRAMEWORKS_SOURCE"
    log_info "Run this first:"
    if [ "$BUILD_TYPE" == "Debug" ]; then
        echo "  cd reels_flutter"
        echo "  flutter build ios-framework --debug --output=.ios/Flutter/Debug"
    else
        echo "  ./scripts/sdk/ios/build-frameworks.sh --clean"
    fi
    exit 1
fi

# Check for required frameworks
REQUIRED_FRAMEWORKS=(
    "App.xcframework"
    "Flutter.xcframework"
    "FlutterPluginRegistrant.xcframework"
)

MISSING_FRAMEWORKS=()
for framework in "${REQUIRED_FRAMEWORKS[@]}"; do
    if [ ! -d "$FRAMEWORKS_SOURCE/$framework" ]; then
        MISSING_FRAMEWORKS+=("$framework")
    fi
done

if [ ${#MISSING_FRAMEWORKS[@]} -gt 0 ]; then
    log_error "Missing required frameworks:"
    for framework in "${MISSING_FRAMEWORKS[@]}"; do
        echo "  ❌ $framework"
    done
    exit 1
fi

log_success "All required frameworks found"
track_step_end

# Step 2: List frameworks to package
log_step "2/4" "Listing frameworks"
track_step_start

FRAMEWORK_COUNT=0
echo ""
for framework in "$FRAMEWORKS_SOURCE"/*.xcframework; do
    if [ -d "$framework" ]; then
        framework_name=$(basename "$framework")
        size=$(du -sh "$framework" | cut -f1)
        log_info "  📦 $framework_name ($size)"
        FRAMEWORK_COUNT=$((FRAMEWORK_COUNT + 1))
    fi
done
echo ""
log_success "Found $FRAMEWORK_COUNT frameworks"
track_step_end

# Step 3: Create zip archive
log_step "3/4" "Creating zip archive"
track_step_start

# Remove old zip if exists
if [ -f "$OUTPUT_ZIP" ]; then
    log_info "Removing old zip..."
    rm "$OUTPUT_ZIP"
fi

# Create temporary directory for renamed frameworks
TEMP_DIR=$(mktemp -d)
log_info "Renaming frameworks with _{$BUILD_TYPE} suffix..."
echo ""

RENAMED_COUNT=0
for framework in "$FRAMEWORKS_SOURCE"/*.xcframework; do
    if [ -d "$framework" ]; then
        original_name=$(basename "$framework" .xcframework)
        renamed_name="${original_name}_${BUILD_TYPE}.xcframework"
        log_info "  $original_name.xcframework → $renamed_name"
        cp -R "$framework" "$TEMP_DIR/$renamed_name"
        RENAMED_COUNT=$((RENAMED_COUNT + 1))
    fi
done

echo ""
log_success "Renamed $RENAMED_COUNT frameworks"

log_info "Packaging frameworks..."
cd "$TEMP_DIR"
zip -r "$OUTPUT_ZIP" *.xcframework -q

if [ $? -eq 0 ]; then
    log_success "Archive created successfully"
else
    log_error "Failed to create archive"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up temporary directory
cd "$SDK_ROOT"
rm -rf "$TEMP_DIR"
track_step_end

# Step 4: Generate checksum and manifest
log_step "4/4" "Generating metadata"
track_step_start

# Calculate checksum
CHECKSUM=$(shasum -a 256 "$OUTPUT_ZIP" | cut -d' ' -f1)
ZIP_SIZE=$(du -sh "$OUTPUT_ZIP" | cut -f1)

log_success "Archive size: $ZIP_SIZE"
log_success "SHA256: $CHECKSUM"

# Create manifest
MANIFEST_FILE="$SDK_ROOT/FRAMEWORK_MANIFEST_${BUILD_TYPE}.txt"
echo "ReelsSDK Flutter Frameworks - $BUILD_TYPE" > "$MANIFEST_FILE"
echo "Version: $VERSION" >> "$MANIFEST_FILE"
echo "Generated: $(date)" >> "$MANIFEST_FILE"
echo "Archive: $(basename "$OUTPUT_ZIP")" >> "$MANIFEST_FILE"
echo "Size: $ZIP_SIZE" >> "$MANIFEST_FILE"
echo "SHA256: $CHECKSUM" >> "$MANIFEST_FILE"
echo "" >> "$MANIFEST_FILE"
echo "Frameworks (renamed with _${BUILD_TYPE} suffix):" >> "$MANIFEST_FILE"

for framework in "$FRAMEWORKS_SOURCE"/*.xcframework; do
    if [ -d "$framework" ]; then
        original_name=$(basename "$framework" .xcframework)
        renamed_name="${original_name}_${BUILD_TYPE}.xcframework"
        size=$(du -sh "$framework" | cut -f1)
        echo "  - $renamed_name ($size)" >> "$MANIFEST_FILE"
    fi
done

log_success "Manifest created: $(basename "$MANIFEST_FILE")"
track_step_end

# Success
log_footer "Frameworks Packaged Successfully!"
track_script_end

echo ""
log_info "Output files:"
echo "  📦 $(basename "$OUTPUT_ZIP") ($ZIP_SIZE)"
echo "  📄 $(basename "$MANIFEST_FILE")"
echo ""

log_info "Next steps:"
echo "  1. Test the zip: unzip -l $(basename "$OUTPUT_ZIP")"
echo "  2. Upload to GitHub release as asset"
echo "  3. Or use CI/CD workflow to automate"
echo ""

log_info "GitHub Release Upload:"
echo "  gh release create v$VERSION \\"
echo "    --title 'ReelsSDK v$VERSION' \\"
echo "    --notes-file RELEASE_NOTES.md \\"
echo "    $(basename "$OUTPUT_ZIP")"
echo ""
