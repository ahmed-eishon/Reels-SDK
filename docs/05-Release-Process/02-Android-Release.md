# ReelsSDK Android Release Process

Complete guide for creating and distributing Android AAR releases of ReelsSDK.

## Overview

ReelsSDK uses **GitHub Actions** to automate AAR building and release creation. This eliminates the need for users to build from source and ensures consistent, reproducible builds.

## Release Architecture

ReelsSDK uses **separate workflows** for Debug and Release builds:

```
┌─────────────────────────────────────────────────────────────┐
│  Developer                                                   │
│  1. Update VERSION file → 0.1.4                             │
│  2. Commit and push to release branch                        │
│  3. Push two tags:                                           │
│     - v0.1.4-android → Triggers Release workflow            │
│     - v0.1.4-android-debug → Triggers Debug workflow        │
└────────────────────────┬─────────────────────────────────────┘
                         │
                ┌────────┴────────┐
                ▼                 ▼
┌───────────────────────┐  ┌───────────────────────┐
│  Release Workflow     │  │  Debug Workflow       │
│  (release-android)    │  │  (release-android-    │
│                       │  │   debug)              │
│  1. Build Flutter AAR │  │  1. Build Flutter AAR │
│     (Release)         │  │     (Debug)           │
│  2. Build reels_      │  │  2. Build reels_      │
│     android AAR       │  │     android AAR       │
│     (Release)         │  │     (Debug)           │
│  3. Package Maven     │  │  3. Package Maven     │
│     repository        │  │     repository        │
│  4. Create release    │  │  4. Create release    │
│  5. Upload assets     │  │  5. Upload assets     │
└───────────┬───────────┘  └───────────┬───────────┘
            │                          │
            ▼                          ▼
┌──────────────────────┐    ┌──────────────────────┐
│  v0.1.4-android      │    │  v0.1.4-android-     │
│  Release             │    │  debug Release       │
│  Package:            │    │  Package:            │
│  ReelsSDK-Android-   │    │  ReelsSDK-Android-   │
│  0.1.4.zip           │    │  Debug-0.1.4.zip     │
│  Contains:           │    │  Contains:           │
│  - Flutter Release   │    │  - Flutter Debug     │
│  - reels_android     │    │  - reels_android     │
│    Release           │    │    Debug             │
│  (Maven repo)        │    │  (Maven repo)        │
└──────────────────────┘    └──────────────────────┘
            │                          │
            └────────┬─────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  End User                                                     │
│  # For Debug (development):                                  │
│  Download ReelsSDK-Android-Debug-0.1.4.zip                   │
│  → Maven repository with Flutter Debug + reels_android Debug │
│                                                               │
│  # For Release (production):                                 │
│  Download ReelsSDK-Android-0.1.4.zip                        │
│  → Maven repository with Flutter Release + reels_android     │
│    Release                                                   │
│                                                               │
│  No Flutter installation required!                           │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### One-Time Setup

1. **GitHub Actions Enabled**
   - Workflow files: `.github/workflows/release-android*.yml`
   - Automatically enabled when files are present

2. **Git Remotes Configured**
   ```bash
   git remote -v
   # Should show both GitHub and GitPub
   ```

3. **Java & Gradle** (for local testing only)
   ```bash
   java -version  # Should be Java 17
   ./gradlew --version
   ```

## Creating a New Release

### Step 1: Update Version

```bash
# Update VERSION file
echo "0.1.4" > VERSION

# Verify version
cat VERSION
```

### Step 2: Commit Changes

```bash
# Stage all changes
git add .

# Commit
git commit -m "Prepare Android release v0.1.4"

# Push to main/master
git push origin master
```

### Step 3: Test Locally (Optional but Recommended)

Before pushing tags, test the build process locally:

```bash
# Test both Debug and Release
./scripts/sdk/android/test-release-locally.sh

# Or test individually
./scripts/sdk/android/test-release-locally.sh debug
./scripts/sdk/android/test-release-locally.sh release
```

**What the script does:**
- ✅ Builds Flutter AARs (Debug and/or Release)
- ✅ Builds reels_android AARs
- ✅ Packages everything into zip files
- ✅ Creates checksums
- ✅ Mimics GitHub Actions workflow exactly

**Output:**
- `ReelsSDK-Android-0.1.4.zip` (Release build)
- `ReelsSDK-Android-Debug-0.1.4.zip` (Debug build)

You can test these locally with your Android app before pushing to GitHub!

### Step 4: Create and Push Release Tags

Push **both** tags to trigger independent workflows:

```bash
# Navigate to SDK root
cd /path/to/reels-sdk

