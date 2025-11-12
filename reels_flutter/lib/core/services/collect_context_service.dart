import '../pigeon_generated.dart';

/// Service for managing Collect context data from native platform
class CollectContextService {
  CollectContextService({
    required this.getCollectCallback,
    required this.isDebugModeCallback,
  });

  /// Callback to get initial Collect from native
  final Future<CollectData?> Function() getCollectCallback;

  /// Callback to check if debug mode is enabled
  final Future<bool> Function() isDebugModeCallback;

  /// Get the initial Collect data that was used to open this screen
  /// Returns null if screen was not opened from a Collect
  Future<CollectData?> getInitialCollect() async {
    try {
      final result = await getCollectCallback();
      return result;
    } catch (e) {
      return null;
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
