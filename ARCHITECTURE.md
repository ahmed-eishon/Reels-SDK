# Reels SDK Architecture

## Overview

The Reels SDK is designed as an **independent package** that can be integrated into any iOS app without creating dependencies on host app types. This document explains the architecture and what can/cannot be made common.

## Architecture Layers

```
┌──────────────────────────────────────────────┐
│       Host App (room-ios)                    │
│  ┌────────────────────────────────────────┐  │
│  │   FeedCoordinator (BaseCoordinator)    │  │
│  │   - Creates ReelsDetailCoordinator     │  │
│  │   - Manages child coordinator          │  │
│  └────────────────────────────────────────┘  │
│              ↓                                │
│  ┌────────────────────────────────────────┐  │
│  │  ReelsDetailCoordinator (extends       │  │
│  │  BaseCoordinator)                      │  │
│  │   - Wraps ReelsCoordinator SDK         │  │
│  │   - Implements ReelsCoordinatorDelegate│  │
│  │   - Manages navigation (MyRoom, etc.)  │  │
│  └────────────────────────────────────────┘  │
│              ↓                                │
│  ┌────────────────────────────────────────┐  │
│  │  Model+ReelsExtensions                 │  │
│  │  - toReelsCollectData()                │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
              ↓
┌──────────────────────────────────────────────┐
│       Reels SDK (reels-sdk)                  │
│  ┌────────────────────────────────────────┐  │
│  │   ReelsCoordinator (static utility)    │  │
│  │   - Default listener                   │  │
│  │   - Delegate pattern                   │  │
│  └────────────────────────────────────────┘  │
│              ↓                                │
│  ┌────────────────────────────────────────┐  │
│  │   ReelsModule / Flutter                │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

## What CAN Be Made Common (in Reels SDK)

### ✅ 1. Default Event Handling
**Location:** `ReelsCoordinator` → `DefaultReelsListener`

All ReelsListener events have default implementations:
- `onLikeButtonClick` - Logs event
- `onShareButtonClick` - Logs event
- `onScreenStateChanged` - Logs event
- `onVideoStateChanged` - Logs event (commented to reduce verbosity)
- `onSwipeRight` - Does nothing by default
- `onAnalyticsEvent` - Logs event

**Benefit:** Host apps don't need to implement these unless they want custom behavior.

### ✅ 2. Navigation Delegation
**Location:** `ReelsCoordinator` → `ReelsCoordinatorDelegate` protocol

Navigation callbacks that need coordinator access are abstracted:
- `reelsDidRequestUserProfile()` - Called when user clicks profile
- `reelsDidSwipeLeft()` - Called when user swipes left

**Benefit:** Clean separation between SDK and host app navigation logic.

### ✅ 3. Collect Data Conversion
**Location:** Host app → `Model+ReelsExtensions.swift`

Helper extension converts `Model.Collect` to dictionary format:
```swift
extension Model.Collect {
    func toReelsCollectData() -> [String: Any?] {
        // Builds dictionary with all required fields
    }
}
```

**Benefit:** One place to maintain the conversion logic. Easy to add new fields.

## What CANNOT Be Made Common

### ❌ 1. Direct Model.Collect Usage
**Why:** `Model.Collect` is defined in host app (room-ios), not in SDK (reels-sdk).

**Constraint:** SDKs must not depend on host app types to maintain independence.

**Solution:** Use dictionary format as contract between SDK and host app.

### ❌ 2. Navigation Implementation
**Why:** Each screen/coordinator needs different navigation behavior:
- FeedCoordinator might open MyRoom
- DiscoverCoordinator might open different screens
- Each coordinator manages its own child coordinators

**Constraint:** Navigation requires:
- Access to parent coordinator's `addChildCoordinator()`
- Knowledge of host app's coordinator hierarchy
- Different behavior per screen

**Solution:** Delegate pattern - SDK calls delegate methods, host app implements navigation.

### ❌ 3. Analytics Integration
**Why:** Each app has different analytics systems:
- Different event tracking libraries
- Different event naming conventions
- Different required properties

**Constraint:** SDK doesn't know host app's analytics implementation.

**Solution:** Default implementation logs events. Host apps can implement `ReelsListener` directly for custom analytics.

## Usage Examples

### Simple Usage (Following BaseCoordinator Pattern)

```swift
// FeedCoordinator - Create and start ReelsDetailCoordinator
func openItemDetail(item: Model.Collect, defaultImage: UIImage?, ...) {
    let reelsDetailCoordinator = ReelsDetailCoordinator(
        navigationController: navigationController,
        item: item,
        defaultImage: defaultImage
    )
    addChildCoordinator(reelsDetailCoordinator)  // ✅ Proper hierarchy
    reelsDetailCoordinator.start(animated: animated, completion: completion)
}
```

**Benefits:**
- ✅ Follows ItemDetailCoordinator pattern exactly
- ✅ Proper coordinator lifecycle management (start, finish, addChildCoordinator)
- ✅ Reusable navigation logic in ReelsDetailCoordinator
- ✅ Only 3 lines of code!

### ReelsDetailCoordinator (Common for All Screens)

```swift
class ReelsDetailCoordinator: BaseCoordinator {
    var navigationController: UINavigationController
    var item: Model.Collect?

