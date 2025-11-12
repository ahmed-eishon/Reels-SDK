import 'package:flutter/foundation.dart';
import 'package:reels_flutter/core/pigeon_generated.dart';
import 'package:reels_flutter/core/services/analytics_service.dart';
import 'package:reels_flutter/core/services/button_events_service.dart';
import 'package:reels_flutter/core/services/collect_context_service.dart';
import 'package:reels_flutter/domain/entities/video_entity.dart';
import 'package:reels_flutter/domain/usecases/get_videos_usecase.dart';
import 'package:reels_flutter/domain/usecases/increment_share_count_usecase.dart';
import 'package:reels_flutter/domain/usecases/toggle_like_usecase.dart';

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
  /// First checks if collect context exists from native.
  /// If collect is null, shows "no videos" state.
  /// Sets loading state, fetches videos, and handles errors.
  /// Notifies listeners of state changes.
  Future<void> loadVideos() async {
    print('[ReelsSDK-Flutter] VideoProvider.loadVideos() called');

    // Prevent multiple simultaneous load calls
    if (_isLoading) {
      print('[ReelsSDK-Flutter] VideoProvider: Already loading, skipping');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if collect context exists from native (optional for now)
      _collectData = await collectContextService.getInitialCollect();
      print('[ReelsSDK-Flutter] VideoProvider: collectData received: ${_collectData != null ? "CollectData(id: ${_collectData!.id})" : "null"}');

      // Load videos (collect context is optional for now)
      // TODO: In future, can load videos from collect reference or recommended videos
      _videos = await getVideosUseCase();
      _isLoading = false;
      _hasLoadedOnce = true;
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
    notifyListeners();
  }
}
