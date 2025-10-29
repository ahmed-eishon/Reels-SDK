# reels_flutter

A Flutter module that provides the core reels UI and functionality for the Reels SDK. This module is integrated into native iOS and Android apps using Flutter's add-to-app approach.

## Overview

This is a Flutter module (not a standalone app) designed to be embedded in native iOS and Android applications. It provides a vertical swipeable video reels experience with engagement features like likes, shares, and comments.

## Features

- 🎥 **Vertical Video Player**: Swipeable video reels interface
- 💙 **Engagement**: Like, share, and comment functionality
- 📊 **Analytics**: Built-in event tracking
- 🔐 **Authentication**: Access token integration with native apps
- 🎨 **Clean Architecture**: Domain-driven design with clear separation of concerns
- 🔄 **State Management**: Provider-based state management
- 🎯 **Type-Safe Communication**: Pigeon-generated platform channels

## Architecture

### Clean Architecture Layers

```
lib/
├── main.dart                       # Entry point
├── core/
│   ├── pigeon_generated.dart      # Type-safe platform channels
│   ├── di/                        # Dependency injection
│   ├── platform/                  # Platform initialization
│   └── services/                  # Core services
│       ├── access_token_service.dart
│       ├── analytics_service.dart
│       ├── button_events_service.dart
│       ├── navigation_events_service.dart
│       └── state_events_service.dart
├── domain/
│   ├── entities/                  # Business logic models
│   ├── repositories/              # Repository interfaces
│   └── usecases/                  # Business logic use cases
├── data/
│   ├── models/                    # Data transfer objects
│   ├── datasources/               # Data sources (local, remote)
│   └── repositories/              # Repository implementations
└── presentation/
    ├── providers/                 # State management
    ├── screens/                   # UI screens
    └── widgets/                   # Reusable widgets
```

### Key Components

**Core Services:**
- `AccessTokenService`: Manages authentication tokens from native apps
- `AnalyticsService`: Tracks user events and sends to native apps
- `ButtonEventsService`: Handles button interactions (like, share)
- `NavigationEventsService`: Manages screen navigation
- `StateEventsService`: Tracks screen and video state changes

**Domain Layer:**
- `VideoEntity`: Core video model
- `ProductEntity`: Product information for shopping features
- `UserEntity`: User profile data
- `VideoRepository`: Interface for video data access
- Use cases: `GetVideosUseCase`, `GetVideoByIdUseCase`, `ToggleLikeUsecase`, etc.

**Presentation Layer:**
- `VideoProvider`: Main state management for video list
- `ReelsScreen`: Full-screen vertical video feed
- `VideoListScreen`: Alternative list view
- `VideoReelItem`: Individual video player component
- `EngagementButtons`: Like, comment, share buttons
- `VideoDescription`: Video info and product details

## Platform Communication

### Pigeon-Generated Channels

The module uses Pigeon for type-safe communication with native platforms:

**Flutter → Native (Host API):**
```dart
// Request access token from native app
String? token = await accessTokenService.getAccessToken();
```

**Native → Flutter (Flutter API):**
```dart
// Receive analytics events
void trackEvent(String eventName, Map<String, String> properties);

// Receive button interactions
void onLikeButtonClick(String videoId, bool isLiked, int likeCount);
void onShareButtonClick(ShareData shareData);

// Receive state changes
void onScreenStateChanged(String screenName, String state);
void onVideoStateChanged(String videoId, String state, int position);
```

### Pigeon Configuration

See `pigeons/messages.dart` for the complete Pigeon API definition.

To regenerate platform code:

```bash
flutter pub run pigeon --input pigeons/messages.dart
```

This generates:
- `lib/core/pigeon_generated.dart` (Flutter)
- `../reels_ios/Sources/ReelsIOS/PigeonGenerated.swift` (iOS)
- `../reels_android/.../PigeonGenerated.kt` (Android)

## Integration

This module is not meant to be run standalone. It's integrated into native apps:

### iOS Integration

See [reels_ios README](../reels_ios/README.md) for iOS integration.

### Android Integration

See [reels_android README](../reels_android/README.md) for Android integration.

## Development

### Requirements

- Flutter SDK 3.9.2+
- Dart 3.0+

### Setup

```bash
# Install dependencies
flutter pub get

# Run code generation (if needed)
flutter pub run build_runner build

# Regenerate Pigeon code (if platform APIs changed)
flutter pub run pigeon --input pigeons/messages.dart
```

### Testing

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage
```

### Mock Data

The module includes mock video data in `assets/mock_videos.json` for development and testing.

## State Management

Uses Provider for state management:

```dart
// VideoProvider manages video list state
class VideoProvider extends ChangeNotifier {
  List<VideoEntity> videos = [];
  int currentVideoIndex = 0;

  Future<void> loadVideos() async { ... }
  void toggleLike(String videoId) { ... }
  void shareVideo(VideoEntity video) { ... }
}
```

## Dependencies

Key dependencies:
- `video_player`: Video playback
- `provider`: State management
- `get_it`: Dependency injection
- `pigeon`: Type-safe platform channels

See `pubspec.yaml` for complete dependency list.

## Platform Support

This module is designed for **iOS and Android only**. It does not support web, desktop, or other platforms.

## Contributing

When adding new features:

1. Follow Clean Architecture principles
2. Add domain entities and use cases first
3. Implement data layer (repositories, data sources)
4. Build presentation layer (providers, screens, widgets)
5. Update Pigeon definitions if adding platform communication
6. Write unit tests for business logic
7. Update documentation

### Adding Platform Communication

1. Update `pigeons/messages.dart` with new APIs
2. Run `flutter pub run pigeon --input pigeons/messages.dart`
3. Implement handlers in `core/services/`
4. Update native platform code to call new APIs
5. Document in both Flutter and native READMEs

## Architecture Benefits

- **Testability**: Business logic isolated in domain layer
- **Maintainability**: Clear separation of concerns
- **Scalability**: Easy to add new features
- **Type Safety**: Pigeon ensures compile-time safety across platforms
- **Flexibility**: Can swap data sources without affecting business logic

## License

Proprietary - Copyright Rakuten
