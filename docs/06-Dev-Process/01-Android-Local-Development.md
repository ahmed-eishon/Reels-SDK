# Android Local Development Guide

This guide explains how to set up the Reels SDK for local development with folder-based integration, allowing you to make live changes to the SDK while developing your Android app.

## ✅ Verified Setup

This setup has been **successfully tested** with:
- **SDK Version:** 0.1.4
- **Flutter Version:** 3.38.1
- **Android Gradle Plugin:** 8.13
- **Test Date:** 2025-11-20

**What was verified:**
1. ✅ `clean-install-android.sh` script completes successfully (9-10s)
2. ✅ All Pigeon files generated correctly
3. ✅ Local folder integration with Android app project
4. ✅ Gradle sync resolves all dependencies
5. ✅ Build completes without errors

## Overview

**Local folder-based integration** allows you to:
- ✅ Make changes to the SDK and see them immediately in your app
- ✅ Debug SDK code directly from your app
- ✅ Test SDK changes before creating a release
- ✅ Contribute to SDK development

This approach is **recommended for SDK development** but not for production apps.

---

## Prerequisites

- Android Studio (latest stable version)
- Android SDK with Build Tools 35.0.0
- Flutter 3.35.6 or higher
- Git

**Environment Variables:**
```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"  # macOS
# or
export ANDROID_HOME="$HOME/Android/Sdk"  # Linux
```

---

## Setup Process

### Step 1: Clone the Reels SDK

```bash
# Clone to a location accessible by your Android app project
cd ~/Projects  # Or your preferred location
git clone <reels-sdk-repo-url> reels-sdk
cd reels-sdk
```

### Step 2: Run the Setup Script

Run the `clean-install-android.sh` script to prepare the SDK for local development:

```bash
./scripts/dev/android/clean-install-android.sh
```

**What this script does:**
1. ✅ Verifies Flutter installation
2. 🧹 Cleans Flutter build artifacts
3. 🗑️ Removes `.android` directory
4. 📦 Runs `flutter pub get`
5. 🔄 Regenerates Android platform files
6. 🐦 Regenerates Pigeon platform channel code
7. ✓ Verifies all generated files
8. ✓ Verifies reels_android module
9. ⚙️ Creates `local.properties` with SDK paths

**Expected output:**
```
✅ Android Development Setup Complete!

Total time: ~10 seconds
```

### Step 3: Configure Your Android App

#### 3.1 Update `settings.gradle`

Add the following to your app's `settings.gradle`:

```gradle
rootProject.name = 'your-app-name'
include ':app'

// ReelsSDK - Local folder integration for development
include ':reels_android'
project(':reels_android').projectDir = new File(
    settingsDir.parentFile,
    'reels-sdk/reels_android'  // Adjust path relative to your project
)

// Flutter module from reels_flutter
setBinding(new Binding([gradle: this]))
evaluate(new File(
    settingsDir.parentFile,
    'reels-sdk/reels_flutter/.android/include_flutter.groovy'
))
```

**Path Adjustment:**
- If `reels-sdk` and your app are in the same parent directory:
  ```
  ~/Projects/
  ├── reels-sdk/
  └── your-app/
  ```
  Use: `'reels-sdk/reels_android'` (as shown above)

- If different structure, adjust the path accordingly

#### 3.2 Update `app/build.gradle`

Replace the Maven-based dependency with local project dependency:

**Remove or comment out:**
```gradle
// debugImplementation 'com.rakuten:reels_android:0.1.4'
```

**Add:**
```gradle
// ReelsSDK - Local folder integration for development
implementation project(':reels_android')
```

#### 3.3 Disable AAR Download Task (if applicable)

If your project has an auto-download task for ReelsSDK from GitHub releases, disable it:

