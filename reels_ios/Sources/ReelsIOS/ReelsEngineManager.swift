import Flutter
import Foundation

/// Manages Flutter engine lifecycle and communication
class ReelsEngineManager {

    // MARK: - Singleton

    static let shared = ReelsEngineManager()

    // MARK: - Properties

    private var flutterEngine: FlutterEngine?
    private var pigeonHandler: ReelsPigeonHandler?
    private weak var listener: ReelsListener?

    private init() {}

    // MARK: - Engine Management

    /// Initialize the Flutter engine
    func initializeFlutterEngine() {
        guard flutterEngine == nil else {
            print("Flutter engine already initialized")
            return
        }

        // Create Flutter engine with a unique name
        let engine = FlutterEngine(name: "reels_flutter_engine")

        // Run the engine with the main Dart entrypoint
        // This ensures the Flutter app is properly started
        engine.run(withEntrypoint: nil)

        // Register Flutter plugins (including video_player)
        // This is critical for Add-to-App scenarios where plugins need explicit registration
        // TODO: Fix plugin registration - GeneratedPluginRegistrant not accessible from ReelsIOS module
        // GeneratedPluginRegistrant.register(with: engine)

        // Setup Pigeon handler
        let handler = ReelsPigeonHandler(flutterEngine: engine)
        handler.setupPigeonApis()

        self.flutterEngine = engine
        self.pigeonHandler = handler

        print("Flutter engine initialized successfully")
    }

    /// Create a Flutter view controller
    /// - Parameter initialRoute: Initial route to navigate to
    /// - Returns: FlutterViewController instance
    func createFlutterViewController(initialRoute: String = "/") -> FlutterViewController {
        // Ensure engine is initialized
        if flutterEngine == nil {
            initializeFlutterEngine()
        }

        guard let engine = flutterEngine else {
            fatalError("Flutter engine not initialized")
        }

        // Create view controller with the engine
        // Note: Don't call setInitialRoute after engine is already running
        // The Flutter app is already running, so we just attach the view controller
        let viewController = FlutterViewController(
            engine: engine,
            nibName: nil,
            bundle: nil
        )

        // Setup dismiss channel
        setupDismissChannel(for: viewController, engine: engine)

        return viewController
    }

    /// Setup method channel to handle dismiss requests from Flutter
    private func setupDismissChannel(for viewController: FlutterViewController, engine: FlutterEngine) {
        let channel = FlutterMethodChannel(
            name: "reels_flutter/dismiss",
            binaryMessenger: engine.binaryMessenger
        )

        channel.setMethodCallHandler { [weak viewController] (call, result) in
            if call.method == "dismiss" {
                // Dismiss the view controller on the main thread
                DispatchQueue.main.async {
                    viewController?.dismiss(animated: true, completion: nil)
                    result(nil)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    /// Destroy the Flutter engine
    func destroyFlutterEngine() {
        flutterEngine?.destroyContext()
        flutterEngine = nil
        pigeonHandler = nil
        print("Flutter engine destroyed")
    }

    // MARK: - Listener Management

    /// Set the reels listener
    /// - Parameter listener: Listener to receive events
    func setListener(_ listener: ReelsListener?) {
        self.listener = listener
    }

    /// Get the current listener
    func getListener() -> ReelsListener? {
        return listener
    }

    // MARK: - Communication with Flutter

    /// Track analytics event in Flutter
    /// - Parameters:
    ///   - eventName: Event name
    ///   - properties: Event properties
    func trackAnalyticsEvent(eventName: String, properties: [String: String]) {
        pigeonHandler?.trackAnalyticsEvent(eventName: eventName, properties: properties)
    }

    /// Notify Flutter about like button click
    /// - Parameters:
    ///   - videoId: Video ID
    ///   - isLiked: Whether liked
    ///   - likeCount: Like count
    func notifyLikeButtonClick(videoId: String, isLiked: Bool, likeCount: Int) {
        pigeonHandler?.notifyLikeButtonClick(
            videoId: videoId,
            isLiked: isLiked,
            likeCount: Int64(likeCount)
        )
    }

    /// Notify Flutter about share button click
    /// - Parameters:
    ///   - videoId: Video ID
    ///   - videoUrl: Video URL
    ///   - title: Title
    ///   - description: Description
    ///   - thumbnailUrl: Thumbnail URL
    func notifyShareButtonClick(
        videoId: String,
        videoUrl: String,
        title: String,
        description: String,
        thumbnailUrl: String?
    ) {
        pigeonHandler?.notifyShareButtonClick(
            videoId: videoId,
            videoUrl: videoUrl,
            title: title,
            description: description,
            thumbnailUrl: thumbnailUrl
        )
    }

    /// Notify Flutter about screen state change
    /// - Parameters:
    ///   - screenName: Screen name
    ///   - state: State
    func notifyScreenStateChanged(screenName: String, state: String) {
        pigeonHandler?.notifyScreenStateChanged(screenName: screenName, state: state)
    }

    /// Notify Flutter about video state change
    /// - Parameters:
    ///   - videoId: Video ID
    ///   - state: State
    ///   - position: Position in seconds
    ///   - duration: Duration in seconds
    func notifyVideoStateChanged(
        videoId: String,
        state: String,
        position: Int?,
        duration: Int?
    ) {
        pigeonHandler?.notifyVideoStateChanged(
            videoId: videoId,
            state: state,
            position: position.map { Int64($0) },
            duration: duration.map { Int64($0) }
        )
    }

    // MARK: - Engine Status

    /// Check if engine is initialized
    var isEngineInitialized: Bool {
        return flutterEngine != nil
    }

    /// Get the Flutter engine (for advanced use cases)
    func getEngine() -> FlutterEngine? {
        return flutterEngine
    }
}
