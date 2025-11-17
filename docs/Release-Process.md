# ReelsSDK Release Process

Complete guide for creating and distributing new releases of ReelsSDK.

## Overview

ReelsSDK uses **GitHub Actions** to automate framework building and release creation. This eliminates the need for users to have Flutter installed and ensures consistent, reproducible builds.

## Release Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Developer                                                   │
│  1. Update VERSION file                                      │
│  2. Commit and push to master                                │
│  3. Push tag: v0.1.2-ios                                     │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions (Triggered by v*.*.*-ios tag)               │
│  1. Builds Debug frameworks                                  │
│  2. Builds Release frameworks                                │
│  3. Packages 3 variants:                                     │
│     - Full package (all frameworks with _Debug/_Release)     │
│     - Debug-only package (only _Debug frameworks)            │
│     - Release-only package (only _Release frameworks)        │
│  4. Creates GitHub Release                                   │
│  5. Uploads framework zips as assets                         │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  End User                                                     │
│  pod 'ReelsSDK', :git => '...', :tag => 'v0.1.2-ios'       │
│  → CocoaPods downloads FULL package from release             │
│  → Both Debug & Release frameworks installed                 │
│  → Build script automatically selects correct variant        │
│  → No Flutter installation required!                         │
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
echo "1.0.0" > VERSION

# Update in podspec (automatically read from VERSION)
cat ReelsSDK.podspec | grep version
# Should show: spec.version = File.read(...)
```

### Step 2: Commit Changes

```bash
# Stage all changes
git add .

# Commit
git commit -m "Prepare release v1.0.0"

# Push to main/master
git push origin master
```

### Step 3: Run Release Script

```bash
# Navigate to SDK root
cd /path/to/reels-sdk

# Run prepare release script
./scripts/sdk/ios/prepare-release.sh 1.0.0

# Or use VERSION file
./scripts/sdk/ios/prepare-release.sh
```

**What the script does:**
1. ✅ Verifies git status (clean working directory)
2. ✅ Validates SDK integrity
3. ✅ Lints podspec
4. ✅ Creates git tag `v1.0.0`
5. ✅ Pushes tag to GitHub (triggers CI)

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

1. **Check Release Page**
   ```
   https://github.com/ahmed-eishon/Reels-SDK/releases/tag/v0.1.2-ios
   ```

2. **Verify Assets** (3 packages created)
   - ✅ `ReelsSDK-Frameworks-0.1.2.zip` (Full - both Debug & Release)
   - ✅ `ReelsSDK-Frameworks-Debug-0.1.2.zip` (Debug only)
   - ✅ `ReelsSDK-Frameworks-Release-0.1.2.zip` (Release only)

3. **Test Download**
   ```bash
   # Download full package (this is what users get by default)
   curl -L -O https://github.com/ahmed-eishon/Reels-SDK/releases/download/v0.1.2-ios/ReelsSDK-Frameworks-0.1.2.zip
   unzip -l ReelsSDK-Frameworks-0.1.2.zip

   # You'll see frameworks with both suffixes:
   # - App_Debug.xcframework
   # - App_Release.xcframework
   # - Flutter_Debug.xcframework
   # - Flutter_Release.xcframework
   # etc.

   # This naming allows both variants to coexist
   # Build script automatically selects correct variant per configuration
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
# Their Podfile
pod 'ReelsSDK',
    :git => 'https://github.com/rakuten/reels-sdk.git',
    :tag => 'v1.0.0'
```

**What happens:**
- ❌ `.reelsdk-dev` file doesn't exist
- ✅ pod install downloads from GitHub release
- ✅ Extracts Release frameworks
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

# Creates: ReelsSDK-Frameworks-Release-1.0.0.zip

# Upload manually to GitHub release
gh release upload v1.0.0 ReelsSDK-Frameworks-Release-1.0.0.zip
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
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
./scripts/sdk/ios/prepare-release.sh 1.0.0
```

### Users Can't Download Frameworks

**Check:**
1. Release exists: `https://github.com/rakuten/reels-sdk/releases/tag/v1.0.0`
2. Assets uploaded (2 zip files + checksums)
3. Assets are public (not private)

**Solution:**
```bash
# Re-upload assets
gh release upload v1.0.0 ReelsSDK-Frameworks-Release-1.0.0.zip --clobber
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
  - Example: `1.0.0` → `2.0.0`
  - API changes, removed features

- **MINOR** version: New features (backward compatible)
  - Example: `1.0.0` → `1.1.0`
  - New APIs, enhancements

- **PATCH** version: Bug fixes
  - Example: `1.0.0` → `1.0.1`
  - Bug fixes only

### Pre-releases

For beta/alpha versions:

```bash
echo "1.0.0-beta.1" > VERSION
./scripts/sdk/ios/prepare-release.sh

# Creates: v1.0.0-beta.1
# Users: pod 'ReelsSDK', :git => '...', :tag => 'v1.0.0-beta.1'
```

## User Installation Instructions

Share these instructions with SDK users:

### Step 1: Add to Podfile

```ruby
# Podfile
target 'YourApp' do
  use_frameworks!

  # ReelsSDK from GitHub - Automatic framework selection
  pod 'ReelsSDK',
      :git => 'https://github.com/ahmed-eishon/Reels-SDK.git',
      :tag => 'v0.1.2-ios'
end
```

### Step 2: Install

```bash
cd your-app
pod install
```

**What happens:**
1. CocoaPods clones the repo
2. Checks out tag `v0.1.2-ios`
3. Runs `prepare_command` in podspec
4. Downloads FULL package from GitHub (contains both Debug & Release frameworks)
5. Extracts frameworks (with _Debug/_Release suffixes)
6. Adds all frameworks to Pods/ReelsSDK/Frameworks/
7. Script phase automatically creates symlinks to correct variant during build
8. Links to Xcode project

**Time: ~30 seconds** (vs ~30 minutes if they had to build Flutter)

**Technical Details:**
- Frameworks use suffix naming (_Debug, _Release) to allow both variants to coexist
- A build script phase runs before compilation to create symlinks
- Your Debug builds: symlinks point to *_Debug.xcframework
- Your Release builds: symlinks point to *_Release.xcframework
- This happens transparently without any configuration needed
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
echo "1.0.0-test.1" > VERSION
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
   - Always use `v` prefix: `v1.0.0` (not `1.0.0`)
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
pod install

Total time: ~30 seconds
```

**Migration steps:**
1. ✅ Update Podfile to use new format
2. ✅ Remove manual framework links
3. ✅ Run `pod install`
4. ✅ Clean Xcode build

## Summary

**Release Checklist:**
- [ ] Update VERSION file
- [ ] Commit all changes
- [ ] Run `./scripts/sdk/ios/prepare-release.sh`
- [ ] Monitor GitHub Actions
- [ ] Verify release created
- [ ] Test pod install from release
- [ ] Announce to team

**Key Benefits:**
- ✅ Automated builds via GitHub Actions
- ✅ No Flutter required for users
- ✅ Fast installation (~30 seconds)
- ✅ Reproducible builds
- ✅ Easy version management
- ✅ Works with CocoaPods naturally

---

**Need Help?**
- Scripts: `scripts/sdk/ios/README.md`
- Integration: `docs/02-Integration/01-iOS-Integration-Guide.md`
- Issues: Create GitHub issue
