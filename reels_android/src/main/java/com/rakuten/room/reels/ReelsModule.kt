package com.rakuten.room.reels

import android.content.Context
import android.content.Intent
import androidx.fragment.app.Fragment
import com.rakuten.room.reels.flutter.FlutterReelsActivity
import com.rakuten.room.reels.flutter.FlutterReelsFragment
import com.rakuten.room.reels.flutter.FlutterEngineManager
import com.rakuten.room.reels.flutter.ReelsFlutterSDK
import com.rakuten.room.reels.flutter.ReelsListener


/**
 * Main entry point for the Reels module.
 * Provides a clean API for the main app to interact with Flutter reels functionality.
 */
object ReelsModule {
    
    /**
     * Initialize the Reels module. Call this once in your Application class.
     * @param context Application context
     * @param accessTokenProvider Optional provider for user access token
     */
    fun initialize(context: Context, accessTokenProvider: (() -> String?)? = null) {
        FlutterEngineManager.getInstance().initializeFlutterEngine(context, accessTokenProvider)
    }
    
    /**
     * Create an intent to launch the Flutter Reels in full-screen mode
     * @param context Context
     * @param initialRoute Flutter route to navigate to (default: "/" - reels screen)
     * @param accessToken Optional access token for authenticated content
     * @return Intent to start the Flutter activity
     */
    fun createReelsIntent(context: Context, initialRoute: String = "/", accessToken: String? = null): Intent {
        return FlutterReelsActivity.createIntent(context, initialRoute, accessToken)
    }
    
    /**
     * Create an intent specifically for the reels screen with analytics tracking
     * @param context Context  
     * @param accessToken Optional access token for authenticated content
     * @return Intent to start the Flutter reels screen
     */
    fun createReelsIntent(context: Context, accessToken: String? = null): Intent {
        return FlutterReelsActivity.createReelsIntent(context, accessToken)
    }
    
    /**
     * Create a fragment to embed Flutter Reels in existing screens
     * @param initialRoute Flutter route to navigate to (default: "/")
     * @return Fragment containing Flutter reels
     */
    fun createReelsFragment(initialRoute: String = "/"): Fragment {
        return FlutterReelsFragment.newInstance(initialRoute)
    }
    

    
    /**
     * Set listener for reels events
     * @param listener Listener to receive events from Flutter
     */
    fun setListener(listener: ReelsListener?) {
        ReelsFlutterSDK.setListener(listener)
    }
    
    /**
     * Track analytics event
     * @param eventName Name of the event
     * @param properties Event properties
     */
    fun trackEvent(eventName: String, properties: Map<String, String> = emptyMap()) {
        FlutterEngineManager.getInstance().trackAnalyticsEvent(eventName, properties)
    }
    
    /**
     * Notify about like button interaction
     * @param videoId Video ID that was liked
     * @param isLiked Whether the video is now liked
     * @param likeCount Updated like count
     */
    fun notifyLikeButtonClick(videoId: String, isLiked: Boolean, likeCount: Int) {
        FlutterEngineManager.getInstance().notifyLikeButtonClick(videoId, isLiked, likeCount)
    }
    
    /**
     * Notify about share button interaction
     * @param videoId Video ID that was shared
     * @param videoUrl URL of the video
     * @param title Video title
     * @param description Video description
     * @param thumbnailUrl Optional thumbnail URL
     */
    fun notifyShareButtonClick(videoId: String, videoUrl: String, title: String, description: String, thumbnailUrl: String? = null) {
        FlutterEngineManager.getInstance().notifyShareButtonClick(videoId, videoUrl, title, description, thumbnailUrl)
    }
    
    /**
     * Notify about screen state changes
     * @param screenName Screen name
     * @param state State (appeared, disappeared, focused, unfocused)
     */
    fun notifyScreenStateChanged(screenName: String, state: String) {
        FlutterEngineManager.getInstance().notifyScreenStateChanged(screenName, state)
    }
    
    /**
     * Notify about video state changes
     * @param videoId Video ID
     * @param state State (playing, paused, stopped, buffering, completed)
     * @param position Current position in seconds (optional)
     * @param duration Total duration in seconds (optional)
     */
    fun notifyVideoStateChanged(videoId: String, state: String, position: Int? = null, duration: Int? = null) {
        FlutterEngineManager.getInstance().notifyVideoStateChanged(videoId, state, position, duration)
    }
    
    /**
     * Get the Flutter SDK for advanced operations
     */
    fun getFlutterSDK() = FlutterEngineManager.getInstance().getFlutterSDK()
    
    /**
     * Clean up resources when the app is destroyed
     */
    fun cleanup() {
        FlutterEngineManager.getInstance().destroyFlutterEngine()
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