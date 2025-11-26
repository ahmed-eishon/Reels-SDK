# Technology Stack

This document details all technologies, frameworks, and dependencies used in the Reels SDK.

## Technology Overview

```mermaid
graph TB
    subgraph "Flutter Core (reels_flutter)"
        DART[Dart SDK ^3.9.2]
        FLUTTER[Flutter 3.35.6]

        subgraph "State & DI"
            PROVIDER[Provider 6.1.2]
            GETIT[GetIt 7.6.7]
        end

        subgraph "Video Playback"
            VIDEO_PLAYER[video_player 2.8.7]
            CHEWIE[chewie 1.8.5]
            VISIBILITY[visibility_detector 0.4.0+2]
        end

        subgraph "Platform Communication"
            PIGEON[Pigeon 22.7.4]
        end
    end

    subgraph "iOS Bridge (reels_ios)"
        SWIFT[Swift 5.9+]
        IOS_SDK[iOS 16.0+]
        COCOAPODS[CocoaPods]
    end

    subgraph "Android Bridge (reels_android)"
        KOTLIN[Kotlin 2.1.0]
        ANDROID_SDK[Android SDK 21-35]
        GRADLE[Gradle 8.14]
        AGP[Android Gradle Plugin 8.7.3]
    end

    FLUTTER --> PROVIDER
    FLUTTER --> GETIT
    FLUTTER --> VIDEO_PLAYER
    FLUTTER --> PIGEON

    VIDEO_PLAYER --> CHEWIE
    VIDEO_PLAYER --> VISIBILITY

    style FLUTTER fill:#9370DB
    style SWIFT fill:#FFB6C1
    style KOTLIN fill:#FFD700
```

## Flutter Module (reels_flutter)

### Core Framework

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter SDK** | 3.35.6 | UI framework |
| **Dart SDK** | ^3.9.2 | Programming language (from pubspec.yaml) |

### Dependencies

#### State Management
```yaml
provider: ^6.1.2
```
- Purpose: Reactive state management
- Usage: Video state, UI state, app-wide state

#### Dependency Injection
```yaml
get_it: ^7.6.7
```
- Purpose: Service locator pattern
- Usage: Register and resolve services, repositories, use cases

#### Video Playback
```yaml
video_player: ^2.8.7
chewie: ^1.8.5
visibility_detector: ^0.4.0+2
```
- **video_player**: Core video playback functionality
- **chewie**: Video player UI controls and overlays
- **visibility_detector**: Detect when videos enter/exit viewport for autoplay

#### UI Components
```yaml
cupertino_icons: ^1.0.8
```
- Purpose: iOS-style icons
- Usage: Icon widgets throughout the app

### Dev Dependencies

#### Code Generation
```yaml
pigeon: ^22.7.4
```
- Purpose: Type-safe platform channel code generation
- Generates: Swift, Kotlin, and Dart communication code

#### Testing
```yaml
flutter_test: sdk: flutter
mockito: ^5.4.4
network_image_mock: ^2.1.1
build_runner: ^2.4.8
```
- **mockito**: Mocking framework for unit tests
- **network_image_mock**: Mock network images in tests
- **build_runner**: Code generation runner

#### Linting
```yaml
flutter_lints: ^5.0.0
```
- Purpose: Code quality and style enforcement
- Follows Flutter recommended lints

## iOS Bridge (reels_ios)

### Platform Requirements

```mermaid
graph LR
    subgraph "iOS Requirements"
        IOS[iOS 16.0+]
        SWIFT[Swift 5.9+]
        XCODE[Xcode 15.0+]
        COCOAPODS[CocoaPods]
    end

    subgraph "Frameworks"
        UIKIT[UIKit]
        FOUNDATION[Foundation]
        AVFOUNDATION[AVFoundation]
    end

    IOS --> SWIFT
    SWIFT --> XCODE
    XCODE --> COCOAPODS

    SWIFT --> UIKIT
    SWIFT --> FOUNDATION
    SWIFT --> AVFOUNDATION

    style IOS fill:#87CEEB
    style SWIFT fill:#FFB6C1
```

