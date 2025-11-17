# ReelsSDK Automated Dual-Release Guide

## Overview

This document explains the automated dual-release approach for distributing ReelsSDK Debug and Release versions. The GitHub Actions workflow automatically creates both releases from a single tag push.

## Problem We Solved

Previously, complex approaches using framework renaming or symlinks caused:
- CocoaPods GUID conflicts
- Xcode build system errors
- Complex post_install hooks
- Manual tag creation

## Solution

We now use **automated dual releases** triggered by a single tag:
- Push tag: `v0.1.3-ios`
- Workflow automatically creates:
  - **v0.1.3-ios**: Release version (production-optimized)
  - **v0.1.3-ios-debug**: Debug version (with symbols and assertions)

Each release contains a single podspec that downloads the appropriate 6 frameworks (no suffixes, no renaming).

## File Structure

### In Reels-SDK Repository

```
reels-sdk/
├── ReelsSDK.podspec                    # Single podspec for both builds
├── .github/workflows/release-ios.yml   # Automated workflow
├── scripts/sdk/ios/package-all-frameworks.sh  # Packaging script
└── VERSION                              # Current version number (0.1.3)
```

### Framework Structure

Both Debug and Release packages contain 6 frameworks without suffixes:
```
Frameworks/
├── App.xcframework
├── Flutter.xcframework
├── FlutterPluginRegistrant.xcframework
├── package_info_plus.xcframework
├── video_player_avfoundation.xcframework
└── wakelock_plus.xcframework
```

## Usage

### For ROOM iOS Developers

**Install Debug version (for development):**
```ruby
# In Podfile
pod 'ReelsSDK', :git => 'https://github.com/ahmed-eishon/Reels-SDK.git', :tag => 'v0.1.3-ios-debug'
```

**Install Release version (for production/distribution):**
```ruby
# In Podfile
pod 'ReelsSDK', :git => 'https://github.com/ahmed-eishon/Reels-SDK.git', :tag => 'v0.1.3-ios'
```

Then run:
```bash
pod install
```

## Creating New Releases

The process is fully automated via GitHub Actions:

### Step 1: Update Version

```bash
cd reels-sdk
echo "0.1.3" > VERSION
git add VERSION
git commit -m "chore: Bump version to 0.1.3"
```

### Step 2: Update Code (if needed)

Make any necessary changes to:
- Podspec
- Packaging script
- Workflow file

Commit all changes:
```bash
git add .
git commit -m "feat: Your changes"
git push origin release/0.1.3-ios
```

### Step 3: Trigger Release

Push the release tag (must match pattern `v*.*.*-ios`):
```bash
VERSION=$(cat VERSION)
git tag "v${VERSION}-ios"
git push origin "v${VERSION}-ios"
```

**That's it!** GitHub Actions automatically:
1. Builds Debug and Release frameworks
2. Packages them into separate zips
3. Creates 2 GitHub releases:
   - `v0.1.3-ios-debug` with Debug frameworks
   - `v0.1.3-ios` with Release frameworks
4. Uploads framework zips to each release
5. Adds installation instructions

### Step 4: Verify

Check the GitHub Actions workflow:
- Go to: https://github.com/ahmed-eishon/Reels-SDK/actions
- Verify the workflow completed successfully
- Check both releases exist: https://github.com/ahmed-eishon/Reels-SDK/releases

## How It Works

### Podspec Detection

The single `ReelsSDK.podspec` automatically detects build type from the git tag:

```ruby
# In prepare_command:
CURRENT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
if echo "$CURRENT_TAG" | grep -q "debug"; then
  BUILD_TYPE="Debug"
  ZIP_NAME="ReelsSDK-Frameworks-Debug-${VERSION}.zip"
else
  BUILD_TYPE="Release"
  ZIP_NAME="ReelsSDK-Frameworks-${VERSION}.zip"
fi
```

When you install:
- With tag `v0.1.3-ios-debug` → Downloads Debug frameworks
- With tag `v0.1.3-ios` → Downloads Release frameworks

### Workflow Process

The `.github/workflows/release-ios.yml` workflow:

1. **Triggers** on tags matching `v*.*.*-ios`
2. **Builds** both Debug and Release frameworks
3. **Packages** them into 2 separate zips (no renaming)
4. **Creates** 2 GitHub releases with separate tags
5. **Uploads** framework zips as release assets

All from a single tag push!

## Benefits

1. **No Framework Conflicts**: Each release contains only 6 frameworks
2. **No Renaming**: Frameworks keep original names
3. **No Symlinks**: Simple direct framework vendoring
4. **Automated**: Single tag push triggers everything
5. **Fast**: One workflow run creates both releases
6. **Clean Podfile**: Just change the tag to switch versions
7. **Standard CocoaPods**: Works with standard mechanisms

## Troubleshooting

### Workflow Not Running

**Problem:** Pushed tag but workflow didn't start

**Solution:**
1. Check tag pattern matches `v*.*.*-ios` (e.g., `v0.1.3-ios`)
2. Verify workflow file exists at the tagged commit
3. Check GitHub Actions page for errors
4. Ensure you pushed to the correct remote (GitHub, not gitpub)

### Pod Install Fails to Download

**Error:** `Failed to download Debug/Release frameworks`

**Solution:**
1. Check if GitHub release exists: https://github.com/ahmed-eishon/Reels-SDK/releases
2. Verify the release has the correct zip uploaded
3. Check your internet connection
4. Try cleaning pod cache: `pod cache clean ReelsSDK --all`

### Wrong Framework Version Installed

**Solution:**
```bash
# Clean pod cache
pod cache clean ReelsSDK --all

# Remove existing installation
rm -rf Pods/ReelsSDK Podfile.lock

# Reinstall with correct tag
pod install
```

### Need to Update an Existing Release

**Solution:**
```bash
# Delete local tag
git tag -d v0.1.3-ios

# Delete remote tag
git push origin :refs/tags/v0.1.3-ios

# Create new tag at desired commit
git tag v0.1.3-ios

# Force push
git push origin v0.1.3-ios --force
```

This will trigger a new workflow run.

## Migration from v0.1.2

If you're using v0.1.2 or earlier with the old approach:

1. Update your Podfile to use the new tag format:
   ```ruby
   # Old (if you had environment variables)
   pod 'ReelsSDK', :git => '...', :tag => reels_sdk_tag

   # New (simple and direct)
   pod 'ReelsSDK', :git => 'https://github.com/ahmed-eishon/Reels-SDK.git', :tag => 'v0.1.3-ios'
   ```

2. Clean your Pods:
   ```bash
   rm -rf Pods Podfile.lock
   pod cache clean ReelsSDK --all
   ```

3. Install with the new version:
   ```bash
   pod install
   ```

## Example Release Process

Here's a complete example of releasing v0.1.4:

```bash
# 1. Update version
cd reels-sdk
echo "0.1.4" > VERSION

# 2. Commit changes
git add VERSION
git commit -m "chore: Bump version to 0.1.4"

# 3. Push changes
git push origin release/0.1.4-ios

# 4. Create and push tag
git tag v0.1.4-ios
git push origin v0.1.4-ios

# 5. Wait for GitHub Actions (10-15 minutes)
# Check: https://github.com/ahmed-eishon/Reels-SDK/actions

# 6. Verify releases created
# https://github.com/ahmed-eishon/Reels-SDK/releases
# Should see:
#   - v0.1.4-ios (Release)
#   - v0.1.4-ios-debug (Debug)
```

## Questions?

Contact: room-team@rakuten.com or ahmed.eishon@rakuten.com
