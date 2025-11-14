import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../pigeon_generated.dart';
import '../services/access_token_service.dart';
import '../services/analytics_service.dart';
import '../services/button_events_service.dart';
import '../services/collect_context_service.dart';
import '../services/lifecycle_service.dart';
import '../services/navigation_events_service.dart';
import '../services/state_events_service.dart';

/// Platform initialization result
class PlatformServices {
  const PlatformServices({
    required this.accessTokenService,
    required this.analyticsService,
    required this.buttonEventsService,
    required this.stateEventsService,
    required this.navigationEventsService,
    required this.collectContextService,
    required this.lifecycleService,
  });

  final AccessTokenService accessTokenService;
  final AnalyticsService analyticsService;
  final ButtonEventsService buttonEventsService;
  final StateEventsService stateEventsService;
  final NavigationEventsService navigationEventsService;
  final CollectContextService collectContextService;
  final LifecycleService lifecycleService;
}

/// Implementation of ReelsFlutterAnalyticsApi that sends events to native
class _ReelsAnalyticsApiImpl extends ReelsFlutterAnalyticsApi {
  static const MessageCodec<Object?> _codec =
      ReelsFlutterAnalyticsApi.pigeonChannelCodec;
  static const String _channelName =
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterAnalyticsApi.trackEvent';

  @override
  void trackEvent(AnalyticsEvent event) {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
      _channelName,
      _codec,
    );

    channel.send(<Object?>[event]);
  }
}

/// Implementation of ReelsFlutterButtonEventsApi that sends events to native
class _ReelsButtonEventsApiImpl extends ReelsFlutterButtonEventsApi {
  static const MessageCodec<Object?> _codec =
      ReelsFlutterButtonEventsApi.pigeonChannelCodec;

  @override
  void onBeforeLikeButtonClick(String videoId) {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterButtonEventsApi.onBeforeLikeButtonClick',
      _codec,
    );
    channel.send(<Object?>[videoId]);
  }

  @override
  void onAfterLikeButtonClick(String videoId, bool isLiked, int likeCount) {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterButtonEventsApi.onAfterLikeButtonClick',
      _codec,
    );
    channel.send(<Object?>[videoId, isLiked, likeCount]);
  }

  @override
  void onShareButtonClick(ShareData shareData) {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterButtonEventsApi.onShareButtonClick',
      _codec,
    );
    channel.send(<Object?>[shareData]);
  }
}

/// Implementation of ReelsFlutterStateApi that sends state events to native
class _ReelsStateApiImpl extends ReelsFlutterStateApi {
  static const MessageCodec<Object?> _codec =
      ReelsFlutterStateApi.pigeonChannelCodec;

  @override
  void onScreenStateChanged(ScreenStateData state) {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterStateApi.onScreenStateChanged',
      _codec,
    );
    channel.send(<Object?>[state]);
  }

  @override
  void onVideoStateChanged(VideoStateData state) {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterStateApi.onVideoStateChanged',
      _codec,
    );
    channel.send(<Object?>[state]);
  }
}

/// Implementation of ReelsFlutterNavigationApi that sends navigation events to native
class _ReelsNavigationApiImpl extends ReelsFlutterNavigationApi {
  static const MessageCodec<Object?> _codec =
      ReelsFlutterNavigationApi.pigeonChannelCodec;

  @override
  void onSwipeLeft(String userId, String userName) {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.onSwipeLeft',
      _codec,
    );
    channel.send(<Object?>[userId, userName]);
  }

  @override
  void onSwipeRight() {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.onSwipeRight',
      _codec,
    );
    channel.send(null);
  }

  @override
  void onUserProfileClick(String userId, String userName) {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.onUserProfileClick',
      _codec,
    );
    channel.send(<Object?>[userId, userName]);
  }

  @override
  void dismissReels() {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.dismissReels',
      _codec,
    );
    channel.send(null);
  }
}

