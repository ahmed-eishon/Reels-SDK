# Reels Android Module

This is a self-contained Android module that provides Flutter-based reels functionality for the Room Android app. The module keeps the main codebase clean by encapsulating all Flutter-related implementations.

## Features

- **Flutter Integration**: Complete Flutter add-to-app implementation
- **Clean API**: Simple interface for the main app to use
- **Modular Design**: Self-contained with all dependencies managed internally
- **Sample Activity**: Demo showing different integration methods
- **Platform Communication**: Bidirectional communication between Android and Flutter

## Structure

```
reels_android/
├── build.gradle                           # Module dependencies and configuration
├── proguard-rules.pro                    # ProGuard rules for the module
├── src/main/
│   ├── AndroidManifest.xml               # Module manifest with activities
│   └── java/com/rakuten/room/reels/
│       ├── ReelsModule.kt                 # Public API for main app
│       ├── flutter/                       # Flutter integration classes
│       │   ├── FlutterReelsActivity.kt    # Full-screen Flutter activity
│       │   ├── FlutterReelsFragment.kt    # Flutter fragment for embedding
│       │   ├── FlutterEngineManager.kt    # Engine lifecycle management
│       │   └── FlutterMethodChannelHandler.kt # Platform communication
│       ├── sample/
│       │   └── SampleFlutterIntegrationActivity.kt # Demo activity
│       └── example/
│           └── ReelsIntegrationExample.kt  # Usage examples
```

## Quick Start

### 1. Initialize the Module

In your main app's `Application` class:

```kotlin
class RoomApp : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize the Reels module
        ReelsModule.initialize(this)
    }
    
    override fun onTerminate() {
        super.onTerminate()
        // Clean up resources
        ReelsModule.cleanup()
    }
}
```

### 2. Launch Flutter Reels

```kotlin
// Launch full-screen reels
val intent = ReelsModule.createReelsIntent(this, ReelsModule.Routes.REELS)
startActivity(intent)

// Or use the convenience method
ReelsModule.createReelsIntent(this).also { startActivity(it) }
```

### 3. Embed as Fragment

```kotlin
// Embed reels in existing activity
val fragment = ReelsModule.createReelsFragment(ReelsModule.Routes.PROFILE)
supportFragmentManager
    .beginTransaction()
    .replace(R.id.fragment_container, fragment)
    .commit()
```

### 4. Try the Demo

```kotlin
// Launch demo activity showing all integration methods
val intent = ReelsModule.createSampleIntent(this)
startActivity(intent)
```

## Available Routes

- `ReelsModule.Routes.HOME` - Home screen (default)
- `ReelsModule.Routes.REELS` - Reels listing page
- `ReelsModule.Routes.PROFILE` - User profile page

## API Reference

### ReelsModule

Main entry point for the module with the following methods:

- `initialize(context: Context)` - Initialize the module
- `createReelsIntent(context: Context, initialRoute: String)` - Create intent for full-screen
- `createReelsFragment(initialRoute: String)` - Create fragment for embedding
- `createSampleIntent(context: Context)` - Create intent for demo activity
- `sendDataToFlutter(method: String, data: Any?)` - Send data to Flutter
- `cleanup()` - Clean up resources

## Communication

The module supports bidirectional communication between Android and Flutter:

### Android → Flutter

```kotlin
// Send user data to Flutter
ReelsModule.sendDataToFlutter("updateUserData", mapOf(
    "userId" to "12345",
    "name" to "John Doe"
))

// Trigger refresh in Flutter
ReelsModule.sendDataToFlutter("refreshReels", null)
```

### Flutter → Android

Flutter can call Android methods through platform channels:

- `getUserProfile()` - Get user profile data
- `shareReel(reelId, title)` - Share a reel using native Android sharing
- `openNativeScreen(screenName)` - Navigate to native Android screens

## Integration in Main App

Add the module dependency to your main app's `build.gradle`:

```gradle
dependencies {
    implementation project(':reels_android')
}
```

The module automatically includes all necessary Flutter dependencies, so you don't need to add them separately.

## Development

### Adding New Flutter Screens

1. Modify `reels_flutter/lib/main.dart` to add new routes
2. Update `ReelsModule.Routes` if needed
3. No changes required in Android code

### Extending Platform Communication

1. Add new methods in `FlutterMethodChannelHandler.kt`
2. Implement corresponding Flutter side in `reels_flutter/lib/services/native_channel_service.dart`
3. Update documentation

### Testing

The module includes a comprehensive demo activity that shows:
- Full-screen Flutter integration
- Fragment embedding
- Platform communication examples
- Navigation between different Flutter screens

## Benefits

1. **Clean Separation**: Main app stays clean, all Flutter code isolated
2. **Easy Integration**: Simple API for the main app to use
3. **Reusable**: Module can be easily reused in other projects
4. **Maintainable**: Clear boundaries and responsibilities
5. **Testable**: Module can be tested independently

## Building

The module is automatically built when you build the main project:

```bash
./gradlew assembleDebug
```

The Flutter integration is handled transparently by the build system.