# Android Local Scripts Documentation

Documentation for Android development and build scripts.

## Overview

Android scripts are organized into two categories:
- **Development Scripts** (`scripts/dev/android/`) - Local development setup
- **SDK Build Scripts** (`scripts/sdk/android/`) - AAR building for distribution

**Note:** GitHub Actions workflows for Android releases run all build steps inline (not using these scripts). These scripts are specifically for local development and testing.

---

## Development Scripts

### `clean-install-android.sh`

**Location:** `scripts/dev/android/clean-install-android.sh`

**Purpose:** Sets up the SDK for local folder-based Android development

**Use Case:** When you want to integrate the SDK directly from source (without AAR files) into your Android app for development.

#### What it does:

1. ✅ Verifies Flutter installation
2. 🧹 Cleans Flutter build artifacts
3. 🗑️ Removes `.android` directory
4. 📦 Runs `flutter pub get`
5. 🔄 Regenerates Android platform files
6. 🐦 Regenerates Pigeon platform channel code
7. ✓ Verifies all generated files (Flutter + Android)
8. ✓ Verifies reels_android module structure
9. ⚙️ Creates `local.properties` with SDK paths

#### Usage:

```bash
# Run from SDK root
./scripts/dev/android/clean-install-android.sh
```

#### Output:

- Regenerated `.android/` folder with platform files
- Regenerated Pigeon code in `reels_android/`
- Configured `local.properties` with Android SDK and Flutter SDK paths
- Integration instructions for `settings.gradle`

#### Time:

~10-15 seconds

#### Integration Instructions (Provided by Script):

After running the script, add to your Android app's `settings.gradle`:

```gradle
// ReelsSDK - Local folder integration
include ':reels_android'
project(':reels_android').projectDir = new File('/path/to/reels-sdk/reels_android')

// Flutter module from reels_flutter
setBinding(new Binding([gradle: this]))
evaluate(new File(
    '/path/to/reels-sdk/reels_flutter/.android/include_flutter.groovy'
))
```

And in `app/build.gradle`:

```gradle
dependencies {
    implementation project(':reels_android')
}
```

#### When to use:

- ✅ Local development with live code changes
- ✅ Debugging SDK issues
- ✅ Contributing to SDK development
- ❌ Not for production (use AAR builds instead)

---

## SDK Build Scripts

### `build-reels-android-aar.sh`

**Location:** `scripts/sdk/android/build-reels-android-aar.sh`

**Purpose:** Builds complete SDK AARs (Flutter + reels_android) for AAR-based integration

**Use Case:** When you want to test the full AAR build process locally before releasing.

#### What it does:

1. 📦 Runs `flutter pub get`
2. 🐦 Regenerates Pigeon code
3. 🏗️ Builds Flutter AAR (debug or release)
4. 📍 Sets up Maven repository path
5. ⚙️ Prepares helper-reels-android wrapper project
6. 🏗️ Builds reels_android AAR (debug or release)
7. 📊 Shows build outputs
8. 🧹 Cleans up generated files

#### Usage:

```bash
# Build debug AARs (default)
./scripts/sdk/android/build-reels-android-aar.sh

# Build debug AARs (explicit)
./scripts/sdk/android/build-reels-android-aar.sh debug

# Build release AARs
./scripts/sdk/android/build-reels-android-aar.sh release
```

#### Prerequisites:

- `ANDROID_HOME` environment variable must be set
- Flutter installed and in PATH
- Android SDK installed

#### Output Locations:

**Flutter AAR:**
```
reels_flutter/build/host/outputs/repo/
├── com/example/reels_flutter/flutter_debug/1.0/
│   └── flutter_debug-1.0.aar
└── [plugin AARs...]
```

**reels_android AAR:**
```
reels_android/build/outputs/aar/
└── reels_android-debug.aar
   (or reels_android-release.aar)
```

#### Time:

- Debug: ~15-20 seconds
- Release: ~20-30 seconds

#### Build Modes:

| Mode | Optimization | Size | Symbols | Use Case |
|------|-------------|------|---------|----------|
| **debug** | None | Larger | Yes | Development, debugging |
| **release** | Full | Smaller | No | Production testing |

#### When to use:

- ✅ Testing AAR build process locally
- ✅ Verifying AAR packaging before release
- ✅ Creating AARs for manual distribution
- ❌ Not used by GitHub Actions (workflows build inline)

#### Differences from GitHub Actions:

GitHub Actions workflows (`release-android.yml` and `release-android-debug.yml`) perform the same build steps **inline** in the workflow YAML rather than calling this script. This script is equivalent but exists for local development and testing.

