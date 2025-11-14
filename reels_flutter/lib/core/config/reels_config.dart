/// Configuration constants for Reels SDK
///
/// Centralizes all tunable parameters for performance optimization
/// and behavior customization.
class ReelsConfig {
  /// Viewport buffer size - keep player initialized for ±N pages from current
  ///
  /// Example with VIEWPORT_BUFFER = 2:
  /// - Current video: 25
  /// - Players kept alive: 23, 24, 25, 26, 27 (5 total)
  ///
  /// Higher values = smoother scrolling but more memory usage
  /// Lower values = less memory but potential stutter when scrolling fast
  static const int viewportBuffer = 2;

  /// Maximum number of cached screen states to keep in memory
  ///
  /// Each cached state includes:
  /// - Video list
  /// - Collect data
  /// - Scroll position
  ///
  /// Higher values = more resume scenarios work without reload
  /// Lower values = less memory usage
  static const int maxCachedGenerations = 5;

  /// How long to keep cached screen state before expiring
  ///
  /// Expired state will trigger fresh data load on resume
  /// Balance between fresh data vs instant resume
  static const Duration cacheExpiry = Duration(minutes: 10);

  /// Minimum distance in milliseconds between video position updates
  ///
  /// Prevents excessive state updates during video playback
  /// Lower values = more accurate position tracking but more CPU
  static const Duration positionUpdateThrottle = Duration(milliseconds: 500);
}
