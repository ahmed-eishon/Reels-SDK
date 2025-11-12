import '../pigeon_generated.dart';

/// Service for navigation event communication with native platform
class NavigationEventsService {
  NavigationEventsService({required this.api});

  final ReelsFlutterNavigationApi api;

  /// Called when user swipes left (opens user's My Room)
  void onSwipeLeft(String userId, String userName) {
    try {
      api.onSwipeLeft(userId, userName);
      print('[ReelsSDK-Flutter] Swipe left detected - opening My Room for user: $userId');
    } catch (e) {
      print('[ReelsSDK-Flutter] Error on swipe left: $e');
    }
  }

  /// Called when user swipes right (open detail/profile)
  void onSwipeRight() {
    try {
      api.onSwipeRight();
      print('[ReelsSDK-Flutter] Swipe right detected - opening detail');
    } catch (e) {
      print('[ReelsSDK-Flutter] Error on swipe right: $e');
    }
  }

  // Convenience wrapper methods

  /// Notify swipe left with user info
  void notifySwipeLeft({required String userId, required String userName}) {
    onSwipeLeft(userId, userName);
  }

  /// Notify swipe right
  void notifySwipeRight({int? currentIndex}) {
    onSwipeRight();
  }

  /// Called when user clicks on profile/user image
  void onUserProfileClick(String userId, String userName) {
    try {
      api.onUserProfileClick(userId, userName);
      print('[ReelsSDK-Flutter] User profile click - userId: $userId, userName: $userName');
    } catch (e) {
      print('[ReelsSDK-Flutter] Error on user profile click: $e');
    }
  }

  /// Notify user profile click (method name for clarity)
  void notifyUserProfileClick({required String userId, required String userName}) {
    onUserProfileClick(userId, userName);
  }

  /// Called when user wants to dismiss/close the reels screen
  void dismissReels() {
    try {
      api.dismissReels();
      print('[ReelsSDK-Flutter] Dismiss reels requested');
    } catch (e) {
      print('[ReelsSDK-Flutter] Error dismissing reels: $e');
    }
  }
}
