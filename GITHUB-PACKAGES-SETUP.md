# Android SDK Integration Guide

## Overview

The Reels SDK Android library is published to **GitHub Releases** and automatically downloaded when you build your project. **No authentication required** - just like iOS CocoaPods!

## Quick Setup

### 1. Configure Gradle (Already Done!)

Your `settings.gradle` and `app/build.gradle` are already configured to automatically download the SDK from GitHub Releases.

### 2. Build Your Project

That's it! Just run:

```bash
./gradlew clean build
```

The SDK will be automatically downloaded from GitHub Releases on first build.

## How It Works

### settings.gradle
```gradle
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}
```

### app/build.gradle
```gradle
// Reels SDK - Download AARs from GitHub Releases (similar to iOS CocoaPods)
// Automatically downloads from GitHub when you run gradlew build - no authentication required
ext.reelsSDKVersion = '0.1.4'
ext.reelsSDKDir = file("$buildDir/reels-sdk-libs")

task downloadReelsSDK {
    description = 'Downloads Reels SDK AARs from GitHub Releases'
    group = 'reels-sdk'

    doLast {
        // Downloads release and debug AARs from GitHub Releases
        // Only downloads if not already cached
    }
}

preBuild.dependsOn(downloadReelsSDK)

dependencies {
    debugImplementation files("$buildDir/reels-sdk-libs/reels-sdk-debug-${reelsSDKVersion}.aar")
    debugImplementation files("$buildDir/reels-sdk-libs/flutter-debug-${reelsSDKVersion}.aar")

    releaseImplementation files("$buildDir/reels-sdk-libs/reels-sdk-${reelsSDKVersion}.aar")
    releaseImplementation files("$buildDir/reels-sdk-libs/flutter-release-${reelsSDKVersion}.aar")
}
```

## Comparison with iOS

| Platform | Package Manager | Authentication | Auto-Download |
|----------|----------------|----------------|---------------|
| **iOS** | CocoaPods | Not required | ✅ Yes |
| **Android** | Gradle + GitHub Releases | Not required | ✅ Yes |

Both provide automatic fetching and version management with no authentication!

## Updating SDK Version

To update to a new version, simply change the version number in `app/build.gradle`:

```gradle
ext.reelsSDKVersion = '0.1.5'  // Change this
```

Then clean and rebuild:

```bash
./gradlew clean build
```

## Build Output

When building, you'll see:

```
📦 Downloading Reels SDK 0.1.4 (Release) from GitHub...
   Downloading reels-sdk-0.1.4.aar...
   ✅ reels-sdk-0.1.4.aar downloaded
   Downloading flutter-release-0.1.4.aar...
   ✅ flutter-release-0.1.4.aar downloaded
🐛 Downloading Reels SDK 0.1.4 (Debug) from GitHub...
   Downloading reels-sdk-debug-0.1.4.aar...
   ✅ reels-sdk-debug-0.1.4.aar downloaded
   Downloading flutter-debug-0.1.4.aar...
   ✅ flutter-debug-0.1.4.aar downloaded
✅ Reels SDK 0.1.4 ready!
```

## Troubleshooting

### Download fails with network error

**Cause**: Network connectivity issue or GitHub is down

**Solution**:
1. Check your internet connection
2. Try again - the task will resume from where it failed
3. Check GitHub status: https://www.githubstatus.com/

### "Could not find reels-sdk-X.X.X.aar"

**Cause**: Version doesn't exist in GitHub Releases

**Solution**:
1. Check available versions at: https://github.com/ahmed-eishon/Reels-SDK/releases
2. Update `reelsSDKVersion` in `app/build.gradle`

### Build error after SDK update

**Cause**: Cached old version

**Solution**:
```bash
./gradlew clean
rm -rf app/build/reels-sdk-libs
./gradlew build
```

## Available Versions

Check published versions at:
https://github.com/ahmed-eishon/Reels-SDK/releases

## Documentation

For full integration guide, see:
- [Android Integration Guide](docs/02-Integration/02-Android-Integration-Guide.md)
- [API Reference](docs/05-API/02-Android-API-Reference.md)

## Support

If you encounter issues:
1. Check this guide first
2. Review the [Android Integration Guide](docs/02-Integration/02-Android-Integration-Guide.md)
3. Open an issue on GitHub

---

**Last Updated**: 2025-11-18
**SDK Version**: 0.1.4
