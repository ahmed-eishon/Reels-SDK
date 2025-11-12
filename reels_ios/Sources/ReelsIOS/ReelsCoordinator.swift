import UIKit
import Flutter

/// Simple coordinator for launching the Flutter reels screen
/// This is a convenience wrapper around ReelsModule for easier usage
public class ReelsCoordinator {

    /// Initialize the Flutter engine (call this once during app startup for better performance)
    /// - Parameter accessTokenProvider: Optional async provider for user access token
    ///   The provider receives a completion handler and should call it with the token (or nil)
    public static func initialize(accessTokenProvider: ((@escaping (String?) -> Void) -> Void)? = nil) {
        ReelsModule.initialize(accessTokenProvider: accessTokenProvider)
    }

    /// Open the reels screen with optional item data
    /// - Parameters:
    ///   - from: The view controller to present from
    ///   - itemId: Optional item ID to display (can be passed via initial route)
    ///   - collectData: Optional collect data as dictionary to pass to Flutter
    ///   - animated: Whether to animate the presentation
    ///   - completion: Completion handler called after presentation
    public static func openReels(
        from viewController: UIViewController,
        itemId: String? = nil,
        collectData: [String: Any?]? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        // Build initial route with item ID if provided
        let initialRoute: String
        if let itemId = itemId {
            initialRoute = "/?itemId=\(itemId)"
        } else {
            initialRoute = "/"
        }

        ReelsModule.openReels(
            from: viewController,
            initialRoute: initialRoute,
            collectData: collectData,
            animated: animated,
            completion: completion
        )
    }

    /// Set listener for reels events
    /// - Parameter listener: Listener to receive events from Flutter
    public static func setListener(_ listener: ReelsListener?) {
        ReelsModule.setListener(listener)
    }

    /// Clean up the Flutter engine (call this when you want to reset)
    public static func cleanup() {
        ReelsModule.cleanup()
    }
}
