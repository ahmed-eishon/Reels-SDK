package com.rakuten.room.reels.flutter

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import com.rakuten.room.reels.CollectData
import com.rakuten.room.reels.ReelsModule

/**
 * Flutter Activity for displaying video reels with sophisticated features.
 * 
 * This activity:
 * - Loads the reels screen directly from Flutter
 * - Integrates with analytics and event tracking
 * - Handles video interaction callbacks
 * - Manages access tokens and authentication
 * - Tracks screen lifecycle events
 */
class FlutterReelsActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "[ReelsSDK-Android]"
        const val FLUTTER_ROUTE = "flutter_route"
        const val ACCESS_TOKEN_EXTRA = "access_token"
        const val EXTRA_COLLECT_DATA = "collect_data"
        const val EXTRA_GENERATION = "generation"
        
        /**
         * Create intent to launch Flutter reels activity
         * @param context Android context
         * @param initialRoute Flutter route (defaults to reels screen)
         * @param accessToken Optional access token for authenticated content
         */
        fun createIntent(
            context: Context, 
            initialRoute: String = "/", // Default to reels screen
            accessToken: String? = null
        ): Intent {
            val intent = Intent(context, FlutterReelsActivity::class.java)
            intent.putExtra(FLUTTER_ROUTE, initialRoute)
            accessToken?.let { intent.putExtra(ACCESS_TOKEN_EXTRA, it) }
            return intent
        }
        
        /**
         * Create intent specifically for reels screen
         */
        fun createReelsIntent(context: Context, accessToken: String? = null): Intent {
            return createIntent(context, "/", accessToken) // Loads reels directly
        }
    }
    
    override fun getCachedEngineId(): String? {
        return ReelsFlutterSDK.getEngineId()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "Creating FlutterReelsActivity - Enhanced initialization")

        // Extract collectData and generation from intent
        val collectData = intent.getParcelableExtra<CollectData>(EXTRA_COLLECT_DATA)
        val generation = intent.getIntExtra(EXTRA_GENERATION, 0)

        if (collectData != null) {
            Log.d(TAG, "Received collectData: id=${collectData.id}, generation=$generation")
        } else {
            Log.d(TAG, "No collectData provided, generation=$generation")
        }

        // Initialize Flutter engine BEFORE calling super.onCreate()
        val accessToken = intent.getStringExtra(ACCESS_TOKEN_EXTRA)

        try {
            Log.d(TAG, "Starting Flutter engine initialization...")

            if (accessToken != null) {
                // Initialize with access token provider
                ReelsFlutterSDK.initialize(this) { accessToken }
                Log.d(TAG, "Initialized with access token: ${accessToken.take(10)}...")
            } else {
                // Initialize without access token
                ReelsFlutterSDK.initialize(this)
                Log.d(TAG, "Initialized without access token")
            }
            
            // Verify engine is properly initialized
            val engine = ReelsFlutterSDK.getFlutterEngine()
            if (engine != null) {
                Log.d(TAG, "Flutter engine verified: ${engine.javaClass.simpleName}")
                
                // Check if video player plugin is available
                try {
                    val hasVideoPlayer = engine.plugins.has(io.flutter.plugins.videoplayer.VideoPlayerPlugin::class.java)
                    Log.d(TAG, "Video player plugin available: $hasVideoPlayer")
                    
                    if (!hasVideoPlayer) {
                        Log.w(TAG, "WARNING: Video player plugin not detected - videos may not load")
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Could not verify video player plugin: ${e.message}")
                }
                
                // Give plugins extra time to initialize
                Log.d(TAG, "Allowing additional time for plugin initialization...")
                Thread.sleep(300)
                
            } else {
                Log.e(TAG, "CRITICAL: Flutter engine is null after initialization!")
                Toast.makeText(this, "Critical error: Flutter engine failed to initialize", Toast.LENGTH_LONG).show()
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Flutter engine", e)
            Toast.makeText(this, "Failed to initialize video player: ${e.message}", Toast.LENGTH_LONG).show()
            
            // Don't finish the activity - let it try to work anyway
            Log.w(TAG, "Continuing despite initialization error...")
        }
        
        // Setup sophisticated reels listener for this activity
        setupReelsEventListener()
        
        Log.d(TAG, "Calling super.onCreate()...")
        super.onCreate(savedInstanceState)
        
        // Track analytics event for reels screen opening
        ReelsModule.trackEvent("reels_screen_opened", mapOf(
            "source" to "flutter_activity",
            "has_token" to (accessToken != null).toString()
        ))
        
        // Notify screen state change
        ReelsModule.notifyScreenStateChanged("flutter_reels", "appeared")
    }
    
    private fun setupReelsEventListener() {
        ReelsModule.setListener(object : ReelsListener {
            override fun onReelViewed(videoId: String) {
                Log.d(TAG, "Video completed: $videoId")
                // Here you can integrate with your analytics or backend
            }
            
            override fun onReelLiked(videoId: String, isLiked: Boolean) {
                Log.d(TAG, "Video ${if (isLiked) "liked" else "unliked"}: $videoId")
                // Update your backend with like status
            }
            
            override fun onReelShared(videoId: String) {
                Log.d(TAG, "Video shared: $videoId")
                // Track share events in your analytics
            }
            
            override fun onReelsClosed() {
                Log.d(TAG, "Reels closed by user")
                // Handle reels closure
                finish()
            }
            
            override fun onError(errorMessage: String) {
                Log.e(TAG, "Reels error: $errorMessage")
                Toast.makeText(this@FlutterReelsActivity, 
                    "Error: $errorMessage", Toast.LENGTH_LONG).show()
            }
            
            override fun getAccessToken(): String? {
                // Return access token from intent or provide default
                return intent.getStringExtra(ACCESS_TOKEN_EXTRA)
            }
        })
    }
    
    override fun onResume() {
        super.onResume()
        Log.d(TAG, "FlutterReelsActivity resumed")

        // Resume Flutter resources for this generation
        val generation = intent.getIntExtra(EXTRA_GENERATION, 0)
        if (generation > 0) {
            ReelsModule.resumeFlutter(generation)
        }

        // Track screen resume
        ReelsModule.notifyScreenStateChanged("flutter_reels", "focused")

        // Track analytics event
        ReelsModule.trackEvent("reels_screen_resumed", mapOf(
            "timestamp" to System.currentTimeMillis().toString()
        ))
    }
    
    override fun onPause() {
        super.onPause()
        Log.d(TAG, "FlutterReelsActivity paused")

        // Pause Flutter resources
        ReelsModule.pauseFlutter()

        // Track screen pause
        ReelsModule.notifyScreenStateChanged("flutter_reels", "unfocused")
    }
    
    override fun onDestroy() {
        Log.d(TAG, "FlutterReelsActivity destroyed")

        // Clean up generation data if activity is truly finishing (not just recreating)
        if (isFinishing) {
            val generation = intent.getIntExtra(EXTRA_GENERATION, 0)
            if (generation > 0) {
                ReelsModule.cleanupGeneration(generation)
                Log.d(TAG, "Activity finishing, cleaned up generation #$generation")
            }
        } else {
            Log.d(TAG, "Activity destroyed but not finishing (config change?) - keeping data")
        }

        // Track screen destruction
        ReelsModule.notifyScreenStateChanged("flutter_reels", "disappeared")

        // Track analytics event
        ReelsModule.trackEvent("reels_screen_closed", mapOf(
            "duration" to "unknown" // You could track actual duration if needed
        ))

        super.onDestroy()
    }
}