# ReelsSDK Separate Tags Implementation Guide

## Overview

This document explains the new separate-tags approach for distributing ReelsSDK Debug and Release versions. This solution eliminates the dual-framework conflicts that were causing build failures.

## Problem We Solved

Previously, the ReelsSDK podspec included both Debug and Release frameworks with `_Debug`/`_Release` suffixes. This caused:
- CocoaPods GUID conflicts
- Xcode build system errors
- Complex workarounds in Podfile post_install hooks

## Solution

We now maintain **separate git tags** for Debug and Release versions:
- **v0.1.2-ios**: Release version (production-optimized)
- **v0.1.2-ios-debug**: Debug version (with symbols and assertions)

Each tag contains a `ReelsSDK.podspec` that references only the appropriate frameworks.

## File Structure

### In Reels-SDK Repository

```
reels-sdk/
├── ReelsSDK.podspec              # Release version (used for v0.1.2-ios tag)
├── ReelsSDK-Debug.podspec         # Debug template (used to create debug tags)
├── scripts/
│   └── create-debug-release-tag.sh  # Helper script to create debug tags
└── VERSION                        # Current version number (0.1.2)
```

### In ROOM iOS App

```ruby
# Podfile
reels_sdk_version = ENV['REELS_SDK_VERSION'] || '0.1.2'
reels_sdk_mode = ENV['REELS_SDK_MODE'] || 'release'
reels_sdk_tag = reels_sdk_mode == 'debug' ? "v#{reels_sdk_version}-ios-debug" : "v#{reels_sdk_version}-ios"

pod 'ReelsSDK', :git => 'https://github.com/ahmed-eishon/Reels-SDK.git', :tag => reels_sdk_tag
```

## Usage

### For ROOM iOS Developers

**Install Debug version (for development):**
```bash
cd ROOM
REELS_SDK_MODE=debug pod install
```

**Install Release version (for production/distribution):**
```bash
cd ROOM
pod install  # defaults to release
# or explicitly:
REELS_SDK_MODE=release pod install
```

**Install specific version:**
```bash
REELS_SDK_VERSION=0.1.3 REELS_SDK_MODE=debug pod install
```

## Creating New Releases

### Step 1: Update Version

```bash
cd reels-sdk
echo "0.1.2" > VERSION
git add VERSION
git commit -m "chore: Bump version to 0.1.2"
```

### Step 2: Build Frameworks

```bash
cd reels_flutter

# Build Release frameworks
flutter build ios-framework --release --no-codesign --output=../Frameworks/Release

# Build Debug frameworks
flutter build ios-framework --debug --no-codesign --output=../Frameworks/Debug
```

### Step 3: Package Frameworks

```bash
cd ..
VERSION=$(cat VERSION)

# Package Release frameworks
cd Frameworks/Release
zip -r ../../ReelsSDK-Frameworks-Release-${VERSION}.zip *.xcframework
cd ../..

# Package Debug frameworks
cd Frameworks/Debug
zip -r ../../ReelsSDK-Frameworks-Debug-${VERSION}.zip *.xcframework
cd ../..
```

### Step 4: Create Release Tag

```bash
# Commit podspec changes
git add ReelsSDK.podspec ReelsSDK-Debug.podspec
git commit -m "chore: Update podspecs for v${VERSION}"
git push origin release/0.1.2-ios

# Create and push Release tag
git tag -a "v${VERSION}-ios" -m "ReelsSDK v${VERSION} - iOS Release"
git push upstream "v${VERSION}-ios"
```

### Step 5: Create Debug Tag

```bash
# Use the helper script
./scripts/create-debug-release-tag.sh

# Follow the script instructions to push the debug tag
git push upstream "v${VERSION}-ios-debug"

# Clean up temporary branch
git checkout release/0.1.2-ios
git branch -D "temp/debug-release-v${VERSION}"
```

### Step 6: Upload to GitHub Releases

1. Go to https://github.com/ahmed-eishon/Reels-SDK/releases
2. Create release for `v0.1.2-ios`:
   - Upload `ReelsSDK-Frameworks-Release-0.1.2.zip`
   - Add release notes
3. Create release for `v0.1.2-ios-debug`:
   - Upload `ReelsSDK-Frameworks-Debug-0.1.2.zip`
   - Add release notes mentioning it's for development use

## Podspec Details

### ReelsSDK.podspec (Release)

- Downloads from: `https://github.com/ahmed-eishon/Reels-SDK/releases/download/v${VERSION}-ios/ReelsSDK-Frameworks-Release-${VERSION}.zip`
- Vendors: `Frameworks/*.xcframework` (without suffixes)
- Optimized for production

### ReelsSDK-Debug.podspec (Debug)

- Downloads from: `https://github.com/ahmed-eishon/Reels-SDK/releases/download/v${VERSION}-ios-debug/ReelsSDK-Frameworks-Debug-${VERSION}.zip`
- Vendors: `Frameworks/*.xcframework` (without suffixes)
- Includes debug symbols and assertions

## Workflow Automation (Future Enhancement)

The GitHub Actions workflow can be updated to automatically create both tags and releases:

```yaml
# .github/workflows/ios-release.yml
- name: Create Release Tag
  run: |
    VERSION=$(cat VERSION)
    git tag "v${VERSION}-ios"
    git push origin "v${VERSION}-ios"

- name: Create Debug Tag
  run: |
    ./scripts/create-debug-release-tag.sh
    git push origin "v${VERSION}-ios-debug"

- name: Upload Release Frameworks
  uses: softprops/action-gh-release@v1
  with:
    tag_name: v${{ steps.version.outputs.VERSION }}-ios
    files: ReelsSDK-Frameworks-Release-*.zip

- name: Upload Debug Frameworks
  uses: softprops/action-gh-release@v1
  with:
    tag_name: v${{ steps.version.outputs.VERSION }}-ios-debug
    files: ReelsSDK-Frameworks-Debug-*.zip
```

## Benefits

1. **No Framework Conflicts**: Each version contains only one set of frameworks
2. **Clean Podfile**: No complex post_install hooks needed
3. **Explicit Version Control**: Clear separation between Debug and Release
4. **Standard CocoaPods**: Works with standard CocoaPods mechanisms
5. **Easy to Use**: Simple environment variable toggles for developers

## Troubleshooting

### Pod Install Fails to Download

**Error:** `Failed to download Release/Debug frameworks`

**Solution:**
1. Check if the GitHub release exists: https://github.com/ahmed-eishon/Reels-SDK/releases
2. Verify the release has the correct asset uploaded
3. Check your internet connection

### Wrong Framework Version Installed

**Solution:**
```bash
# Clean pod cache
pod cache clean ReelsSDK --all

# Remove existing installation
rm -rf Pods/ReelsSDK Podfile.lock

# Reinstall with correct mode
REELS_SDK_MODE=debug pod install
```

### Framework Naming Conflicts

The old dual-framework approach is no longer used. If you see `_Debug` or `_Release` suffixes:
1. Update to v0.1.2 or later
2. Clean install: `rm -rf Pods Podfile.lock && pod install`

## Migration from v0.1.1

If you're currently using v0.1.1 with the dual-framework setup:

1. Update your Podfile to the new conditional format (already done in ROOM)
2. Clean your Pods:
   ```bash
   rm -rf Pods Podfile.lock
   pod cache clean ReelsSDK --all
   ```
3. Install with the new approach:
   ```bash
   REELS_SDK_MODE=debug pod install
   ```

## Questions?

Contact: room-team@rakuten.com or ahmed.eishon@rakuten.com