    override func start(...) {
        ReelsCoordinator.openReels(
            from: navigationController,
            collectData: item.toReelsCollectData(),  // ✅ Extension
            delegate: self,                           // ✅ Handle navigation
            animated: animated
        )
    }
}

// Navigation implementation - common for all callers
extension ReelsDetailCoordinator: ReelsCoordinatorDelegate {
    func reelsDidRequestUserProfile(...) {
        let myRoomCoordinator = MyRoomCoordinator(...)
        addChildCoordinator(myRoomCoordinator)  // ✅ Proper hierarchy
        myRoomCoordinator.start(...)
    }

    func reelsDidSwipeLeft(...) {
        // Similar pattern
    }
}
```

**Benefit:** Navigation logic is written once in ReelsDetailCoordinator, reused by all screens!

### Advanced Usage (Custom Event Handling)

If you need custom analytics or event tracking:

```swift
// Set custom listener instead of using delegate
ReelsCoordinator.setListener(self)

extension YourCoordinator: ReelsListener {
    // Implement all methods you need
    func onAnalyticsEvent(eventName: String, properties: [String: String]) {
        MyAnalytics.track(event: eventName, properties: properties)
    }

    func onLikeButtonClick(videoId: String, isLiked: Bool, likeCount: Int) {
        MyAnalytics.track(event: "video_liked", properties: [...])
    }

    // Other methods have default empty implementations
}
```

## Key Design Decisions

### 1. **SDK Independence**
- SDK does not reference host app types (`Model.Collect`, coordinators, etc.)
- Maintains clean package boundaries
- Can be used in any iOS app

### 2. **Delegate Pattern for Navigation**
- Navigation requires parent coordinator access
- Each screen may have different navigation logic
- Delegate pattern keeps this flexible

### 3. **Dictionary Contract**
- Simple, type-agnostic data passing
- Easy to extend with new fields
- No coupling between SDK and host types

### 4. **Default Implementations**
- `ReelsListener` has default empty implementations
- `ReelsCoordinatorDelegate` has default empty implementations
- Host apps only implement what they need

## Migration Path for Other Screens

When adding ReelsSDK to other screens (e.g., DiscoverCoordinator), follow the same pattern as ItemDetailCoordinator:

```swift
// In DiscoverCoordinator (or any other coordinator)
func openItemDetail(item: Model.Collect, defaultImage: UIImage?, ...) {
    let reelsDetailCoordinator = ReelsDetailCoordinator(
        navigationController: navigationController,
        item: item,
        defaultImage: defaultImage
    )
    addChildCoordinator(reelsDetailCoordinator)
    reelsDetailCoordinator.start(animated: animated, completion: completion)
}
```

**That's it!** No need to implement any delegate methods. ReelsDetailCoordinator handles everything:
- ✅ Collect data conversion via `item.toReelsCollectData()`
- ✅ Navigation to MyRoom for profile clicks
- ✅ Swipe left handling
- ✅ Proper coordinator hierarchy management

## Summary

| Feature | Can Be Common? | Location | Reason |
|---------|---------------|----------|---------|
| Default event logging | ✅ Yes | ReelsCoordinator | Events are SDK-generic |
| Navigation callbacks | ❌ No (delegate) | Host coordinator | Needs parent coordinator |
| Collect→Dictionary conversion | ✅ Yes | Model extension | One place to maintain |
| Direct Model.Collect usage | ❌ No | N/A | SDK independence |
| Analytics integration | ❌ No (can override) | Host app | App-specific systems |

**Result:** Screens implementing ReelsSDK only need to:
1. Create ReelsDetailCoordinator with item (3 lines)
2. No delegate methods to implement
3. Follows exact same pattern as ItemDetailCoordinator

Clean, maintainable, follows BaseCoordinator architecture, and proper coordinator hierarchy! 🎉
