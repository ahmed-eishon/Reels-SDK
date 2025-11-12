# Quick Start Guide for AI Agents

This guide helps AI assistants quickly understand the reels-sdk project structure, key components, and recent changes.

## Project Overview

**reels-sdk** is a multi-platform SDK for integrating video reels functionality into iOS and Android applications using Flutter.

- **Type**: Flutter module with native iOS (Swift) and Android (Kotlin) bridges
- **Architecture**: Add-to-App pattern (Flutter embedded in native apps)
- **Communication**: Type-safe platform channels using Pigeon
- **Primary Use Case**: Integration with room-ios app for development/testing

## Key Directories

```
reels-sdk/
├── reels_flutter/              # Flutter module (shared UI/business logic)
│   ├── lib/
│   │   ├── presentation/       # UI layer (screens, widgets, providers)
│   │   ├── domain/             # Business logic (entities, repositories)
│   │   ├── data/               # Data layer (models, data sources)
│   │   └── core/
│   │       ├── pigeon_generated.dart    # Auto-generated platform comm
│   │       └── services/       # Core services (navigation, context)
│   ├── pigeons/
│   │   └── messages.dart       # Pigeon API definitions
│   └── .ios/Flutter/           # Built Flutter frameworks (generated)
│
├── reels_ios/                  # iOS Swift bridge
│   ├── Sources/ReelsIOS/
│   │   ├── ReelsModule.swift          # Main public API
│   │   ├── ReelsEngineManager.swift   # Flutter engine lifecycle
│   │   ├── ReelsPigeonHandler.swift   # Platform communication
│   │   └── PigeonGenerated.swift      # Auto-generated from Pigeon
│   └── ReelsIOS.podspec        # CocoaPods spec
│
├── reels_android/              # Android Kotlin bridge
│   └── src/main/java/com/rakuten/room/reels/
│       ├── ReelsModule.kt
│       └── pigeon/PigeonGenerated.kt
│
├── scripts/                    # Build automation scripts
│   ├── build-flutter-frameworks.sh    # Build Flutter frameworks
│   ├── build-room-ios.sh              # Incremental room-ios build
│   └── clean-build-room-ios.sh        # Full clean build
│
└── docs/                       # Documentation
    ├── Build-Process.md        # Comprehensive build documentation
    └── Quick-Start-Guide-AI-Agent.md  # This file
```

## External Dependencies

**room-ios** (test/integration app):
- Location: `/Users/ahmed.eishon/Rakuten/room-ios/ROOM/`
- Integration point: References reels-sdk via CocoaPods (external folder import)
- Key files:
  - `ROOM/Podfile` - Includes Flutter pods and ReelsIOS module
  - `ROOM/Source/App/RRAppDelegate.swift` - Initializes ReelsModule, registers plugins
  - `ROOM/Source/Feed/FeedFollowing/Item/FeedItemCollectionViewController.swift` - Opens reels on collect tap

## Critical Files and Recent Changes

### 1. Platform Communication (Pigeon)

**File**: `reels_flutter/pigeons/messages.dart`
- Defines type-safe APIs between Flutter ↔ Native
- Recent additions:
  - `isDebugMode()` - Returns debug flag state
  - `getInitialCollect()` - Gets collect context (if any)

**Regenerate Pigeon code**:
```bash
cd reels_flutter
flutter pub run pigeon --input pigeons/messages.dart
```

Generates:
- `reels_flutter/lib/core/pigeon_generated.dart`
- `reels_ios/Sources/ReelsIOS/PigeonGenerated.swift`
- `reels_android/.../PigeonGenerated.kt`

### 2. iOS Bridge - ReelsModule.swift

**Location**: `reels_ios/Sources/ReelsIOS/ReelsModule.swift`

**Key Changes**:
- **Line 37-38**: Added `debugMode` flag
- **Line 46-52**: Initialize method accepts `debug` parameter
- **Line 140-143**: Added `isDebugMode()` method
- **Line 145-148**: Added `getEngine()` public method for plugin registration

**Critical**: The `getEngine()` method was added to expose the Flutter engine for plugin registration in the host app.

### 3. Flutter - Debug Menu Implementation

**File**: `reels_flutter/lib/presentation/widgets/engagement_buttons.dart`

