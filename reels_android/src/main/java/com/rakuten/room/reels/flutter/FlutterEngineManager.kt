package com.rakuten.room.reels.flutter

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class FlutterEngineManager private constructor() {
    
    companion object {
        private const val FLUTTER_ENGINE_ID = "reels_flutter_engine"
        
        @Volatile
        private var INSTANCE: FlutterEngineManager? = null
        
        fun getInstance(): FlutterEngineManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: FlutterEngineManager().also { INSTANCE = it }
            }
        }
    }
    
    private var flutterEngine: FlutterEngine? = null
    private var isInitialized = false
    
    fun initializeFlutterEngine(context: Context, accessTokenProvider: (() -> String?)? = null) {
        if (!isInitialized) {
            // Use the sophisticated ReelsFlutterSDK instead of direct engine management
            ReelsFlutterSDK.initialize(context, accessTokenProvider)
            
            // Get the initialized engine from the SDK
            flutterEngine = ReelsFlutterSDK.getFlutterEngine()
            
            // Cache the FlutterEngine to be used by FlutterActivity or FlutterFragment
            flutterEngine?.let {
                FlutterEngineCache
                    .getInstance()
                    .put(FLUTTER_ENGINE_ID, it)
            }
            
            isInitialized = true
        }
    }
    
    fun getFlutterEngineId(): String = FLUTTER_ENGINE_ID
    
    fun getFlutterSDK() = ReelsFlutterSDK
    
    fun trackAnalyticsEvent(eventName: String, properties: Map<String, String> = emptyMap()) {
        ReelsFlutterSDK.trackEvent(eventName, properties)
    }
    
    fun notifyLikeButtonClick(videoId: String, isLiked: Boolean, likeCount: Int) {
        ReelsFlutterSDK.notifyLikeButtonClick(videoId, isLiked, likeCount)
    }
    
    fun notifyShareButtonClick(videoId: String, videoUrl: String, title: String, description: String, thumbnailUrl: String? = null) {
        ReelsFlutterSDK.notifyShareButtonClick(videoId, videoUrl, title, description, thumbnailUrl)
    }
    
    fun notifyScreenStateChanged(screenName: String, state: String) {
        ReelsFlutterSDK.notifyScreenStateChanged(screenName, state)
    }
    
    fun notifyVideoStateChanged(videoId: String, state: String, position: Int? = null, duration: Int? = null) {
        ReelsFlutterSDK.notifyVideoStateChanged(videoId, state, position, duration)
    }
    
    fun destroyFlutterEngine() {
        ReelsFlutterSDK.dispose()
        FlutterEngineCache
            .getInstance()
            .remove(FLUTTER_ENGINE_ID)
        flutterEngine = null
        isInitialized = false
    }
}