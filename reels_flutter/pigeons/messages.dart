import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/pigeon_generated.dart',
    dartOptions: DartOptions(),
    // Generate Swift files for iOS bridge (reels_ios module)
    swiftOut:
        '../reels_ios/Sources/ReelsIOS/PigeonGenerated.swift',
    swiftOptions: SwiftOptions(),
    // Generate Kotlin files for Android bridge (reels_android module)
    kotlinOut:
        '../reels_android/src/main/java/com/rakuten/room/reels/pigeon/PigeonGenerated.kt',
    kotlinOptions: KotlinOptions(package: 'com.rakuten.room.reels.pigeon'),
    dartPackageName: 'reels_flutter',
  ),
)
// ============================================================================
// DATA MODELS
// ============================================================================

/// Collect data model - represents a user's post/collection item
class CollectData {
  const CollectData({
    required this.id,
    this.content,
    this.name,
    this.likes,
    this.comments,
    this.recollects,
    this.isLiked,
    this.isCollected,
    this.trackingTag,
    this.userName,
    this.userProfileImage,
    this.itemName,
    this.itemImageUrl,
    this.imageUrl,
  });

  final String id;
  final String? content;           // Collect text content
  final String? name;               // Collect title/name
  final int? likes;                 // Like count
  final int? comments;              // Comment count
  final int? recollects;            // Recollect count
  final bool? isLiked;              // Is liked by current user
  final bool? isCollected;          // Is collected by current user
  final String? trackingTag;        // For analytics tracking
  final String? userName;           // User who created the collect
  final String? userProfileImage;   // User's profile image URL
  final String? itemName;           // Associated item name
  final String? itemImageUrl;       // Associated item image URL
  final String? imageUrl;           // Main collect image URL
}

/// Analytics event data
class AnalyticsEvent {
  const AnalyticsEvent({
    required this.eventName,
    required this.eventProperties,
  });

  final String eventName;
  final Map<String?, String?> eventProperties;
}

/// Share data for social sharing
class ShareData {
  const ShareData({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.description,
    this.thumbnailUrl,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String description;
  final String? thumbnailUrl;
}

/// Screen state data for native tracking
class ScreenStateData {
  const ScreenStateData({
    required this.screenName,
    required this.state,
    this.timestamp,
  });

  final String screenName;
  final String state; // appeared, disappeared, focused, unfocused
  final int? timestamp;
}

/// Video state data for playback tracking
class VideoStateData {
  const VideoStateData({
    required this.videoId,
    required this.state,
    this.position,
    this.duration,
    this.timestamp,
  });

  final String videoId;
  final String state; // playing, paused, stopped, buffering, completed
  final int? position; // in seconds
  final int? duration; // in seconds
  final int? timestamp;
}

// ============================================================================
// HOST APIs (Flutter calls Native)
// ============================================================================

/// API for accessing user authentication token from native
@HostApi()
abstract class ReelsFlutterTokenApi {
  /// Get the current access token from native platform
  @async
  String? getAccessToken();
}

/// API for getting initial Collect data from native
@HostApi()
abstract class ReelsFlutterContextApi {
  /// Get the Collect data that was used to open this screen
  /// @return CollectData object if opened from a Collect, null otherwise
  /// If null, Flutter will show "no videos" screen
  CollectData? getInitialCollect();

  /// Check if debug mode is enabled
  /// @return true if debug mode is enabled, false otherwise
  bool isDebugMode();
}

/// API for sending analytics events to native analytics SDK
@FlutterApi()
abstract class ReelsFlutterAnalyticsApi {
  /// Track a custom analytics event
  void trackEvent(AnalyticsEvent event);
}

/// API for notifying native about button interactions
@FlutterApi()
abstract class ReelsFlutterButtonEventsApi {
  /// Called before like button is clicked (for optimistic UI)
  void onBeforeLikeButtonClick(String videoId);

  /// Called after like button click completes (with updated state)
  void onAfterLikeButtonClick(String videoId, bool isLiked, int likeCount);

  /// Called when share button is clicked
  void onShareButtonClick(ShareData shareData);
}

/// API for notifying native about screen and video state changes
@FlutterApi()
abstract class ReelsFlutterStateApi {
  /// Notify native when screen state changes
  void onScreenStateChanged(ScreenStateData state);

  /// Notify native when video state changes
  void onVideoStateChanged(VideoStateData state);
}

/// API for handling navigation gestures
@FlutterApi()
abstract class ReelsFlutterNavigationApi {
  /// Called when user swipes left
  void onSwipeLeft();

  /// Called when user swipes right
  void onSwipeRight();

  /// Called when user clicks on profile/user image
  void onUserProfileClick(String userId, String userName);

  /// Called when user wants to dismiss/close the reels screen
  void dismissReels();
}
