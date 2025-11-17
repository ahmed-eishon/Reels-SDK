#!/bin/bash
set -e

# Script to create a debug release tag for ReelsSDK
# This temporarily replaces ReelsSDK.podspec with ReelsSDK-Debug.podspec content
# and creates a -debug suffixed tag

VERSION=$(cat VERSION)

echo "================================================"
echo "Creating Debug Release Tag for v${VERSION}-ios"
echo "================================================"
echo ""

# Check if we're on a clean branch
if [[ -n $(git status --porcelain) ]]; then
  echo "Error: Working directory not clean. Commit or stash changes first."
  exit 1
fi

# Save current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $CURRENT_BRANCH"
echo ""

# Check if debug tag already exists
if git rev-parse "v${VERSION}-ios-debug" >/dev/null 2>&1; then
  echo "Warning: Tag v${VERSION}-ios-debug already exists"
  read -p "Do you want to delete and recreate it? (y/n) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git tag -d "v${VERSION}-ios-debug"
    git push upstream --delete "v${VERSION}-ios-debug" 2>/dev/null || true
    echo "Deleted existing debug tag"
  else
    echo "Aborted"
    exit 1
  fi
fi

# Create temporary branch for debug release
DEBUG_BRANCH="temp/debug-release-v${VERSION}"
git checkout -b "$DEBUG_BRANCH"

echo "Created temporary branch: $DEBUG_BRANCH"
echo ""

# Replace ReelsSDK.podspec with Debug version
echo "Replacing ReelsSDK.podspec with Debug version..."
cp ReelsSDK-Debug.podspec ReelsSDK.podspec

# Commit the change
git add ReelsSDK.podspec
git commit -m "chore: Use Debug podspec for v${VERSION}-ios-debug release"

# Create the debug tag
echo ""
echo "Creating tag v${VERSION}-ios-debug..."
git tag -a "v${VERSION}-ios-debug" -m "ReelsSDK v${VERSION} - iOS Debug Release

This release includes Debug frameworks with symbols and debug assertions.
Use this version for development and debugging.

For production builds, use v${VERSION}-ios instead.
"

echo ""
echo "================================================"
echo "Debug Release Tag Created Successfully"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Push the debug tag to upstream:"
echo "     git push upstream v${VERSION}-ios-debug"
echo ""
echo "  2. Return to your original branch:"
echo "     git checkout $CURRENT_BRANCH"
echo ""
echo "  3. Delete the temporary branch:"
echo "     git branch -D $DEBUG_BRANCH"
echo ""
echo "  4. Upload Debug frameworks to GitHub release v${VERSION}-ios-debug"
echo ""
