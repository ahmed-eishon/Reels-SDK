# Reels SDK - Version Management

This document tracks all tool and dependency versions used in the Reels SDK project.

## SDK Version
- **Reels SDK**: 0.1.4

## Flutter
- **Flutter Version**: 3.35.6
- **Dart SDK**: ^3.5.0

## Android
### SDK Versions
- **Compile SDK**: 35
- **Target SDK**: 35
- **Min SDK**: 30
- **Build Tools**: 35.0.0

### Build Tools
- **Gradle**: 8.14
- **Android Gradle Plugin**: 8.7.3
- **Kotlin**: 2.1.0

## iOS
### SDK Versions
- **iOS Deployment Target**: 13.0
- **Swift Version**: 5.0

### CocoaPods
- **CocoaPods**: 1.15.2

## Version Management Files

### Android
- **gradle.properties**: Defines Android SDK versions (COMPILE_SDK_VERSION, TARGET_SDK_VERSION, MIN_SDK_VERSION, BUILD_TOOLS_VERSION)
- **settings.gradle**: Declares Gradle plugins and versions
- **gradle/wrapper/gradle-wrapper.properties**: Gradle wrapper version

### Flutter
- **pubspec.yaml**: Flutter and Dart SDK versions, package dependencies

### iOS
- **ReelsSDK.pods pec**: iOS deployment target, CocoaPods version

## Updating Versions

### To update Android SDK versions:
1. Update `gradle.properties`: COMPILE_SDK_VERSION, TARGET_SDK_VERSION, MIN_SDK_VERSION
2. Update `reels_flutter/.android/build.gradle`: compileSdk, minSdk, targetSdk
3. Update `reels_android/build.gradle`: compileSdk, minSdk, targetSdk (uses gradle.properties)

### To update Gradle version:
1. Update `gradle/wrapper/gradle-wrapper.properties`: distributionUrl

### To update Android Gradle Plugin:
1. Update `settings.gradle`: com.android.library version

### To update Flutter version:
1. Update `.github/workflows/*.yml`: Flutter version in all workflows
2. Test locally before pushing

### To update Kotlin version:
1. Update `settings.gradle`: org.jetbrains.kotlin.android version
2. Update `reels_flutter/.android/settings.gradle`: org.jetbrains.kotlin.android version
