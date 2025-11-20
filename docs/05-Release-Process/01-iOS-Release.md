# ReelsSDK Release Process

Complete guide for creating and distributing new releases of ReelsSDK.

## Overview

ReelsSDK uses **GitHub Actions** to automate framework building and release creation. This eliminates the need for users to have Flutter installed and ensures consistent, reproducible builds.

## Release Architecture

ReelsSDK uses **separate workflows** for Debug and Release builds:

```
┌─────────────────────────────────────────────────────────────┐
│  Developer                                                   │
│  1. Update VERSION file                                      │
│  2. Commit and push to release branch                        │
│  3. Push two tags:                                           │
│     - v0.1.4-ios → Triggers Release workflow                │
│     - v0.1.4-ios-debug → Triggers Debug workflow            │
└────────────────────────┬─────────────────────────────────────┘
                         │
                ┌────────┴────────┐
                ▼                 ▼
┌───────────────────────┐  ┌───────────────────────┐
│  Release Workflow     │  │  Debug Workflow       │
│  (release-ios.yml)    │  │  (release-ios-debug)  │
│  1. Build Release     │  │  1. Build Debug       │
│  2. Package zip       │  │  2. Package zip       │
│  3. Create release    │  │  3. Create release    │
│  4. Upload asset      │  │  4. Upload asset      │
└───────────┬───────────┘  └───────────┬───────────┘
            │                          │
            ▼                          ▼
┌──────────────────────┐    ┌──────────────────────┐
│  v0.1.4-ios Release  │    │  v0.1.4-ios-debug    │
│  Package:            │    │  Release             │
│  ReelsSDK-           │    │  Package:            │
│  Frameworks-         │    │  ReelsSDK-           │
│  0.1.4.zip           │    │  Frameworks-Debug-   │
│                      │    │  0.1.4.zip           │
└──────────────────────┘    └──────────────────────┘
            │                          │
            └────────┬─────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  End User                                                     │
│  # For Debug (development):                                  │
│  pod 'ReelsSDK', :git => '...', :tag => 'v0.1.4-ios-debug' │
│  → Downloads Debug frameworks (6 frameworks, clean names)    │
│                                                               │
│  # For Release (production):                                 │
│  pod 'ReelsSDK', :git => '...', :tag => 'v0.1.4-ios'       │
│  → Downloads Release frameworks (6 frameworks, clean names)  │
│                                                               │
│  No Flutter installation required!                           │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### One-Time Setup

1. **GitHub Actions Enabled**
   - Workflow file: `.github/workflows/release.yml`
   - Automatically enabled when file is present

2. **Git Remotes Configured**
   ```bash
   git remote -v
   # Should show both GitHub and GitPub
   ```

3. **CocoaPods Installed**
   ```bash
   gem install cocoapods
   ```

## Creating a New Release

### Step 1: Update Version

```bash
# Update VERSION file
echo "0.1.4" > VERSION

# Update in podspec (automatically read from VERSION)
cat ReelsSDK.podspec | grep version
# Should show: spec.version = File.read(...)
```

### Step 2: Commit Changes

```bash
# Stage all changes
git add .

# Commit
git commit -m "Prepare release v0.1.4"

# Push to main/master
git push origin master
```

### Step 3: Create and Push Release Tags

Push **both** tags to trigger independent workflows:

```bash
# Navigate to SDK root
cd /path/to/reels-sdk

# Get version from VERSION file
VERSION=$(cat VERSION)

# Create and push Release tag (triggers release-ios.yml)
git tag "v${VERSION}-ios"
git push origin "v${VERSION}-ios"

