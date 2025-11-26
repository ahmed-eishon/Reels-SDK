# Reels SDK - Overview

> **Version:** 0.1.4
> **Status:** Active Development
> **Platforms:** iOS 16.0+ | Android SDK 21+

## What is Reels SDK?

Reels SDK is a multi-platform video reels solution that provides a TikTok-style vertical video experience for iOS and Android applications. It uses Flutter's "Add-to-App" pattern to share core functionality between platforms while providing native Swift and Kotlin bridges for seamless integration.

```mermaid
graph TB
    subgraph "Native Applications"
        IOS[iOS App<br/>Swift/UIKit]
        ANDROID[Android App<br/>Kotlin]
    end

    subgraph "Reels SDK"
        subgraph "Native Bridges"
            IOS_BRIDGE[reels_ios<br/>Swift Bridge]
            ANDROID_BRIDGE[reels_android<br/>Kotlin Bridge]
        end

        subgraph "Shared Core"
            FLUTTER[reels_flutter<br/>Flutter Module<br/>Dart]
        end

        PIGEON[Pigeon<br/>Type-Safe Channels]
    end

    IOS -->|Initialize & Open| IOS_BRIDGE
    ANDROID -->|Initialize & Open| ANDROID_BRIDGE

    IOS_BRIDGE <-->|Platform Calls| PIGEON
    ANDROID_BRIDGE <-->|Platform Calls| PIGEON

    PIGEON <-->|Bidirectional| FLUTTER

    style IOS fill:#87CEEB
    style ANDROID fill:#90EE90
    style IOS_BRIDGE fill:#FFB6C1
    style ANDROID_BRIDGE fill:#FFD700
    style FLUTTER fill:#9370DB
    style PIGEON fill:#FFA500
```

## Key Features

### User Features
- **Vertical Video Feed** - TikTok-style swipeable video experience
- **Engagement Actions** - Like, share, and comment functionality
- **User Profiles** - Navigate to user profile pages
- **Product Integration** - Shopping features with product tags
- **Video Playback** - Smooth autoplay with controls

### Technical Features
- **Type-Safe Communication** - Pigeon-generated platform channels
- **Clean Architecture** - Domain-driven design with clear separation
- **Cross-Platform** - Single Flutter codebase for iOS and Android
- **Native Performance** - Native bridges ensure optimal performance
- **Analytics Support** - Built-in event tracking
- **State Management** - Generation-based state for independent screen instances

## Architecture at a Glance

```mermaid
graph LR
    subgraph "Presentation Layer"
        UI[Screens & Widgets]
        STATE[State Providers]
    end

    subgraph "Domain Layer"
        ENTITIES[Entities]
        USECASES[Use Cases]
        REPOS_INTERFACE[Repository<br/>Interfaces]
    end

    subgraph "Data Layer"
        DATASOURCES[Data Sources]
        MODELS[Models]
        REPOS_IMPL[Repository<br/>Implementations]
    end

    subgraph "Core Layer"
        DI[Dependency<br/>Injection]
        SERVICES[Platform<br/>Services]
        PIGEON_GEN[Pigeon<br/>Generated]
    end

    UI --> USECASES
    STATE --> USECASES
    USECASES --> REPOS_INTERFACE
    REPOS_INTERFACE --> REPOS_IMPL
    REPOS_IMPL --> DATASOURCES
    REPOS_IMPL --> MODELS

    UI --> SERVICES
    USECASES --> DI
    SERVICES --> PIGEON_GEN

    style UI fill:#FFB6C1
    style USECASES fill:#87CEEB
    style REPOS_IMPL fill:#90EE90
    style SERVICES fill:#FFD700
```

## SDK Components

### 1. reels_flutter (Flutter Core)
**Purpose:** Shared UI and business logic

**Technologies:**
- Flutter 3.35.6
- Dart SDK ^3.9.2
- Provider (State Management)
- GetIt (Dependency Injection)
- Video Player & Chewie (Video Playback)
- Pigeon (Platform Communication)

### 2. reels_ios (iOS Bridge)
**Purpose:** Native Swift wrapper for iOS apps

**Technologies:**
- Swift 5.9+
- iOS 16.0+
- CocoaPods
- Pigeon-generated channels

**Key Files:**
- `ReelsModule.swift` - Main public API
- `ReelsCoordinator.swift` - Navigation coordinator
- `ReelsEngineManager.swift` - Flutter engine lifecycle
- `ReelsPigeonHandler.swift` - Platform communication
- `PigeonGenerated.swift` - Auto-generated type-safe channels

### 3. reels_android (Android Bridge)
**Purpose:** Native Kotlin wrapper for Android apps

**Technologies:**
- Kotlin 2.1.0
- Android SDK 21+ (Android 5.0+)
- Target SDK 35 (Android 15)
- Gradle 8.14
- Pigeon-generated channels

