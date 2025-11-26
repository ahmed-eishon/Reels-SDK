import 'package:flutter/foundation.dart';
import 'package:reels_flutter/core/config/reels_config.dart';
import 'package:reels_flutter/core/pigeon_generated.dart';
import 'package:reels_flutter/core/services/analytics_service.dart';
import 'package:reels_flutter/core/services/button_events_service.dart';
import 'package:reels_flutter/core/services/collect_context_service.dart';
import 'package:reels_flutter/domain/entities/video_entity.dart';
import 'package:reels_flutter/domain/usecases/get_videos_usecase.dart';
import 'package:reels_flutter/domain/usecases/increment_share_count_usecase.dart';
import 'package:reels_flutter/domain/usecases/toggle_like_usecase.dart';

/// Cached screen state for a specific generation
///
/// Stores everything needed to restore a screen's state:
/// - Video list (with pagination)
/// - Collect data
/// - Current scroll position
/// - Cache timestamp for expiration
class CachedScreenState {
  final List<VideoEntity> videos;
  final CollectData? collectData;
  final int currentIndex;
  final DateTime cachedAt;

  CachedScreenState({
    required this.videos,
    required this.collectData,
    required this.currentIndex,
    required this.cachedAt,
  });

  /// Check if this cached state has expired
  bool isExpired() {
    return DateTime.now().difference(cachedAt) > ReelsConfig.cacheExpiry;
  }
}

/// Provider for managing video state using Provider package with ChangeNotifier.
///
/// This class handles:
/// - Fetching videos from use cases
/// - Managing loading/error states
/// - User interactions (like, share)
/// - Notifying UI of state changes
/// - Tracking analytics events
/// - Notifying native about button events
/// - Checking collect context from native
class VideoProvider with ChangeNotifier {
  final GetVideosUseCase getVideosUseCase;
  final ToggleLikeUseCase toggleLikeUseCase;
  final IncrementShareCountUseCase incrementShareCountUseCase;
  final AnalyticsService analyticsService;
  final ButtonEventsService buttonEventsService;
  final CollectContextService collectContextService;

  VideoProvider({
    required this.getVideosUseCase,
    required this.toggleLikeUseCase,
    required this.incrementShareCountUseCase,
    required this.analyticsService,
    required this.buttonEventsService,
    required this.collectContextService,
  });

  // State properties
  List<VideoEntity> _videos = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;
  CollectData? _collectData;

  // Generation-based state caching - STATIC to share across all Flutter engine instances
  // Each engine creates its own VideoProvider, but they all share the same cache
  // This is critical for multi-engine architectures where each generation uses a separate engine
  static final Map<int, CachedScreenState> _stateCache = {};
  int? _currentGeneration;
  int _currentIndex = 0;

  // Getters for state
  List<VideoEntity> get videos => _videos;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasVideos => _videos.isNotEmpty;
  CollectData? get collectData => _collectData;

