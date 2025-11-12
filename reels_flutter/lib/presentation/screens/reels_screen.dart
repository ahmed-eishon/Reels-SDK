import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reels_flutter/core/di/injection_container.dart';
import 'package:reels_flutter/core/services/analytics_service.dart';
import 'package:reels_flutter/core/services/lifecycle_service.dart';
import 'package:reels_flutter/core/services/navigation_events_service.dart';
import 'package:reels_flutter/core/services/state_events_service.dart';
import 'package:reels_flutter/main.dart';
import 'package:reels_flutter/presentation/providers/video_provider.dart';
import 'package:reels_flutter/presentation/widgets/video_reel_item.dart';
import 'package:provider/provider.dart';

/// Full-screen reels interface with vertical scrolling
///
/// Features:
/// - Vertical PageView for smooth scrolling between videos
/// - Full-screen immersive experience
/// - Pull-to-refresh functionality
/// - Loading and error states
/// - Analytics tracking for video views and page views
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with WidgetsBindingObserver, RouteAware {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isScreenActive = true;
  late AnalyticsService _analyticsService;
  late StateEventsService _stateEventsService;

  @override
  void initState() {
    super.initState();
    print('[ReelsSDK-Flutter] ReelsScreen.initState() called');
    _pageController = PageController();
    _analyticsService = sl<AnalyticsService>();
    _stateEventsService = sl<StateEventsService>();
    WidgetsBinding.instance.addObserver(this);

    // Set up lifecycle callbacks to manage state and resources
    final lifecycleService = sl<LifecycleService>();

    // Reset state callback - only used when native explicitly requests reset
    lifecycleService.setOnResetState(() {
      print('[ReelsSDK-Flutter] ReelsScreen: Resetting state via lifecycle callback');
      context.read<VideoProvider>().reset();
    });

    // Pause all resources when screen loses focus
    lifecycleService.setOnPauseAll(() {
      print('[ReelsSDK-Flutter] ReelsScreen: Pausing all resources');
      if (mounted) {
        setState(() {
          _isScreenActive = false;  // This pauses video players
        });
      }
    });

    // Resume all resources when screen gains focus
    lifecycleService.setOnResumeAll(() {
      print('[ReelsSDK-Flutter] ReelsScreen: Resuming all resources');
      if (mounted) {
        setState(() {
          _isScreenActive = true;  // This resumes video players
        });
      }
    });

    // Reset provider state for fresh screen presentation
    // This ensures collect data is fetched fresh each time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[ReelsSDK-Flutter] ReelsScreen.initState: Resetting and loading videos');
      final videoProvider = context.read<VideoProvider>();

      // Reset to clear any stale data from previous screen
      videoProvider.reset();

      // Load fresh videos and collect data
      videoProvider.loadVideos();

      // Track page view
      _analyticsService.trackPageView('reels_screen');

      // Notify native that screen appeared
      _stateEventsService.notifyScreenFocused(screenName: 'reels_screen');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('[ReelsSDK-Flutter] ReelsScreen.didChangeDependencies() called');

    // Subscribe to route changes
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);

    // Note: We don't reload videos here because initState() already handles
    // resetting and loading fresh data. Reloading here would cause race conditions
    // and potentially load with stale collect data before the reset completes.
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('[ReelsSDK-Flutter] ReelsScreen.didChangeAppLifecycleState: $state');

    setState(() {
      _isScreenActive = state == AppLifecycleState.resumed;
    });

    if (state == AppLifecycleState.resumed) {
      _stateEventsService.notifyScreenFocused(screenName: 'reels_screen');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stateEventsService.notifyScreenUnfocused(screenName: 'reels_screen');
    }
  }

  @override
  void didPush() {
    // Called when this route has been pushed
    print('[ReelsSDK-Flutter] ReelsScreen.didPush() called');
    setState(() {
      _isScreenActive = true;
    });

    // Notify native that screen gained focus
    _stateEventsService.notifyScreenFocused(screenName: 'reels_screen');
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and this route shows up
    setState(() {
      _isScreenActive = true;
    });

    // Notify native that screen regained focus
    _stateEventsService.notifyScreenFocused(screenName: 'reels_screen');
  }

  @override
  void didPushNext() {
    // Called when a new route has been pushed, and this route is no longer visible
    setState(() {
      _isScreenActive = false;
    });

    // Notify native that screen lost focus
    _stateEventsService.notifyScreenUnfocused(screenName: 'reels_screen');
  }

  @override
  void didPop() {
    // Called when this route has been popped off
    setState(() {
      _isScreenActive = false;
    });

    // Notify native that screen disappeared
    _stateEventsService.notifyScreenUnfocused(screenName: 'reels_screen');
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Track video appear event
    final videoProvider = context.read<VideoProvider>();
    if (index < videoProvider.videos.length) {
      final video = videoProvider.videos[index];
      _analyticsService.trackVideoAppear(
        videoId: video.id,
        position: index,
        screenName: 'reels_screen',
      );
    }
  }

  Future<void> _onRefresh() async {
    await context.read<VideoProvider>().refresh();
    // Reset to first video after refresh
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Consumer<VideoProvider>(
            builder: (context, videoProvider, child) {
          // Loading state - show only when loading for the first time
          if (videoProvider.isLoading && !videoProvider.hasLoadedOnce) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          // Error state - show only after loading is complete
          if (videoProvider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      videoProvider.errorMessage ?? 'Something went wrong',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => videoProvider.loadVideos(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty state - show only after loading is complete and no videos
          if (!videoProvider.hasVideos && videoProvider.hasLoadedOnce) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No videos available',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          // Success state - display reels
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.white,
            backgroundColor: Colors.black87,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: videoProvider.videos.length,
              itemBuilder: (context, index) {
                final video = videoProvider.videos[index];
                return VideoReelItem(
                  video: video,
                  onLike: () => videoProvider.toggleLike(video.id),
                  onShare: () => videoProvider.shareVideo(video.id),
                  isActive: index == _currentIndex && _isScreenActive,
                  collectData: videoProvider.collectData,
                );
              },
            ),
          );
            },
          ),
          // Close button overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    // Call native to dismiss the modal presentation
                    // This triggers cleanup on iOS side
                    final navigationService = sl<NavigationEventsService>();
                    navigationService.dismissReels();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
