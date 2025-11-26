import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reels_flutter/core/config/reels_config.dart';
import 'package:reels_flutter/core/di/injection_container.dart';
import 'package:reels_flutter/core/services/analytics_service.dart';
import 'package:reels_flutter/core/services/collect_context_service.dart';
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
  PageController? _pageController;
  int _currentIndex = 0;
  bool _isScreenActive = true;
  int _pageViewGeneration = 0;  // Increment to force complete PageView recreation
  int? _screenGeneration;  // THIS screen's generation number (set once on resetState)
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

    // IMPORTANT: Fetch generation FIRST, then register lifecycle callbacks
    // This ensures each ReelsScreen instance registers its own callbacks under its generation number
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('[ReelsSDK-Flutter] ReelsScreen.initState: Fetching generation and registering lifecycle callbacks');

      // Fetch THIS screen's generation number
      final collectContextService = sl<CollectContextService>();
      final generation = await collectContextService.getCurrentGeneration();
      _screenGeneration = generation;
      print('[ReelsSDK-Flutter] ReelsScreen.initState: Screen generation: $_screenGeneration');

      // Now register lifecycle callbacks FOR THIS GENERATION
      final lifecycleService = sl<LifecycleService>();

      // Reset state callback - triggered by native when screen is presented
      lifecycleService.setOnResetState(() async {
        print('[ReelsSDK-Flutter] ReelsScreen(gen:$_screenGeneration): Resetting state via lifecycle callback');

        final videoProvider = context.read<VideoProvider>();

        // Reset to clear any stale data from previous screen
        videoProvider.reset();

        // Load fresh videos and collect data for THIS screen's generation
        videoProvider.loadVideos(generation: _screenGeneration);

        // Recreate PageController for fresh presentation
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _pageController?.dispose();
                _pageController = PageController();
                _currentIndex = 0;
                _isScreenActive = true;
                _pageViewGeneration++;
                print('[ReelsSDK-Flutter] PageController recreated in resetState (generation: $_pageViewGeneration)');
              });
            }
          });
        }

        print('[ReelsSDK-Flutter] ReelsScreen(gen:$_screenGeneration): Reset and reload triggered');
      }, generation: _screenGeneration);

      // Pause all resources when screen loses focus
      lifecycleService.setOnPauseAll(() {
        print('[ReelsSDK-Flutter] ReelsScreen(gen:$_screenGeneration): Pausing all resources');
        if (mounted) {
          // Save current index to cache before pausing
          final videoProvider = context.read<VideoProvider>();
          videoProvider.updateCurrentIndex(_currentIndex);

          // Set inactive to stop video playback immediately
          setState(() {
            _isScreenActive = false;
          });

          // Dispose PageController synchronously to prevent race conditions
          _pageController?.dispose();
          _pageController = null;
          print('[ReelsSDK-Flutter] PageController disposed, saved index: $_currentIndex');
        }
      }, generation: _screenGeneration);

      // Resume all resources when screen gains focus
      lifecycleService.setOnResumeAll((int generation) async {
        print('[ReelsSDK-Flutter] ReelsScreen(gen:$_screenGeneration): Resuming for generation: $generation');
        // Only handle resume if it's for THIS generation
        if (generation != _screenGeneration) {
          print('[ReelsSDK-Flutter] ⚠️  Resume called for gen $generation but THIS is gen $_screenGeneration, ignoring');
          return;
        }

        if (mounted) {
          final videoProvider = context.read<VideoProvider>();

          // Get saved position BEFORE loading (from previous pause)
          final savedIndex = videoProvider.getCurrentIndex();
          print('[ReelsSDK-Flutter] ReelsScreen(gen:$_screenGeneration): Will restore to index $savedIndex');

          // Recreate PageController immediately in current frame
          // This prevents showing loading spinner
          setState(() {
            _isScreenActive = true;
            _currentIndex = savedIndex;
            _pageViewGeneration++;
            _pageController = PageController(initialPage: savedIndex);
            print('[ReelsSDK-Flutter] PageController recreated at index $savedIndex (gen: $_pageViewGeneration)');
          });

          // Then reload videos asynchronously (will use cache for instant restore)
          await videoProvider.loadVideos(generation: generation);
          print('[ReelsSDK-Flutter] ReelsScreen(gen:$_screenGeneration): Videos reloaded');
        }
      }, generation: _screenGeneration);

      print('[ReelsSDK-Flutter] ReelsScreen: Lifecycle callbacks registered for generation $_screenGeneration');

      // Now load initial videos
      print('[ReelsSDK-Flutter] ReelsScreen.initState: Loading initial videos');

      final videoProvider = context.read<VideoProvider>();

      // Reset to clear any stale data from previous screen
      videoProvider.reset();

      // Load fresh videos and collect data for THIS screen's generation
      videoProvider.loadVideos(generation: _screenGeneration);

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
    print('[ReelsSDK-Flutter] ReelsScreen.dispose() called');
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _pageController?.dispose();

    // Note: We don't clear lifecycle callbacks here because in navigation
    // stack scenarios, multiple view controllers can exist simultaneously
    // (e.g., when pushing to My Room and back). Clearing callbacks would
    // break lifecycle management for screens still in the stack.
    // The callbacks will be overwritten when a new screen sets them up.

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

    // Update VideoProvider with new position (this triggers cache update)
    final videoProvider = context.read<VideoProvider>();
    videoProvider.updateCurrentIndex(index);

    // Track video appear event
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
    if (_pageController?.hasClients ?? false) {
      _pageController!.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player with full reels functionality
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
              // Show loading if PageController is being recreated or no videos yet
              if (_pageController == null || !videoProvider.hasVideos) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                color: Colors.white,
                backgroundColor: Colors.black87,
                child: PageView.builder(
                  key: ValueKey('pageview_gen_$_pageViewGeneration'),  // Unique key per generation
                  controller: _pageController!,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  itemCount: videoProvider.videos.length,
                  itemBuilder: (context, index) {
                    final video = videoProvider.videos[index];

                    // Calculate viewport range for lazy player initialization
                    // Keep players initialized for ±N pages from current
                    final distanceFromCurrent = (index - _currentIndex).abs();
                    final isInViewport = distanceFromCurrent <= ReelsConfig.viewportBuffer;

                    return VideoReelItem(
                      key: ValueKey('video_${video.id}_gen_$_pageViewGeneration'),  // Unique key per video and generation
                      video: video,
                      onLike: () => videoProvider.toggleLike(video.id),
                      onShare: () => videoProvider.shareVideo(video.id),
                      isActive: index == _currentIndex && _isScreenActive,
                      isInViewport: isInViewport,  // Control player initialization
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
                    print('[ReelsSDK-Flutter] 🔴 Close button tapped');
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
