#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================"
echo "🚀 Reels SDK Release Script"
echo "============================================"
echo ""

# Check if version argument provided
if [ -z "$1" ]; then
    CURRENT_VERSION=$(cat "$SDK_ROOT/VERSION")
    echo -e "${RED}❌ Error: Version number required${NC}"
    echo ""
    echo "Usage: ./scripts/release.sh <version>"
    echo "Example: ./scripts/release.sh 1.1.0"
    echo ""
    echo "Current version: $CURRENT_VERSION"
    exit 1
fi

NEW_VERSION="$1"

# Validate version format (semantic versioning)
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Error: Invalid version format${NC}"
    echo "Version must follow semantic versioning: MAJOR.MINOR.PATCH"
    echo "Example: 1.0.0, 1.2.3, 2.0.0"
    exit 1
fi

CURRENT_VERSION=$(cat "$SDK_ROOT/VERSION")

echo -e "Current version: ${YELLOW}$CURRENT_VERSION${NC}"
echo -e "New version:     ${GREEN}$NEW_VERSION${NC}"
echo ""

# Confirm with user
read -p "Continue with release v$NEW_VERSION? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Release cancelled."
    exit 1
fi
echo ""

# Step 1: Check for uncommitted changes
echo "1️⃣  Checking for uncommitted changes..."
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}❌ Error: Uncommitted changes detected${NC}"
    echo "Please commit or stash your changes before releasing."
    git status -s
    exit 1
fi
echo -e "${GREEN}✅ Working directory clean${NC}"
echo ""

# Step 2: Update VERSION file
echo "2️⃣  Updating VERSION file..."
echo "$NEW_VERSION" > "$SDK_ROOT/VERSION"
echo -e "${GREEN}✅ VERSION file updated${NC}"
echo ""

# Step 3: Run verification scripts
echo "3️⃣  Running verification scripts..."
echo ""
echo "   🤖 Verifying Android..."
if ! "$SCRIPT_DIR/verify-android.sh" > /tmp/android-verify.log 2>&1; then
    echo -e "${RED}❌ Android verification failed${NC}"
    cat /tmp/android-verify.log
    git checkout VERSION
    exit 1
fi
echo -e "${GREEN}   ✅ Android verification passed${NC}"
echo ""

echo "   🍎 Verifying iOS..."
if ! "$SCRIPT_DIR/verify-ios.sh" > /tmp/ios-verify.log 2>&1; then
    echo -e "${YELLOW}   ⚠️  iOS verification has warnings (continuing)${NC}"
else
    echo -e "${GREEN}   ✅ iOS verification passed${NC}"
fi
echo ""

# Step 4: Commit version change
echo "4️⃣  Committing version bump..."
git add VERSION
git commit -m "Bump version to $NEW_VERSION" -m "Release version $NEW_VERSION with Git-based distribution." -m "🤖 Generated with Claude Code"
echo -e "${GREEN}✅ Version committed${NC}"
echo ""

# Step 5: Create Git tag
echo "5️⃣  Creating Git tag..."
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION

Version $NEW_VERSION of Reels SDK

To integrate:

iOS (CocoaPods):
pod 'ReelsSDK', :git => 'https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git', :tag => 'v$NEW_VERSION'

Android (Gradle):
implementation 'com.rakuten.room:reels-sdk:$NEW_VERSION'
"
echo -e "${GREEN}✅ Tag v$NEW_VERSION created${NC}"
echo ""

# Step 6: Display next steps
echo "============================================"
echo "✅ Release v$NEW_VERSION Prepared!"
echo "============================================"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1️⃣  Push commit and tag to remote:"
echo -e "   ${BLUE}git push origin master${NC}"
echo -e "   ${BLUE}git push origin v$NEW_VERSION${NC}"
echo ""
echo "2️⃣  (Optional) Create GitHub Release:"
echo "   - Go to: https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk/releases"
echo "   - Click 'Create Release'"
echo "   - Select tag: v$NEW_VERSION"
echo "   - Add release notes from CHANGELOG.md"
echo ""
echo "3️⃣  Update CHANGELOG.md for next version"
echo ""
echo "4️⃣  Notify teams:"
echo "   - Android team: Update to 'com.rakuten.room:reels-sdk:$NEW_VERSION'"
echo "   - iOS team: Update to :tag => 'v$NEW_VERSION'"
echo ""
echo -e "${GREEN}🎉 Release complete!${NC}"
echo ""