| Component | Version/Requirement |
|-----------|---------------------|
| **iOS Deployment Target** | 16.0+ |
| **Swift Version** | 5.9+ |
| **Xcode** | 15.0+ |
| **CocoaPods** | Latest |

### iOS Frameworks Used
- **UIKit** - UI components and view controllers
- **Foundation** - Core data types and utilities
- **AVFoundation** - Video playback support (via Flutter)

### Podspec Configuration

```ruby
# ReelsSDK.podspec
Pod::Spec.new do |spec|
  spec.name                  = "ReelsSDK"
  spec.version               = File.read(File.join(__dir__, 'VERSION')).strip
  spec.ios.deployment_target = '16.0'
  spec.swift_version         = '5.9'

  # Vendored frameworks (downloaded from GitHub releases)
  spec.vendored_frameworks = [
    'Frameworks/App.xcframework',
    'Frameworks/Flutter.xcframework',
    'Frameworks/FlutterPluginRegistrant.xcframework',
    'Frameworks/package_info_plus.xcframework',
    'Frameworks/video_player_avfoundation.xcframework',
    'Frameworks/wakelock_plus.xcframework'
  ]
end
```

## Android Bridge (reels_android)

### Platform Requirements

```mermaid
graph LR
    subgraph "Android Requirements"
        MIN_SDK[Min SDK 21<br/>Android 5.0]
        TARGET_SDK[Target SDK 35<br/>Android 15]
        COMPILE_SDK[Compile SDK 35]
    end

    subgraph "Build Tools"
        KOTLIN[Kotlin 2.1.0]
        GRADLE[Gradle 8.14]
        AGP[AGP 8.7.3]
        JAVA[Java 17]
    end

    subgraph "Dependencies"
        ANDROIDX[AndroidX]
        MEDIA3[Media3 ExoPlayer 1.1.1]
    end

    MIN_SDK --> KOTLIN
    TARGET_SDK --> KOTLIN
    COMPILE_SDK --> KOTLIN

    KOTLIN --> GRADLE
    GRADLE --> AGP
    AGP --> JAVA

    KOTLIN --> ANDROIDX
    KOTLIN --> MEDIA3

    style MIN_SDK fill:#90EE90
    style KOTLIN fill:#FFD700
```

| Component | Version |
|-----------|---------|
| **Min SDK** | 21 (Android 5.0) |
| **Target SDK** | 35 (Android 15) |
| **Compile SDK** | 35 |
| **Kotlin** | 2.1.0 |
| **Gradle** | 8.14 |
| **Android Gradle Plugin** | 8.7.3 |
| **Java** | 17 |

### Android Dependencies

```gradle
dependencies {
    // Flutter embedding
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'

    // Material Design
    implementation 'com.google.android.material:material:1.11.0'

    // Media3 for video playback
    implementation 'androidx.media3:media3-exoplayer:1.1.1'

    // Flutter module (generated)
    implementation project(':flutter')
}
```

### Gradle Configuration

#### gradle.properties
```properties
# Android SDK versions
COMPILE_SDK_VERSION=35
TARGET_SDK_VERSION=35
MIN_SDK_VERSION=21
BUILD_TOOLS_VERSION=35.0.0

# Kotlin
KOTLIN_VERSION=2.1.0

# Gradle
GRADLE_VERSION=8.14
ANDROID_GRADLE_PLUGIN_VERSION=8.7.3
```

#### settings.gradle
```gradle
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id 'com.android.library' version '8.7.3' apply false
    id 'org.jetbrains.kotlin.android' version '2.1.0' apply false
}
```

## Platform Communication (Pigeon)

### Overview

