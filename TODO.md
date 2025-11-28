# ReelsSDK Release Roadmap

## Current Version: v0.1.5
**Status**: ✅ Released (Android Debug + iOS Debug)
- Package renamed from `com.rakuten.room.reels` to `com.eishon.reels`
- Fixed Pigeon configuration for correct package structure
- Successfully integrated with room-android and room-ios

---

## v0.1.6 - iOS Multimodal Fix
**Priority**: HIGH
**Status**: 🔴 TODO

### Issues to Address
- Fix iOS multimodal navigation issues caused by Android-side multimodal implementation
- Ensure nested modal presentations work correctly on iOS
- Verify dismiss behavior works properly when presented modally from already-modal screens

### Tasks
- [ ] Review iOS `ReelsPigeonHandler.swift` for modal presentation issues
- [ ] Test nested modal presentations on iOS
- [ ] Fix dismiss logic to properly handle modal stack
- [ ] Verify `presentingViewController` reference handling
- [ ] Test swipe-to-dismiss gesture in modal context
- [ ] Ensure root listener vs current listener logic is correct

### Testing
- [ ] Test opening reels from normal screen
- [ ] Test opening reels from modal screen
- [ ] Test opening reels from nested modal (modal -> modal -> reels)
- [ ] Test close button behavior in all scenarios
- [ ] Test swipe-right dismiss in all scenarios
- [ ] Test profile navigation from reels in modal context

---

## v0.1.7 - Modular Implementation for External Data
**Priority**: MEDIUM
**Status**: 🟡 PLANNED

### Features
- Support external data sources that directly show list without internal API calls
- Provide 3 major interface types for different UI support levels

### Architecture Design

#### 1. **Data Source Interface** - Support External Data
```kotlin
// Android
interface ReelsDataSource {
    suspend fun loadReels(params: LoadParams): ReelsPage
    suspend fun loadReelById(id: String): ReelItem
}

// iOS
protocol ReelsDataSource {
    func loadReels(params: LoadParams) async throws -> ReelsPage
    func loadReelById(id: String) async throws -> ReelItem
}
```

#### 2. **Three UI Interface Levels**

**Level 1: Full-Screen Reels** (Current Implementation)
- Full-screen vertical scrolling reels
- Built-in controls (like, share, comments, profile)
- Maximum customization of behavior

**Level 2: Feed-Embedded Reels**
- Reels embedded in a scrollable feed
- Inline playback with auto-play on scroll
- Minimal controls (tap to expand)

**Level 3: Thumbnail Grid**
- Grid layout of reel thumbnails
- Tap to open full-screen player
- List/Grid toggle support

### Tasks
- [ ] Design `ReelsDataSource` interface for both platforms
- [ ] Implement external data adapter pattern
- [ ] Create Level 1 interface (Full-Screen) - refactor current implementation
- [ ] Create Level 2 interface (Feed-Embedded)
- [ ] Create Level 3 interface (Thumbnail Grid)
- [ ] Add configuration options for each UI level
- [ ] Document API for external data integration
- [ ] Create sample implementations for each UI level

### API Design
```kotlin
// Example: External data configuration
ReelsModule.initialize(
    context = context,
    dataSource = CustomReelsDataSource(), // External data
    uiLevel = ReelsUILevel.FULL_SCREEN
)

// Open with external data
ReelsModule.openReels(
    activity = activity,
    dataProvider = { customDataList },
    uiLevel = ReelsUILevel.FEED_EMBEDDED
)
```

---

## v0.1.8 - Finalize Build Levels
**Priority**: HIGH
**Status**: 🟡 PLANNED

### Objective
Establish and finalize different build configurations for various deployment scenarios

### Build Levels to Support

#### 1. **Debug Build**
- Development and testing
- Verbose logging enabled
- Debug symbols included
- SDK info screen enabled
- Current implementation: `v0.1.5-android-debug`, `v0.1.5-ios-debug`

#### 2. **Release Build**
- Production deployment
- Optimized performance
- Minimal logging
- Debug features disabled
- Smaller binary size

#### 3. **Profile Build** (Optional)
- Performance profiling
- Optimization enabled but with debug symbols
- Performance monitoring tools enabled

### Tasks
- [ ] Define build variants in Gradle (Android)
- [ ] Define build schemes in Xcode (iOS)
- [ ] Configure ProGuard/R8 rules for release builds
- [ ] Set up code signing for release builds
- [ ] Configure crash reporting for release builds
- [ ] Optimize binary size for release builds
- [ ] Create build scripts for each level
- [ ] Document build process for each level
- [ ] Set up CI/CD for automated builds
- [ ] Create release checklist

