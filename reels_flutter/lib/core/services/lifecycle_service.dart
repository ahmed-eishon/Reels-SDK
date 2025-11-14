import 'package:flutter/foundation.dart';

/// Service for managing Flutter app lifecycle
///
/// Handles lifecycle events from native platform:
/// - resetState: Clear all state for fresh screen start
/// - pauseAll: Pause resources when screen loses focus
/// - resumeAll: Resume resources when screen gains focus
///
/// This ensures each screen presentation is independent with proper
/// resource management for video players and network requests.
class LifecycleService {
  LifecycleService();

  // Callbacks for lifecycle events
  VoidCallback? _onResetState;
  VoidCallback? _onPauseAll;
  void Function(int generation)? _onResumeAll;

  /// Register callback for reset state event
  void setOnResetState(VoidCallback? callback) {
    _onResetState = callback;
  }

  /// Register callback for pause all event
  void setOnPauseAll(VoidCallback? callback) {
    _onPauseAll = callback;
  }

  /// Register callback for resume all event
  /// The callback receives the generation number of the screen being resumed
  void setOnResumeAll(void Function(int generation)? callback) {
    _onResumeAll = callback;
  }

  /// Clear all callbacks
  void clearCallbacks() {
    _onResetState = null;
    _onPauseAll = null;
    _onResumeAll = null;
  }

  /// Called by native to reset Flutter state for fresh screen start
  void resetState() {
    debugPrint('[ReelsSDK-Flutter] LifecycleService: resetState called');
    _onResetState?.call();
  }

  /// Called by native to pause all resources (videos, network)
  void pauseAll() {
    debugPrint('[ReelsSDK-Flutter] LifecycleService: pauseAll called');
    _onPauseAll?.call();
  }

  /// Called by native to resume all resources for a specific screen generation
  /// @param generation The generation number of the screen being resumed
  void resumeAll(int generation) {
    debugPrint('[ReelsSDK-Flutter] LifecycleService: resumeAll($generation) called');
    _onResumeAll?.call(generation);
  }
}