# Create and push Debug tag (triggers release-ios-debug.yml)
git tag "v${VERSION}-ios-debug"
git push origin "v${VERSION}-ios-debug"
```

**What happens:**
1. ✅ Two independent GitHub Actions workflows are triggered
2. ✅ Release workflow builds only Release frameworks
3. ✅ Debug workflow builds only Debug frameworks
4. ✅ Each creates its own GitHub release
5. ✅ Each uploads its framework zip as a release asset

### Step 4: Monitor GitHub Actions

1. **Visit Actions Page**
   ```
   https://github.com/rakuten/reels-sdk/actions
   ```

2. **Watch Build Progress**
   - Debug frameworks building (~5 min)
   - Release frameworks building (~5 min)
   - Packaging zips (~1 min)
   - Creating release (~1 min)

3. **Total Time: ~12-15 minutes**

### Step 5: Verify Release

1. **Check Both Release Pages**
   ```
   https://github.com/ahmed-eishon/Reels-SDK/releases/tag/v0.1.4-ios
   https://github.com/ahmed-eishon/Reels-SDK/releases/tag/v0.1.4-ios-debug
   ```

2. **Verify Assets** (2 separate releases created)
   - ✅ Release: `ReelsSDK-Frameworks-0.1.4.zip` (Release frameworks)
   - ✅ Debug Release: `ReelsSDK-Frameworks-Debug-0.1.4.zip` (Debug frameworks)

3. **Test Download**
   ```bash
   # Download Release package
   curl -L -O https://github.com/ahmed-eishon/Reels-SDK/releases/download/v0.1.4-ios/ReelsSDK-Frameworks-0.1.4.zip
   unzip -l ReelsSDK-Frameworks-0.1.4.zip

   # You'll see 6 frameworks with clean names (no suffixes):
   # - App.xcframework
   # - Flutter.xcframework
   # - FlutterPluginRegistrant.xcframework
   # - package_info_plus.xcframework
   # - video_player_avfoundation.xcframework
   # - wakelock_plus.xcframework

   # Download Debug package
   curl -L -O https://github.com/ahmed-eishon/Reels-SDK/releases/download/v0.1.4-ios-debug/ReelsSDK-Frameworks-Debug-0.1.4.zip
   unzip -l ReelsSDK-Frameworks-Debug-0.1.4.zip
   # Same 6 frameworks with clean names
   ```

## Local Development vs Distribution

### Local Development Mode

**For internal developers** (you):

```bash
# Your workflow (unchanged)
./scripts/dev/ios/build-room.sh

# This creates .reelsdk-dev marker file
# Frameworks built to: reels_flutter/.ios/Flutter/Debug/
```

**What happens:**
- ✅ `.reelsdk-dev` file exists
- ✅ pod install skips GitHub download
- ✅ Uses locally built Debug frameworks
- ✅ Fast iteration

### Distribution Mode

**For external users**:

```ruby
# Their Podfile - Debug version (development)
pod 'ReelsSDK',
    :git => 'https://github.com/ahmed-eishon/Reels-SDK.git',
    :tag => 'v0.1.4-ios-debug'

# OR Release version (production)
pod 'ReelsSDK',
    :git => 'https://github.com/ahmed-eishon/Reels-SDK.git',
    :tag => 'v0.1.4-ios'
```

**What happens:**
- ❌ `.reelsdk-dev` file doesn't exist
- ✅ pod install downloads from appropriate GitHub release
- ✅ Tag with `-ios-debug` downloads Debug frameworks
- ✅ Tag with `-ios` downloads Release frameworks
- ✅ Extracts 6 frameworks with clean names
- ✅ No Flutter required!

## Manual Framework Building (Optional)

If you need to build frameworks manually (without GitHub Actions):

```bash
# Build Release frameworks
cd reels_flutter
flutter build ios-framework --release --output=.ios/Flutter/Release

# Package for distribution
cd ..
./scripts/sdk/ios/package-frameworks.sh Release

# Creates: ReelsSDK-Frameworks-Release-0.1.4.zip

# Upload manually to GitHub release
gh release upload v0.1.4 ReelsSDK-Frameworks-Release-0.1.4.zip
```

## Troubleshooting

### Release Failed to Create

**Check GitHub Actions logs:**
1. Go to Actions tab
2. Click failed workflow
3. Read error messages

**Common issues:**
- Flutter version mismatch
- Missing dependencies
- Pigeon generation failed

**Solution:**
```bash
# Fix issue locally first
./scripts/sdk/ios/setup.sh
./scripts/sdk/ios/verify.sh

# Delete and recreate tag
git tag -d v0.1.4
git push origin :refs/tags/v0.1.4
./scripts/sdk/ios/prepare-release.sh 0.1.4
```

### Users Can't Download Frameworks

**Check:**
1. Release exists: `https://github.com/rakuten/reels-sdk/releases/tag/v0.1.4`
2. Assets uploaded (2 zip files + checksums)
3. Assets are public (not private)

**Solution:**
```bash
# Re-upload assets
gh release upload v0.1.4 ReelsSDK-Frameworks-Release-0.1.4.zip --clobber
```

### Local Development Not Working

**Check for marker file:**
```bash
ls -la .reelsdk-dev
```

**If missing:**
```bash
# Create manually
touch .reelsdk-dev

# Or run dev script
./scripts/dev/ios/build-room.sh
```

## Version Management

### Semantic Versioning

