import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Video player widget with auto-play and pause on visibility change
///
/// Features:
/// - Auto-play when visible
/// - Auto-pause when not visible
/// - Loop playback
/// - Tap to pause/play
/// - Loading indicator
/// - Volume control
/// - Viewport-aware lazy initialization (only creates player when in viewport)
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final bool isMuted;
  final bool isInViewport;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.isActive,
    this.isMuted = false,
    this.isInViewport = true, // Default to true for backward compatibility
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  // Static counter to track total active video player instances
  static int _instanceCount = 0;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showPlayButton = false;
  bool _isInitializing = false;
  String? _errorMessage;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _instanceCount++;
    print('[VideoPlayer] 🎬 CREATED (viewport: ${widget.isInViewport}) - Total active instances: $_instanceCount');

    // Only initialize player if in viewport (lazy initialization)
    if (widget.isInViewport) {
      _safeSetState(() {
        _isInitializing = true;
      });
      _initializePlayer();
    } else {
      print('[VideoPlayer] ⏸️  Skipping initialization - outside viewport');
    }
  }

  /// Safe setState that checks if widget is still mounted and not disposed
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  /// Enhanced platform channel readiness check to ensure video player plugin is available
  Future<void> _waitForPlatformChannelReadiness() async {
    print('VideoPlayerWidget: Checking platform channel readiness...');

    // Progressive delay strategy - start short, increase if needed
    const List<int> delays = [200, 500, 1000, 2000];

    for (int i = 0; i < delays.length; i++) {
      if (_isDisposed) return;

      try {
        // Test platform channel connectivity by creating a temporary controller
        final testController = VideoPlayerController.networkUrl(
          Uri.parse('https://www.w3schools.com/html/mov_bbb.mp4'),
        );

        // Quick initialization test with short timeout
        await testController.initialize().timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw Exception('Platform channel test timeout'),
        );

        // If we get here, platform channel is ready
        await testController.dispose();
        print(
          'VideoPlayerWidget: Platform channel is ready (attempt ${i + 1})',
        );
        return;
      } catch (e) {
        print(
          'VideoPlayerWidget: Platform channel test failed (attempt ${i + 1}): $e',
        );

        if (i < delays.length - 1) {
          print('VideoPlayerWidget: Waiting ${delays[i]}ms before retry...');
          await Future.delayed(Duration(milliseconds: delays[i]));
        } else {
          // Final attempt failed, but continue anyway
          print(
            'VideoPlayerWidget: All platform channel tests failed, continuing anyway...',
          );
          // Add additional delay to give platform more time
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    }
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle viewport transitions (entering/leaving viewport)
    if (oldWidget.isInViewport != widget.isInViewport) {
      if (widget.isInViewport && !oldWidget.isInViewport) {
        // Entered viewport - initialize player
        print('[VideoPlayer] ▶️  Entered viewport, initializing player');
        if (!_isInitializing && _videoPlayerController == null) {
          _safeSetState(() {
            _isInitializing = true;
            _hasError = false;
          });
          _initializePlayer();
        }
      } else if (!widget.isInViewport && oldWidget.isInViewport) {
        // Left viewport - dispose player to free memory
        print('[VideoPlayer] ⏸️  Left viewport, disposing player');
        _disposePlayer();
      }
    }

    // Handle visibility changes (only if player is initialized)
    if (oldWidget.isActive != widget.isActive &&
        !_isDisposed &&
        _videoPlayerController != null) {
      if (widget.isActive) {
        _videoPlayerController!.play();
        _safeSetState(() {
          _showPlayButton = false;
        });
      } else {
        _videoPlayerController!.pause();
        _safeSetState(() {
          _showPlayButton = true;
        });
      }
    }

    // Handle mute state changes (only if player is initialized)
    if (oldWidget.isMuted != widget.isMuted && _videoPlayerController != null) {
      _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  Future<void> _initializePlayer() async {
    try {
      print(
        'VideoPlayerWidget: Initializing player for URL: ${widget.videoUrl}',
      );

      // Enhanced Flutter engine readiness check with platform channel validation
      await _waitForPlatformChannelReadiness();

      // Check if widget was disposed during delay
      if (_isDisposed) return;

      // Check if URL is a network URL or asset
      if (widget.videoUrl.startsWith('http://') ||
          widget.videoUrl.startsWith('https://')) {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          // Add configuration for better HLS support
          httpHeaders: {'User-Agent': 'ReelsFlutter/1.0'},
        );
      } else {
        _videoPlayerController = VideoPlayerController.asset(widget.videoUrl);
      }

      print('VideoPlayerWidget: Starting controller initialization...');

      // Set timeout for initialization with retry logic
      const maxRetries = 3;
      var currentRetry = 0;

      while (currentRetry < maxRetries) {
        try {
          await _videoPlayerController!.initialize().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Video initialization timeout');
            },
          );
          break; // Success, exit retry loop
        } catch (e) {
          currentRetry++;
          print(
            'VideoPlayerWidget: Initialization attempt $currentRetry failed: $e',
          );

          if (currentRetry >= maxRetries) {
            throw Exception(
              'Video initialization failed after $maxRetries attempts: $e',
            );
          }

          // Wait before retry, but check if disposed
          await Future.delayed(Duration(milliseconds: 1000 * currentRetry));
          if (_isDisposed) return;
        }
      }

      print('VideoPlayerWidget: Controller initialized successfully');

      // Check if widget was disposed during initialization
      if (_isDisposed) return;

      // Set initial volume based on muted state
      _videoPlayerController!.setVolume(widget.isMuted ? 0.0 : 1.0);

      // Add listener to update play button state
      _videoPlayerController!.addListener(() {
        if (!_isDisposed && _videoPlayerController != null) {
          final isPlaying = _videoPlayerController!.value.isPlaying;
          if (_showPlayButton == isPlaying) {
            _safeSetState(() {
              _showPlayButton = !isPlaying;
            });
          }
        }
      });

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: widget.isActive,
        looping: true,
        showControls: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        // Allow fullscreen for better HLS experience
        allowFullScreen: false,
        allowMuting: true,
        // Optimize for HLS streaming
        autoInitialize: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading video...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          print('VideoPlayerWidget: Chewie error: $errorMessage');
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white54,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load video',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      _safeSetState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('VideoPlayerWidget: Error initializing player: $e');
      _safeSetState(() {
        _hasError = true;
        _isInitializing = false;
        _errorMessage = e.toString();
      });
    } finally {
      _safeSetState(() {
        _isInitializing = false;
      });
    }
  }

  /// Dispose the player (called when leaving viewport)
  void _disposePlayer() {
    print('[VideoPlayer] 🗑️  Disposing player (left viewport)');

    // Dispose video controller
    if (_videoPlayerController != null) {
      try {
        _videoPlayerController!.dispose();
        _videoPlayerController = null;
        print('VideoPlayerWidget: Video controller disposed successfully');
      } catch (e) {
        print('VideoPlayerWidget: Error disposing video controller: $e');
      }
    }

    // Dispose chewie controller
    if (_chewieController != null) {
      try {
        _chewieController!.dispose();
        _chewieController = null;
        print('VideoPlayerWidget: Chewie controller disposed successfully');
      } catch (e) {
        print('VideoPlayerWidget: Error disposing chewie controller: $e');
      }
    }

    _safeSetState(() {
      _isInitialized = false;
      _isInitializing = false;
      _hasError = false;
      _showPlayButton = false;
    });
  }

  @override
  void dispose() {
    _instanceCount--;
    print('[VideoPlayer] 🗑️  DISPOSED - Remaining active instances: $_instanceCount');
    _isDisposed = true;

    // Dispose player resources
    _disposePlayer();

    super.dispose();
  }

  void _togglePlayPause() {
    if (_isDisposed || _videoPlayerController == null) return;

    if (_videoPlayerController!.value.isPlaying) {
      _videoPlayerController!.pause();
      _safeSetState(() {
        _showPlayButton = true;
      });
    } else {
      _videoPlayerController!.play();
      _safeSetState(() {
        _showPlayButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Video unavailable',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                widget.videoUrl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Chewie(controller: _chewieController!),

          // Play/Pause indicator with smooth fade animation
          AnimatedOpacity(
            opacity: _showPlayButton ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