### Build Configuration Matrix
| Build Level | Logging | Debug Symbols | Optimization | Crash Reporting |
|------------|---------|---------------|--------------|-----------------|
| Debug      | Verbose | Yes           | None         | Optional        |
| Release    | Minimal | No            | Full         | Yes             |
| Profile    | Moderate| Yes           | Full         | Yes             |

### Release Workflow
- [ ] Android: Separate tags `v0.1.8-android-debug` and `v0.1.8-android-release`
- [ ] iOS: Separate tags `v0.1.8-ios-debug` and `v0.1.8-ios-release`
- [ ] GitHub Actions workflows for each build type
- [ ] Maven artifacts naming convention for build levels
- [ ] CocoaPods podspec variants for build levels

---

## v0.1.9 - Update Flutter UI
**Priority**: MEDIUM
**Status**: 🟡 PLANNED

### UI/UX Improvements

#### Design Updates
- [ ] Modernize reels player UI
- [ ] Improve loading states and animations
- [ ] Enhance video controls design
- [ ] Better error state UI
- [ ] Improved empty state UI

#### Interaction Improvements
- [ ] Smoother swipe gestures
- [ ] Better video buffering indicators
- [ ] Enhanced like/share animations
- [ ] Improved profile card design
- [ ] Better comment section UI (if applicable)

#### Performance Optimizations
- [ ] Optimize video preloading
- [ ] Reduce Flutter build size
- [ ] Improve frame rate during scrolling
- [ ] Better memory management for video players
- [ ] Optimize image loading and caching

#### Accessibility
- [ ] Add proper accessibility labels
- [ ] Support screen readers
- [ ] Keyboard navigation support
- [ ] High contrast mode support
- [ ] Font scaling support

### Flutter Dependencies Review
- [ ] Update Flutter SDK to latest stable
- [ ] Update video_player package
- [ ] Review and update all Flutter dependencies
- [ ] Remove unused dependencies
- [ ] Audit dependency licenses

### Tasks
- [ ] Design review with UI/UX team
- [ ] Create Figma designs for new UI
- [ ] Implement new UI components in Flutter
- [ ] Update theme and styling
- [ ] Implement animations and transitions
- [ ] Performance testing and optimization
- [ ] Accessibility audit
- [ ] Cross-platform UI consistency check
- [ ] Update UI documentation and screenshots

---

## Future Considerations (v0.2.0+)

### Features to Explore
- [ ] Support for live streaming reels
- [ ] AR filters and effects
- [ ] Duet/Stitch functionality
- [ ] Advanced analytics and insights
- [ ] Content moderation tools
- [ ] Monetization features (ads, subscriptions)
- [ ] Social features (follow, notifications)
- [ ] Offline mode support
- [ ] Picture-in-picture mode

### Platform Support
- [ ] Web support (Flutter Web)
- [ ] Desktop support (Windows, macOS, Linux)
- [ ] Tablet-optimized layouts
- [ ] TV/Android TV support

### Developer Experience
- [ ] Comprehensive sample apps
- [ ] Interactive documentation
- [ ] Video tutorials
- [ ] Migration guides
- [ ] API reference improvements

---

## Release Checklist Template

For each release, ensure:
- [ ] All planned features implemented
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] UI tests passing
- [ ] Performance benchmarks met
- [ ] Memory leak checks passed
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] Version numbers bumped
- [ ] Git tags created
- [ ] GitHub release created
- [ ] Artifacts published (Maven/CocoaPods)
- [ ] Sample apps updated
- [ ] Migration guide written (if breaking changes)
- [ ] Announcement prepared

---

## Notes

### Version Numbering
- **Major**: Breaking API changes
- **Minor**: New features, backwards compatible
- **Patch**: Bug fixes, backwards compatible

### Current Focus
Working on v0.1.6 to fix iOS multimodal issues introduced during Android implementation.

### Testing Strategy
- Maintain separate test apps: `room-android` and `room-ios`
- Test with both local folder integration and Maven/CocoaPods distribution
- Test on multiple device sizes and OS versions
- Performance testing on lower-end devices

### Distribution Strategy
- Debug builds: GitHub releases with Maven/CocoaPods
- Release builds: TBD based on deployment requirements
- Consider: Maven Central, CocoaPods Trunk for public release