# Get version from VERSION file
VERSION=$(cat VERSION)

# Create and push Release tag (triggers release-android.yml)
git tag "v${VERSION}-android"
git push origin "v${VERSION}-android"

# Create and push Debug tag (triggers release-android-debug.yml)
git tag "v${VERSION}-android-debug"
git push origin "v${VERSION}-android-debug"
```

**What happens:**
1. ✅ Two independent GitHub Actions workflows are triggered
2. ✅ Release workflow builds **Flutter AAR (Release) + reels_android AAR (Release)** in Maven repository
3. ✅ Debug workflow builds **Flutter AAR (Debug) + reels_android AAR (Debug)** in Maven repository
4. ✅ Each creates its own GitHub release with complete SDK
5. ✅ Each uploads its package zip as a release asset

### Step 5: Monitor GitHub Actions

1. **Visit Actions Page**
   ```
   https://github.com/ahmed-eishon/Reels-SDK/actions
   ```

2. **Watch Build Progress**
   - Flutter AAR building (~3-5 min)
   - Android AAR building (~2-3 min)
   - Packaging zips (~1 min)
   - Creating release (~1 min)

3. **Total Time: ~7-10 minutes per build**

### Step 6: Verify Release

1. **Check Both Release Pages**
   ```
   https://github.com/ahmed-eishon/Reels-SDK/releases/tag/v0.1.4-android
   https://github.com/ahmed-eishon/Reels-SDK/releases/tag/v0.1.4-android-debug
   ```

2. **Verify Assets** (2 separate releases)
   - ✅ Release: `ReelsSDK-Android-0.1.4.zip`
   - ✅ Debug Release: `ReelsSDK-Android-Debug-0.1.4.zip`

3. **Test Download**
   ```bash
   # Download Release package
   curl -L -O https://github.com/ahmed-eishon/Reels-SDK/releases/download/v0.1.4-android/ReelsSDK-Android-0.1.4.zip

   unzip ReelsSDK-Android-0.1.4.zip
   ls -lh ReelsSDK-Android-0.1.4/
   # Should see:
   # - maven-repo/ (Maven repository structure)
   # - README.md

   # Check Maven repository contents
   find ReelsSDK-Android-0.1.4/maven-repo -name "*.aar" | head -5
   # Should show Flutter and reels_android Release AARs

   # Download Debug package
   curl -L -O https://github.com/ahmed-eishon/Reels-SDK/releases/download/v0.1.4-android-debug/ReelsSDK-Android-Debug-0.1.4.zip

   unzip ReelsSDK-Android-Debug-0.1.4.zip
   ls -lh ReelsSDK-Android-Debug-0.1.4/
   # Should see:
   # - maven-repo/ (Maven repository structure)
   # - README.md

   # Check Maven repository contents
   find ReelsSDK-Android-Debug-0.1.4/maven-repo -name "*.aar" | head -5
   # Should show Flutter and reels_android Debug AARs
   ```

## Local Development vs Distribution

### Local Development Mode

**For internal developers** (you):

```bash
# Your workflow (unchanged)
cd /path/to/reels-sdk
./scripts/dev/android/init-android.sh /path/to/reels-sdk

# In your Android project's settings.gradle:
include ':reels_android'
project(':reels_android').projectDir = new File('/absolute/path/to/reels-sdk/reels_android')
```

**What happens:**
- ✅ Direct folder import
- ✅ Immediate code changes
- ✅ Fast iteration
- ✅ Full debugging capability

### Distribution Mode

**For external users:**

```gradle
// settings.gradle or build.gradle (project level)
repositories {
    maven {
        // Point to extracted Maven repository
        url "file://${rootProject.projectDir}/../ReelsSDK-Android-0.1.4/maven-repo"
    }
    maven {
        url "https://storage.googleapis.com/download.flutter.io"
    }
}
```

```gradle
// app/build.gradle
dependencies {
    // Debug version (development)
    debugImplementation 'com.rakuten.reels:reels_android:0.1.4'

    // OR Release version (production)
    releaseImplementation 'com.rakuten.reels:reels_android:0.1.4'
}
```

> [!important] Maven Coordinates
> The correct Maven coordinates are `com.rakuten.reels:reels_android` (not `com.rakuten:reels_android`). This ensures the groupId matches the directory structure in the Maven repository: `com/rakuten/reels/reels_android/`.

**What happens:**
- ✅ Download Maven repository ZIP from GitHub release
- ✅ Extract to project directory
- ✅ Add Maven repository URL to Gradle
- ✅ Add dependency (reels_android pulls Flutter transitively)
- ✅ Sync and build!
- ✅ No Flutter installation required!

## Manual AAR Building (Optional)

If you need to build AARs manually (without GitHub Actions):

```bash
# Use the local testing script
./scripts/sdk/android/test-release-locally.sh

