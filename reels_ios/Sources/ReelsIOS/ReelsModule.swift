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

    /// Reels event listener (current listener, may be from nested modal)
    private static weak var listener: ReelsListener?

    /// Root listener - the original app listener that can handle navigation
    /// This is captured when first opening reels and never changed
    /// Used to fix multimodal Y-pattern navigation where f2→n3 needs to bypass f1's listener
    private static weak var rootListener: ReelsListener?

    /// Presenting view controller (used for navigation from Flutter)
    private static weak var presentingViewController: UIViewController?

    /// Flutter's navigation controller (created when wrapping Flutter VC)
    private static weak var flutterNavigationController: UINavigationController?

    /// Debug mode flag
    private static var debugMode: Bool = false

    /// Stored collect data by generation number to support nested modals
    /// Each screen instance has its own collect data keyed by generation
    private static var collectDataByGeneration: [Int: CollectData] = [:]

    // MARK: - SDK Info

    /// SDK version
    public static let sdkVersion = "1.0.0"

    /// SDK generation number - increments each time reels screen is opened
    /// Used to track lifecycle across nested modal presentations
    private static var generationNumber: Int = 0

    /// Get current SDK info
    public static func getSDKInfo() -> SDKInfo {
        return SDKInfo(
            version: sdkVersion,
            generation: generationNumber,
            debugMode: debugMode
        )
    }

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
        // Increment generation number for each new presentation
        generationNumber += 1
        print("[ReelsSDK-iOS] 🎬 Opening Reels - Generation #\(generationNumber) | Version: \(sdkVersion)")

        // Store the presenting view controller for navigation
        presentingViewController = viewController

        // Store collect data by generation number to support nested modals
        if let data = collectData {
            let collectDataObj = convertDictionaryToCollectData(data)
            collectDataByGeneration[generationNumber] = collectDataObj
            print("[ReelsSDK-iOS] ✅ Stored collect data for generation #\(generationNumber): id=\(collectDataObj.id), name=\(collectDataObj.name ?? "nil")")
        } else {
            collectDataByGeneration[generationNumber] = nil
            print("[ReelsSDK-iOS] ⚠️ No collect data provided for generation #\(generationNumber)")
        }
        print("[ReelsSDK-iOS] Total stored collect data entries: \(collectDataByGeneration.count)")

        let flutterViewController = engineManager.createFlutterViewController(initialRoute: initialRoute)

        // Wrap Flutter VC to handle navigation bar visibility
        // Pass the generation number so wrapper knows which screen instance it represents
        let wrapper = FlutterViewControllerWrapper(flutterViewController: flutterViewController, generation: generationNumber)

        // Wrap Flutter in a navigation controller to enable native screen stacking
        let navigationController = UINavigationController(rootViewController: wrapper)
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

        // Capture root listener on first set (when rootListener is nil)
        // This is the original app listener that can handle navigation
        if rootListener == nil && listener != nil {
            rootListener = listener
            print("[ReelsSDK-iOS] Captured root listener: \(String(describing: type(of: listener)))")
        }

        engineManager.setListener(listener)
    }

    /// Get the current listener
    internal static func getListener() -> ReelsListener? {
        return listener
    }

    /// Get the root listener (original app listener)
    /// Used for multimodal navigation to bypass nested modal listeners
    internal static func getRootListener() -> ReelsListener? {
        return rootListener
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

    /// Get the initial collect data for a specific generation
    /// - Parameter generation: The generation number of the screen instance
    /// - Returns: CollectData for the specified generation, or nil if not found
    internal static func getInitialCollect(generation: Int) -> CollectData? {
        let collectData = collectDataByGeneration[generation]
        print("[ReelsSDK-iOS] getInitialCollect(generation: \(generation)) called, returning: \(collectData?.id ?? "nil")")
        return collectData
    }

    /// Get the current generation number
    /// - Returns: Current generation number
    internal static func getCurrentGeneration() -> Int {
        return generationNumber
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

    /// Clear references when reels screen is dismissed
    internal static func clearReferences() {
        presentingViewController = nil
        flutterNavigationController = nil
        listener = nil
        rootListener = nil  // Clear root listener when all reels screens are dismissed
        // Note: We don't clear collectDataByGeneration here because multiple
        // nested modals may exist simultaneously. Each generation's data is
        // managed independently and will be cleared when no longer needed.

        // Also clear ReelsCoordinator references
        ReelsCoordinator.clearReferences()
        print("[ReelsSDK] All references cleared")
    }

    /// Clean up resources when the app is destroyed (call this only when destroying the engine)
    public static func cleanup() {
        clearReferences()
        engineManager.destroyFlutterEngine()
    }

    /// Clean up collect data for a specific generation when the screen is closed
    /// This prevents memory leaks from accumulating collectData across many screen instances
    ///
    /// - Parameter generation: The generation number to clean up
    internal static func cleanupGeneration(_ generation: Int) {
        if let removed = collectDataByGeneration.removeValue(forKey: generation) {
            print("[ReelsSDK-iOS] 🗑️ Cleaned up collectData for generation #\(generation) (id=\(removed.id))")
        } else {
            print("[ReelsSDK-iOS] ⚠️ No collectData found for generation #\(generation)")
        }
        print("[ReelsSDK-iOS]    Remaining generations in memory: \(collectDataByGeneration.count)")
    }

    /// Pause Flutter resources (videos, network) when screen loses focus
    internal static func pauseFlutter() {
        print("[ReelsSDK-DEBUG] ⏸️ pauseFlutter() called")

        guard let engine = engineManager.getEngine() else {
            print("[ReelsSDK-DEBUG] ❌ Cannot pause - no Flutter engine")
            return
        }

        print("[ReelsSDK-DEBUG] 📞 Calling Flutter pauseAll API")
        let lifecycleApi = ReelsFlutterLifecycleApi(binaryMessenger: engine.binaryMessenger)
        lifecycleApi.pauseAll { result in
            switch result {
            case .success:
                print("[ReelsSDK-DEBUG] ✅ Flutter resources paused successfully")
            case .failure(let error):
                print("[ReelsSDK-DEBUG] ❌ Error pausing Flutter resources: \(error)")
            }
        }
    }

    /// Resume Flutter resources (videos, network) when screen gains focus
    /// - Parameter generation: The generation number of the screen being resumed
    internal static func resumeFlutter(generation: Int) {
        print("[ReelsSDK-DEBUG] ▶️ resumeFlutter(generation: \(generation)) called")

        guard let engine = engineManager.getEngine() else {
            print("[ReelsSDK-DEBUG] ❌ Cannot resume - no Flutter engine")
            return
        }

        print("[ReelsSDK-DEBUG] 📞 Calling Flutter resumeAll(\(generation)) API")
        let lifecycleApi = ReelsFlutterLifecycleApi(binaryMessenger: engine.binaryMessenger)
        lifecycleApi.resumeAll(generation: Int64(generation)) { result in
            switch result {
            case .success:
                print("[ReelsSDK-DEBUG] ✅ Flutter resources resumed successfully for generation \(generation)")
            case .failure(let error):
                print("[ReelsSDK-DEBUG] ❌ Error resuming Flutter resources: \(error)")
            }
        }
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
            userId: dict["userId"] as? String,
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

    /// Called when user swipes left (opens user's My Room)
    /// - Parameters:
    ///   - userId: User ID to navigate to
    ///   - userName: User name for display
    func onSwipeLeft(userId: String, userName: String)

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
    func onSwipeLeft(userId: String, userName: String) {}
    func onSwipeRight() {}
    func onUserProfileClick(userId: String, userName: String) {}
    func onAnalyticsEvent(eventName: String, properties: [String: String]) {}
}

/// Wrapper view controller that ensures navigation bar is hidden when Flutter screen appears
private class FlutterViewControllerWrapper: UIViewController {

    private let flutterViewController: FlutterViewController

    /// The generation number of this specific screen instance
    /// Each modal presentation gets a unique generation number
    private let generation: Int

    /// Track if this view controller instance has been initialized with resetState
    /// Only call resumeAll if we've been initialized, otherwise we have no state to resume
    private var hasBeenInitialized = false

    init(flutterViewController: FlutterViewController, generation: Int) {
        self.flutterViewController = flutterViewController
        self.generation = generation
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add Flutter view controller as child
        addChild(flutterViewController)
        view.addSubview(flutterViewController.view)
        flutterViewController.view.frame = view.bounds
        flutterViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        flutterViewController.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print("[ReelsSDK-DEBUG] 🟢 viewWillAppear - START")
        print("[ReelsSDK-DEBUG]   isMovingToParent: \(isMovingToParent)")
        print("[ReelsSDK-DEBUG]   isBeingPresented: \(isBeingPresented)")
        print("[ReelsSDK-DEBUG]   view.frame: \(view.frame)")
        print("[ReelsSDK-DEBUG]   flutterView.frame BEFORE: \(flutterViewController.view.frame)")

        // Always hide navigation bar when Flutter screen appears
        // This ensures the bar is hidden even when navigating back from native screens
        navigationController?.setNavigationBarHidden(true, animated: animated)

        // CRITICAL FIX FOR NESTED MODALS:
        // Re-attach this view controller to the engine if it was detached
        // This happens when another Reels modal was opened on top of this one
        // Each engine can only have one active view controller, so we must re-attach
        // when coming back to this view controller in the stack
        let engine = ReelsEngineManager.shared.getEngine()
        if engine?.viewController !== flutterViewController {
            print("[ReelsSDK-DEBUG]   🔗 Re-attaching view controller to engine (was detached by nested modal)")
            engine?.viewController = flutterViewController
        } else {
            print("[ReelsSDK-DEBUG]   ✅ View controller already attached to engine")
        }

        // Ensure Flutter view frame is correct when coming back
        // This fixes layout corruption after multiple navigation cycles
        flutterViewController.view.frame = view.bounds
        print("[ReelsSDK-DEBUG]   flutterView.frame AFTER: \(flutterViewController.view.frame)")

        // Resume Flutter resources when navigating back
        // Check if we're appearing after being pushed off the stack
        // IMPORTANT: Only resume if this view has been initialized, otherwise we have no state to resume
        if isMovingToParent == false && isBeingPresented == false {
            if hasBeenInitialized {
                print("[ReelsSDK-DEBUG]   🔄 Will resume Flutter resources for generation \(generation)")
                ReelsModule.resumeFlutter(generation: generation)
            } else {
                print("[ReelsSDK-DEBUG]   ⏭️ Skipping resume - view not yet initialized")
            }
        }

        print("[ReelsSDK-DEBUG] 🟢 viewWillAppear - END")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        print("[ReelsSDK-DEBUG] 🟢 viewDidAppear")
        print("[ReelsSDK-DEBUG]   view.frame: \(view.frame)")
        print("[ReelsSDK-DEBUG]   flutterView.frame: \(flutterViewController.view.frame)")
        print("[ReelsSDK-DEBUG]   navigationController: \(String(describing: navigationController))")

        // Mark view as initialized after it has appeared
        // This ensures resetState has been called and the view is ready
        hasBeenInitialized = true
        print("[ReelsSDK-DEBUG]   ✅ View controller marked as initialized")

        // Child view controller automatically receives lifecycle callbacks
        // No need to call manually
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        print("[ReelsSDK-DEBUG] 📐 viewDidLayoutSubviews")
        print("[ReelsSDK-DEBUG]   view.bounds: \(view.bounds)")
        print("[ReelsSDK-DEBUG]   flutterView.frame BEFORE: \(flutterViewController.view.frame)")

        // Ensure Flutter view always matches parent bounds
        // This prevents layout corruption after navigation
        flutterViewController.view.frame = view.bounds

        print("[ReelsSDK-DEBUG]   flutterView.frame AFTER: \(flutterViewController.view.frame)")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        print("[ReelsSDK-DEBUG] 🔴 viewWillDisappear - START")
        print("[ReelsSDK-DEBUG]   isBeingDismissed: \(isBeingDismissed)")
        print("[ReelsSDK-DEBUG]   isMovingFromParent: \(isMovingFromParent)")

        // Pause Flutter resources when navigating away (but not when dismissing)
        if !isBeingDismissed && !isMovingFromParent {
            print("[ReelsSDK-DEBUG]   ⏸️ Will pause Flutter resources")
            ReelsModule.pauseFlutter()
        } else {
            print("[ReelsSDK-DEBUG]   🗑️ Final dismissal - resetting initialization flag")
            // Reset the flag so next presentation will NOT call resumeAll inappropriately
            hasBeenInitialized = false
        }

        print("[ReelsSDK-DEBUG] 🔴 viewWillDisappear - END")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        print("[ReelsSDK-DEBUG] 🔴 viewDidDisappear - START")
        print("[ReelsSDK-DEBUG]   isBeingDismissed: \(isBeingDismissed)")
        print("[ReelsSDK-DEBUG]   isMovingFromParent: \(isMovingFromParent)")

        // If this is the final dismissal (not just navigation to another screen)
        if isBeingDismissed || isMovingFromParent {
            print("[ReelsSDK-DEBUG]   🗑️ Cleaning up Flutter view controller")

            // Clean up generation data to prevent memory leaks
            if generation > 0 {
                ReelsModule.cleanupGeneration(generation)
                print("[ReelsSDK-DEBUG]   View controller being dismissed, cleaned up generation #\(generation)")
            }

            // Remove Flutter view controller as child
            flutterViewController.willMove(toParent: nil)
            flutterViewController.view.removeFromSuperview()
            flutterViewController.removeFromParent()
        } else {
            print("[ReelsSDK-DEBUG]   ℹ️ Keeping Flutter view controller in hierarchy (navigation?) - keeping data")
        }

        print("[ReelsSDK-DEBUG] 🔴 viewDidDisappear - END")
    }

    deinit {
        print("[ReelsSDK] FlutterViewControllerWrapper deallocated")
        // Note: Flag is reset in viewWillDisappear, not here, to ensure proper timing
    }
}

// MARK: - SDK Info

/// SDK information struct
public struct SDKInfo {
    /// SDK version
    public let version: String

    /// Generation number - increments each time reels screen is opened
    /// Useful for tracking lifecycle across nested modal presentations
    public let generation: Int

    /// Debug mode flag
    public let debugMode: Bool

    /// Human-readable description
    public var description: String {
        return "ReelsSDK v\(version) (Generation #\(generation)) - Debug: \(debugMode ? "ON" : "OFF")"
    }
}