```gradle
// Automatically download Maven repo before dependency resolution
// NOTE: Disabled for local folder-based integration
// Uncomment to enable AAR-based integration with GitHub releases
//project.afterEvaluate {
//    tasks.matching { it.name.startsWith('pre') && it.name.contains('Build') }.all {
//        it.dependsOn downloadAndSetupReelsSDK
//    }
//    tasks.findByName('clean')?.finalizedBy cleanReelsSDK
//}
```

#### 3.4 Remove Maven Repository Configuration (Optional)

If you want to completely switch to local development, comment out the Maven repository:

```gradle
repositories {
    // ReelsSDK from GitHub release - Maven repository
    // Disabled for local folder integration
//    maven {
//        url "file://${rootProject.projectDir}/ReelsSDK-Android-Debug-0.1.4/maven-repo"
//    }

    // Keep other repositories...
    google()
    mavenCentral()
}
```

### Step 4: Sync and Build

1. **Open your project in Android Studio**
2. **Sync Gradle** (File → Sync Project with Gradle Files)
3. **Verify the setup:**
   - Check that `:reels_android` appears in the Gradle projects panel
   - Check that Flutter plugins (`:flutter`, `:video_player_android`, etc.) are included
4. **Build the project**

---

## Verifying the Setup

### Check Gradle Sync

After syncing, you should see these projects in the Gradle panel:

```
your-app
├── app
├── reels_android          ← SDK module
├── flutter                ← Flutter engine
├── package_info_plus      ← Flutter plugin
├── video_player_android   ← Flutter plugin
└── wakelock_plus          ← Flutter plugin
```

### Build and Run

```bash
# From command line
./gradlew clean assembleDebug

# Or from Android Studio
# Build → Make Project (Ctrl+F9 / Cmd+F9)
```

---

## Development Workflow

### Making Changes to the SDK

1. **Edit SDK code** in `reels-sdk/reels_android/` or `reels-sdk/reels_flutter/`
2. **Sync Gradle** in your app (if you changed build configurations)
3. **Rebuild** your app
4. **Run** to see changes

### Regenerating Pigeon Code

If you modify the Pigeon schema (`reels_flutter/pigeons/messages.dart`):

```bash
cd reels-sdk
./scripts/dev/android/clean-install-android.sh
```

This will regenerate:
- `reels_flutter/lib/core/pigeon_generated.dart`
- `reels_android/src/main/java/com/rakuten/room/reels/pigeon/PigeonGenerated.kt`

### Debugging SDK Code

1. **Set breakpoints** in `reels_android` Kotlin code
2. **Debug your app** from Android Studio
3. Debugger will stop at SDK breakpoints

---

## Common Issues and Solutions

### Issue 1: "Module not found: reels_android"

**Symptoms:**
```
> Could not resolve project :reels_android
```

**Solutions:**
1. Check that the path in `settings.gradle` is correct
2. Verify `reels-sdk` folder exists at the specified location
3. Run `clean-install-android.sh` again
4. Sync Gradle

### Issue 2: "include_flutter.groovy not found"

**Symptoms:**
```
> /path/to/include_flutter.groovy (No such file or directory)
```

**Solutions:**
1. Run `clean-install-android.sh` to generate `.android/` folder
2. Check path in `settings.gradle` is correct (use `settingsDir.parentFile`)
3. Verify `reels_flutter/.android/include_flutter.groovy` exists

### Issue 3: Flutter dependencies not resolving

**Symptoms:**
```
> Could not find io.flutter:flutter_embedding_debug:1.0.0
```

**Solutions:**
1. Check `ANDROID_HOME` environment variable is set
2. Ensure Flutter SDK is in PATH
3. Run `flutter doctor -v` to verify Flutter setup
4. Restart Android Studio

### Issue 4: Build fails with Pigeon errors

**Symptoms:**
```
> Unresolved reference: ReelsHostApi
```

**Solutions:**
1. Run `clean-install-android.sh` to regenerate Pigeon code
2. Verify Pigeon files were generated:
   ```bash
   ls reels_android/src/main/java/com/rakuten/room/reels/pigeon/
   ```
