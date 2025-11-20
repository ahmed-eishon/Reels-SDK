package com.rakuten.room.reels

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.fragment.app.Fragment
import com.rakuten.room.reels.flutter.FlutterReelsActivity
import com.rakuten.room.reels.flutter.FlutterReelsFragment
import com.rakuten.room.reels.flutter.ReelsFlutterSDK
import com.rakuten.room.reels.flutter.ReelsListener

/**
 * Main entry point for the Reels module.
 * Provides a clean API for the main app to interact with Flutter reels functionality.
 *
 * Usage:
 * ```kotlin
 * // Initialize once in Application class
 * ReelsModule.initialize(context, accessTokenProvider = {
 *     UserSession.accessToken
 * })
 *
 * // Launch reels screen
 * ReelsModule.openReels(activity)
 *
 * // Launch reels screen with collect data
 * val collectData = CollectData(
 *     id = collect.id,
 *     name = collect.name,
 *     content = collect.content,
 *     likes = collect.likeCount.toLong(),
 *     comments = collect.commentCount.toLong(),
 *     userName = collect.user?.name,
 *     userProfileImage = collect.user?.profileImageUrl
 * )
 * ReelsModule.openReels(activity, collectData = collectData)
 *
 * // Set listener for events
 * ReelsModule.setListener(listener)
 * ```
 */
object ReelsModule {

    private const val TAG = "[ReelsSDK-Android]"

    // MARK: - SDK Info

    /**
     * SDK version
     */
    const val SDK_VERSION = "1.0.0"

    /**
     * SDK generation number - increments each time reels screen is opened
     * Used to track lifecycle across nested modal presentations
     */
    private var generationNumber: Int = 0

    /**
     * Stored collect data by generation number to support nested modals
     * Each screen instance has its own collect data keyed by generation
     */
    private val collectDataByGeneration: MutableMap<Int, CollectData?> = mutableMapOf()

    /**
     * Debug mode flag
     */
    private var debugMode: Boolean = false

    /**
     * Get SDK info
     */
    fun getSDKInfo(): SDKInfo {
        return SDKInfo(
            version = SDK_VERSION,
            generation = generationNumber,
            debugMode = debugMode
        )
    }

    // MARK: - Initialization

    /**
     * Initialize the Reels module. Call this once in your Application class.
     * @param context Application context
     * @param accessTokenProvider Optional provider for user access token
     * @param debug Enable debug mode to show SDK info screen (default: false)
     */
    fun initialize(
        context: Context,
        accessTokenProvider: (() -> String?)? = null,
        debug: Boolean = false
    ) {
        this.debugMode = debug
        ReelsFlutterSDK.initialize(context, accessTokenProvider)
        Log.d(TAG, "🎬 ReelsSDK initialized - Version: $SDK_VERSION, Debug: $debug")
    }

    // MARK: - Launch Methods

    /**
     * Open the Flutter Reels screen directly
     * @param activity Activity to launch from
     * @param initialRoute Flutter route to navigate to (default: "/" - reels screen)
     * @param collectData Optional collect data to pass to Flutter
     * @param animated Whether to animate the presentation (default: true)
     */
    fun openReels(
        activity: Activity,
        initialRoute: String = "/",
        collectData: CollectData? = null,
        animated: Boolean = true
    ) {
        // Increment generation number for each new presentation
        generationNumber++
        Log.d(TAG, "🎬 Opening Reels - Generation #$generationNumber | Version: $SDK_VERSION")

        // Store collect data by generation number to support nested modals
        if (collectData != null) {
            collectDataByGeneration[generationNumber] = collectData
            Log.d(TAG, "✅ Stored collect data for generation #$generationNumber: id=${collectData.id}, name=${collectData.name}")
        } else {
            collectDataByGeneration[generationNumber] = null
            Log.d(TAG, "⚠️ No collect data provided for generation #$generationNumber")
        }
        Log.d(TAG, "📊 Total stored collect data entries: ${collectDataByGeneration.size}")

        val intent = createReelsIntent(
            activity,
            initialRoute = initialRoute,
            collectData = collectData,
            generation = generationNumber
        )

        // Apply animation override if needed
        activity.startActivity(intent)
        if (!animated) {
            activity.overridePendingTransition(0, 0)
        }
    }

