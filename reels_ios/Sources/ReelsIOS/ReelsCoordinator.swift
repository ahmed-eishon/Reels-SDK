import UIKit
import Flutter

/// Protocol for handling navigation callbacks from Reels
/// Implement this to handle user profile navigation and other coordinator-level actions
public protocol ReelsCoordinatorDelegate: AnyObject {

    /// Called when user clicks on a profile
    /// Implement this to navigate to your app's user profile screen
    /// - Parameters:
    ///   - userId: User ID
    ///   - userName: User name
    ///   - navigationController: Navigation controller to push onto (optional, from Flutter)
    func reelsDidRequestUserProfile(userId: String, userName: String, navigationController: UINavigationController?)

    /// Called when user swipes left
    /// Implement this to handle custom left swipe action (e.g., open current user's profile)
    /// - Parameter navigationController: Navigation controller to push onto (optional, from Flutter)
    func reelsDidSwipeLeft(navigationController: UINavigationController?)
}

// Make delegate methods optional with default empty implementations
public extension ReelsCoordinatorDelegate {
    func reelsDidRequestUserProfile(userId: String, userName: String, navigationController: UINavigationController?) {}
    func reelsDidSwipeLeft(navigationController: UINavigationController?) {}
}

/// Simple coordinator for launching the Flutter reels screen
/// This is a convenience wrapper around ReelsModule for easier usage
public class ReelsCoordinator {

    /// Delegate for handling navigation callbacks
    private static weak var delegate: ReelsCoordinatorDelegate?

    /// Default listener that handles common cases and delegates navigation
    private static var defaultListener: DefaultReelsListener?

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
    ///   - delegate: Optional delegate for handling navigation callbacks
    ///   - animated: Whether to animate the presentation
    ///   - completion: Completion handler called after presentation
    public static func openReels(
        from viewController: UIViewController,
        itemId: String? = nil,
        collectData: [String: Any?]? = nil,
        delegate: ReelsCoordinatorDelegate? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        // Store delegate
        self.delegate = delegate

        // Create and set default listener if delegate is provided
        if delegate != nil {
            defaultListener = DefaultReelsListener(delegate: delegate)
            ReelsModule.setListener(defaultListener)
        }

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
    /// Note: If you use this, you'll need to handle all events yourself
    /// Consider using the delegate parameter in openReels() instead for common cases
    /// - Parameter listener: Listener to receive events from Flutter
    public static func setListener(_ listener: ReelsListener?) {
        ReelsModule.setListener(listener)
    }

    /// Clear delegate and listener references (called automatically when dismissed)
    internal static func clearReferences() {
        delegate = nil
        defaultListener = nil
    }

    /// Clean up the Flutter engine (call this when you want to reset)
    public static func cleanup() {
        clearReferences()
        ReelsModule.cleanup()
    }
}

/// Default implementation of ReelsListener that handles common cases
/// and delegates navigation to ReelsCoordinatorDelegate
private class DefaultReelsListener: ReelsListener {

    weak var delegate: ReelsCoordinatorDelegate?

    init(delegate: ReelsCoordinatorDelegate?) {
        self.delegate = delegate
    }

    func onLikeButtonClick(videoId: String, isLiked: Bool, likeCount: Int) {
        print("[ReelsSDK] Like button clicked - videoId: \(videoId), isLiked: \(isLiked), likeCount: \(likeCount)")
        // Default: just log, host app can track analytics via their own systems
    }

    func onShareButtonClick(videoId: String, videoUrl: String, title: String, description: String, thumbnailUrl: String?) {
        print("[ReelsSDK] Share button clicked - videoId: \(videoId)")
        // Default: just log, host app can implement native share sheet if needed
    }

    func onScreenStateChanged(screenName: String, state: String) {
        print("[ReelsSDK] Screen state changed - screen: \(screenName), state: \(state)")
        // Default: just log
    }

    func onVideoStateChanged(videoId: String, state: String, position: Int?, duration: Int?) {
        // Default: just log (can be verbose, so commented out)
        // print("[ReelsSDK] Video state changed - videoId: \(videoId), state: \(state)")
    }

    func onSwipeLeft() {
        print("[ReelsSDK] User swiped left")
        let navController = ReelsModule.getFlutterNavigationController()
        delegate?.reelsDidSwipeLeft(navigationController: navController)
    }

    func onSwipeRight() {
        print("[ReelsSDK] User swiped right")
        // Default: do nothing
    }

    func onUserProfileClick(userId: String, userName: String) {
        print("[ReelsSDK] User profile clicked - userId: \(userId), userName: \(userName)")
        let navController = ReelsModule.getFlutterNavigationController()
        delegate?.reelsDidRequestUserProfile(userId: userId, userName: userName, navigationController: navController)
    }

    func onAnalyticsEvent(eventName: String, properties: [String: String]) {
        print("[ReelsSDK] Analytics event - \(eventName): \(properties)")
        // Default: just log, host app should track via their analytics system
    }
}
