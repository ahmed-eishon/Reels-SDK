import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../pigeon_generated.dart';
import '../services/access_token_service.dart';
import '../services/analytics_service.dart';
import '../services/button_events_service.dart';
import '../services/collect_context_service.dart';
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
  });

  final AccessTokenService accessTokenService;
  final AnalyticsService analyticsService;
  final ButtonEventsService buttonEventsService;
  final StateEventsService stateEventsService;
  final NavigationEventsService navigationEventsService;
  final CollectContextService collectContextService;
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
  void onSwipeLeft() {
    const channel = BasicMessageChannel<Object?>(
      'dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.onSwipeLeft',
      _codec,
    );
    channel.send(null);
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
    // Create collect context service with callback to native
    final collectContextService = CollectContextService(
      getCollectCallback: () async {
        // Use Pigeon-generated API for type-safe communication
        final contextApi = ReelsFlutterContextApi();
        try {
          final result = await contextApi.getInitialCollect();
          debugPrint('[ReelsSDK-Flutter] getInitialCollect result: $result');
          return result;
        } catch (e) {
          debugPrint('[ReelsSDK-Flutter] Error getting collect context: $e');
          return null;
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

    return PlatformServices(
      accessTokenService: accessTokenService,
      analyticsService: analyticsService,
      buttonEventsService: buttonEventsService,
      stateEventsService: stateEventsService,
      navigationEventsService: navigationEventsService,
      collectContextService: collectContextService,
    );
  }
}
