import Flutter
import Foundation

/// Pigeon-based handler for type-safe communication between iOS and Flutter
/// Implements the Host API protocols that Flutter can call
class ReelsPigeonHandler: NSObject {

    private weak var flutterEngine: FlutterEngine?

    // Flutter API instances for calling Flutter methods
    private var analyticsApi: ReelsFlutterAnalyticsApi?
    private var buttonEventsApi: ReelsFlutterButtonEventsApi?
    private var stateApi: ReelsFlutterStateApi?
    private var navigationApi: ReelsFlutterNavigationApi?

    init(flutterEngine: FlutterEngine) {
        self.flutterEngine = flutterEngine
        super.init()
    }

    /// Setup Pigeon APIs
    func setupPigeonApis() {
        guard let engine = flutterEngine else { return }
        let messenger = engine.binaryMessenger

        // Setup Host APIs - iOS methods that Flutter can call
        ReelsFlutterTokenApiSetup.setUp(binaryMessenger: messenger, api: self)
        ReelsFlutterContextApiSetup.setUp(binaryMessenger: messenger, api: self)

        // Setup Flutter APIs - Flutter methods that iOS can call
        analyticsApi = ReelsFlutterAnalyticsApi(binaryMessenger: messenger)
        buttonEventsApi = ReelsFlutterButtonEventsApi(binaryMessenger: messenger)
        stateApi = ReelsFlutterStateApi(binaryMessenger: messenger)
        navigationApi = ReelsFlutterNavigationApi(binaryMessenger: messenger)

        // Setup navigation event listeners from Flutter
        setupNavigationEventHandlers(messenger: messenger)
    }

    /// Setup handlers to receive navigation events from Flutter
    private func setupNavigationEventHandlers(messenger: FlutterBinaryMessenger) {
        let codec = FlutterStandardMessageCodec.sharedInstance()

        // Handle swipe left events
        let swipeLeftChannel = FlutterBasicMessageChannel(
            name: "dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.onSwipeLeft",
            binaryMessenger: messenger,
            codec: codec
        )
        swipeLeftChannel.setMessageHandler { message, reply in
            guard let args = message as? [Any],
                  args.count >= 2,
                  let userId = args[0] as? String,
                  let userName = args[1] as? String else {
                print("[ReelsSDK-iOS] Invalid swipe left arguments")
                reply(nil)
                return
            }

            print("[ReelsSDK-iOS] Received swipe left: userId=\(userId), userName=\(userName)")

            // MULTIMODAL FIX: Always use root listener for navigation events
            // This ensures navigation works even when called from nested modals
            let targetListener = ReelsModule.getRootListener() ?? ReelsModule.getListener()
            targetListener?.onSwipeLeft(userId: userId, userName: userName)
            reply(nil)
        }

        // Handle user profile click events
        let userProfileClickChannel = FlutterBasicMessageChannel(
            name: "dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.onUserProfileClick",
            binaryMessenger: messenger,
            codec: codec
        )
        userProfileClickChannel.setMessageHandler { message, reply in
            guard let args = message as? [Any],
                  args.count >= 2,
                  let userId = args[0] as? String,
                  let userName = args[1] as? String else {
                print("[ReelsSDK-iOS] Invalid user profile click arguments")
                reply(nil)
                return
            }

            print("[ReelsSDK-iOS] Received user profile click: userId=\(userId), userName=\(userName)")

            // MULTIMODAL FIX: Always use root listener for navigation events
            // This ensures navigation works even when called from nested modals
            let targetListener = ReelsModule.getRootListener() ?? ReelsModule.getListener()
            targetListener?.onUserProfileClick(userId: userId, userName: userName)
            reply(nil)
        }

        // Handle dismiss reels events (close button)
        let dismissReelsChannel = FlutterBasicMessageChannel(
            name: "dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.dismissReels",
            binaryMessenger: messenger,
            codec: codec
        )
        dismissReelsChannel.setMessageHandler { [weak self] message, reply in
            print("[ReelsSDK-iOS] Received dismiss reels request (close button)")

            // Dismiss the modal presentation and cleanup
            DispatchQueue.main.async {
                // CRITICAL FIX FOR NESTED MODALS:
                // Instead of using the shared static reference (which becomes stale),
                // find the current navigation controller from the engine's attached view controller
                guard let strongSelf = self,
                      let engine = strongSelf.flutterEngine,
                      let flutterVC = engine.viewController,
                      let navController = flutterVC.navigationController,
                      let presentingVC = navController.presentingViewController else {
                    print("[ReelsSDK-iOS] ⚠️ Cannot find required components to dismiss")
                    return
                }

                print("[ReelsSDK-iOS] ✅ Dismissing modal presentation...")
                presentingVC.dismiss(animated: true) {
                    print("[ReelsSDK-iOS] ✅ Modal dismissed successfully")
                    ReelsModule.clearReferences()
                }
            }

            reply(nil)
        }

        // Handle swipe right events (dismiss gesture)
        let swipeRightChannel = FlutterBasicMessageChannel(
            name: "dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.onSwipeRight",
            binaryMessenger: messenger,
            codec: codec
        )
        swipeRightChannel.setMessageHandler { [weak self] message, reply in
            print("[ReelsSDK-iOS] Received swipe right event - dismissing reels")

            // Dismiss the modal presentation and cleanup (same as close button)
            DispatchQueue.main.async {
                // CRITICAL FIX FOR NESTED MODALS:
                // Instead of using the shared static reference (which becomes stale),
                // find the current navigation controller from the engine's attached view controller
                guard let strongSelf = self,
                      let engine = strongSelf.flutterEngine,
                      let flutterVC = engine.viewController,
                      let navController = flutterVC.navigationController,
                      let presentingVC = navController.presentingViewController else {
                    print("[ReelsSDK-iOS] ⚠️ Cannot find required components to dismiss")
                    return
                }

                print("[ReelsSDK-iOS] ✅ Dismissing modal presentation...")
                presentingVC.dismiss(animated: true) {
                    print("[ReelsSDK-iOS] ✅ Modal dismissed successfully")
                    ReelsModule.clearReferences()
                }
            }

            reply(nil)
        }
    }

