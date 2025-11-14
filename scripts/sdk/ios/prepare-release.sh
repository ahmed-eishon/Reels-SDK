#!/bin/bash
set -e

# ============================================
# Prepare Release for ReelsSDK
# ============================================
# Creates a new release with GitHub Actions automation
# Run this locally to prepare and push a new version tag

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Show help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [VERSION]"
    echo ""
    echo "Prepares a new release of ReelsSDK."
    echo "If VERSION not provided, uses VERSION file."
    echo ""
    echo "What this script does:"
    echo "  1. Verifies SDK integrity"
    echo "  2. Validates podspec"
    echo "  3. Creates git tag"
    echo "  4. Pushes tag (triggers GitHub Actions)"
    echo "  5. GitHub Actions builds frameworks and creates release"
    echo ""
    echo "Examples:"
    echo "  $0              # Use current VERSION file"
    echo "  $0 1.0.0        # Create release v1.0.0"
    echo ""
    echo "Prerequisites:"
    echo "  • All changes committed"
    echo "  • Clean working directory"
    echo "  • VERSION file updated"
    echo "  • On main/master branch"
    exit 0
fi

# Start time tracking
track_script_start

# Header
log_header "Prepare Release: ReelsSDK"

# Get SDK paths
SDK_ROOT=$(get_sdk_root "$0")
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")

log_info "SDK Root: $SDK_ROOT"
echo ""

# Get version
if [ -n "$1" ]; then
    NEW_VERSION="$1"
    log_info "Target version: $NEW_VERSION (from argument)"
else
    NEW_VERSION=$(cat "$SDK_ROOT/VERSION")
    log_info "Target version: $NEW_VERSION (from VERSION file)"
fi
echo ""

# Step 1: Check git status
log_step "1/6" "Checking git status"
track_step_start

cd "$SDK_ROOT"

if ! git diff-index --quiet HEAD --; then
    log_error "Working directory has uncommitted changes"
    log_info "Please commit or stash changes first:"
    echo ""
    git status --short
    exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)
log_success "On branch: $CURRENT_BRANCH"
log_success "Working directory clean"
track_step_end

# Step 2: Verify SDK integrity
log_step "2/6" "Verifying SDK integrity"
track_step_start

if ! check_flutter_installed; then
    exit 1
fi

if ! verify_pigeon_files "$SDK_ROOT"; then
    log_error "SDK verification failed"
    log_info "Run this first: ./scripts/sdk/ios/setup.sh"
    exit 1
fi

log_success "SDK integrity verified"
track_step_end

# Step 3: Validate podspec
log_step "3/6" "Validating podspec"
track_step_start

cd "$SDK_ROOT"
log_command "pod spec lint ReelsSDK.podspec"

if pod spec lint ReelsSDK.podspec --allow-warnings; then
    log_success "Podspec valid"
else
    log_error "Podspec validation failed"
    log_info "Fix the issues above and try again"
    exit 1
fi
track_step_end

# Step 4: Check if tag already exists
log_step "4/6" "Checking for existing tag"
track_step_start

if git rev-parse "v$NEW_VERSION" >/dev/null 2>&1; then
    log_error "Tag v$NEW_VERSION already exists"
    log_info "To delete and recreate:"
    echo "  git tag -d v$NEW_VERSION"
    echo "  git push origin :refs/tags/v$NEW_VERSION"
    exit 1
fi

log_success "Tag v$NEW_VERSION does not exist"
track_step_end

# Step 5: Create git tag
log_step "5/6" "Creating git tag"
track_step_start

log_info "Creating tag v$NEW_VERSION..."
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
log_success "Tag created locally"
track_step_end

# Step 6: Push tag
log_step "6/6" "Pushing tag to trigger release"
track_step_start

log_info "Pushing tag to origin..."
log_warning "This will trigger GitHub Actions to build frameworks"
echo ""

# Ask for confirmation
read -p "Push tag v$NEW_VERSION to origin? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin "v$NEW_VERSION"
    log_success "Tag pushed successfully"
else
    log_warning "Push cancelled"
    log_info "Tag exists locally. To push later:"
    echo "  git push origin v$NEW_VERSION"
    log_info "Or to delete local tag:"
    echo "  git tag -d v$NEW_VERSION"
    exit 0
fi

track_step_end

# Success
log_footer "Release Preparation Complete!"
track_script_end

echo ""
log_info "✅ Release v$NEW_VERSION initiated!"
echo ""
log_info "What happens next:"
echo "  1. GitHub Actions will build Flutter frameworks (Debug & Release)"
echo "  2. Frameworks will be packaged into zip files"
echo "  3. GitHub Release v$NEW_VERSION will be created automatically"
echo "  4. Framework zips will be uploaded as release assets"
echo "  5. Users can install via CocoaPods"
echo ""
log_info "Monitor progress:"
echo "  • GitHub Actions: https://github.com/rakuten/reels-sdk/actions"
echo "  • Release page: https://github.com/rakuten/reels-sdk/releases/tag/v$NEW_VERSION"
echo ""
log_info "Installation for users:"
echo "  pod 'ReelsSDK', :git => 'https://github.com/rakuten/reels-sdk.git', :tag => 'v$NEW_VERSION'"
echo ""