Use [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Breaking changes
  - Example: `0.1.4` → `2.0.0`
  - API changes, removed features

- **MINOR** version: New features (backward compatible)
  - Example: `0.1.4` → `0.1.5`
  - New APIs, enhancements

- **PATCH** version: Bug fixes
  - Example: `0.1.4` → `1.0.1`
  - Bug fixes only

### Pre-releases

For beta/alpha versions:

```bash
echo "0.1.4-beta.1" > VERSION
./scripts/sdk/ios/prepare-release.sh

# Creates: v0.1.4-beta.1
# Users: pod 'ReelsSDK', :git => '...', :tag => 'v0.1.4-beta.1'
```

## User Installation Instructions

Share these instructions with SDK users:

### Step 1: Add to Podfile

```ruby
# Podfile
target 'YourApp' do
  use_frameworks!

  # ReelsSDK from GitHub - Debug version for development
  pod 'ReelsSDK',
      :git => 'https://github.com/ahmed-eishon/Reels-SDK.git',
      :tag => 'v0.1.4-ios-debug'

  # OR use Release version for production builds
  # pod 'ReelsSDK',
  #     :git => 'https://github.com/ahmed-eishon/Reels-SDK.git',
  #     :tag => 'v0.1.4-ios'
end
```

### Step 2: Install

```bash
cd your-app
pod install
```

**What happens:**
1. CocoaPods clones the repo
2. Checks out the specified tag (e.g., `v0.1.4-ios-debug` or `v0.1.4-ios`)
3. Runs `prepare_command` in podspec
4. Downloads appropriate framework package from GitHub release:
   - Tag with `-ios-debug` → Downloads Debug frameworks
   - Tag with `-ios` → Downloads Release frameworks
5. Extracts 6 frameworks with clean names (no suffixes)
6. Adds frameworks to Pods/ReelsSDK/Frameworks/
7. Links to Xcode project

**Time: ~30 seconds** (vs ~30 minutes if they had to build Flutter)

**Technical Details:**
- Each release contains only one variant (Debug OR Release)
- Frameworks have clean names without suffixes
- Simply change the tag to switch between Debug and Release
- No build scripts or symlinks needed
- No environment variables required

### Step 3: Use in Code

```swift
import ReelsSDK

class ViewController: UIViewController {
    func showReels() {
        // Use ReelsSDK
    }
}
```

## CI/CD Integration

### Automated Releases

Add to your CI/CD pipeline:

```yaml
# Example: Automated release on version bump
on:
  push:
    paths:
      - 'VERSION'
    branches:
      - main

jobs:
  release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create release
        run: |
          VERSION=$(cat VERSION)
          ./scripts/sdk/ios/prepare-release.sh $VERSION
```

### Testing Releases

Before official release:

```bash
# Create test release
echo "0.1.4-test.1" > VERSION
./scripts/sdk/ios/prepare-release.sh

# Test in another project
cd test-app
# Update Podfile to use test tag
pod install

# Verify it works
# If good, create official release
```

## Best Practices

1. **Always test locally first**
   ```bash
   ./scripts/dev/ios/clean-build-room.sh
   ```

2. **Update VERSION file first**
   - Commit version bump separately
   - Makes git history cleaner

3. **Write release notes**
   - Add to GitHub release after creation
   - Document breaking changes
   - List new features

4. **Tag naming convention**
   - Always use `v` prefix: `v0.1.4` (not `0.1.4`)
   - Matches semantic versioning

5. **Keep releases stable**
   - Test thoroughly before releasing
   - Don't delete tags (users may depend on them)
   - If broken, release a patch: `v1.0.1`

## Migration from Old System

If you previously had a different distribution method:

### Before (Manual)
```bash
# Users had to:
1. Install Flutter
2. Clone repo
3. Build frameworks manually
4. Link to Xcode

Total time: ~30 minutes
```

### After (Automated)
```bash
# Users just:
# Update Podfile with tag (Debug or Release)
pod 'ReelsSDK', :git => '...', :tag => 'v0.1.4-ios-debug'
pod install

Total time: ~30 seconds
```

**Migration steps:**
1. ✅ Update Podfile to use new tag format (with `-ios-debug` or `-ios` suffix)
2. ✅ Remove manual framework links
3. ✅ Run `pod install`
4. ✅ Clean Xcode build

## Summary

**Release Checklist:**
- [ ] Update VERSION file
- [ ] Commit all changes
- [ ] Push both tags (`v*.*.*-ios` and `v*.*.*-ios-debug`)
- [ ] Monitor both GitHub Actions workflows
- [ ] Verify both releases created (Debug and Release)
- [ ] Test pod install from both releases
- [ ] Announce to team

**Key Benefits:**
- ✅ Separate workflows for Debug and Release builds
- ✅ Independent releases reduce build times
- ✅ Automated builds via GitHub Actions
- ✅ No Flutter required for users
- ✅ Fast installation (~30 seconds)
- ✅ Reproducible builds
- ✅ Easy version management (just change tag)
- ✅ Clean framework names (no suffixes)
- ✅ Works with CocoaPods naturally

---

**Need Help?**
- Scripts: `scripts/sdk/ios/README.md`
- Integration: `docs/02-Integration/01-iOS-Integration-Guide.md`
- Issues: Create GitHub issue
