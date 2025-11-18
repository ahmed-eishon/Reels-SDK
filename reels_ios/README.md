# ReelsIOS

A Swift module that provides a clean interface for integrating Flutter reels functionality into iOS applications.

## Overview

This module encapsulates all the complexity of communicating with the Flutter `reels_flutter` module, providing a simple API for native iOS apps to launch and interact with reels screens using type-safe Pigeon-generated communication.

## Features

- **Simple API**: Launch Flutter reels screen with a single method call
- **Type-Safe Communication**: Uses Pigeon for compile-time safety
- **Dual Interface**: Both `ReelsModule` (full-featured) and `ReelsCoordinator` (convenience wrapper)
- **Event Listener**: Receive callbacks for likes, shares, and analytics
- **Access Token Provider**: Supply authentication tokens dynamically

## Usage

### Initialize

Initialize the module once during app startup for better performance:

```swift
import ReelsIOS

// In AppDelegate or app initialization with async access token provider
ReelsModule.initialize(accessTokenProvider: { completion in
    // Call your async token provider
    loginManager.getRoomAccessToken { token in
        completion(token)
    }
})

// Or if you have a synchronous token
ReelsModule.initialize(accessTokenProvider: { completion in
    completion(UserSession.shared.accessToken)
})
```

### Open Reels Screen

**Option 1: Using ReelsCoordinator (Recommended - Simpler API)**

```swift
import ReelsIOS

// Simple usage
ReelsCoordinator.openReels(from: viewController)

// With item ID
ReelsCoordinator.openReels(
    from: viewController,
    itemId: "12345",
    animated: true,
    completion: {
        print("Reels screen presented")
    }
)
```

**Option 2: Using ReelsModule or ReelsCoordinator with Collect Data**

```swift
import ReelsIOS

// Open reels without collect context (browse mode)
ReelsModule.openReels(from: viewController)

// Open reels WITH collect context (from a collect/item detail screen)
// This passes the collect data to Flutter for display in SDK Info screen
let collectData: [String: Any?] = [
    "id": collect.id,
    "name": collect.name,
    "content": collect.content,
    "likes": Int64(collect.likeCount),
    "comments": Int64(collect.commentCount),
    "userName": collect.user?.name,
    "userProfileImage": collect.user?.profileImageUrl
]

ReelsModule.openReels(
    from: viewController,
    initialRoute: "/",
    collectData: collectData,
    animated: true,
    completion: {
        print("Reels opened with collect context")
    }
)

// Using ReelsCoordinator (simpler)
ReelsCoordinator.openReels(
    from: viewController,
    itemId: "12345",
    collectData: collectData
)

// Or create a view controller for custom presentation
let flutterVC = ReelsModule.createViewController(initialRoute: "/")
navigationController?.pushViewController(flutterVC, animated: true)
```

**Collect Data Fields**:
The `collectData` dictionary can include any of these optional fields:
- `id` (String) - Collect ID
- `name` (String) - Collect name/title
- `content` (String) - Collect description
- `likes` (Int64) - Like count
- `comments` (Int64) - Comment count
- `recollects` (Int64) - Recollect count
- `isLiked` (Bool) - Whether current user has liked
- `isCollected` (Bool) - Whether current user has collected
- `trackingTag` (String) - Analytics tracking tag
- `userName` (String) - Collect author name
- `userProfileImage` (String) - Collect author profile image URL
- `itemName` (String) - Associated item name
- `itemImageUrl` (String) - Associated item image URL
- `imageUrl` (String) - Collect cover image URL

### Set Event Listener

Implement `ReelsListener` to receive events from Flutter:

```swift
import ReelsIOS

class YourViewController: UIViewController, ReelsListener {

    override func viewDidLoad() {
        super.viewDidLoad()
        ReelsCoordinator.setListener(self)
    }

    func onLikeButtonClick(videoId: String, isLiked: Bool, likeCount: Int64) {
        print("Video \(videoId) liked: \(isLiked), count: \(likeCount)")
        // Update your backend
    }

    func onShareButtonClick(
        videoId: String,
        videoUrl: String,
        title: String,
        description: String,
        thumbnailUrl: String?
    ) {
        // Present native share sheet
        let activityVC = UIActivityViewController(
            activityItems: [title, URL(string: videoUrl)!],
            applicationActivities: nil
        )
        present(activityVC, animated: true)
    }

    func onAnalyticsEvent(eventName: String, properties: [String: String]) {
        // Track with your analytics service
        Analytics.track(eventName, properties: properties)
    }
}
```

## Architecture

### Components

1. **ReelsModule**: Full-featured API for reels functionality
2. **ReelsCoordinator**: Convenience wrapper around ReelsModule
3. **ReelsEngineManager**: Manages Flutter engine lifecycle
4. **ReelsPigeonHandler**: Handles Pigeon-generated platform communication
5. **PigeonGenerated.swift**: Auto-generated type-safe communication layer
6. **ReelsListener**: Protocol for receiving events from Flutter

### Communication Flow

```
Native iOS App
    ↓
ReelsCoordinator / ReelsModule
    ↓
ReelsEngineManager (Flutter engine)
    ↓
ReelsPigeonHandler (Pigeon)
    ↓
Flutter (reels_flutter module)
    ↓ (user interactions)
ReelsPigeonHandler → ReelsListener
    ↓
Native iOS App (handle callbacks)
```

### Pigeon Communication

