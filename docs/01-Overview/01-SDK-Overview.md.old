---
title: SDK Overview
type: overview
tags: [sdk, overview, reels]
---

# 🎥 SDK Overview

> [!info] Reels SDK
> Multi-platform SDK for integrating vertical video reels functionality into iOS and Android applications using Flutter's Add-to-App pattern

## What is Reels SDK?

The Reels SDK is a **multi-platform video reels solution** that provides a TikTok-style vertical video experience for iOS and Android applications. It leverages Flutter's "Add-to-App" approach to share core functionality between platforms while providing native Swift and Kotlin bridges for seamless integration.

## Key Characteristics

### Multi-Platform Architecture

```mermaid
graph TB
    subgraph "Reels SDK"
        FLUTTER[reels_flutter<br/>Shared Core<br/>Flutter/Dart]
        IOS_BRIDGE[reels_ios<br/>iOS Bridge<br/>Swift]
        ANDROID_BRIDGE[reels_android<br/>Android Bridge<br/>Kotlin]
    end

    subgraph "Native Apps"
        IOS_APP[iOS App]
        ANDROID_APP[Android App]
    end

    IOS_APP -->|CocoaPods| IOS_BRIDGE
    ANDROID_APP -->|Gradle| ANDROID_BRIDGE
    IOS_BRIDGE -->|Pigeon| FLUTTER
    ANDROID_BRIDGE -->|Pigeon| FLUTTER

    style FLUTTER fill:#9370DB
    style IOS_BRIDGE fill:#87CEEB
    style ANDROID_BRIDGE fill:#90EE90
```

### Core Components

| Component | Technology | Purpose | Size |
|-----------|-----------|---------|------|
| **reels_flutter** | Flutter/Dart | Shared UI and business logic | ~5,000 LOC |
| **reels_ios** | Swift 5.9+ | iOS native bridge | ~800 LOC |
| **reels_android** | Kotlin 1.9+ | Android native bridge | ~900 LOC |
| **Pigeon** | Code Generation | Type-safe communication | Auto-generated |

## Features

### User-Facing Features

| Feature | Description | Status |
|---------|-------------|--------|
| **Vertical Video Feed** | Swipeable vertical reels (TikTok-style) | ✅ |
| **Like/Unlike** | Like button with like count | ✅ |
| **Share** | Share videos to social platforms | ✅ |
| **Comments** | Comment on videos | ✅ |
| **User Profiles** | Navigate to user profiles | ✅ |
| **Product Tags** | Shopping integration with products | ✅ |
| **Autoplay** | Automatic video playback on view | ✅ |
| **Video Controls** | Play/pause, seek, volume | ✅ |
| **Video Descriptions** | Show video title, description | ✅ |

### Technical Features

| Feature | Description | Status |
|---------|-------------|--------|
| **Type-Safe Communication** | Pigeon-generated platform channels | ✅ |
| **Clean Architecture** | Domain-driven design pattern | ✅ |
| **Dependency Injection** | GetIt for IoC container | ✅ |
| **State Management** | Provider pattern | ✅ |
| **Async Access Tokens** | Support for async token providers | ✅ |
| **Event Callbacks** | ReelsListener interface | ✅ |
| **Analytics Tracking** | Built-in event tracking | ✅ |
| **Screen State Monitoring** | Lifecycle tracking | ✅ |
| **Video State Monitoring** | Playback state tracking | ✅ |
| **Mock Data Support** | Development/testing support | ✅ |

## Platform Support

### iOS Requirements

| Requirement | Value | Notes |
|-------------|-------|-------|
| **Minimum iOS** | 16.0 | Modern iOS support |
| **Swift Version** | 5.9+ | Native bridge language |
| **Xcode** | 15.0+ | Development environment |
| **CocoaPods** | Latest | Dependency manager (required) |
| **Flutter SDK** | 3.9.2+ | Build-time requirement |

### Android Requirements

| Requirement | Value | Notes |
|-------------|-------|-------|
| **Min SDK** | 21 | Android 5.0 (Lollipop) |
| **Target SDK** | 35 | Android 15 |
| **Kotlin** | 1.9+ | Native bridge language |
| **Gradle** | 8.0+ | Build tool |
| **Android Studio** | Latest | Development environment |
| **Flutter SDK** | 3.9.2+ | Build-time requirement |

## Distribution Model

### Version Control

```mermaid
graph LR
    GIT[Git Repository<br/>Private Rakuten GitPub] --> TAGS[Version Tags<br/>v1.0.0, v1.1.0, etc.]
    TAGS --> IOS[iOS Integration<br/>CocoaPods]
    TAGS --> ANDROID[Android Integration<br/>Gradle]

    style GIT fill:#FFB6C1
    style TAGS fill:#FFD700
    style IOS fill:#87CEEB
    style ANDROID fill:#90EE90
```

| Aspect | Details |
|--------|---------|
| **Repository** | Private Rakuten GitPub |
| **URL** | `https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git` |
| **Versioning** | Semantic Versioning (SemVer) |
| **Current Version** | 1.0.0 |
| **Distribution** | Git tags + Git repository |
| **Access** | Private (Rakuten only) |

### Integration Methods

#### iOS Integration Options

| Method | Use Case | Pros | Cons |
|--------|----------|------|------|
| **Git + CocoaPods** | Production builds | ✅ Version control<br/>✅ Easy updates<br/>✅ CI/CD friendly | ⚠️ Git auth required<br/>⚠️ Network needed |
| **Local Folder** | Development | ✅ No auth issues<br/>✅ Instant changes<br/>✅ Easy debugging | ⚠️ Manual version mgmt |

#### Android Integration Options