    /**
     * Create an intent to launch the Flutter Reels in full-screen mode
     * @param context Context
     * @param initialRoute Flutter route to navigate to (default: "/" - reels screen)
     * @param accessToken Optional access token for authenticated content
     * @param collectData Optional collect data to pass to Flutter
     * @param generation Generation number for this instance (auto-assigned if not provided)
     * @return Intent to start the Flutter activity
     */
    fun createReelsIntent(
        context: Context,
        initialRoute: String = "/",
        accessToken: String? = null,
        collectData: CollectData? = null,
        generation: Int? = null
    ): Intent {
        // Use provided generation or assign a new one
        val actualGeneration = generation ?: run {
            generationNumber++
            generationNumber
        }

        // Store collect data by generation number if not already stored
        if (generation == null && collectData != null) {
            collectDataByGeneration[actualGeneration] = collectData
            Log.d(TAG, "✅ Stored collect data for generation #$actualGeneration: id=${collectData.id}, name=${collectData.name}")
        } else if (generation == null) {
            collectDataByGeneration[actualGeneration] = null
            Log.d(TAG, "⚠️ No collect data provided for generation #$actualGeneration")
        }

        val intent = FlutterReelsActivity.createIntent(context, initialRoute, accessToken)

        // Add collect data and generation to intent
        collectData?.let {
            intent.putExtra(FlutterReelsActivity.EXTRA_COLLECT_DATA, it)
        }
        intent.putExtra(FlutterReelsActivity.EXTRA_GENERATION, actualGeneration)

        return intent
    }

    /**
     * Create a fragment to embed Flutter Reels in existing screens
     * @param initialRoute Flutter route to navigate to (default: "/")
     * @param collectData Optional collect data to pass to Flutter
     * @return Fragment containing Flutter reels
     */
    fun createReelsFragment(
        initialRoute: String = "/",
        collectData: CollectData? = null
    ): Fragment {
        generationNumber++
        collectDataByGeneration[generationNumber] = collectData
        return FlutterReelsFragment.newInstance(initialRoute, collectData, generationNumber)
    }

    // MARK: - Listener

    /**
     * Set listener for reels events
     * @param listener Listener to receive events from Flutter
     */
    fun setListener(listener: ReelsListener?) {
        ReelsFlutterSDK.setListener(listener)
    }

    // MARK: - Context Data

    /**
     * Get the initial collect data for a specific generation
     * @param generation The generation number of the screen instance
     * @return CollectData for the specified generation, or null if not found
     */
    internal fun getInitialCollect(generation: Int): CollectData? {
        val collectData = collectDataByGeneration[generation]
        Log.d(TAG, "📦 getInitialCollect(generation: $generation) called, returning: ${collectData?.id ?: "null"}")
        return collectData
    }

    /**
     * Get the current generation number
     * @return Current generation number
     */
    fun getCurrentGeneration(): Int {
        return generationNumber
    }

    /**
     * Check if debug mode is enabled
     */
    internal fun isDebugMode(): Boolean {
        return debugMode
    }

    // MARK: - Lifecycle Management

    /**
     * Pause Flutter resources (videos, network) when screen loses focus
     */
    fun pauseFlutter() {
        Log.d(TAG, "⏸️ pauseFlutter() called")

        Log.d(TAG, "📞 Calling Flutter pauseAll API")
        try {
            // Call Pigeon API to pause Flutter resources
            ReelsFlutterSDK.pauseAll()
            Log.d(TAG, "✅ Flutter resources paused successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error pausing Flutter resources", e)
        }
    }

