# Reels SDK

A multi-platform SDK for integrating video reels functionality into iOS and Android applications using Flutter.

## Features

- 🎥 **Video Reels Player** - Vertical swipeable video experience
- 📱 **Native Integration** - Seamless iOS (Swift) and Android (Kotlin) bridges
- 🔄 **Type-Safe Communication** - Pigeon-generated platform channels
- 💙 **Engagement Features** - Like, share, and comment functionality
- 📊 **Analytics Tracking** - Built-in event tracking support
- 🎨 **Clean Architecture** - Maintainable and testable codebase
- 🔐 **Private Distribution** - Git-based, secure access

## Requirements

### iOS
- iOS 16.0+
- Swift 5.9+
- CocoaPods or Swift Package Manager
- Xcode 15.0+

### Android
- Android SDK 21+
- Kotlin 1.9+
- Gradle 8.0+

## Installation

### iOS Integration

#### Option 1: CocoaPods (Recommended)

Add to your `Podfile`:

```ruby
pod 'ReelsSDK', :git => 'https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git', :tag => '1.0.0'
```

Then run:

```bash
pod install
```

#### Option 2: Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git", from: "1.0.0")
]
```

### Android Integration

#### Step 1: Configure Git Repository

Add to your `settings.gradle`:

```gradle
sourceControl {
    gitRepository(uri("https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git")) {
        producesModule("com.rakuten.room:reels-sdk")
    }
}
```

#### Step 2: Add Dependency

Add to your `app/build.gradle`:

```gradle
dependencies {
    implementation 'com.rakuten.room:reels-sdk:1.0.0'
}
```

## Usage

### iOS

```swift
import ReelsIOS

// Initialize SDK
ReelsCoordinator.initialize(accessTokenProvider: {
    return "your-access-token"
})

// Set up event listener
ReelsCoordinator.setListener(self)

// Open reels screen
ReelsCoordinator.openReels(
    from: navigationController,
    itemId: "video123",
    animated: true
)

// Implement ReelsListener protocol
extension YourViewController: ReelsListener {
    func onLikeButtonClick(videoId: String, isLiked: Bool, likeCount: Int) {
        print("Video \(videoId) liked: \(isLiked)")
    }

    func onShareButtonClick(videoId: String, videoUrl: String, title: String, description: String, thumbnailUrl: String?) {
        // Handle share action
    }

    func onAnalyticsEvent(eventName: String, properties: [String: String]) {
        // Track analytics
    }
}
```

### Android

```kotlin
import com.rakuten.room.reels.ReelsModule

// Initialize SDK
ReelsModule.initialize(
    accessTokenProvider = { "your-access-token" }
)

// Set up event listener
ReelsModule.setListener(object : ReelsListener {
    override fun onLikeButtonClick(videoId: String, isLiked: Boolean, likeCount: Int) {
        Log.d("Reels", "Video $videoId liked: $isLiked")
    }

    override fun onShareButtonClick(shareData: ShareData) {
        // Handle share action
    }

    override fun onAnalyticsEvent(eventName: String, properties: Map<String, String>) {
        // Track analytics
    }
})

// Open reels screen
ReelsModule.openReels(
    context = this,
    itemId = "video123"
)
```

## Architecture

```
reels-sdk/
├── reels_ios/          # iOS Swift bridge
│   └── Sources/
│       └── ReelsIOS/
│           ├── ReelsCoordinator.swift      # Public API
│           ├── ReelsModule.swift           # Core logic
│           ├── ReelsEngineManager.swift    # Flutter engine
│           └── PigeonGenerated.swift       # Type-safe channels
│
├── reels_android/      # Android Kotlin bridge
│   └── src/main/
│       └── java/com/rakuten/room/reels/
│           ├── ReelsModule.kt              # Public API
│           ├── flutter/                    # Flutter integration
│           └── pigeon/
│               └── PigeonGenerated.kt      # Type-safe channels
│
└── reels_flutter/      # Shared Flutter module
    └── lib/
        ├── presentation/   # UI layer
        ├── domain/         # Business logic
        ├── data/           # Data sources
        └── core/
            └── pigeon_generated.dart       # Platform interface
```

## Development

### Prerequisites

- Flutter SDK 3.9.2+
- iOS: Xcode 15.0+, CocoaPods
- Android: Android Studio, JDK 17

### Running Verification

Verify iOS SDK integrity:

```bash
./scripts/verify-ios.sh
```

Verify Android SDK integrity:

```bash
./scripts/verify-android.sh
```

### Regenerating Pigeon Code

When modifying platform communication APIs:

```bash
cd reels_flutter
flutter pub run pigeon --input pigeons/messages.dart
```

This generates:
- `lib/core/pigeon_generated.dart` (Flutter)
- `../reels_ios/Sources/ReelsIOS/PigeonGenerated.swift` (iOS)
- `../reels_android/.../PigeonGenerated.kt` (Android)

## Versioning

The SDK follows [Semantic Versioning](https://semver.org/):

- **Major**: Breaking API changes
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, backward compatible

Current version: **1.0.0**

## Platform Communication

The SDK uses [Pigeon](https://pub.dev/packages/pigeon) for type-safe platform channels:

### Flutter → Native (Host API)
- `getAccessToken()` - Retrieve user authentication token

### Native → Flutter (Flutter API)
- `trackEvent()` - Send analytics events
- `onLikeButtonClick()` - Notify like interactions
- `onShareButtonClick()` - Notify share interactions
- `onScreenStateChanged()` - Track screen state
- `onVideoStateChanged()` - Track playback state

## Distribution

### Git Tags

Each release is tagged with a version:

```bash
git tag -l
# v1.0.0
# v1.1.0
# etc.
```

### Updating to New Versions

**iOS (CocoaPods):**
```ruby
# Update Podfile
pod 'ReelsSDK', :git => '...', :tag => '1.1.0'

# Run
pod update ReelsSDK
```

**Android (Gradle):**
```gradle
// Update version in build.gradle
implementation 'com.rakuten.room:reels-sdk:1.1.0'

// Sync project
```

## Size Impact

- **iOS**: ~300 KB (Swift bridge + Flutter source)
- **Android**: ~370 KB (Kotlin bridge + Flutter source)

Build artifacts (`.dart_tool`, etc.) are automatically excluded.

## License

Proprietary - Copyright Rakuten

## Support

For issues and questions:
- **Internal**: Contact ROOM Team at room-team@rakuten.com
- **Git**: https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

Made with ❤️ by Rakuten ROOM Team
