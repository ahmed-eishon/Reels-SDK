# Build Process Documentation

## Overview

This document explains the build process for the ReelsSDK and its integration with room-ios. The build process has been automated with scripts to eliminate manual steps and common issues.

## Quick Start

### Option 1: Clean Build (Recommended when starting fresh)

```bash
cd /Users/ahmed.eishon/Rakuten/reels-sdk
./scripts/clean-build-room-ios.sh
```

This performs a complete clean build:
1. Cleans and rebuilds Flutter frameworks
2. Updates CocoaPods dependencies
3. Cleans Xcode build artifacts
4. Builds the room-ios app

**When to use:** First build, after major changes, or when encountering build issues.

### Option 2: Incremental Build (Faster)

```bash
cd /Users/ahmed.eishon/Rakuten/reels-sdk
./scripts/build-room-ios.sh
```

This performs an incremental build without cleaning:
1. Checks if Flutter frameworks exist (builds if missing)
2. Builds the room-ios app incrementally

**When to use:** After making small changes to Swift or Flutter code.

### Option 3: Build Only Flutter Frameworks

```bash
cd /Users/ahmed.eishon/Rakuten/reels-sdk
./scripts/build-flutter-frameworks.sh         # Incremental
./scripts/build-flutter-frameworks.sh --clean # Clean build
```

**When to use:** When you only modified Flutter code and want to rebuild frameworks.

## Architecture

### Build Dependencies

```
reels-sdk/
├── reels_flutter/          # Flutter module
│   ├── .ios/Flutter/       # Built Flutter frameworks (generated)
│   │   ├── Debug/
│   │   ├── Profile/
│   │   └── Release/
│   └── lib/                # Flutter source code
├── reels_ios/              # Native iOS bridge
│   ├── Sources/ReelsIOS/   # Swift source files
│   └── ReelsIOS.podspec    # CocoaPods spec
└── scripts/                # Build automation scripts

room-ios/ROOM/
├── Podfile                 # References reels-sdk modules
├── ROOM.xcworkspace        # Xcode workspace
└── Source/                 # room-ios source code
```

### Build Order (Critical!)

**The order matters because of dependencies:**

1. **Flutter Frameworks** - Must be built first
   - Located: `reels_flutter/.ios/Flutter/`
   - Contains: `App.xcframework`, `Flutter.xcframework`, plugins
   - Referenced by: room-ios Podfile

2. **ReelsIOS Module** - Built by Xcode
   - Located: `reels_ios/Sources/ReelsIOS/`
   - Depends on: Flutter frameworks
   - Referenced by: room-ios Podfile

3. **room-ios App** - Built last
   - Workspace: `room-ios/ROOM/ROOM.xcworkspace`
   - Depends on: Flutter frameworks + ReelsIOS module
   - Integrates: ReelsSDK via CocoaPods

## Common Issues & Solutions

### Issue 1: "FlutterPluginRegistrant not found"

**Symptom:**
```
error: no such module 'FlutterPluginRegistrant'
```

**Cause:** Flutter frameworks not built or cleaned.

**Solution:**
```bash
./scripts/build-flutter-frameworks.sh --clean
```

### Issue 2: "CpHeader failed"

**Symptom:**
```
CpHeader ... GeneratedPluginRegistrant.h failed
```

**Cause:** Flutter `.ios` folder was deleted by `flutter clean`.

**Solution:**
```bash
cd reels_flutter
flutter build ios-framework --debug --output=.ios/Flutter
```

### Issue 3: Videos not playing

**Symptom:** Videos in reels screen show black screen or loading spinner forever.

**Cause:** Flutter plugins (video_player) not registered.

**Solution:** Verify in `RRAppDelegate.swift` (should already be there):
```swift
// This code should be in didFinishLaunchingWithOptions
if let flutterEngine = ReelsModule.getEngine() {
    GeneratedPluginRegistrant.register(with: flutterEngine)
}
```

### Issue 4: Debug menu not showing

**Symptom:** 3-dot menu in reels doesn't show "SDK Info & Debug" option.

**Cause:** Debug flag not set or old build cached.

**Solution:**
1. Verify `debug: true` in `RRAppDelegate.swift`:
   ```swift
   ReelsModule.initialize(
       accessTokenProvider: { completion in
           completion("test_access_token")
       },
       debug: true  // ← Should be true
   )
   ```

2. Clean rebuild:
   ```bash
   ./scripts/clean-build-room-ios.sh
   ```

### Issue 5: "Module compiled with Swift X.X cannot be imported"

**Symptom:** Swift version mismatch errors.

**Cause:** Different Swift versions between modules.

**Solution:**
1. Check Swift version in all modules:
   - ReelsIOS.podspec: `spec.swift_version = '5.9'`
   - Xcode project settings

2. Update to match and rebuild:
   ```bash
   ./scripts/clean-build-room-ios.sh
   ```

## Manual Build Process (For Reference)

If you need to build manually (not recommended):

### Step 1: Build Flutter Frameworks

```bash
cd /Users/ahmed.eishon/Rakuten/reels-sdk/reels_flutter

# Clean (optional)
flutter clean

# Build frameworks
flutter build ios-framework --debug --output=.ios/Flutter
```

This creates:
- `.ios/Flutter/Debug/App.xcframework`
- `.ios/Flutter/Debug/Flutter.xcframework`
- `.ios/Flutter/Debug/FlutterPluginRegistrant.xcframework`
- Plus Profile and Release versions

### Step 2: Update CocoaPods (if needed)

```bash
cd /Users/ahmed.eishon/Rakuten/room-ios/ROOM
pod install
```