**Key Files:**
- `ReelsModule.kt` - Main public API
- `FlutterReelsActivity.kt` - Full-screen activity
- `FlutterReelsFragment.kt` - Embeddable fragment
- `FlutterEngineManager.kt` - Flutter engine lifecycle
- `FlutterMethodChannelHandler.kt` - Platform communication
- `PigeonGenerated.kt` - Auto-generated type-safe channels

## Platform Communication Flow

```mermaid
sequenceDiagram
    participant App as Native App
    participant Bridge as Native Bridge<br/>(Swift/Kotlin)
    participant Pigeon as Pigeon Channels
    participant Flutter as Flutter Module

    App->>Bridge: 1. Initialize SDK<br/>with accessTokenProvider
    App->>Bridge: 2. Set ReelsListener
    App->>Bridge: 3. openReels()

    Bridge->>Flutter: 4. Launch Flutter View
    activate Flutter

    Note over Flutter: Flutter initializes<br/>and requests token

    Flutter->>Pigeon: 5. getAccessToken()
    Pigeon->>Bridge: Host API Call
    Bridge->>App: accessTokenProvider()
    App-->>Bridge: return token
    Bridge-->>Pigeon: return token
    Pigeon-->>Flutter: return token

    Note over Flutter: User interacts<br/>with reels

    Flutter->>Pigeon: 6. onLikeButtonClick()
    Pigeon->>Bridge: Flutter API Call
    Bridge->>App: listener.onLikeButtonClick()

    Flutter->>Pigeon: 7. onAnalyticsEvent()
    Pigeon->>Bridge: Flutter API Call
    Bridge->>App: listener.onAnalyticsEvent()

    App->>Bridge: 8. User dismisses
    Bridge->>Flutter: Cleanup & Dispose
    deactivate Flutter
```

## Quick Start

### iOS (Swift)

```swift
import ReelsIOS

// 1. Initialize (in AppDelegate)
ReelsModule.initialize(
    accessTokenProvider: { completion in
        LoginManager.shared.getAccessToken { token in
            completion(token)
        }
    },
    debug: true
)

// 2. Set listener
ReelsModule.setListener(self)

// 3. Open reels
ReelsModule.openReels(
    from: viewController,
    initialRoute: "/",
    animated: true
)
```

### Android (Kotlin)

```kotlin
import com.rakuten.room.reels.ReelsModule

// 1. Initialize (in Application.onCreate)
ReelsModule.initialize(
    context = applicationContext,
    accessTokenProvider = { UserSession.accessToken },
    debug: true
)

// 2. Set listener
ReelsModule.setListener(this)

// 3. Open reels
ReelsModule.openReels(
    activity = this,
    initialRoute = "/",
    animated = true
)
```

## Integration Options

```mermaid
graph TB
    subgraph "Production Integration"
        GIT_IOS[iOS: CocoaPods + Git Tag]
        GIT_ANDROID[Android: Gradle + Git Tag]
    end

    subgraph "Development Integration"
        LOCAL_IOS[iOS: CocoaPods + Local Folder]
        LOCAL_ANDROID[Android: Gradle + Local Folder]
    end

    SDK[Reels SDK Repository]

    SDK -->|Version Tag| GIT_IOS
    SDK -->|Version Tag| GIT_ANDROID
    SDK -->|Direct Path| LOCAL_IOS
    SDK -->|Direct Path| LOCAL_ANDROID

    GIT_IOS -->|Downloads<br/>Frameworks| IOS_APP[iOS App]
    GIT_ANDROID -->|Downloads<br/>AARs| ANDROID_APP[Android App]
    LOCAL_IOS -->|Immediate<br/>Access| IOS_DEV[iOS Development]
    LOCAL_ANDROID -->|Immediate<br/>Access| ANDROID_DEV[Android Development]

    style GIT_IOS fill:#FFB6C1
    style GIT_ANDROID fill:#FFD700
    style LOCAL_IOS fill:#87CEEB
    style LOCAL_ANDROID fill:#90EE90
```

### Integration Comparison

| Method | Use Case | Advantages | Disadvantages |
|--------|----------|------------|---------------|
| **Git + CocoaPods/Gradle** | Production | ✅ Version control<br/>✅ Reproducible builds<br/>✅ CI/CD friendly | ⚠️ Requires Git auth<br/>⚠️ Slower updates |
| **Local Folder Import** | Development | ✅ No auth needed<br/>✅ Instant updates<br/>✅ Full debugging<br/>✅ Fast iteration | ⚠️ Manual version control<br/>⚠️ Requires local SDK |

## SDK Metrics