| Method | Use Case | Pros | Cons |
|--------|----------|------|------|
| **Git + Gradle** | Production builds | ✅ Version control<br/>✅ Gradle managed<br/>✅ CI/CD friendly | ⚠️ Git auth required<br/>⚠️ Slower builds |
| **Local Folder** | Development | ✅ No auth issues<br/>✅ Fast builds<br/>✅ Easy debugging | ⚠️ Manual version mgmt |

## SDK Size & Performance

### Size Metrics

| Platform | SDK Size | Notes |
|----------|----------|-------|
| **iOS** | ~300 KB | Swift bridge + Flutter source |
| **Android** | ~370 KB | Kotlin bridge + Flutter source |
| **Flutter Engine** | Shared | Built into app, not counted in SDK size |

### Performance Metrics

| Metric | iOS | Android | Notes |
|--------|-----|---------|-------|
| **Initialization** | ~500ms | ~600ms | First launch |
| **Memory Overhead** | ~50 MB | ~60 MB | Flutter engine + UI |
| **Video Playback** | 60 FPS | 60 FPS | Smooth scrolling |
| **Startup Time** | <1s | <1s | After initialization |

## Use Cases

### Primary Use Cases

1. **In-App Content Discovery**
   - Browse video reels within your app
   - Discover new content and creators
   - Engage with videos (like, share, comment)

2. **User-Generated Content**
   - Display user-created video reels
   - Enable social interactions
   - Track engagement metrics

3. **Product Showcase**
   - Show products in video format
   - Interactive shopping experience
   - Direct product links

4. **Marketing Campaigns**
   - Promotional video content
   - Campaign-specific reels
   - Track campaign performance

### Integration Scenarios

#### Scenario 1: Full-Screen Experience

```swift
// iOS: Open full-screen reels
ReelsCoordinator.openReels(from: viewController)
```

```kotlin
// Android: Open full-screen activity
ReelsModule.openReels(context = this)
```

#### Scenario 2: Embedded Experience (Android Only)

```kotlin
// Android: Embed in existing activity
val fragment = ReelsModule.createReelsFragment()
supportFragmentManager
    .beginTransaction()
    .replace(R.id.container, fragment)
    .commit()
```

#### Scenario 3: Context-Aware Reels (iOS)

```swift
// iOS: Open reels with collect context
ReelsModule.openReels(
    from: viewController,
    collect: collectObject,  // Pass collect/item data
    animated: true
)
```

## Benefits

### For Mobile Teams

✅ **Reduced Development Time** - Single Flutter codebase for both platforms
✅ **Consistent UX** - Same UI and behavior across iOS/Android
✅ **Easy Integration** - Simple API with minimal setup
✅ **Type Safety** - Compile-time safety with Pigeon
✅ **Flexible Integration** - Multiple integration options
✅ **Maintainable** - Clean architecture with clear boundaries

### For Product Teams

✅ **Faster Time-to-Market** - Quick feature deployment
✅ **Cross-Platform Consistency** - Same features everywhere
✅ **Rich Analytics** - Built-in event tracking
✅ **Easy Customization** - Configurable behavior
✅ **Production Ready** - Version 1.0.0, battle-tested

### For Users

✅ **Smooth Experience** - 60 FPS video playback
✅ **Familiar Interface** - TikTok-style UX
✅ **Fast Loading** - Optimized performance
✅ **Native Feel** - Native bridges for seamless integration

## Architecture Highlights

### Clean Architecture

```mermaid
graph TB
    PRESENTATION[🎨 Presentation Layer<br/>UI + State Management]
    DOMAIN[💼 Domain Layer<br/>Business Logic]
    DATA[📦 Data Layer<br/>Repositories]

    PRESENTATION --> DOMAIN
    DOMAIN --> DATA

    style PRESENTATION fill:#FFB6C1
    style DOMAIN fill:#87CEEB
    style DATA fill:#90EE90
```

- **Presentation Layer:** Screens, widgets, state providers
- **Domain Layer:** Use cases, entities, repository interfaces
- **Data Layer:** Data sources, models, repository implementations

### Communication Architecture

```mermaid
graph LR
    NATIVE[Native App] -->|Method Calls| PIGEON[Pigeon<br/>Type-Safe Channels]
    PIGEON -->|Platform Calls| FLUTTER[Flutter Module]
    FLUTTER -->|Callbacks| PIGEON
    PIGEON -->|Events| NATIVE

    style NATIVE fill:#90EE90
    style PIGEON fill:#FFD700
    style FLUTTER fill:#9370DB
```

**Key Communication Patterns:**
- **Host API:** Flutter calls native (e.g., get access token)
- **Flutter API:** Native calls Flutter (e.g., analytics events)
- **Type-Safe:** Compile-time safety with Pigeon code generation
- **Bidirectional:** Two-way communication

📖 **See:** [[03-Architecture/05-Platform-Communication|Platform Communication]]

## Getting Started

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git
   ```

2. **For iOS:**
   ```bash
   cd reels-sdk
   ./scripts/init-ios.sh /path/to/reels-sdk /path/to/your-ios-app
   ```

3. **For Android:**
   ```bash
   cd reels-sdk
   ./scripts/init-android.sh /path/to/reels-sdk
   ```

4. **Integrate into your app:**
   - [[02-Integration/01-iOS-Integration-Guide|iOS Integration Guide]]
   - [[02-Integration/05-Android-Integration-Guide|Android Integration Guide]]

## Related Documentation

- [[02-Architecture-Overview|Architecture Overview]]
- [[03-Technology-Stack|Technology Stack]]
- [[04-Project-Structure|Project Structure]]
- [[02-Integration/01-iOS-Integration-Guide|iOS Integration]]
- [[02-Integration/05-Android-Integration-Guide|Android Integration]]

---

Back to [[00-MOC-Reels-SDK|Main Hub]]

#sdk #overview #reels #flutter #ios #android
