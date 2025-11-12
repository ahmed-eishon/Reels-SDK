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
/// // Launch reels screen with collect data
/// let collectData: [String: Any?] = [
///     "id": collect.id,
///     "name": collect.name,
///     "content": collect.content,
///     "likes": Int64(collect.likeCount),
///     "comments": Int64(collect.commentCount),
///     "userName": collect.user?.name,
///     "userProfileImage": collect.user?.profileImageUrl
/// ]
/// ReelsModule.openReels(from: viewController, collectData: collectData)
///
/// // Set listener for events
/// ReelsModule.setListener(self)
/// ```
public class ReelsModule {

    /// Shared instance of the engine manager
    private static let engineManager = ReelsEngineManager.shared

    /// Access token provider closure (async)
    private static var accessTokenProvider: ((@escaping (String?) -> Void) -> Void)?

    /// Reels event listener
    private static weak var listener: ReelsListener?

    /// Presenting view controller (used for navigation from Flutter)
    private static weak var presentingViewController: UIViewController?

    /// Flutter's navigation controller (created when wrapping Flutter VC)
    private static weak var flutterNavigationController: UINavigationController?

    /// Debug mode flag
    private static var debugMode: Bool = false

    /// Stored collect data to pass to Flutter
    private static var initialCollectData: CollectData?

    // MARK: - Initialization

    /// Initialize the Reels module. Call this once in your AppDelegate.
    /// - Parameters:
    ///   - accessTokenProvider: Optional async provider for user access token
    ///   - debug: Enable debug mode to show SDK info screen (default: false)
    public static func initialize(
        accessTokenProvider: ((@escaping (String?) -> Void) -> Void)? = nil,
        debug: Bool = false
    ) {
        self.accessTokenProvider = accessTokenProvider
        self.debugMode = debug
        engineManager.initializeFlutterEngine()
    }

    // MARK: - Launch Methods

    /// Open the Flutter Reels screen
    /// - Parameters:
    ///   - viewController: The view controller to present from
    ///   - initialRoute: Flutter route to navigate to (default: "/")
    ///   - collectData: Optional collect data as dictionary to pass to Flutter
    ///   - animated: Whether to animate the presentation
    ///   - completion: Completion handler called after presentation
    public static func openReels(
        from viewController: UIViewController,
        initialRoute: String = "/",
        collectData: [String: Any?]? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        // Store the presenting view controller for navigation
        presentingViewController = viewController

        // Store collect data if provided
        if let data = collectData {
            initialCollectData = convertDictionaryToCollectData(data)
            print("[ReelsSDK-iOS] Stored collect data: id=\(initialCollectData?.id ?? "nil")")
        } else {
            initialCollectData = nil
            print("[ReelsSDK-iOS] No collect data provided")
        }

        let flutterViewController = engineManager.createFlutterViewController(initialRoute: initialRoute)

        // Wrap Flutter in a navigation controller to enable native screen stacking
        let navigationController = UINavigationController(rootViewController: flutterViewController)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.setNavigationBarHidden(true, animated: false)

        // Store reference to Flutter's navigation controller
        flutterNavigationController = navigationController

        viewController.present(navigationController, animated: animated, completion: completion)
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

    /// Get the presenting view controller
    public static func getPresentingViewController() -> UIViewController? {
        return presentingViewController
    }

    /// Get the Flutter navigation controller for pushing native screens
    public static func getFlutterNavigationController() -> UINavigationController? {
        return flutterNavigationController
    }

    // MARK: - Token Provider

    /// Get access token from provider (async)
    /// This method is called by Pigeon with a completion handler
    internal static func getAccessToken(completion: @escaping (String?) -> Void) {
        guard let provider = accessTokenProvider else {
            completion(nil)
            return
        }

        // Call the async provider and forward the result to completion
        provider { token in
            completion(token)
        }
    }

    // MARK: - Context Data

    /// Get the initial collect data that was passed when opening reels
    /// Returns the collect data if provided, nil otherwise
    internal static func getInitialCollect() -> CollectData? {
        print("[ReelsSDK-iOS] getInitialCollect called, returning: \(initialCollectData?.id ?? "nil")")
        return initialCollectData
    }

    /// Check if debug mode is enabled
    internal static func isDebugMode() -> Bool {
        return debugMode
    }

    /// Get the Flutter engine instance (for advanced use cases like plugin registration)
    public static func getEngine() -> FlutterEngine? {
        return ReelsEngineManager.shared.getEngine()
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

    // MARK: - Helper Methods

    /// Convert dictionary to CollectData
    /// - Parameter dict: Dictionary containing collect data
    /// - Returns: CollectData instance
    private static func convertDictionaryToCollectData(_ dict: [String: Any?]) -> CollectData {
        return CollectData(
            id: dict["id"] as? String ?? "",
            content: dict["content"] as? String,
            name: dict["name"] as? String,
            likes: dict["likes"] as? Int64,
            comments: dict["comments"] as? Int64,
            recollects: dict["recollects"] as? Int64,
            isLiked: dict["isLiked"] as? Bool,
            isCollected: dict["isCollected"] as? Bool,
            trackingTag: dict["trackingTag"] as? String,
            userName: dict["userName"] as? String,
            userProfileImage: dict["userProfileImage"] as? String,
            itemName: dict["itemName"] as? String,
            itemImageUrl: dict["itemImageUrl"] as? String,
            imageUrl: dict["imageUrl"] as? String
        )
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

    /// Called when user clicks on profile/user image
    /// - Parameters:
    ///   - userId: User ID
    ///   - userName: User name
    func onUserProfileClick(userId: String, userName: String)

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
    func onUserProfileClick(userId: String, userName: String) {}
    func onAnalyticsEvent(eventName: String, properties: [String: String]) {}
}