```mermaid
graph LR
    subgraph "Size"
        IOS_SIZE[iOS: ~300 KB]
        ANDROID_SIZE[Android: ~370 KB]
        FLUTTER_ENGINE[Flutter Engine<br/>~50-60 MB<br/>Shared Runtime]
    end

    subgraph "Requirements"
        IOS_REQ[iOS 16.0+<br/>Swift 5.9+]
        ANDROID_REQ[Android 21+<br/>Kotlin 2.1.0]
        FLUTTER_REQ[Flutter 3.35.6]
    end

    subgraph "Performance"
        INIT_IOS[Init: ~500ms<br/>iOS]
        INIT_ANDROID[Init: ~600ms<br/>Android]
        PLAYBACK[60 FPS Video<br/>Smooth Scrolling]
    end

    style IOS_SIZE fill:#87CEEB
    style ANDROID_SIZE fill:#90EE90
    style FLUTTER_ENGINE fill:#9370DB
```

| Metric | iOS | Android |
|--------|-----|---------|
| **Bridge Size** | ~300 KB | ~370 KB |
| **Min Version** | iOS 16.0 | SDK 21 (Android 5.0) |
| **Target Version** | iOS 18 | SDK 35 (Android 15) |
| **Language** | Swift 5.9+ | Kotlin 2.1.0 |
| **Init Time** | ~500ms | ~600ms |
| **Memory** | ~50 MB | ~60 MB |

## Repository Structure

```
reels-sdk/
├── reels_flutter/              # Flutter module (shared)
│   ├── lib/
│   │   ├── presentation/       # UI layer
│   │   ├── domain/             # Business logic
│   │   ├── data/               # Data sources
│   │   └── core/               # DI, services, pigeon
│   ├── assets/                 # Mock data
│   └── pubspec.yaml
│
├── reels_ios/                  # iOS bridge
│   └── Sources/ReelsIOS/
│       ├── ReelsModule.swift
│       ├── ReelsCoordinator.swift
│       ├── ReelsEngineManager.swift
│       └── PigeonGenerated.swift
│
├── reels_android/              # Android bridge
│   └── src/main/java/com/rakuten/room/reels/
│       ├── ReelsModule.kt
│       ├── flutter/
│       └── pigeon/
│
├── scripts/                    # Build & release scripts
│   ├── sdk/ios/
│   ├── sdk/android/
│   └── dev/
│
├── docs/                       # Documentation
└── .github/workflows/          # CI/CD workflows
```

## Distribution Model

```mermaid
graph TB
    DEV[Developer] -->|1. Update VERSION| VERSION[VERSION file]
    DEV -->|2. Commit & Push| GIT[Git Repository]

    GIT -->|3. Push Tags| WORKFLOWS

    subgraph "GitHub Actions"
        WORKFLOWS[Workflows Triggered]

        subgraph "iOS"
            IOS_DEBUG[release-ios-debug.yml]
            IOS_RELEASE[release-ios.yml]
        end

        subgraph "Android"
            ANDROID_DEBUG[release-android-debug.yml]
            ANDROID_RELEASE[release-android.yml]
        end
    end

    WORKFLOWS --> IOS_DEBUG
    WORKFLOWS --> IOS_RELEASE
    WORKFLOWS --> ANDROID_DEBUG
    WORKFLOWS --> ANDROID_RELEASE

    IOS_DEBUG -->|Build| IOS_DEBUG_RELEASE[v0.1.4-ios-debug<br/>Frameworks ZIP]
    IOS_RELEASE -->|Build| IOS_RELEASE_RELEASE[v0.1.4-ios<br/>Frameworks ZIP]
    ANDROID_DEBUG -->|Build| ANDROID_DEBUG_RELEASE[v0.1.4-android-debug<br/>AARs ZIP]
    ANDROID_RELEASE -->|Build| ANDROID_RELEASE_RELEASE[v0.1.4-android<br/>AARs ZIP]

    IOS_DEBUG_RELEASE -->|Download| USERS[End Users]
    IOS_RELEASE_RELEASE -->|Download| USERS
    ANDROID_DEBUG_RELEASE -->|Download| USERS
    ANDROID_RELEASE_RELEASE -->|Download| USERS

    style DEV fill:#FFB6C1
    style WORKFLOWS fill:#87CEEB
    style USERS fill:#90EE90
```

**Distribution Features:**
- ✅ Automated builds via GitHub Actions
- ✅ Separate Debug and Release artifacts
- ✅ No Flutter required for end users
- ✅ Fast installation (~30 seconds vs ~30 minutes)
- ✅ Version-tagged releases

## Next Steps

- **Integration:** See [iOS Integration Guide](../02-Integration/01-iOS-Integration-Guide.md) or [Android Integration Guide](../02-Integration/02-Android-Integration-Guide.md)
- **Architecture:** Learn about [Platform Communication](../03-Architecture/01-Platform-Communication.md) and [Architecture Overview](../03-Architecture/README.md)
- **Build Process:** Check [iOS Build Process](../04-Build-Process/01-iOS-Build.md) and [Android Build Process](../04-Build-Process/02-Android-Build.md)
- **Release Process:** Review [iOS Release](../05-Release-Process/01-iOS-Release.md) and [Android Release](../05-Release-Process/02-Android-Release.md)
- **Technology Stack:** Review [Technology Stack](./02-Technology-Stack.md) for detailed dependency information