3. Clean and rebuild:
   ```bash
   ./gradlew clean build
   ```

### Issue 5: Changes not reflecting

**Symptoms:**
- Made changes to SDK but app still uses old code

**Solutions:**
1. **Clean build:**
   ```bash
   ./gradlew clean
   ```
2. **Invalidate caches** in Android Studio:
   - File → Invalidate Caches → Invalidate and Restart
3. **Verify you're editing the right location:**
   ```bash
   # Check which reels_android is being used
   ./gradlew :app:dependencies | grep reels_android
   ```

---

## Switching Between Local and AAR Integration

### From Local → AAR (Production)

1. **Comment out local project setup** in `settings.gradle`:
   ```gradle
   //include ':reels_android'
   //project(':reels_android').projectDir = new File(...)
   //evaluate(new File(...))
   ```

2. **Switch dependency** in `app/build.gradle`:
   ```gradle
   //implementation project(':reels_android')
   debugImplementation 'com.rakuten:reels_android:0.1.4'
   ```

3. **Enable AAR download task** (if applicable)

4. **Sync Gradle**

### From AAR → Local (Development)

Follow the setup process above.

---

## Best Practices

### 1. Keep SDK Updated
```bash
cd reels-sdk
git pull
./scripts/dev/android/clean-install-android.sh
```

### 2. Use Version Control
- Keep `settings.gradle` and `build.gradle` changes in a separate branch
- Don't commit local development setup to production branches

### 3. Test Before Releasing
Before creating a PR or release:
1. Test with local folder integration
2. Build AAR using `build-reels-android-aar.sh`
3. Test with AAR integration

### 4. Document Your Changes
- Update SDK documentation if you add/change APIs
- Add comments for complex logic
- Update CHANGELOG.md

---

## Scripts Reference

### `clean-install-android.sh`
**Location:** `scripts/dev/android/clean-install-android.sh`

**Purpose:** Sets up SDK for local folder-based integration

**When to run:**
- Initial setup
- After pulling SDK changes
- After modifying Pigeon schema
- When Flutter dependencies change

**Runtime:** ~10 seconds

### `build-reels-android-aar.sh`
**Location:** `scripts/sdk/android/build-reels-android-aar.sh`

**Purpose:** Builds complete SDK AARs for testing distribution

**Usage:**
```bash
# Debug
./scripts/sdk/android/build-reels-android-aar.sh debug

# Release
./scripts/sdk/android/build-reels-android-aar.sh release
```

**When to use:**
- Testing AAR-based integration
- Before creating a release
- Verifying build process

---

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│         Your Android App                    │
│  ┌───────────────────────────────────────┐  │
│  │  settings.gradle                      │  │
│  │  - include ':reels_android'           │  │
│  │  - evaluate include_flutter.groovy    │  │
│  └───────────────────────────────────────┘  │
│              ↓                               │
│  ┌───────────────────────────────────────┐  │
│  │  app/build.gradle                     │  │
│  │  - implementation project(':reels..') │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│         Reels SDK (Local Folder)            │
│  ┌───────────────────────────────────────┐  │
│  │  reels_android/                       │  │
│  │  - build.gradle                       │  │
│  │  - src/main/java/.../ReelsModule.kt  │  │
│  │  - PigeonGenerated.kt                 │  │
│  └───────────────────────────────────────┘  │
│              ↓                               │
│  ┌───────────────────────────────────────┐  │
│  │  reels_flutter/.android/              │  │
│  │  - include_flutter.groovy             │  │
│  │  - Flutter module integration         │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

---

## See Also

- [Android Build Process](../04-Build-Process/02-Android-Build.md)
- [Android Integration Guide](../02-Integration/02-Android-Integration-Guide.md)
- [Android Local Scripts](../07-Scripts/Android/01-Local-Scripts.md)
- [Platform Communication](../03-Architecture/01-Platform-Communication.md)