**Lines 318-348**: Debug menu (3-dot menu)
- Only shows when `CollectContextService.isDebugMode() == true`
- Opens SDK info screen on tap

**File**: `reels_flutter/lib/presentation/screens/sdk_info_screen.dart`
- Shows SDK version, platform info, collect context, etc.

### 4. Plugin Registration Fix

**Problem**: Video playback not working after Flutter integration

**Root Cause**: `GeneratedPluginRegistrant.register()` wasn't being called

**Solution** (in room-ios):

**File**: `/Users/ahmed.eishon/Rakuten/room-ios/ROOM/ROOM/Source/App/RRAppDelegate.swift`

```swift
// Lines 8-17: Imports
import FlutterPluginRegistrant

// Lines 155-170: In didFinishLaunchingWithOptions
ReelsModule.initialize(
    accessTokenProvider: { completion in
        completion("test_access_token")  // TODO: Get real token
    },
    debug: true
)

// Register Flutter plugins (CRITICAL for video playback)
if let flutterEngine = ReelsModule.getEngine() {
    GeneratedPluginRegistrant.register(with: flutterEngine)
    print("[ROOM] Flutter plugins registered for ReelsModule")
}
```

## Build Process

### Quick Commands

```bash
cd /Users/ahmed.eishon/Rakuten/reels-sdk

# Clean build (recommended when starting fresh or after major changes)
./scripts/clean-build-room-ios.sh

# Incremental build (faster for day-to-day development)
./scripts/build-room-ios.sh

# Build only Flutter frameworks
./scripts/build-flutter-frameworks.sh         # Incremental
./scripts/build-flutter-frameworks.sh --clean # Clean
```

### Build Order (CRITICAL!)

Flutter frameworks MUST be built BEFORE room-ios:

1. **Flutter Frameworks** → `reels_flutter/.ios/Flutter/`
2. **CocoaPods** → `pod install` in room-ios
3. **Xcode Build** → room-ios app

**Why**: room-ios Podfile references Flutter frameworks. If frameworks don't exist or are stale, build fails.

### Common Issues

See [Build-Process.md](Build-Process.md) for detailed troubleshooting. Quick fixes:

1. **Video not playing**: Check plugin registration in RRAppDelegate
2. **Debug menu missing**: Verify `debug: true` in ReelsModule.initialize()
3. **"FlutterPluginRegistrant not found"**: Run `./scripts/build-flutter-frameworks.sh --clean`

## Recent Session Summary (2025-11-12)

### What Was Accomplished

1. **Created Automated Build Scripts**:
   - `build-flutter-frameworks.sh` - Build Flutter frameworks
   - `build-room-ios.sh` - Fast incremental builds
   - `clean-build-room-ios.sh` - Complete clean build automation

2. **Added Comprehensive Documentation**:
   - `docs/Build-Process.md` - 406 lines covering architecture, common issues, workflows
   - Updated README.md and reels_ios/README.md with build script references

3. **Fixed Critical Issues**:
   - Video playback: Added plugin registration in RRAppDelegate
   - Debug menu: Implemented debug flag propagation (iOS → Pigeon → Flutter)
   - Build process: Automated previously manual multi-step process

4. **Git Commit**: `887de32` - "Add automated build scripts and comprehensive build documentation"

### Known State

- Debug flag: ✅ Working (controlled via ReelsModule.initialize(debug: true))
- Video playback: ✅ Fixed (plugins registered in RRAppDelegate)
- Build scripts: ✅ Tested and committed
- Integration: ✅ room-ios successfully building with reels-sdk

## Git History

Check recent changes:
```bash
cd /Users/ahmed.eishon/Rakuten/reels-sdk
git log --oneline -10
```

Key commits:
- `887de32` - Add automated build scripts and comprehensive build documentation
- `ba56eb6` - Update all module documentation to reflect Pigeon implementation
- `eee054f` - Add client initialization scripts
- `a12fcb8` - Add local folder import documentation for Android

## Architecture Patterns

### Flutter to Native Communication

```
Flutter (reels_flutter)
    ↓ [Pigeon - Type Safe]
ReelsFlutterTokenApi.getAccessToken()
    ↓
ReelsPigeonHandler (iOS)
    ↓
ReelsModule.getAccessToken()
    ↓
accessTokenProvider closure (provided by host app)
```

### Native to Flutter Communication

