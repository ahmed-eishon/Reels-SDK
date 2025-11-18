# Android-iOS Parity Implementation - Remaining Tasks

## ✅ Completed (Phase 1)

### CollectData Model
- [x] Created `CollectData.kt` with all fields matching iOS
- [x] Added Parcelable support for Intent passing
- [x] Implemented `toMap()` and `fromMap()` helpers

### ReelsModule Core Features
- [x] Added generation tracking (`generationNumber`, `collectDataByGeneration`)
- [x] Implemented direct `openReels(activity, collectData)` method
- [x] Added `pauseFlutter()` lifecycle method
- [x] Added `resumeFlutter(generation)` lifecycle method
- [x] Implemented `getInitialCollect(generation)` internal method
- [x] Added `getSDKInfo()` and `SDKInfo` data class
- [x] Enhanced logging to match iOS style
- [x] Updated `createReelsIntent()` methods to support collectData and generation

## 🔨 Remaining Work (Phase 2)

### 1. FlutterReelsActivity Updates
**File:** `reels_android/src/main/java/com/rakuten/room/reels/flutter/FlutterReelsActivity.kt`

**Add constants:**
```kotlin
const val EXTRA_COLLECT_DATA = "collect_data"
const val EXTRA_GENERATION = "generation"
```

**In `onCreate()`:**
```kotlin
// Extract collectData and generation from intent
val collectData = intent.getParcelableExtra<CollectData>(EXTRA_COLLECT_DATA)
val generation = intent.getIntExtra(EXTRA_GENERATION, 0)

if (collectData != null) {
    Log.d(TAG, "Received collectData: id=${collectData.id}, generation=$generation")
}
```

**Update `onResume()`:**
```kotlin
override fun onResume() {
    super.onResume()
    Log.d(TAG, "FlutterReelsActivity resumed")

    // Resume Flutter resources for this generation
    val generation = intent.getIntExtra(EXTRA_GENERATION, 0)
    if (generation > 0) {
        ReelsModule.resumeFlutter(generation)
    }

    // ... rest of existing code
}
```

**Update `onPause()`:**
```kotlin
override fun onPause() {
    super.onPause()
    Log.d(TAG, "FlutterReelsActivity paused")

    // Pause Flutter resources
    ReelsModule.pauseFlutter()

    // ... rest of existing code
}
```

### 2. FlutterReelsFragment Updates
**File:** `reels_android/src/main/java/com/rakuten/room/reels/flutter/FlutterReelsFragment.kt`

**Update `newInstance()` method:**
```kotlin
fun newInstance(
    initialRoute: String = "/",
    collectData: CollectData? = null,
    generation: Int = 0
): FlutterReelsFragment {
    val fragment = FlutterReelsFragment()
    val args = Bundle()
    args.putString(ARG_ROUTE, initialRoute)
    collectData?.let { args.putParcelable(ARG_COLLECT_DATA, it) }
    args.putInt(ARG_GENERATION, generation)
    fragment.arguments = args
    return fragment
}
```

**Add constants:**
```kotlin
private const val ARG_COLLECT_DATA = "collect_data"
private const val ARG_GENERATION = "generation"
```

**In `onResume()` and `onPause()`:**
- Add similar pause/resume logic as Activity

### 3. FlutterPigeonHandler Updates
**File:** `reels_android/src/main/java/com/rakuten/room/reels/flutter/FlutterPigeonHandler.kt`

