import UIKit
import Flutter

/// Main entry point for the Reels module.
/// Provides a clean API for the main app to interact with Flutter reels functionality.
///
/// Usage:
/// ```swift
/// // Initialize once in AppDelegate
/// ReelsModule.initialize(accessTokenProvider: {
///     return UserSession.shared.accessToken
/// })
///
/// // Launch reels screen
/// ReelsModule.openReels(from: viewController, initialRoute: "/")
///
/// // Set listener for events
/// ReelsModule.setListener(self)
/// ```
public class ReelsModule {

    /// Shared instance of the engine manager
    private static let engineManager = ReelsEngineManager.shared

    /// Access token provider closure
    private static var accessTokenProvider: (() -> String?)?

    /// Reels event listener
    private static weak var listener: ReelsListener?

    // MARK: - Initialization

    /// Initialize the Reels module. Call this once in your AppDelegate.
    /// - Parameter accessTokenProvider: Optional provider for user access token
    public static func initialize(accessTokenProvider: (() -> String?)? = nil) {
        self.accessTokenProvider = accessTokenProvider
        engineManager.initializeFlutterEngine()
    }

    // MARK: - Launch Methods

    /// Open the Flutter Reels screen
    /// - Parameters:
    ///   - viewController: The view controller to present from
    ///   - initialRoute: Flutter route to navigate to (default: "/")
    ///   - animated: Whether to animate the presentation
    ///   - completion: Completion handler called after presentation
    public static func openReels(
        from viewController: UIViewController,
        initialRoute: String = "/",
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let flutterViewController = engineManager.createFlutterViewController(initialRoute: initialRoute)
        flutterViewController.modalPresentationStyle = .fullScreen

        viewController.present(flutterViewController, animated: animated, completion: completion)
    }

    /// Create a Flutter view controller for custom presentation
    /// - Parameter initialRoute: Flutter route to navigate to (default: "/")
    /// - Returns: FlutterViewController instance
    public static func createViewController(initialRoute: String = "/") -> FlutterViewController {
        return engineManager.createFlutterViewController(initialRoute: initialRoute)
    }

    // MARK: - Listener

    /// Set listener for reels events
    /// - Parameter listener: Listener to receive events from Flutter
    public static func setListener(_ listener: ReelsListener?) {
        self.listener = listener
        engineManager.setListener(listener)
    }

    /// Get the current listener
    internal static func getListener() -> ReelsListener? {
        return listener
    }

    // MARK: - Token Provider

    /// Get access token from provider
    internal static func getAccessToken() -> String? {
        return accessTokenProvider?()
    }

    // MARK: - Analytics

    /// Track analytics event
    /// - Parameters:
    ///   - eventName: Name of the event
    ///   - properties: Event properties
    public static func trackEvent(eventName: String, properties: [String: String] = [:]) {
        // Forward to listener for native analytics tracking
        listener?.onAnalyticsEvent(eventName: eventName, properties: properties)
    }

    // MARK: - Cleanup

    /// Clean up resources when the app is destroyed
    public static func cleanup() {
        engineManager.destroyFlutterEngine()
    }

    // MARK: - Routes

    /// Available Flutter routes
    public enum Routes {
        public static let home = "/"
        public static let reels = "/reels"
        public static let profile = "/profile"
    }
}

/// Protocol for receiving events from Flutter reels
public protocol ReelsListener: AnyObject {

    /// Called when user performs a like action
    /// - Parameters:
    ///   - videoId: Video ID that was liked
    ///   - isLiked: Whether the video is now liked
    ///   - likeCount: Updated like count
    func onLikeButtonClick(videoId: String, isLiked: Bool, likeCount: Int)

    /// Called when user shares a video
    /// - Parameters:
    ///   - videoId: Video ID
    ///   - videoUrl: URL of the video
    ///   - title: Video title
    ///   - description: Video description
    ///   - thumbnailUrl: Optional thumbnail URL
    func onShareButtonClick(videoId: String, videoUrl: String, title: String, description: String, thumbnailUrl: String?)

    /// Called when screen state changes
    /// - Parameters:
    ///   - screenName: Screen name
    ///   - state: State (appeared, disappeared, focused, unfocused)
    func onScreenStateChanged(screenName: String, state: String)

    /// Called when video state changes
    /// - Parameters:
    ///   - videoId: Video ID
    ///   - state: State (playing, paused, stopped, buffering, completed)
    ///   - position: Current position in seconds (optional)
    ///   - duration: Total duration in seconds (optional)
    func onVideoStateChanged(videoId: String, state: String, position: Int?, duration: Int?)

    /// Called when user swipes left
    func onSwipeLeft()

    /// Called when user swipes right
    func onSwipeRight()

    /// Called when analytics event is tracked
    /// - Parameters:
    ///   - eventName: Event name
    ///   - properties: Event properties
    func onAnalyticsEvent(eventName: String, properties: [String: String])
}

// Make all methods optional with default empty implementations
public extension ReelsListener {
    func onLikeButtonClick(videoId: String, isLiked: Bool, likeCount: Int) {}
    func onShareButtonClick(videoId: String, videoUrl: String, title: String, description: String, thumbnailUrl: String?) {}
    func onScreenStateChanged(screenName: String, state: String) {}
    func onVideoStateChanged(videoId: String, state: String, position: Int?, duration: Int?) {}
    func onSwipeLeft() {}
    func onSwipeRight() {}
    func onAnalyticsEvent(eventName: String, properties: [String: String]) {}
}