Run this when:
- First time setup
- After modifying Podfile
- After updating dependencies

### Step 3: Build room-ios

```bash
cd /Users/ahmed.eishon/Rakuten/room-ios/ROOM

# Clean build (slow)
xcodebuild -workspace ROOM.xcworkspace \
    -scheme "D_Development Staging" \
    -configuration "D_Development Staging" \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    clean build

# Or incremental build (faster)
xcodebuild -workspace ROOM.xcworkspace \
    -scheme "D_Development Staging" \
    -configuration "D_Development Staging" \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    build
```

## Development Workflow

### Typical Day-to-Day Development

1. **Make changes** to Flutter or Swift code

2. **Incremental build** (fast):
   ```bash
   ./scripts/build-room-ios.sh
   ```

3. **Test in Xcode**:
   ```bash
   open /Users/ahmed.eishon/Rakuten/room-ios/ROOM/ROOM.xcworkspace
   ```
   Then press Cmd+R

### After Major Changes

If you've made significant changes or encounter weird issues:

1. **Clean build** (slower but safer):
   ```bash
   ./scripts/clean-build-room-ios.sh
   ```

2. **Test thoroughly**:
   - Video playback
   - Debug menu visibility
   - Collect item tap → reels screen
   - All debug info displaying correctly

### Before Committing Code

1. **Clean build** to ensure everything works from scratch:
   ```bash
   ./scripts/clean-build-room-ios.sh
   ```

2. **Verify all features**:
   - [ ] App launches successfully
   - [ ] Tap collect item opens reels
   - [ ] Videos play correctly
   - [ ] Debug menu visible (if debug=true)
   - [ ] SDK info shows correct data
   - [ ] No console errors

## Integration Points

### room-ios Podfile

Location: `/Users/ahmed.eishon/Rakuten/room-ios/ROOM/Podfile`

Key sections:
```ruby
# Flutter module integration
flutter_application_path = '/Users/ahmed.eishon/Rakuten/reels-sdk/reels_flutter'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'ROOM' do
  # Install Flutter pods
  install_all_flutter_pods(flutter_application_path)

  # Add ReelsIOS native module
  pod 'ReelsIOS', :path => '/Users/ahmed.eishon/Rakuten/reels-sdk/reels_ios'
end
```

### RRAppDelegate.swift

Location: `/Users/ahmed.eishon/Rakuten/room-ios/ROOM/ROOM/Source/App/RRAppDelegate.swift`

Key sections:
```swift
import ReelsIOS
import FlutterPluginRegistrant

// In didFinishLaunchingWithOptions:

// 1. Initialize ReelsModule
ReelsModule.initialize(
    accessTokenProvider: { completion in
        completion("test_access_token")
    },
    debug: true
)

// 2. Register Flutter plugins (CRITICAL for video playback)
if let flutterEngine = ReelsModule.getEngine() {
    GeneratedPluginRegistrant.register(with: flutterEngine)
    print("[ROOM] Flutter plugins registered for ReelsModule")
}
```

### FeedItemCollectionViewController.swift

Location: `/Users/ahmed.eishon/Rakuten/room-ios/ROOM/ROOM/Source/Feed/FeedFollowing/Item/FeedItemCollectionViewController.swift`

Opens reels when collect item tapped:
```swift
func collectImageAction(node: ASDisplayNode) {
    // ... existing code ...

    // Open Reels screen instead of item detail
    guard let viewController = self.navigationController ?? UIApplication.room.topViewController() else {
        return
    }
    ReelsModule.openReels(from: viewController, initialRoute: "/", animated: true)
}
```

## Performance Tips

### Faster Builds

1. **Use incremental builds** for day-to-day development
2. **Don't run `flutter clean`** unless necessary
3. **Keep Xcode DerivedData** - only clean when encountering cache issues
4. **Use Xcode directly** for fastest iteration (Cmd+R in Xcode)

### When to Clean Build

- First time setup
- After pulling major changes from git
- After modifying build configurations
- When encountering unexplainable build errors
- Before creating a release build
- Before committing significant changes

### Build Times (Approximate)

- **Incremental build**: 30-60 seconds
- **Flutter frameworks only**: 1-2 minutes
- **Full clean build**: 5-8 minutes

## Troubleshooting Checklist

If build fails, check in this order:

1. **Flutter frameworks exist**:
   ```bash
   ls -la /Users/ahmed.eishon/Rakuten/reels-sdk/reels_flutter/.ios/Flutter/Debug/
   ```
   Should show: `App.xcframework`, `Flutter.xcframework`, etc.

2. **CocoaPods up to date**:
   ```bash
   cd /Users/ahmed.eishon/Rakuten/room-ios/ROOM
   pod install
   ```

3. **Correct paths in Podfile**:
   - Verify `flutter_application_path` points to `reels_flutter`
   - Verify `ReelsIOS` pod path points to `reels_ios`

4. **Import statements**:
   - RRAppDelegate.swift has `import ReelsIOS`
   - RRAppDelegate.swift has `import FlutterPluginRegistrant`

5. **Plugin registration**:
   - `GeneratedPluginRegistrant.register(with: engine)` is called

If all else fails:
```bash
./scripts/clean-build-room-ios.sh
```

## Additional Resources

- [Flutter Add-to-App Documentation](https://docs.flutter.dev/development/add-to-app)
- [CocoaPods Integration](https://guides.cocoapods.org/using/using-cocoapods.html)
- [Pigeon Documentation](https://pub.dev/packages/pigeon)

## Support

For issues or questions:
1. Check this documentation first
2. Review error messages carefully
3. Try a clean build
4. Check recent git changes that might have affected the build
