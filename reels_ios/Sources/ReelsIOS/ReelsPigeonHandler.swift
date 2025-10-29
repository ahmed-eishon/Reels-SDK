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

        // Setup Host API - iOS methods that Flutter can call
        ReelsFlutterTokenApiSetup.setUp(binaryMessenger: messenger, api: self)

        // Setup Flutter APIs - Flutter methods that iOS can call
        analyticsApi = ReelsFlutterAnalyticsApi(binaryMessenger: messenger)
        buttonEventsApi = ReelsFlutterButtonEventsApi(binaryMessenger: messenger)
        stateApi = ReelsFlutterStateApi(binaryMessenger: messenger)
        navigationApi = ReelsFlutterNavigationApi(binaryMessenger: messenger)
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
    func getAccessToken() throws -> String? {
        return ReelsModule.getAccessToken()
    }
}