/// Initializes platform communication channels
///
/// This sets up the Pigeon APIs that handle communication between
/// Flutter and native platforms (Android/iOS).
class PlatformInitializer {
  /// Initialize all platform APIs
  ///
  /// This should be called once during app initialization, before
  /// any other platform communication occurs.
  ///
  /// Returns [PlatformServices] with configured services.
  static PlatformServices initializePlatformAPIs() {
    // Create access token service with callback to native
    final accessTokenService = AccessTokenService(
      getTokenCallback: () async {
        // Use Pigeon-generated API for type-safe communication
        final tokenApi = ReelsFlutterTokenApi();
        try {
          final result = await tokenApi.getAccessToken();
          debugPrint('[ReelsSDK-Flutter] getAccessToken result: ${result != null ? "token received" : "no token"}');
          return result;
        } catch (e) {
          debugPrint('[ReelsSDK-Flutter] Error getting access token: $e');
          return null;
        }
      },
    );

    // Create analytics service
    final analyticsApi = _ReelsAnalyticsApiImpl();
    final analyticsService = AnalyticsService(api: analyticsApi);
    print('[ReelsSDK-Flutter] Analytics service initialized');

    // Create button events service
    final buttonEventsApi = _ReelsButtonEventsApiImpl();
    final buttonEventsService = ButtonEventsService(api: buttonEventsApi);
    print('[ReelsSDK-Flutter] Button events service initialized');

    // Create state events service
    final stateEventsApi = _ReelsStateApiImpl();
    final stateEventsService = StateEventsService(api: stateEventsApi);
    print('[ReelsSDK-Flutter] State events service initialized');

    // Create navigation events service
    final navigationEventsApi = _ReelsNavigationApiImpl();
    final navigationEventsService = NavigationEventsService(
      api: navigationEventsApi,
    );
    // Create collect context service with callbacks to native
    final collectContextService = CollectContextService(
      getCollectByGenerationCallback: (int generation) async {
        // Use Pigeon-generated API for type-safe communication
        final contextApi = ReelsFlutterContextApi();
        try {
          final result = await contextApi.getInitialCollect(generation);
          debugPrint('[ReelsSDK-Flutter] getInitialCollect(generation: $generation) result: $result');
          return result;
        } catch (e) {
          debugPrint('[ReelsSDK-Flutter] Error getting collect context for generation $generation: $e');
          return null;
        }
      },
      getCurrentGenerationCallback: () async {
        // Use Pigeon-generated API for type-safe communication
        final contextApi = ReelsFlutterContextApi();
        try {
          final result = await contextApi.getCurrentGeneration();
          debugPrint('[ReelsSDK-Flutter] getCurrentGeneration result: $result');
          return result;
        } catch (e) {
          debugPrint('[ReelsSDK-Flutter] Error getting current generation: $e');
          return 0;
        }
      },
      isDebugModeCallback: () async {
        // Use Pigeon-generated API for type-safe communication
        final contextApi = ReelsFlutterContextApi();
        try {
          final result = await contextApi.isDebugMode();
          debugPrint('[ReelsSDK-Flutter] isDebugMode result: $result');
          return result;
        } catch (e) {
          debugPrint('[ReelsSDK-Flutter] Error checking debug mode: $e');
          return false;
        }
      },
    );

    // Create lifecycle service and set up handler for native calls
    final lifecycleService = LifecycleService();
    ReelsFlutterLifecycleApi.setUp(_ReelsLifecycleApiHandler(lifecycleService));
    print('[ReelsSDK-Flutter] Lifecycle service initialized');

    return PlatformServices(
      accessTokenService: accessTokenService,
      analyticsService: analyticsService,
      buttonEventsService: buttonEventsService,
      stateEventsService: stateEventsService,
      navigationEventsService: navigationEventsService,
      collectContextService: collectContextService,
      lifecycleService: lifecycleService,
    );
  }
}

/// Handler for lifecycle API calls from native
class _ReelsLifecycleApiHandler extends ReelsFlutterLifecycleApi {
  _ReelsLifecycleApiHandler(this._lifecycleService);

  final LifecycleService _lifecycleService;

  @override
  void resetState() {
    debugPrint('[ReelsSDK-Flutter] Lifecycle API: resetState called from native');
    _lifecycleService.resetState();
  }

  @override
  void pauseAll() {
    debugPrint('[ReelsSDK-Flutter] Lifecycle API: pauseAll called from native');
    _lifecycleService.pauseAll();
  }

  @override
  void resumeAll(int generation) {
    debugPrint('[ReelsSDK-Flutter] Lifecycle API: resumeAll($generation) called from native');
    _lifecycleService.resumeAll(generation);
  }
}