The module uses [Pigeon](https://pub.dev/packages/pigeon) for type-safe platform channels:

#### Flutter → Native (Host API)
- `getAccessToken()` - Request user authentication token (async)
- `getInitialCollect()` - Get the collect context that was used to open the screen

#### Native → Flutter (Flutter API)
- `onLikeButtonClick()` - Notify like interactions
- `onShareButtonClick()` - Notify share interactions
- `onAnalyticsEvent()` - Send analytics events
- `onScreenStateChanged()` - Track screen lifecycle
- `onVideoStateChanged()` - Track video playback state

**Important**: Always use the Pigeon-generated API classes (`ReelsFlutterTokenApi`, `ReelsFlutterContextApi`) instead of manually creating `BasicMessageChannel` instances. The Pigeon-generated classes use the correct codec (`_PigeonCodec`) which ensures proper serialization of complex data types like `CollectData`.

## Integration

### Using CocoaPods from GitHub (Recommended for Production)

```ruby
# In your Podfile
target 'YourApp' do
  use_frameworks!

  # ReelsSDK with automatic Debug/Release framework selection
  pod 'ReelsSDK',
      :git => 'https://github.com/ahmed-eishon/Reels-SDK.git',
      :tag => 'v0.1.4-ios'
end
```

Then run `pod install`. The SDK will:
1. Download pre-built frameworks from GitHub release
2. Install both Debug and Release frameworks (with `_Debug` and `_Release` suffixes)
3. Automatically select the correct variant based on your build configuration
4. No Flutter installation required!

See the main [README.md](../README.md) for additional integration methods including local folder import for development.

### Using Xcode Directly

For external folder import during development:

1. Run the initialization script:
   ```bash
   cd /path/to/reels-sdk
   ./scripts/init-ios.sh /path/to/reels-sdk /path/to/your-ios-app
   ```

2. In Xcode, add files from external location:
   - Right-click project → Add Files
   - Navigate to: `/path/to/reels-sdk/reels_ios/Sources/ReelsIOS`
   - Select 'Create groups' and ensure target is checked

3. Update your Podfile to include Flutter (see init script output)

4. Run `pod install`

## API Reference

### ReelsCoordinator

Simple wrapper for common use cases:

```swift
// Initialize with async access token provider
static func initialize(accessTokenProvider: ((@escaping (String?) -> Void) -> Void)?)

// Open reels with optional collect data
static func openReels(
    from: UIViewController,
    itemId: String?,
    collectData: [String: Any?]?,
    animated: Bool,
    completion: (() -> Void)?
)

// Set listener
static func setListener(_ listener: ReelsListener?)

// Cleanup
static func cleanup()
```

### ReelsModule

Full-featured API:

```swift
// Initialize with async access token provider
static func initialize(accessTokenProvider: ((@escaping (String?) -> Void) -> Void)?)

// Open reels with optional collect data
static func openReels(
    from: UIViewController,
    initialRoute: String,
    collectData: [String: Any?]?,
    animated: Bool,
    completion: (() -> Void)?
)

// Create view controller
static func createViewController(initialRoute: String) -> FlutterViewController

// Set listener
static func setListener(_ listener: ReelsListener?)

// Track analytics
static func trackEvent(eventName: String, properties: [String: String])

// Cleanup
static func cleanup()

// Available routes
enum Routes {
    static let home = "/"
    static let reels = "/reels"
    static let profile = "/profile"
}
```

### ReelsListener Protocol

```swift
protocol ReelsListener: AnyObject {
    func onLikeButtonClick(videoId: String, isLiked: Bool, likeCount: Int64)
    func onShareButtonClick(
        videoId: String,
        videoUrl: String,
        title: String,
        description: String,
        thumbnailUrl: String?
    )
    func onAnalyticsEvent(eventName: String, properties: [String: String])
}
```

## Development

### Requirements

- iOS 16.0+
- Swift 5.9+
- Flutter 3.9.2+
- CocoaPods (for Flutter integration)

### Building with room-ios

For development with the room-ios app, automated build scripts are available to streamline the build process:

**Quick Start:**

```bash
# Clean build (recommended when starting fresh)
cd /path/to/reels-sdk
./scripts/clean-build-room-ios.sh

# Incremental build (faster for day-to-day development)
./scripts/build-room-ios.sh

# Build only Flutter frameworks
./scripts/build-flutter-frameworks.sh         # Incremental
./scripts/build-flutter-frameworks.sh --clean # Clean build
```

**Detailed Documentation:**

For comprehensive information about the build process, troubleshooting, and common issues, see [docs/Build-Process.md](../docs/Build-Process.md).

The build documentation covers:
- Build architecture and critical dependencies
- Common issues (video playback, debug menu, plugin registration)
- Development workflow best practices
- Integration points with room-ios
- Troubleshooting checklist

**Important Notes:**
- Flutter frameworks must be built BEFORE building room-ios
- Always register Flutter plugins in RRAppDelegate after ReelsModule initialization
- Use clean build when encountering unexplainable build errors

### Regenerating Pigeon Code

When modifying platform communication APIs:

```bash
cd reels_flutter
flutter pub run pigeon --input pigeons/messages.dart
```

This regenerates `PigeonGenerated.swift` with type-safe communication code.

### Testing

The module is designed to be integrated via CocoaPods or external folder import. Standalone Swift builds are not supported for Flutter modules.

## Platform Support

This SDK is designed for **iOS and Android only** (not macOS, web, or other platforms).
