# ReelsIOS

A Swift package that provides a clean interface for integrating Flutter reels functionality into the ROOM iOS app.

## Overview

This package encapsulates all the complexity of communicating with the Flutter `reels_flutter` module, providing a simple API for the native iOS app to launch and interact with Flutter screens.

## Features

- **Simple API**: Launch Flutter reels screen with a single line of code
- **Method Channel Bridge**: Handles all communication between native iOS and Flutter
- **Item Data Passing**: Send item information from native to Flutter
- **Callbacks**: Handle Flutter requests to navigate back to native screens

## Usage

### Initialize (Optional)

For better performance, initialize the Flutter engine during app startup:

```swift
import ReelsIOS

// In AppDelegate or app initialization
ReelsCoordinator.initialize()
```

### Open Reels Screen

```swift
import ReelsIOS

// Simple usage
ReelsCoordinator.openReels(from: viewController)

// With item data
ReelsCoordinator.openReels(
    from: viewController,
    itemId: "12345",
    animated: true,
    completion: {
        print("Reels screen presented")
    }
)
```

## Architecture

### Components

1. **ReelsCoordinator**: Main entry point for opening reels screens
2. **ReelsFlutterBridge**: Handles method channel communication with Flutter

### Communication Flow

```
Native iOS (FeedCoordinator)
    ↓
ReelsCoordinator.openReels()
    ↓
ReelsFlutterBridge (setup channels)
    ↓
Flutter (reels_flutter module)
    ↓ (user actions)
ReelsFlutterBridge (handle callbacks)
    ↓
Native iOS (dismiss, navigate, share, etc.)
```

### Method Channels

#### Native → Flutter (`com.rakuten.room.reels/native_to_flutter`)
- `showItem`: Send item data to Flutter

#### Flutter → Native (`com.rakuten.room.reels/flutter_to_native`)
- `closeReels`: Close the reels screen
- `navigateToItemDetail`: Navigate to native item detail
- `shareItem`: Open native share sheet

## Integration

### Add to Xcode Project

1. Open your Xcode project
2. Go to File → Add Packages → Add Local...
3. Select the `reels_ios` directory
4. Add `ReelsIOS` to your target's frameworks

### Add Flutter Module

The `reels_flutter` Flutter module must be integrated via CocoaPods. See the main Podfile for configuration.

## Development

### Requirements

- iOS 16.0+
- Swift 5.9+
- Flutter 3.9.2+

### Testing

Run unit tests:
```bash
swift test
```

## Future Enhancements

- [ ] Add Pigeon for type-safe communication
- [ ] Support for video playback
- [ ] Analytics integration
- [ ] Deep linking support