    // MARK: - Call Flutter Methods

    /// Send analytics event to Flutter
    func trackAnalyticsEvent(eventName: String, properties: [String: String]) {
        let event = AnalyticsEvent(
            eventName: eventName,
            eventProperties: properties
        )
        analyticsApi?.trackEvent(event: event) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("Error tracking analytics event: \(error)")
            }
        }
    }

    /// Notify Flutter about like button click
    func notifyLikeButtonClick(videoId: String, isLiked: Bool, likeCount: Int64) {
        buttonEventsApi?.onAfterLikeButtonClick(
            videoId: videoId,
            isLiked: isLiked,
            likeCount: likeCount
        ) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("Error notifying like button click: \(error)")
            }
        }
    }

    /// Notify Flutter about share button click
    func notifyShareButtonClick(videoId: String, videoUrl: String, title: String, description: String, thumbnailUrl: String?) {
        let shareData = ShareData(
            videoId: videoId,
            videoUrl: videoUrl,
            title: title,
            description: description,
            thumbnailUrl: thumbnailUrl
        )
        buttonEventsApi?.onShareButtonClick(shareData: shareData) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("Error notifying share button click: \(error)")
            }
        }
    }

    /// Notify Flutter about screen state change
    func notifyScreenStateChanged(screenName: String, state: String) {
        let stateData = ScreenStateData(
            screenName: screenName,
            state: state,
            timestamp: Int64(Date().timeIntervalSince1970)
        )
        stateApi?.onScreenStateChanged(state: stateData) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("Error notifying screen state: \(error)")
            }
        }
    }

    /// Notify Flutter about video state change
    func notifyVideoStateChanged(videoId: String, state: String, position: Int64?, duration: Int64?) {
        let stateData = VideoStateData(
            videoId: videoId,
            state: state,
            position: position,
            duration: duration,
            timestamp: Int64(Date().timeIntervalSince1970)
        )
        stateApi?.onVideoStateChanged(state: stateData) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("Error notifying video state: \(error)")
            }
        }
    }
}

// MARK: - ReelsFlutterTokenApi Implementation

extension ReelsPigeonHandler: ReelsFlutterTokenApi {
    /// Get the current access token from native
    func getAccessToken(completion: @escaping (Result<String?, Error>) -> Void) {
        ReelsModule.getAccessToken { token in
            completion(.success(token))
        }
    }
}

// MARK: - ReelsFlutterContextApi Implementation

extension ReelsPigeonHandler: ReelsFlutterContextApi {
    /// Get the initial Collect data that was used to open this screen
    /// - Parameter generation: The generation number of the screen instance
    /// - Returns: CollectData for the specified generation, or nil if not found
    func getInitialCollect(generation: Int64) throws -> CollectData? {
        let collectData = ReelsModule.getInitialCollect(generation: Int(generation))
        if let collect = collectData {
            print("[ReelsSDK-iOS] Returning collect data for generation #\(generation): id=\(collect.id), name=\(collect.name ?? "nil")")
        } else {
            print("[ReelsSDK-iOS] No collect data available for generation #\(generation)")
        }
        return collectData
    }

    /// Get the current generation number
    /// - Returns: Current generation number
    func getCurrentGeneration() throws -> Int64 {
        let generation = ReelsModule.getCurrentGeneration()
        print("[ReelsSDK-iOS] Current generation: \(generation)")
        return Int64(generation)
    }

    /// Check if debug mode is enabled
    func isDebugMode() throws -> Bool {
        let debugMode = ReelsModule.isDebugMode()
        print("[ReelsSDK-iOS] Debug mode: \(debugMode)")
        return debugMode
    }
}
