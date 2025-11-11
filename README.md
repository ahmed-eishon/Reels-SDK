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
- CocoaPods (required for Flutter integration)
- Xcode 15.0+

### Android
- Android SDK 21+
- Kotlin 1.9+
- Gradle 8.0+

## Installation

### iOS Integration

**Note:** This SDK is designed for iOS and Android only. It requires Flutter integration via CocoaPods.

#### Option 1: CocoaPods with Git (Recommended for Production)

Add to your `Podfile`:

```ruby
pod 'ReelsSDK', :git => 'https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git', :tag => '1.0.0'
```

Then run:

```bash
pod install
```

#### Option 2: External Folder Import (Recommended for Development)

**Step 1:** Clone the SDK repository and run initialization script:

```bash
cd /path/to/your/workspace
git clone https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git
cd reels-sdk
./scripts/init-ios.sh /path/to/reels-sdk /path/to/your-ios-app
```

The init script will:
- Verify Flutter installation
- Run `flutter pub get` to generate `.ios` platform files
- Check that all required files are present
- Provide step-by-step integration instructions

**Step 2:** Follow the initialization script's output to update your `Podfile`:

```ruby
# Flutter module integration - External folder import
flutter_application_path = '/path/to/reels-sdk/reels_flutter'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'YourApp' do
  # Your existing pods...

  # Install Flutter pods
  install_all_flutter_pods(flutter_application_path)
end

post_install do |installer|
  # Flutter post install
  flutter_post_install(installer)

  # Your existing post_install code...
end
```

**Step 3:** Add reels_ios files to your Xcode project:
- In Xcode, remove any local reels_ios group if it exists
- Right-click project → Add Files → Navigate to: `/path/to/reels-sdk/reels_ios/Sources/ReelsIOS`
- Select 'Create groups' and ensure target is checked

**Step 4:** Run pod install and open workspace:

```bash
cd /path/to/your-ios-app
pod install
open YourApp.xcworkspace
```

**Advantages of External Folder Import:**
- ✅ No Git authentication issues
- ✅ Immediate access to SDK updates during development
- ✅ Easy debugging and code navigation in Xcode
- ✅ Works in corporate environments with firewall restrictions
- ✅ Simpler setup for active development

**Updating SDK Version:**
```bash
cd /path/to/reels-sdk
git pull origin master
git checkout v1.1.0  # Switch to desired version
# Re-run pod install in your iOS project
```

**Important:** If you run `flutter clean` in the reels_flutter module, you must re-run:
```bash
cd /path/to/reels-sdk/reels_flutter
flutter pub get
```

### Android Integration

Choose one of the following integration methods:

#### Option 1: Git Repository (Remote)

**Step 1:** Configure Git Repository in `settings.gradle`:

```gradle
sourceControl {
    gitRepository(uri("https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git")) {
        producesModule("com.rakuten.room:reels-sdk")
    }
}
```

**Step 2:** Add Dependency in `app/build.gradle`:

```gradle
dependencies {
    implementation 'com.rakuten.room:reels-sdk:1.0.0'
}
```

**Note:** Git-based integration requires authentication. In corporate environments, you may encounter authentication issues with Gradle's Git support. If so, use Option 2 below.

#### Option 2: Local Folder Import (Recommended for Development)

**Step 1:** Clone the SDK repository and run initialization script:

```bash
cd /path/to/your/workspace
git clone https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git
cd reels-sdk
./scripts/init-android.sh /path/to/reels-sdk
```

The init script will:
- Verify Flutter installation
- Run `flutter pub get` to generate `.android` platform files
- Check that all required files are present
- Provide step-by-step integration instructions

**Step 2:** Follow the initialization script's output to update `settings.gradle`:

```gradle
rootProject.name = 'your-app'
include ':app'

// Reels SDK - External folder import
include ':reels_android'
project(':reels_android').projectDir = new File('/path/to/reels-sdk/reels_android')

// Flutter module from reels-sdk
setBinding(new Binding([gradle: this]))
evaluate(new File(
  '/path/to/reels-sdk/reels_flutter/.android/include_flutter.groovy'
))
```

**Step 3:** Add dependency in `app/build.gradle`:

```gradle
dependencies {
    implementation project(':reels_android')
}
```

**Step 4:** Sync your Android project:

```bash
./gradlew clean build
```

**Advantages of Local Folder Import:**
- ✅ No Git authentication issues
- ✅ Immediate access to SDK updates during development
- ✅ Easy debugging and code navigation
- ✅ Works in corporate environments with firewall restrictions
- ✅ Simpler setup for multi-module projects

**Updating SDK Version:**
```bash
cd /path/to/reels-sdk
git pull origin master
git checkout v1.1.0  # Switch to desired version
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

### Building with room-ios

For development with the room-ios app, use the automated build scripts to streamline the build process:

#### Quick Start

**Clean Build** (recommended when starting fresh or after major changes):
```bash
cd /path/to/reels-sdk
./scripts/clean-build-room-ios.sh
```

**Incremental Build** (faster for day-to-day development):
```bash
cd /path/to/reels-sdk
./scripts/build-room-ios.sh
```

**Build Flutter Frameworks Only**:
```bash
cd /path/to/reels-sdk
./scripts/build-flutter-frameworks.sh         # Incremental
./scripts/build-flutter-frameworks.sh --clean # Clean build
```

#### Documentation

For detailed information about the build process, common issues, and troubleshooting:
- See [docs/Build-Process.md](docs/Build-Process.md)

The documentation covers:
- Build architecture and dependencies
- Build order (critical!)
- Common issues with solutions
- Development workflow best practices
- Integration points with room-ios
- Performance tips

### Client Initialization Scripts

Before integrating the SDK into your client app, run the appropriate initialization script:

**For iOS:**
```bash
cd /path/to/reels-sdk
./scripts/init-ios.sh /path/to/reels-sdk /path/to/your-ios-app
```

**For Android:**
```bash
cd /path/to/reels-sdk
./scripts/init-android.sh /path/to/reels-sdk
```

These scripts will:
- Check Flutter installation
- Run `flutter pub get` to generate platform-specific files
- Verify all required artifacts are present
- Provide step-by-step integration instructions

### SDK Verification Scripts

Verify iOS SDK integrity:

```bash
./scripts/verify-ios.sh
```

Verify Android SDK integrity:

```bash
./scripts/verify-android.sh
```

These verification scripts check:
- VERSION file
- Module structure (podspec/gradle)
- Source files
- Flutter module
- Pigeon generated files
- Build configurations

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

**iOS - Option 1 (CocoaPods with Git):**
```ruby
# Update Podfile
pod 'ReelsSDK', :git => '...', :tag => '1.1.0'

# Run
pod update ReelsSDK
```

**iOS - Option 2 (External Folder):**
```bash
# Navigate to SDK folder
cd /path/to/reels-sdk

# Pull latest changes and checkout version
git pull origin master
git checkout v1.1.0

# Re-run pod install in your iOS project
cd /path/to/your-ios-app
pod install
```

**Android - Option 1 (Git Repository):**
```gradle
// Update version in build.gradle
implementation 'com.rakuten.room:reels-sdk:1.1.0'

// Sync project
```

**Android - Option 2 (Local Folder):**
```bash
# Navigate to SDK folder
cd /path/to/reels-sdk

# Pull latest changes
git pull origin master

# Checkout desired version
git checkout v1.1.0

# Sync your Android project
# Changes are automatically picked up since it references the folder
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