**Key differences:**
- Workflows publish to Maven Local and create release packages
- This script only builds AARs (no publishing or packaging)
- Workflows run on Ubuntu; this script runs on macOS/Linux

---

## Common Utilities

### `common.sh`

**Location:** `scripts/lib/common.sh`

**Purpose:** Shared utility library for all scripts (iOS + Android)

Both Android scripts use functions from `common.sh`:

#### Logging Functions:
- `log_info()` - Informational messages (blue)
- `log_success()` - Success messages (green)
- `log_error()` - Error messages (red)
- `log_warning()` - Warning messages (yellow)
- `log_step()` - Step headers
- `log_header()` - Section headers
- `log_footer()` - Section footers
- `log_command()` - Command being executed

#### Time Tracking:
- `track_script_start()` - Start timing
- `track_script_end()` - End timing and display duration

#### Validation:
- `check_flutter_installed()` - Verify Flutter in PATH
- `verify_file_exists()` - Check file existence
- `verify_directory_exists()` - Check directory existence

#### Path Resolution:
- `get_sdk_root()` - Get SDK root directory
- `get_flutter_module_dir()` - Get reels_flutter path
- `get_android_module_dir()` - Get reels_android path

#### Flutter Operations:
- `clean_flutter_build()` - Run flutter clean
- `flutter_pub_get()` - Run flutter pub get
- `regenerate_pigeon()` - Run pigeon code generation
- `verify_pigeon_files()` - Verify generated files (iOS + Android)

---

## Script Testing Status

| Script | Status | Tested Date | Notes |
|--------|--------|-------------|-------|
| `clean-install-android.sh` | ✅ Verified | 2025-11-20 | All steps pass, 10s runtime |
| `build-reels-android-aar.sh` (debug) | ✅ Verified | 2025-11-20 | Successful build, 17s runtime |
| `build-reels-android-aar.sh` (release) | ⚠️ Env Issue | 2025-11-20 | SSL cert issue (network/env) |

---

## Troubleshooting

### ANDROID_HOME not set

**Error:**
```
❌ Error: ANDROID_HOME environment variable not set
```

**Solution:**
```bash
# macOS
export ANDROID_HOME="$HOME/Library/Android/sdk"

# Linux
export ANDROID_HOME="$HOME/Android/Sdk"
```

### SSL Certificate Issues (Release builds)

**Error:**
```
PKIX path building failed: unable to find valid certification path
```

**Cause:** Corporate network with SSL inspection or certificate issues

**Solutions:**
1. Use debug build instead (no remote dependencies)
2. Update Java certificates
3. Configure Gradle to trust corporate proxy
4. Use VPN/different network

### Flutter not found

**Error:**
```
❌ Flutter not found in PATH
```

**Solution:**
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### Helper project build fails

**Symptoms:** Gradle build fails in step 4

**Common causes:**
- Maven repo path incorrect
- Flutter AAR not built properly
- Gradle cache corruption

**Solution:**
```bash
# Clean and retry
cd helper-reels-android
./gradlew clean --refresh-dependencies
cd ..
./scripts/sdk/android/build-reels-android-aar.sh
```

---

## FAQ

### Q: Why are there two different integration methods?

**A:**
- **Folder-based** (`clean-install-android.sh`) - For SDK development, allows live code changes
- **AAR-based** (`build-reels-android-aar.sh`) - For testing distribution, mimics production integration

### Q: Why don't GitHub Actions use these scripts?

**A:**
- Android workflows run steps inline for transparency and easier CI/CD debugging
- iOS workflows use scripts because the build process is more complex
- May be unified in the future for consistency

### Q: Do I need to run both scripts?

**A:**
- **For local development:** Only run `clean-install-android.sh`
- **For testing AAR builds:** Only run `build-reels-android-aar.sh`
- They serve different purposes and are independent

### Q: How often should I run clean-install-android.sh?

**A:** Run it when:
- Pigeon schema changes (`pigeons/messages.dart`)
- Flutter dependencies update (`pubspec.yaml`)
- Flutter module structure changes
- After pulling major changes from git
- When Android integration breaks

### Q: Can I use these scripts on Windows?

**A:**
- Currently optimized for macOS/Linux (bash scripts)
- Windows support via WSL or Git Bash may work but is untested
- Consider using the GitHub Actions workflows for Windows

---

## See Also

- [Android Workflow Scripts](./01-Android-Workflow-Scripts.md) - GitHub Actions workflows
- [Android Integration Guide](../02-Integration/02-Android-Integration-Guide.md) - Integration instructions
- [Android Build Process](../04-Build-Process/02-Android-Build.md) - Build architecture
