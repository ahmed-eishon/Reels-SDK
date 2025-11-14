import '../pigeon_generated.dart';

/// Service for managing Collect context data from native platform
class CollectContextService {
  CollectContextService({
    required this.getCollectByGenerationCallback,
    required this.getCurrentGenerationCallback,
    required this.isDebugModeCallback,
  });

  /// Callback to get Collect data by generation from native
  final Future<CollectData?> Function(int generation) getCollectByGenerationCallback;

  /// Callback to get current generation number from native
  final Future<int> Function() getCurrentGenerationCallback;

  /// Callback to check if debug mode is enabled
  final Future<bool> Function() isDebugModeCallback;

  /// Get the initial Collect data that was used to open this screen
  /// Fetches the current generation number and returns the collect data for that generation
  /// Returns null if screen was not opened from a Collect
  Future<CollectData?> getInitialCollect() async {
    print('[ReelsSDK-Flutter] CollectContextService.getInitialCollect() called');
    try {
      // First, get the current generation number
      final generation = await getCurrentGenerationCallback();
      print('[ReelsSDK-Flutter] - Current generation: $generation');

      // Then get the collect data for this generation
      final result = await getCollectByGenerationCallback(generation);
      print('[ReelsSDK-Flutter] - getCollectCallback(generation: $generation) returned: ${result != null ? "CollectData(id: ${result.id})" : "null"}');
      return result;
    } catch (e) {
      print('[ReelsSDK-Flutter] - getCollectCallback ERROR: $e');
      return null;
    }
  }

  /// Get the Collect data for a specific generation number
  /// Use this when you already know the generation number (e.g., stored in screen state)
  /// Returns null if no collect data exists for that generation
  Future<CollectData?> getCollectForGeneration(int generation) async {
    print('[ReelsSDK-Flutter] CollectContextService.getCollectForGeneration($generation) called');
    try {
      final result = await getCollectByGenerationCallback(generation);
      print('[ReelsSDK-Flutter] - getCollectCallback(generation: $generation) returned: ${result != null ? "CollectData(id: ${result.id})" : "null"}');
      return result;
    } catch (e) {
      print('[ReelsSDK-Flutter] - getCollectCallback ERROR: $e');
      return null;
    }
  }

  /// Get the current generation number from native
  /// Returns 0 if there's an error
  Future<int> getCurrentGeneration() async {
    try {
      final result = await getCurrentGenerationCallback();
      return result;
    } catch (e) {
      print('[ReelsSDK-Flutter] - getCurrentGeneration ERROR: $e');
      return 0;
    }
  }

  /// Check if debug mode is enabled
  /// Returns false if there's an error
  Future<bool> isDebugMode() async {
    try {
      final result = await isDebugModeCallback();
      return result;
    } catch (e) {
      return false;
    }
  }
}
