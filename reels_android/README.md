# Reels Android Module

A self-contained Android module that provides Flutter-based reels functionality with type-safe Pigeon communication.

## Overview

This module encapsulates all Flutter-related implementations, providing a clean API for integrating reels functionality into Android applications. It uses Pigeon for type-safe platform channel communication.

## Features

- **Flutter Integration**: Complete Flutter add-to-app implementation
- **Type-Safe Communication**: Uses Pigeon for compile-time safety
- **Clean API**: Simple interface via `ReelsModule`
- **Event Listener**: Receive callbacks for likes, shares, and analytics
- **Access Token Provider**: Supply authentication tokens dynamically
- **Flexible Presentation**: Full-screen activity or embedded fragment

## Structure

```
reels_android/
├── build.gradle                           # Module dependencies and configuration
├── proguard-rules.pro                    # ProGuard rules
└── src/main/
    ├── AndroidManifest.xml               # Module manifest
    └── java/com/rakuten/room/reels/
        ├── ReelsModule.kt                 # Public API
        ├── flutter/
        │   ├── FlutterReelsActivity.kt    # Full-screen Flutter activity
        │   ├── FlutterReelsFragment.kt    # Flutter fragment for embedding
        │   ├── FlutterEngineManager.kt    # Engine lifecycle management
        │   ├── ReelsFlutterSDK.kt         # SDK entry point
        │   └── ReelsListener.kt           # Event listener interface
        └── pigeon/
            └── PigeonGenerated.kt         # Auto-generated type-safe communication
```

## Quick Start

### 1. Initialize the Module

In your `Application` class:

```kotlin
import com.rakuten.room.reels.ReelsModule

class YourApp : Application() {
    override fun onCreate() {
        super.onCreate()

        // Initialize with access token provider
        ReelsModule.initialize(this, accessTokenProvider = {
            UserSession.instance.accessToken
        })
    }
}
```

### 2. Launch Flutter Reels

**Option 1: Full-Screen Activity**

```kotlin
// Launch reels screen
val intent = ReelsModule.createReelsIntent(this)
startActivity(intent)

// Or with custom route
val intent = ReelsModule.createReelsIntent(this, initialRoute = "/reels")
startActivity(intent)
```

**Option 2: Embedded Fragment**

```kotlin
// Embed reels in existing activity
val fragment = ReelsModule.createReelsFragment(initialRoute = "/")
supportFragmentManager
    .beginTransaction()
    .replace(R.id.fragment_container, fragment)
    .commit()
```

### 3. Set Event Listener

Implement `ReelsListener` to receive events:

```kotlin
import com.rakuten.room.reels.flutter.ReelsListener

class MainActivity : AppCompatActivity(), ReelsListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ReelsModule.setListener(this)
    }

    override fun onLikeButtonClick(videoId: String, isLiked: Boolean, likeCount: Long) {
        Log.d("Reels", "Video $videoId liked: $isLiked, count: $likeCount")
        // Update your backend
    }

    override fun onShareButtonClick(shareData: ShareData) {
        // Present native share dialog
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, "${shareData.title}\n${shareData.videoUrl}")
        }
        startActivity(Intent.createChooser(shareIntent, "Share Video"))
    }

    override fun onAnalyticsEvent(eventName: String, properties: Map<String, String>) {
        // Track with your analytics service
        Analytics.track(eventName, properties)
    }
}
```

## Architecture

### Components

1. **ReelsModule**: Main entry point with simple API
2. **FlutterEngineManager**: Manages Flutter engine lifecycle
3. **FlutterReelsActivity**: Full-screen Flutter presentation
4. **FlutterReelsFragment**: Embeddable Flutter fragment
5. **ReelsFlutterSDK**: Internal SDK coordinator
6. **PigeonGenerated.kt**: Auto-generated type-safe communication
7. **ReelsListener**: Interface for receiving events from Flutter

### Communication Flow

```
Android App
    ↓
ReelsModule
    ↓
FlutterEngineManager
    ↓
Pigeon (type-safe channels)
    ↓
Flutter (reels_flutter module)
    ↓ (user interactions)
Pigeon → ReelsListener
    ↓
Android App (handle callbacks)
```

### Pigeon Communication

The module uses [Pigeon](https://pub.dev/packages/pigeon) for type-safe platform channels:

#### Flutter → Android (Host API)
- `getAccessToken()` - Request user authentication token

#### Android → Flutter (Flutter API)
- `onLikeButtonClick()` - Notify like interactions
- `onShareButtonClick()` - Notify share interactions
- `onAnalyticsEvent()` - Send analytics events
- `onScreenStateChanged()` - Track screen lifecycle
- `onVideoStateChanged()` - Track video playback state

## API Reference

### ReelsModule

```kotlin
// Initialize
fun initialize(
    context: Context,
    accessTokenProvider: (() -> String?)? = null
)

// Create full-screen intent
fun createReelsIntent(
    context: Context,
    initialRoute: String = "/",
    accessToken: String? = null
): Intent

// Create fragment
fun createReelsFragment(initialRoute: String = "/"): Fragment

// Set event listener
fun setListener(listener: ReelsListener?)

// Track analytics
fun trackEvent(eventName: String, properties: Map<String, String> = emptyMap())

// Cleanup
fun cleanup()
```

### ReelsListener Interface

```kotlin
interface ReelsListener {
    fun onLikeButtonClick(videoId: String, isLiked: Boolean, likeCount: Long)
    fun onShareButtonClick(shareData: ShareData)
    fun onAnalyticsEvent(eventName: String, properties: Map<String, String>)
}

data class ShareData(
    val videoId: String,
    val videoUrl: String,
    val title: String,
    val description: String,
    val thumbnailUrl: String?
)
```

## Integration in Main App

### Add Module Dependency

**Option 1: Git Repository**

See main [README.md](../README.md) for Git-based integration.

**Option 2: Local Folder Import (Recommended for Development)**

In `settings.gradle`:

```gradle
include ':reels_android'
project(':reels_android').projectDir = new File('/path/to/reels-sdk/reels_android')

// Flutter module from reels-sdk
setBinding(new Binding([gradle: this]))
evaluate(new File('/path/to/reels-sdk/reels_flutter/.android/include_flutter.groovy'))
```

In `app/build.gradle`:

```gradle
dependencies {
    implementation project(':reels_android')
}
```

Then run initialization script:

```bash
cd /path/to/reels-sdk
./scripts/init-android.sh /path/to/reels-sdk
```

## Development

### Requirements

- Android SDK 21+
- Kotlin 1.9+
- Gradle 8.0+
- Flutter 3.9.2+

### Regenerating Pigeon Code

When modifying platform communication APIs:

```bash
cd reels_flutter
flutter pub run pigeon --input pigeons/messages.dart
```

This regenerates `PigeonGenerated.kt` with type-safe communication code.

### Building

The module is automatically built when you build the main project:

```bash
./gradlew assembleDebug
```

The Flutter integration is handled transparently by the build system.

## Platform Support

This SDK is designed for **iOS and Android only** (not desktop, web, or other platforms).

## Benefits

1. **Clean Separation**: Main app stays clean, all Flutter code isolated
2. **Type Safety**: Compile-time safety with Pigeon-generated code
3. **Easy Integration**: Simple API for the main app
4. **Reusable**: Module can be easily reused in other projects
5. **Maintainable**: Clear boundaries and responsibilities
6. **Testable**: Module can be tested independently