```mermaid
graph TB
    MESSAGES[pigeons/messages.dart<br/>API Definition]

    subgraph "Code Generation"
        PIGEON_CMD[flutter pub run pigeon]
    end

    subgraph "Generated Files"
        DART_GEN[lib/core/pigeon_generated.dart<br/>Flutter Side]
        SWIFT_GEN[reels_ios/PigeonGenerated.swift<br/>iOS Side]
        KOTLIN_GEN[reels_android/PigeonGenerated.kt<br/>Android Side]
    end

    MESSAGES -->|Input| PIGEON_CMD

    PIGEON_CMD -->|Generate| DART_GEN
    PIGEON_CMD -->|Generate| SWIFT_GEN
    PIGEON_CMD -->|Generate| KOTLIN_GEN

    style MESSAGES fill:#FFB6C1
    style PIGEON_CMD fill:#FFA500
    style DART_GEN fill:#9370DB
    style SWIFT_GEN fill:#87CEEB
    style KOTLIN_GEN fill:#90EE90
```

### Pigeon Configuration

**Version:** 22.7.4

**Purpose:** Generate type-safe, bidirectional platform channels

**Generated APIs:**

#### Host APIs (Flutter → Native)
- `ReelsFlutterTokenApi.getAccessToken()` - Request access token
- `ReelsFlutterContextApi.getInitialCollect()` - Get collect context
- `ReelsFlutterContextApi.getCurrentGeneration()` - Get screen generation
- `ReelsFlutterContextApi.isDebugMode()` - Check debug status

#### Flutter APIs (Native → Flutter)
- `ReelsFlutterAnalyticsApi.trackEvent()` - Track analytics
- `ReelsFlutterButtonEventsApi.onLikeButtonClick()` - Handle like
- `ReelsFlutterButtonEventsApi.onShareButtonClick()` - Handle share
- `ReelsFlutterStateApi.onScreenStateChanged()` - Screen lifecycle
- `ReelsFlutterStateApi.onVideoStateChanged()` - Video state
- `ReelsFlutterNavigationApi.onSwipeLeft/Right()` - Navigation
- `ReelsFlutterNavigationApi.onUserProfileClick()` - Profile click
- `ReelsFlutterLifecycleApi.resetState()` - Reset state
- `ReelsFlutterLifecycleApi.pauseAll()` - Pause resources
- `ReelsFlutterLifecycleApi.resumeAll()` - Resume resources

## Version Management

### SDK Version
**Current Version:** 0.1.4

Defined in: `VERSION` file at repository root

### Version Files Location

```mermaid
graph TB
    VERSION[VERSION file<br/>Root directory<br/>0.1.4]

    subgraph "Auto-read by"
        PODSPEC[ReelsSDK.podspec<br/>iOS]
        BUILD_GRADLE[build.gradle<br/>Android]
        WORKFLOWS[GitHub Actions<br/>Workflows]
    end

    VERSION -->|Read| PODSPEC
    VERSION -->|Read| BUILD_GRADLE
    VERSION -->|Read| WORKFLOWS

    style VERSION fill:#FFA500
    style PODSPEC fill:#87CEEB
    style BUILD_GRADLE fill:#90EE90
    style WORKFLOWS fill:#FFB6C1
```

| Platform | File | Version Source |
|----------|------|----------------|
| **SDK** | `VERSION` | Single source of truth |
| **iOS** | `ReelsSDK.podspec` | Reads from `VERSION` |
| **Android** | `build.gradle` | Reads from `VERSION` |
| **CI/CD** | `.github/workflows/*.yml` | Reads from `VERSION` |

## Development Tools

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Flutter SDK** | 3.35.6 | Core development (CI/CD version) |
| **Dart SDK** | ^3.9.2 | Comes with Flutter |
| **Xcode** | 15.0+ | iOS development |
| **Android Studio** | Latest | Android development |
| **CocoaPods** | Latest | iOS dependency management |
| **Git** | Any | Version control |

### Optional Tools

| Tool | Purpose |
|------|---------|
| **VS Code** | Lightweight editor with Flutter extensions |
| **IntelliJ IDEA** | Alternative IDE with Flutter plugin |
| **GitHub CLI** | Release management |

## CI/CD Technology

### GitHub Actions

