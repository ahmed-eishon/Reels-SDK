import '../pigeon_generated.dart';

/// Service for navigation event communication with native platform
class NavigationEventsService {
  NavigationEventsService({required this.api});

  final ReelsFlutterNavigationApi api;

  /// Called when user swipes left (navigate back)
  void onSwipeLeft() {
    try {
      api.onSwipeLeft();
      print('[ReelsSDK-Flutter] Swipe left detected - navigating back');
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

  // Legacy compatibility wrapper methods

  /// Notify swipe left (legacy method name)
  void notifySwipeLeft({int? currentIndex}) {
    onSwipeLeft();
  }

  /// Notify swipe right (legacy method name)
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