```
Native iOS (ReelsModule)
    ↓
ReelsFlutterContextApi.isDebugMode()
    ↓ [Pigeon]
CollectContextService (Flutter)
    ↓
engagement_buttons.dart (UI)
```

### Data Flow

```
room-ios app
    ↓ [tap collect item]
FeedItemCollectionViewController.collectImageAction()
    ↓
ReelsModule.openReels(from: viewController)
    ↓ [presents FlutterViewController]
Flutter Reels Screen
    ↓ [requests debug mode]
Pigeon → ReelsModule.isDebugMode()
    ↓ [returns true/false]
Shows/Hides debug menu
```

## Common Tasks for AI Agents

### 1. Adding New Platform Communication

1. Edit `reels_flutter/pigeons/messages.dart`
2. Run `flutter pub run pigeon --input pigeons/messages.dart`
3. Implement handler in `ReelsPigeonHandler.swift` (iOS) and corresponding Android
4. Test with room-ios

### 2. Modifying Flutter UI

- Main files: `reels_flutter/lib/presentation/`
- Key screens: `reels_screen.dart`, `sdk_info_screen.dart`
- Key widgets: `video_reel_item.dart`, `engagement_buttons.dart`
- State management: Provider pattern (see `video_provider.dart`)

### 3. Debugging Build Issues

1. Check Flutter frameworks exist: `ls reels_flutter/.ios/Flutter/Debug/`
2. Run clean build: `./scripts/clean-build-room-ios.sh`
3. Check documentation: `docs/Build-Process.md`

### 4. Testing Changes

```bash
# After making changes
cd /Users/ahmed.eishon/Rakuten/reels-sdk
./scripts/build-room-ios.sh

# Open in Xcode
open /Users/ahmed.eishon/Rakuten/room-ios/ROOM/ROOM.xcworkspace

# Press Cmd+R to run on simulator
```

## Important Notes

### DO NOT commit:
- `reels_flutter/.ios/` - Generated Flutter frameworks
- `reels_flutter/.dart_tool/` - Dart build artifacts
- `*.DS_Store` - macOS system files
- Build artifacts in room-ios

### DO commit:
- Source code changes
- Pigeon generated files (`*PigeonGenerated.*`)
- Documentation updates
- Build scripts

### Test Device
- Simulator: iPhone 16 Pro (ID: `948E5950-D944-47AB-BE9D-B65358CF0400`)
- Scheme: "D_Development Staging"

## Documentation Updates Policy

**IMPORTANT**: When making changes to build process, project structure, or any significant updates:

1. **Update Obsidian docs** (this docs/ directory) along with code changes
2. **Keep documentation in sync** with code during the same commit
3. **Document why, not just what** - explain reasoning behind changes
4. **Update this guide** if project structure or key files change

Examples of changes requiring doc updates:
- Adding/modifying build scripts → Update Build-Process.md
- Changing project structure → Update this Quick-Start-Guide
- Adding new platform APIs → Update architecture section
- Fixing critical bugs → Update "Common Issues" section
- Adding new workflows → Update "Common Tasks" section

**Rule**: Any PR/commit that touches build, architecture, or core functionality must include documentation updates in the same commit.

## Next Steps / TODO

Potential areas for future work:

- [ ] Add Android build scripts (similar to iOS)
- [ ] Implement real access token provider in room-ios
- [ ] Add more comprehensive SDK info in debug screen
- [ ] Consider adding unit tests for platform communication
- [ ] Document Android integration process similar to iOS

## Getting Started (For Next AI Session)

When starting a new session, say:

> "I'm working on reels-sdk. Please read:
> 1. docs/Quick-Start-Guide-AI-Agent.md (this file)
> 2. docs/Build-Process.md (if build-related)
> 3. Recent git commits: `git log -5 --oneline`
>
> Then help me with [specific task]"

This gives complete context in seconds.

## References

- Main README: [README.md](../README.md)
- Build Process: [Build-Process.md](Build-Process.md)
- iOS Module: [reels_ios/README.md](../reels_ios/README.md)
- Flutter Docs: https://docs.flutter.dev/development/add-to-app
- Pigeon Docs: https://pub.dev/packages/pigeon

---

**Last Updated**: 2025-11-12
**Session**: Build Process Automation
**Status**: Fully functional, scripts tested, documentation complete