```mermaid
graph LR
    subgraph "Workflows"
        IOS_DEBUG[release-ios-debug.yml]
        IOS_RELEASE[release-ios.yml]
        ANDROID_DEBUG[release-android-debug.yml]
        ANDROID_RELEASE[release-android.yml]
    end

    subgraph "Runners"
        MACOS[macOS-latest<br/>iOS builds]
        UBUNTU[ubuntu-latest<br/>Android builds]
    end

    IOS_DEBUG --> MACOS
    IOS_RELEASE --> MACOS
    ANDROID_DEBUG --> UBUNTU
    ANDROID_RELEASE --> UBUNTU

    style MACOS fill:#87CEEB
    style UBUNTU fill:#90EE90
```

**Runners:**
- **macOS-latest** - iOS framework builds
- **ubuntu-latest** - Android AAR builds

**Tools Used:**
- Flutter action
- Java setup action
- Artifact upload action
- Release creation action

## Size Breakdown

### iOS Distribution

```mermaid
graph TB
    subgraph "iOS Frameworks"
        APP[App.xcframework<br/>~150 KB]
        FLUTTER[Flutter.xcframework<br/>~50 MB]
        PLUGIN_REG[FlutterPluginRegistrant<br/>~50 KB]
        PKG_INFO[package_info_plus<br/>~20 KB]
        VIDEO_PLAYER[video_player_avfoundation<br/>~100 KB]
        WAKELOCK[wakelock_plus<br/>~30 KB]
    end

    REELS_IOS[reels_ios Swift Bridge<br/>~300 KB]

    TOTAL[Total: ~50-60 MB<br/>One-time download]

    APP --> TOTAL
    FLUTTER --> TOTAL
    PLUGIN_REG --> TOTAL
    PKG_INFO --> TOTAL
    VIDEO_PLAYER --> TOTAL
    WAKELOCK --> TOTAL
    REELS_IOS --> TOTAL

    style FLUTTER fill:#9370DB
    style REELS_IOS fill:#FFB6C1
    style TOTAL fill:#FFA500
```

### Android Distribution

```mermaid
graph TB
    subgraph "Android AARs"
        REELS_AAR[reels-sdk-0.1.4.aar<br/>~3-4 MB]
        FLUTTER_AAR[flutter-release-0.1.4.aar<br/>~8-9 MB]
    end

    TOTAL[Total: ~11-12 MB<br/>Release Build]

    REELS_AAR --> TOTAL
    FLUTTER_AAR --> TOTAL

    style REELS_AAR fill:#FFD700
    style FLUTTER_AAR fill:#9370DB
    style TOTAL fill:#FFA500
```

## Update Strategy

### Dependency Updates

```mermaid
graph TB
    CHECK[Check for Updates]

    subgraph "Flutter Dependencies"
        FLUTTER_CHECK[flutter pub outdated]
        FLUTTER_UPDATE[flutter pub upgrade]
    end

    subgraph "iOS Dependencies"
        POD_CHECK[pod outdated]
        POD_UPDATE[pod update]
    end

    subgraph "Android Dependencies"
        GRADLE_CHECK[./gradlew dependencyUpdates]
        GRADLE_UPDATE[Update versions in gradle.properties]
    end

    CHECK --> FLUTTER_CHECK
    CHECK --> POD_CHECK
    CHECK --> GRADLE_CHECK

    FLUTTER_CHECK --> FLUTTER_UPDATE
    POD_CHECK --> POD_UPDATE
    GRADLE_CHECK --> GRADLE_UPDATE

    FLUTTER_UPDATE --> TEST[Run Tests]
    POD_UPDATE --> TEST
    GRADLE_UPDATE --> TEST

    TEST --> COMMIT[Commit Updates]

    style CHECK fill:#FFB6C1
    style TEST fill:#FFA500
    style COMMIT fill:#90EE90
```

### Version Compatibility Matrix

| Flutter | Dart SDK | iOS | Android | Gradle | Kotlin |
|---------|----------|-----|---------|--------|--------|
| 3.35.6 | ^3.9.2 | 16.0+ | 21+ | 8.14 | 2.1.0 |