  /// Loads videos from the use case.
  ///
  /// First checks cache for existing state to enable instant resume.
  /// If cache hit and not expired, restores state without network call.
  /// Otherwise, fetches fresh data and caches it.
  ///
  /// [generation] - Optional generation number to fetch collect data for a specific screen instance.
  ///                If null, fetches collect data for the current generation.
  Future<void> loadVideos({int? generation}) async {
    print('[ReelsSDK-Flutter] VideoProvider.loadVideos(generation: $generation) called');

    // Prevent multiple simultaneous load calls
    if (_isLoading) {
      print('[ReelsSDK-Flutter] VideoProvider: Already loading, skipping');
      return;
    }

    _currentGeneration = generation;

    // NOTE: Cache disabled due to multi-engine architecture
    // Each Flutter engine has its own Dart isolate with separate static variables
    // Static _stateCache is NOT shared across engines, causing cache misses
    // Solution: Always reload videos (fast since they're mock data)
    // Future: Move caching to native layer where it can be shared
    print('[ReelsSDK-Flutter] Loading videos for generation $generation (cache disabled)');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if collect context exists from native (optional for now)
      // If generation is provided, use it. Otherwise fetch current generation.
      if (generation != null) {
        _collectData = await collectContextService.getCollectForGeneration(generation);
        print('[ReelsSDK-Flutter] VideoProvider: collectData for generation $generation: ${_collectData != null ? "CollectData(id: ${_collectData!.id})" : "null"}');
      } else {
        _collectData = await collectContextService.getInitialCollect();
        print('[ReelsSDK-Flutter] VideoProvider: collectData received: ${_collectData != null ? "CollectData(id: ${_collectData!.id})" : "null"}');
      }

      // Load videos (collect context is optional for now)
      // TODO: In future, can load videos from collect reference or recommended videos
      _videos = await getVideosUseCase();
      _isLoading = false;
      _hasLoadedOnce = true;

      print('[ReelsSDK-Flutter] Videos loaded: ${_videos.length} videos');
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasLoadedOnce = true;
      _errorMessage = 'Failed to load videos: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Toggles the like status of a video.
  ///
  /// Updates the video in the list and notifies listeners.
  /// Tracks analytics event for the like action.
  /// Notifies native before and after the action.
  Future<void> toggleLike(String videoId) async {
    // Notify native BEFORE like action
    buttonEventsService.notifyBeforeLikeClick(videoId);

    try {
      final updatedVideo = await toggleLikeUseCase(videoId);

      // Find and update the video in the list
      final index = _videos.indexWhere((v) => v.id == videoId);
      if (index != -1) {
        _videos[index] = updatedVideo;
        notifyListeners();

        // Notify native AFTER like action completes
        buttonEventsService.notifyAfterLikeClick(
          videoId,
          updatedVideo.isLiked,
          updatedVideo.likes,
        );

        // Track analytics
        analyticsService.trackLike(
          videoId: videoId,
          isLiked: updatedVideo.isLiked,
          likeCount: updatedVideo.likes,
        );
      }
    } catch (e) {
      // In a real app, you might want to show a snackbar or error message
      debugPrint('Failed to toggle like: $e');
      analyticsService.trackError(
        error: 'like_error',
        context: videoId,
        additionalData: {'error_message': e.toString()},
      );
    }
  }

  /// Increments the share count for a video.
  ///
  /// Updates the video in the list and notifies listeners.
  /// Tracks analytics event for the share action.
  /// Notifies native to handle share action.
  Future<void> shareVideo(String videoId) async {
    // Find video to get share data
    final videoIndex = _videos.indexWhere((v) => v.id == videoId);
    if (videoIndex == -1) {
      debugPrint('Video not found: $videoId');
      return;
    }

    final video = _videos[videoIndex];

    // Notify native to handle share (native can show share sheet)
    buttonEventsService.notifyShareClick(
      videoId: videoId,
      videoUrl: video.url,
      title: video.title,
      description: video.description,
      thumbnailUrl: null, // Could add thumbnail URL to VideoEntity if needed
    );

    try {
      final updatedVideo = await incrementShareCountUseCase(videoId);

      // Find and update the video in the list
      final index = _videos.indexWhere((v) => v.id == videoId);
      if (index != -1) {
        _videos[index] = updatedVideo;
        notifyListeners();

        // Track analytics
        analyticsService.trackShare(videoId: videoId);
      }
    } catch (e) {
      debugPrint('Failed to increment share count: $e');
      analyticsService.trackError(
        error: 'share_error',
        context: videoId,
        additionalData: {'error_message': e.toString()},
      );
    }
  }

  /// Refreshes the video list.
  ///
  /// Useful for pull-to-refresh functionality.
  Future<void> refresh() async {
    await loadVideos();
  }

  /// Clears any error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset all state for fresh screen start
  /// Called when native wants to present a new independent screen
  void reset() {
    print('[ReelsSDK-Flutter] VideoProvider.reset() called');
    _videos = [];
    _isLoading = false;
    _hasLoadedOnce = false;
    _errorMessage = null;
    _collectData = null;
    _currentIndex = 0;
    // Note: Don't clear _stateCache here - we want to preserve it for resume
    notifyListeners();
  }

  /// Update the current video index and cache it
  void updateCurrentIndex(int index) {
    _currentIndex = index;
    // Update cache with new position
    if (_currentGeneration != null) {
      _cacheState(_currentGeneration!);
    }
  }

  /// Get the current video index
  int getCurrentIndex() => _currentIndex;

  /// Cache the current state for a generation
  void _cacheState(int generation) {
    _stateCache[generation] = CachedScreenState(
      videos: List.from(_videos), // Create copy to avoid reference issues
      collectData: _collectData,
      currentIndex: _currentIndex,
      cachedAt: DateTime.now(),
    );

    print('[ReelsSDK-Flutter] 💾 Cached state for generation $generation (index: $_currentIndex, videos: ${_videos.length})');

    // Cleanup old generations (keep only last N)
    if (_stateCache.length > ReelsConfig.maxCachedGenerations) {
      // Remove oldest cached generation
      final oldestKey = _stateCache.keys.first;
      _stateCache.remove(oldestKey);
      print('[ReelsSDK-Flutter] 🗑️ Removed cached state for generation $oldestKey (cache limit reached)');
    }
  }

  /// Get cache information for debug screen
  Map<String, dynamic> getCacheInfo() {
    return {
      'cachedGenerations': _stateCache.length,
      'currentGeneration': _currentGeneration,
      'currentIndex': _currentIndex,
      'cacheDetails': _stateCache.entries.map((e) {
        return {
          'generation': e.key,
          'videos': e.value.videos.length,
          'currentIndex': e.value.currentIndex,
          'expired': e.value.isExpired(),
          'cachedAt': e.value.cachedAt.toIso8601String(),
        };
      }).toList(),
    };
  }
}