# Or build step-by-step:

# 1. Build Flutter AARs
cd reels_flutter
flutter pub get
flutter pub run pigeon --input pigeons/messages.dart
flutter build aar --release --no-debug --no-profile

# 2. Build reels_android AAR
cd ../reels_android
../gradlew assembleRelease

# 3. Find built AARs
# Flutter: reels_flutter/build/host/outputs/repo/...
# Android: reels_android/build/outputs/aar/reels_android-release.aar
```

## Critical Release Issues & Lessons Learned

### Maven Structure Mismatch (CRITICAL)

**Problem:** Users reported `Could not find com.rakuten.reels:reels_android:0.1.4` error even though the package was downloaded correctly.

**Root Cause:** Maven groupId in POM file didn't match the actual directory structure in the repository.

**Example of the Issue:**
```
❌ Wrong Structure:
POM file declares: groupId = "com.rakuten.reels"
Directory structure: com/rakuten/reels_android/0.1.4/
Gradle looks for: com/rakuten/reels/reels_android/0.1.4/ (doesn't exist!)
Result: "Could not find" error

✅ Correct Structure:
POM file declares: groupId = "com.rakuten.reels"
Directory structure: com/rakuten/reels/reels_android/0.1.4/
Gradle finds: com/rakuten/reels/reels_android/0.1.4/reels_android-0.1.4.aar
Result: Dependency resolves successfully
```

**How We Fixed It:**

1. **Updated `build.gradle` to use correct groupId:**
   ```gradle
   publishing {
       publications {
           debug(MavenPublication) {
               groupId = 'com.rakuten.reels'  // Changed from 'com.rakuten'
               artifactId = 'reels_android'
               version = getVersionName()
           }
       }
   }
   ```

2. **Fixed workflow copy command to preserve directory structure:**
   ```yaml
   # ❌ Wrong (had trailing slash):
   cp -r ~/.m2/repository/com/rakuten/reels "$PACKAGE_DIR/maven-repo/com/rakuten/"

   # ✅ Correct (no trailing slash):
   cp -r ~/.m2/repository/com/rakuten/reels "$PACKAGE_DIR/maven-repo/com/rakuten"
   ```

3. **Verification steps added to workflow:**
   ```yaml
   - name: List published artifacts
     run: |
       echo "=== Published reels_android artifacts ===="
       find ~/.m2/repository/com/rakuten/reels -name "*.aar" -o -name "*.pom"

   - name: Verify package structure
     run: |
       echo "=== Package Maven structure ===="
       find "$PACKAGE_DIR/maven-repo" -name "*.aar" -o -name "reels_android*.pom"
   ```

**Verification Checklist:**
```bash
# After building, always verify:

# 1. Check Maven local repository structure
find ~/.m2/repository/com/rakuten/reels -type f

# Expected output:
# ~/.m2/repository/com/rakuten/reels/reels_android/0.1.4/reels_android-0.1.4.aar
# ~/.m2/repository/com/rakuten/reels/reels_android/0.1.4/reels_android-0.1.4.pom

# 2. Check package structure
unzip -l ReelsSDK-Android-Debug-0.1.4.zip | grep "reels_android.*\.aar"

# Expected output:
# ReelsSDK-Android-Debug-0.1.4/maven-repo/com/rakuten/reels/reels_android/0.1.4/reels_android-0.1.4.aar

# 3. Verify POM groupId matches directory
unzip -p ReelsSDK-Android-Debug-0.1.4.zip \
  ReelsSDK-Android-Debug-0.1.4/maven-repo/com/rakuten/reels/reels_android/0.1.4/reels_android-0.1.4.pom \
  | grep -A 1 "<groupId>"

# Expected output:
# <groupId>com.rakuten.reels</groupId>
```

### Debug and Release Workflow Alignment

**Problem:** Debug and Release workflows initially used different groupIds, causing confusion and integration issues.

**Solution:** Ensured both workflows use identical Maven coordinates:
- Debug: `com.rakuten.reels:reels_android`
- Release: `com.rakuten.reels:reels_android`

**Best Practice:**
```gradle
// In reels_android/build.gradle
publishing {
    publications {
        release(MavenPublication) {
            groupId = 'com.rakuten.reels'  // Same
            artifactId = 'reels_android'    // Same
        }

        debug(MavenPublication) {
            groupId = 'com.rakuten.reels'  // Same
            artifactId = 'reels_android'    // Same
        }
    }
}
```

This allows users to easily switch between debug and release by changing only the variant in their `build.gradle`.

### Shell Copy Commands and Trailing Slashes

**Problem:** Trailing slashes in shell copy commands caused directory flattening.

**Explanation:**
```bash
# If com/rakuten/ already exists:

# ❌ With trailing slash - copies CONTENTS
cp -r source/reels/ dest/com/rakuten/
# Result: dest/com/rakuten/reels_android/ (flattened!)

# ✅ Without trailing slash - copies DIRECTORY
cp -r source/reels dest/com/rakuten
# Result: dest/com/rakuten/reels/reels_android/ (correct!)
```

**Prevention:**
- Always use paths without trailing slashes when preserving directory structure
- Test copy commands locally before pushing to CI/CD
- Add verification steps to workflow to catch structure issues early

### Precautions for Future Releases

1. **Always verify Maven structure before release:**
   ```bash
   ./scripts/sdk/android/test-release-locally.sh
   # Then manually verify structure before pushing tags
   ```

2. **Ensure groupId matches directory structure:**
   - GroupId: `com.rakuten.reels`
   - Directory: `com/rakuten/reels/reels_android/`
   - POM file must declare exact groupId

3. **Test dependency resolution locally:**
   ```bash
   # After building package, test in a sample project
   ./gradlew app:dependencies --configuration debugCompileClasspath | grep reels_android
   ```

4. **Keep debug and release workflows aligned:**
   - Same groupId
   - Same artifactId
   - Only variant differs (debug vs release)

5. **Document structure in README:**
   - Include Maven coordinates
   - Show expected directory structure
   - Provide verification commands

## Troubleshooting

### Release Failed to Create

**Check GitHub Actions logs:**
1. Go to Actions tab
2. Click failed workflow
3. Read error messages

**Common issues:**
- Flutter version mismatch
- Gradle build failure
- Pigeon generation failed
- Missing dependencies

**Solution:**
```bash
# Test locally first
./scripts/sdk/android/test-release-locally.sh

# Fix issues, then delete and recreate tag
git tag -d v0.1.4-android
git push origin :refs/tags/v0.1.4-android

# Create new tag
git tag v0.1.4-android
git push origin v0.1.4-android
```

### Users Can't Download AARs

**Check:**
1. Release exists: `https://github.com/ahmed-eishon/Reels-SDK/releases/tag/v0.1.4-android`
2. Assets uploaded (zip + checksum)
3. Assets are public (not private)

**Solution:**
```bash
# Re-upload assets manually if needed
gh release upload v0.1.4-android ReelsSDK-Android-0.1.4.zip --clobber
```

### Local Testing Not Working

**Check prerequisites:**
```bash
# Flutter installed?
flutter --version

# Java 17?
java -version

# Gradle wrapper?
ls -la gradlew
```

**If missing:**
```bash
# Install Flutter
# https://flutter.dev/docs/get-started/install

# Install Java 17
# https://adoptium.net/

# Gradle wrapper should be in repo
```

## Version Management

### Semantic Versioning

Use [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Breaking changes
  - Example: `0.1.4` → `2.0.0`
  - API changes, removed features

- **MINOR** version: New features (backward compatible)
  - Example: `0.1.4` → `0.2.0`
  - New APIs, enhancements

- **PATCH** version: Bug fixes
  - Example: `0.1.4` → `0.1.5`
  - Bug fixes only

### Pre-releases

For beta/alpha versions:

```bash
echo "0.1.4-beta.1" > VERSION
git add VERSION
git commit -m "Prepare beta release"
git push origin master

git tag v0.1.4-beta.1-android
git push origin v0.1.4-beta.1-android
```

## User Installation Instructions

Share these instructions with SDK users:

### Step 1: Download AAR Package

**For Development (Debug):**
```bash
# Download from GitHub Releases
curl -L -O https://github.com/ahmed-eishon/Reels-SDK/releases/download/v0.1.4-android-debug/ReelsSDK-Android-Debug-0.1.4.zip

# Extract
unzip ReelsSDK-Android-Debug-0.1.4.zip
```

**For Production (Release):**
```bash
# Download from GitHub Releases
curl -L -O https://github.com/ahmed-eishon/Reels-SDK/releases/download/v0.1.4-android/ReelsSDK-Android-0.1.4.zip

# Extract
unzip ReelsSDK-Android-0.1.4.zip
```

### Step 2: Add Maven Repository

```gradle
// settings.gradle (or project-level build.gradle)
repositories {
    maven {
        // Point to extracted Maven repository
        url "file://${rootProject.projectDir}/../ReelsSDK-Android-0.1.4/maven-repo"
    }
    maven {
        url "https://storage.googleapis.com/download.flutter.io"
    }
    google()
    mavenCentral()
}
```

### Step 3: Update app/build.gradle

```gradle
// app/build.gradle
android {
    compileSdk 35

    defaultConfig {
        minSdk 21
        targetSdk 35
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    // For Debug build
    debugImplementation 'com.rakuten.reels:reels_android:0.1.4'

    // For Release build
    releaseImplementation 'com.rakuten.reels:reels_android:0.1.4'

    // Required dependencies (if not already present)
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.google.android.material:material:1.11.0'
}
```

### Step 4: Sync and Build

```bash
cd your-app
./gradlew clean build
```

**Time: ~30 seconds** (vs ~30 minutes if building from source)

### Step 5: Use in Code

```kotlin
import com.rakuten.room.reels.ReelsModule

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize SDK
        ReelsModule.initialize(this) {
            UserSession.accessToken
        }

        // Open reels
        ReelsModule.openReels(this)
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
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create release tags
        run: |
          VERSION=$(cat VERSION)
          git tag "v${VERSION}-android"
          git tag "v${VERSION}-android-debug"
          git push origin "v${VERSION}-android"
          git push origin "v${VERSION}-android-debug"
```

## Best Practices

1. **Always test locally first**
   ```bash
   ./scripts/sdk/android/test-release-locally.sh
   ```

2. **Update VERSION file first**
   - Commit version bump separately
   - Makes git history cleaner

3. **Write release notes**
   - Add to GitHub release after creation
   - Document breaking changes
   - List new features

4. **Tag naming convention**
   - Always use `v` prefix: `v0.1.4-android` (not `0.1.4-android`)
   - Matches semantic versioning

5. **Keep releases stable**
   - Test thoroughly before releasing
   - Don't delete tags (users may depend on them)
   - If broken, release a patch: `v0.1.5-android`

## Summary

**Release Checklist:**
- [ ] Update VERSION file
- [ ] Commit all changes
- [ ] Test locally with `test-release-locally.sh`
- [ ] Push both tags (`v*.*.*-android` and `v*.*.*-android-debug`)
- [ ] Monitor both GitHub Actions workflows
- [ ] Verify both releases created
- [ ] Test AAR download and integration
- [ ] Announce to team

**Key Benefits:**
- ✅ Separate workflows for Debug and Release builds
- ✅ Both workflows build **complete SDK** (Flutter + reels_android)
- ✅ Release workflow: Optimized Release AARs for production
- ✅ Debug workflow: Debug AARs with symbols for development
- ✅ Maven repository distribution (standard Android approach)
- ✅ Automated builds via GitHub Actions
- ✅ No Flutter installation required for users
- ✅ Fast installation (~30 seconds)
- ✅ Reproducible builds
- ✅ Easy version management

---

**Need Help?**
- Scripts: `scripts/sdk/android/`
- Integration: `docs/02-Integration/02-Android-Integration-Guide.md`
- Issues: Create GitHub issue