**Implement `getInitialCollect()` in the Pigeon API handler:**
```kotlin
override fun getInitialCollect(generation: Long, callback: (Result<CollectData?>) -> Unit) {
    try {
        val collectData = ReelsModule.getInitialCollect(generation.toInt())

        if (collectData != null) {
            Log.d(TAG, "getInitialCollect($generation) -> returning: ${collectData.id}")
            // Convert CollectData to Pigeon CollectData type
            val pigeonCollectData = convertToPigeonCollectData(collectData)
            callback(Result.success(pigeonCollectData))
        } else {
            Log.d(TAG, "getInitialCollect($generation) -> returning: null")
            callback(Result.success(null))
        }
    } catch (e: Exception) {
        Log.e(TAG, "Error in getInitialCollect", e)
        callback(Result.failure(e))
    }
}

private fun convertToPigeonCollectData(data: CollectData): PigeonCollectData {
    return PigeonCollectData(
        id = data.id,
        content = data.content,
        name = data.name,
        likes = data.likes,
        comments = data.comments,
        recollects = data.recollects,
        isLiked = data.isLiked,
        isCollected = data.isCollected,
        trackingTag = data.trackingTag,
        userId = data.userId,
        userName = data.userName,
        userProfileImage = data.userProfileImage,
        itemName = data.itemName,
        itemImageUrl = data.itemImageUrl,
        imageUrl = data.imageUrl
    )
}
```

### 4. Build Configuration
**File:** `reels_android/build.gradle`

**Add Parcelize plugin:**
```gradle
plugins {
    id 'com.android.library'
    id 'org.jetbrains.kotlin.android'
    id 'kotlin-parcelize'  // <-- Add this
}
```

### 5. Testing Checklist

**Basic Functionality:**
- [ ] ReelsModule.openReels() launches without collectData
- [ ] ReelsModule.openReels() launches with collectData
- [ ] Generation number increments correctly
- [ ] CollectData is retrieved in Flutter via getInitialCollect()

**Lifecycle Management:**
- [ ] pauseFlutter() is called when navigating away
- [ ] resumeFlutter() is called when returning
- [ ] Videos pause when backgrounded
- [ ] Videos resume when foregrounded

**Nested Modals:**
- [ ] Multiple reels screens can be opened
- [ ] Each screen has its own generation number
- [ ] Each screen retrieves its own collectData
- [ ] Proper cleanup when screens close

**Edge Cases:**
- [ ] Opening reels without initialization (should handle gracefully)
- [ ] Invalid collectData (null/empty fields)
- [ ] Rapid open/close cycles
- [ ] Memory leaks (check collectDataByGeneration cleanup)

## 📝 Implementation Notes

### Key Design Decisions

1. **Generation Tracking**: Each screen instance gets a unique generation number to support nested modals
2. **Parcelable**: CollectData uses Parcelize for efficient Intent passing
3. **Lifecycle**: Pause/resume tied to Activity/Fragment lifecycle for resource management
4. **Pigeon API**: getInitialCollect bridges native context to Flutter

### iOS Parity Status

| Feature | iOS | Android Phase 1 | Android Phase 2 |
|---------|-----|-----------------|-----------------|
| CollectData passing | ✅ | ✅ | - |
| Generation tracking | ✅ | ✅ | - |
| Direct openReels() | ✅ | ✅ | - |
| pauseFlutter() | ✅ | ✅ | ⏳ Activity integration |
| resumeFlutter() | ✅ | ✅ | ⏳ Activity integration |
| getInitialCollect() | ✅ | ✅ | ⏳ Pigeon handler |
| SDK info | ✅ | ✅ | - |
| Nested modal support | ✅ | ✅ | ⏳ Testing |

## 🚀 Next Steps

1. Complete FlutterReelsActivity updates
2. Complete FlutterReelsFragment updates
3. Implement FlutterPigeonHandler getInitialCollect
4. Add Parcelize plugin to build.gradle
5. Build and test Android AAR locally
6. Integration testing with ROOM Android app
7. Update Android documentation with new APIs
8. Create Android usage examples matching iOS

## 📚 Reference

- iOS Implementation: `reels_ios/Sources/ReelsIOS/ReelsModule.swift`
- Pigeon API: `reels_flutter/pigeons/messages.dart`
- Android Activity: `reels_android/src/main/java/com/rakuten/room/reels/flutter/FlutterReelsActivity.kt`

---

**Phase 1 completed:** Core ReelsModule and CollectData model
**Phase 2 remaining:** Activity/Fragment/Pigeon integration and testing