    /**
     * Resume Flutter resources (videos, network) when screen gains focus
     * @param generation The generation number of the screen being resumed
     */
    fun resumeFlutter(generation: Int) {
        Log.d(TAG, "▶️ resumeFlutter(generation: $generation) called")

        Log.d(TAG, "📞 Calling Flutter resumeAll($generation) API")
        try {
            // Call Pigeon API to resume Flutter resources
            ReelsFlutterSDK.resumeAll(generation.toLong())
            Log.d(TAG, "✅ Flutter resources resumed successfully for generation $generation")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error resuming Flutter resources", e)
        }
    }

    // MARK: - Analytics

    /**
     * Track analytics event
     * @param eventName Name of the event
     * @param properties Event properties
     */
    fun trackEvent(eventName: String, properties: Map<String, String> = emptyMap()) {
        ReelsFlutterSDK.trackEvent(eventName, properties)
    }

    /**
     * Notify about like button interaction
     * @param videoId Video ID that was liked
     * @param isLiked Whether the video is now liked
     * @param likeCount Updated like count
     */
    fun notifyLikeButtonClick(videoId: String, isLiked: Boolean, likeCount: Int) {
        ReelsFlutterSDK.notifyLikeButtonClick(videoId, isLiked, likeCount)
    }

    /**
     * Notify about share button interaction
     * @param videoId Video ID that was shared
     * @param videoUrl URL of the video
     * @param title Video title
     * @param description Video description
     * @param thumbnailUrl Optional thumbnail URL
     */
    fun notifyShareButtonClick(
        videoId: String,
        videoUrl: String,
        title: String,
        description: String,
        thumbnailUrl: String? = null
    ) {
        ReelsFlutterSDK.notifyShareButtonClick(
            videoId,
            videoUrl,
            title,
            description,
            thumbnailUrl
        )
    }

    /**
     * Notify about screen state changes
     * @param screenName Screen name
     * @param state State (appeared, disappeared, focused, unfocused)
     */
    fun notifyScreenStateChanged(screenName: String, state: String) {
        ReelsFlutterSDK.notifyScreenStateChanged(screenName, state)
    }

    /**
     * Notify about video state changes
     * @param videoId Video ID
     * @param state State (playing, paused, stopped, buffering, completed)
     * @param position Current position in seconds (optional)
     * @param duration Total duration in seconds (optional)
     */
    fun notifyVideoStateChanged(
        videoId: String,
        state: String,
        position: Int? = null,
        duration: Int? = null
    ) {
        ReelsFlutterSDK.notifyVideoStateChanged(videoId, state, position, duration)
    }

    // MARK: - Advanced

    /**
     * Get the Flutter SDK for advanced operations
     */
    fun getFlutterSDK() = ReelsFlutterSDK

    /**
     * Clean up collect data for a specific generation when the screen is closed
     * This prevents memory leaks from accumulating collectData across many screen instances
     *
     * @param generation The generation number to clean up
     */
    fun cleanupGeneration(generation: Int) {
        val removed = collectDataByGeneration.remove(generation)
        if (removed != null) {
            Log.d(TAG, "🗑️ Cleaned up collectData for generation #$generation (id=${removed.id})")
        } else {
            Log.d(TAG, "⚠️ No collectData found for generation #$generation")
        }
        Log.d(TAG, "   Remaining generations in memory: ${collectDataByGeneration.size}")
    }

    /**
     * Clean up resources when the app is destroyed
     */
    fun cleanup() {
        collectDataByGeneration.clear()
        ReelsFlutterSDK.dispose()
        Log.d(TAG, "🧹 ReelsSDK cleaned up")
    }

    /**
     * Available Flutter routes
     */
    object Routes {
        const val HOME = "/"
        const val REELS = "/reels"
        const val PROFILE = "/profile"
    }
}

/**
 * SDK information data class
 */
data class SDKInfo(
    val version: String,
    val generation: Int,
    val debugMode: Boolean
) {
    override fun toString(): String {
        return "ReelsSDK v$version (Generation #$generation) - Debug: ${if (debugMode) "ON" else "OFF"}"
    }
}
