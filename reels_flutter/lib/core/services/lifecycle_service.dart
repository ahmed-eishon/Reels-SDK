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
///
/// MULTI-ENGINE SUPPORT:
/// - iOS: Single engine, generations are sequential (1, then 2, then 3)
/// - Android: Multiple engines, generations can exist simultaneously
/// - Solution: Store callbacks per generation, invoke only the relevant one
class LifecycleService {
  LifecycleService();

  // Per-generation callbacks for multi-engine support
  // Maps generation number to its callbacks
  final Map<int, VoidCallback?> _resetStateCallbacks = {};
  final Map<int, VoidCallback?> _pauseAllCallbacks = {};
  final Map<int, void Function(int)?> _resumeAllCallbacks = {};

  /// Register callback for reset state event
  /// @param generation The generation number (optional, for multi-engine support)
  /// @param callback The callback to invoke
  void setOnResetState(VoidCallback? callback, {int? generation}) {
    if (generation != null) {
      _resetStateCallbacks[generation] = callback;
      debugPrint('[ReelsSDK-Flutter] LifecycleService: Registered resetState for generation $generation');
    } else {
      // Legacy support: if no generation, register for generation 0 (default)
      _resetStateCallbacks[0] = callback;
      debugPrint('[ReelsSDK-Flutter] LifecycleService: Registered resetState for default generation');
    }
  }

  /// Register callback for pause all event
  /// @param generation The generation number (optional, for multi-engine support)
  /// @param callback The callback to invoke
  void setOnPauseAll(VoidCallback? callback, {int? generation}) {
    if (generation != null) {
      _pauseAllCallbacks[generation] = callback;
      debugPrint('[ReelsSDK-Flutter] LifecycleService: Registered pauseAll for generation $generation');
    } else {
      // Legacy support: if no generation, register for generation 0 (default)
      _pauseAllCallbacks[0] = callback;
      debugPrint('[ReelsSDK-Flutter] LifecycleService: Registered pauseAll for default generation');
    }
  }

  /// Register callback for resume all event
  /// @param generation The generation number (optional, for multi-engine support)
  /// @param callback The callback to invoke (receives generation number)
  void setOnResumeAll(void Function(int generation)? callback, {int? generation}) {
    if (generation != null) {
      _resumeAllCallbacks[generation] = callback;
      debugPrint('[ReelsSDK-Flutter] LifecycleService: Registered resumeAll for generation $generation');
    } else {
      // Legacy support: if no generation, register for generation 0 (default)
      _resumeAllCallbacks[0] = callback;
      debugPrint('[ReelsSDK-Flutter] LifecycleService: Registered resumeAll for default generation');
    }
  }

  /// Clear callbacks for a specific generation
  /// @param generation The generation to clear (if null, clears default generation 0)
  void clearCallbacks({int? generation}) {
    final gen = generation ?? 0;
    _resetStateCallbacks.remove(gen);
    _pauseAllCallbacks.remove(gen);
    _resumeAllCallbacks.remove(gen);
    debugPrint('[ReelsSDK-Flutter] LifecycleService: Cleared callbacks for generation $gen');
  }

  /// Called by native to reset Flutter state for fresh screen start
  /// Calls ALL registered resetState callbacks (typically only one active)
  void resetState() {
    debugPrint('[ReelsSDK-Flutter] LifecycleService: resetState called (${_resetStateCallbacks.length} callbacks)');
    for (final entry in _resetStateCallbacks.entries) {
      debugPrint('[ReelsSDK-Flutter] LifecycleService: Calling resetState for generation ${entry.key}');
      entry.value?.call();
    }
  }

  /// Called by native to pause all resources
  /// Calls ALL registered pauseAll callbacks (important for multi-engine)
  void pauseAll() {
    debugPrint('[ReelsSDK-Flutter] LifecycleService: pauseAll called (${_pauseAllCallbacks.length} callbacks)');
    for (final entry in _pauseAllCallbacks.entries) {
      debugPrint('[ReelsSDK-Flutter] LifecycleService: Calling pauseAll for generation ${entry.key}');
      entry.value?.call();
    }
  }

  /// Called by native to resume resources for a specific generation
  /// @param generation The generation number to resume
  /// Only calls the callback for the specified generation
  void resumeAll(int generation) {
    debugPrint('[ReelsSDK-Flutter] LifecycleService: resumeAll($generation) called');
    final callback = _resumeAllCallbacks[generation];
    if (callback != null) {
      debugPrint('[ReelsSDK-Flutter] LifecycleService: Calling resumeAll for generation $generation');
      callback(generation);
    } else {
      debugPrint('[ReelsSDK-Flutter] ⚠️  No resumeAll callback for generation $generation (${_resumeAllCallbacks.length} total callbacks)');
      // List all registered generations for debugging
      debugPrint('[ReelsSDK-Flutter] Registered generations: ${_resumeAllCallbacks.keys.toList()}');
    }
  }
}
