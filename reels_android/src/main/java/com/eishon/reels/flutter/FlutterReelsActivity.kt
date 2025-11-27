package com.eishon.reels.flutter

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import com.eishon.reels.CollectData
import com.eishon.reels.ReelsModule

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
        private const val CODE_VERSION = 7  // Must match ReelsFlutterSDK.CODE_VERSION
        const val FLUTTER_ROUTE = "flutter_route"
        const val ACCESS_TOKEN_EXTRA = "access_token"
        const val EXTRA_COLLECT_DATA = "collect_data"
        const val EXTRA_GENERATION = "generation"
        
        /**
         * Create intent to launch Flutter reels activity
         * Internal use only - use ReelsModule.createReelsIntent() or ReelsModule.openReels() instead
         * @param context Android context
         * @param initialRoute Flutter route (defaults to reels screen)
         * @param accessToken Optional access token for authenticated content
         */
        internal fun createIntent(
            context: Context,
            initialRoute: String = "/", // Default to reels screen
            accessToken: String? = null
        ): Intent {
            val intent = Intent(context, FlutterReelsActivity::class.java)
            intent.putExtra(FLUTTER_ROUTE, initialRoute)
            accessToken?.let { intent.putExtra(ACCESS_TOKEN_EXTRA, it) }
            return intent
        }
    }
    
    private var isDestroying = false
    private var isFirstResume = true  // Track if this is the initial resume vs returning from nested screen
    private var capturedListener: ReelsListener? = null  // Captured listener for event forwarding

    override fun getCachedEngineId(): String? {
        // Don't create new engines during destruction
        if (isDestroying) {
            Log.d(TAG, "⚠️ Activity is destroying, not creating new engine")
            return null
        }

        // Get generation from intent to use correct engine
        val generation = intent.getIntExtra(EXTRA_GENERATION, 0)

        return if (generation > 0) {
            // Try to get existing engine for this generation
            val existingEngineId = ReelsFlutterSDK.getEngineIdForGeneration(generation)
            if (existingEngineId != null) {
                Log.d(TAG, "Using existing engine for generation $generation: $existingEngineId")
                existingEngineId
            } else {
                // Create new engine for this generation
                val initialRoute = intent.getStringExtra(FLUTTER_ROUTE) ?: "/"
                val engineId = ReelsFlutterSDK.createEngineForGeneration(this, generation, initialRoute)
                Log.d(TAG, "Created new engine for generation $generation: $engineId")
                engineId
            }
        } else {
            Log.w(TAG, "No generation number provided, falling back to primary engine")
            ReelsFlutterSDK.getEngineId()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "🎬 Creating FlutterReelsActivity - Multi-modal support enabled")

        // Extract collectData and generation from intent
        val collectData = intent.getParcelableExtra<CollectData>(EXTRA_COLLECT_DATA)
        val generation = intent.getIntExtra(EXTRA_GENERATION, 0)

        if (collectData != null) {
            Log.d(TAG, "✅ Received collectData: id=${collectData.id}, generation=$generation")
        } else {
            Log.d(TAG, "⚠️ No collectData provided, generation=$generation")
        }

        // Initialize Flutter engine BEFORE calling super.onCreate()
        val accessToken = intent.getStringExtra(ACCESS_TOKEN_EXTRA)

        try {
            Log.d(TAG, "Starting Flutter engine initialization for generation $generation...")

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

        // Capture the ROOT listener (not the current one which may be from another FlutterReelsActivity)
        // The root listener is the original app listener (e.g., MyRoomFragment) that can handle navigation
        // This fixes multimodal navigation where f2->n3 needs to bypass f1's listener
        capturedListener = ReelsFlutterSDK.getRootListener()
        Log.d(TAG, "[ReelsSDK-Android] [CODE_VERSION=$CODE_VERSION] Captured ROOT listener for event forwarding")
        Log.d(TAG, "[ReelsSDK-Android] [CODE_VERSION=$CODE_VERSION]    capturedListener type: ${capturedListener?.javaClass?.simpleName ?: "NULL"}")
        Log.d(TAG, "[ReelsSDK-Android] [CODE_VERSION=$CODE_VERSION]    capturedListener hashCode: ${capturedListener?.hashCode() ?: "N/A"}")

        // Set up a listener that forwards all events to the captured listener
        // IMPORTANT: We store capturedListener as an instance variable so it can be refreshed in onResume()
        // The close button (dismissReels) is handled differently - it finishes the current activity
        // which is tracked separately via setCurrentActivity/clearCurrentActivity
        ReelsFlutterSDK.setListener(object : ReelsListener {
            override fun onReelsClosed() {
                // This is NOT called anymore - dismissReels handler directly finishes the current activity
                // But we keep this for safety/fallback
                Log.d(TAG, "⚠️ onReelsClosed called on activity listener (unexpected)")
                try {
                    capturedListener?.onReelsClosed()
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Error in onReelsClosed: ${e.message}", e)
                }
            }

            // Forward all other events to the captured listener with error handling
            override fun onReelViewed(videoId: String) {
                try {
                    capturedListener?.onReelViewed(videoId)
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Error in onReelViewed: ${e.message}", e)
                }
            }

            override fun onReelLiked(videoId: String, isLiked: Boolean) {
                try {
                    capturedListener?.onReelLiked(videoId, isLiked)
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Error in onReelLiked: ${e.message}", e)
                }
            }

            override fun onReelShared(videoId: String) {
                try {
                    capturedListener?.onReelShared(videoId)
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Error in onReelShared: ${e.message}", e)
                }
            }

            override fun onError(errorMessage: String) {
                Log.e(TAG, "Reels error: $errorMessage")
                try {
                    capturedListener?.onError(errorMessage)
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Error in onError: ${e.message}", e)
                }
            }

            override fun getAccessToken(): String? {
                // First try our own access token, then fall back to captured listener
                return accessToken ?: try {
                    capturedListener?.getAccessToken()
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Error in getAccessToken: ${e.message}", e)
                    null
                }
            }

            override fun onLikeButtonClick(videoId: String, isLiked: Boolean, likeCount: Int) {
                try {
                    capturedListener?.onLikeButtonClick(videoId, isLiked, likeCount)
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Error in onLikeButtonClick: ${e.message}", e)
                }
            }

            override fun onShareButtonClick(videoId: String, videoUrl: String, title: String, description: String, thumbnailUrl: String?) {
                try {
                    capturedListener?.onShareButtonClick(videoId, videoUrl, title, description, thumbnailUrl)
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Error in onShareButtonClick: ${e.message}", e)
                }
            }

            override fun onScreenStateChanged(screenName: String, state: String) {
                try {
                    capturedListener?.onScreenStateChanged(screenName, state)
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Error in onScreenStateChanged: ${e.message}", e)
                }
            }

            override fun onVideoStateChanged(videoId: String, state: String, position: Int?, duration: Int?) {
                try {
                    capturedListener?.onVideoStateChanged(videoId, state, position, duration)
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Error in onVideoStateChanged: ${e.message}", e)
                }
            }

            override fun onSwipeLeft(userId: String, userName: String) {
                Log.d(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ⬅️ Swipe left detected - forwarding to captured listener")
                try {
                    capturedListener?.onSwipeLeft(userId, userName)
                    Log.d(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ✅ Swipe left forwarded successfully")
                } catch (e: IllegalStateException) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ⚠️ Swipe left failed - fragment detached: ${e.message}")
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ⚠️ Unexpected error in onSwipeLeft: ${e.message}", e)
                }
            }

            override fun onSwipeRight() {
                Log.d(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ➡️ Swipe right detected - forwarding to captured listener")
                try {
                    capturedListener?.onSwipeRight()
                    Log.d(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ✅ Swipe right forwarded successfully")
                } catch (e: IllegalStateException) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ⚠️ Swipe right failed - fragment detached: ${e.message}")
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ⚠️ Unexpected error in onSwipeRight: ${e.message}", e)
                }
            }

            override fun onUserProfileClick(userId: String, userName: String) {
                Log.d(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] 👤 User profile click detected - userId: $userId, userName: $userName")

                // MULTIMODAL FIX: The capturedListener may reference a detached fragment
                // This happens when we're in a nested Flutter activity after returning from deeper nesting
                // Example: N1→F1(captures N1's listener)→N2→F2(captures F1's listener which has N1)→back to F1
                // Now F1's capturedListener still points to N1, but N1's fragment is detached
                // Solution: We refresh capturedListener in onResume() to get the current valid listener
                try {
                    capturedListener?.onUserProfileClick(userId, userName)
                    Log.d(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ✅ Profile click forwarded successfully")
                } catch (e: IllegalStateException) {
                    // Fragment not attached - this is expected in nested navigation if listener wasn't refreshed
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ⚠️ Profile click failed - fragment detached: ${e.message}")
                    Log.e(TAG, "[ReelsSDK-Android] This indicates the listener wasn't refreshed properly in onResume()")

                    // Show helpful message to user
                    runOnUiThread {
                        android.widget.Toast.makeText(
                            this@FlutterReelsActivity,
                            "Cannot navigate - please close and retry",
                            android.widget.Toast.LENGTH_LONG
                        ).show()
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] ⚠️ Unexpected error in onUserProfileClick: ${e.message}", e)
                }
            }

            override fun onAnalyticsEvent(eventName: String, properties: Map<String, String>) {
                try {
                    capturedListener?.onAnalyticsEvent(eventName, properties)
                } catch (e: Exception) {
                    Log.e(TAG, "[ReelsSDK-Android] [CODE_VERSION=4] Error in onAnalyticsEvent: ${e.message}", e)
                }
            }
        })

        Log.d(TAG, "[ReelsSDK-Android] [CODE_VERSION=3] Listener chain established for generation $generation")

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

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "FlutterReelsActivity resumed")

        // Register this activity as the current one for handling close button
        ReelsFlutterSDK.setCurrentActivity(this)

        // MULTIMODAL FIX: Always use the root listener (not the current global listener)
        // This solves the detached fragment issue in n1>f1>n2>f2>n3<f2<n2<f1 flow
        // The root listener is the original app listener that can handle navigation
        val generation = intent.getIntExtra(EXTRA_GENERATION, 0)
        if (!isFirstResume) {
            val currentRootListener = ReelsFlutterSDK.getRootListener()
            if (currentRootListener != null && currentRootListener != capturedListener) {
                Log.d(TAG, "[CODE_VERSION=$CODE_VERSION] 🔄 MULTIMODAL FIX: Refreshing to root listener on resume")
                Log.d(TAG, "[CODE_VERSION=$CODE_VERSION]    Generation: $generation")
                Log.d(TAG, "[CODE_VERSION=$CODE_VERSION]    Previous listener: ${capturedListener?.javaClass?.simpleName}")
                Log.d(TAG, "[CODE_VERSION=$CODE_VERSION]    Root listener: ${currentRootListener.javaClass.simpleName}")
                capturedListener = currentRootListener
                Log.d(TAG, "[CODE_VERSION=$CODE_VERSION] ✅ Listener refreshed to root - navigation should now work")
            } else {
                Log.d(TAG, "[CODE_VERSION=$CODE_VERSION] Root listener unchanged, no refresh needed")
            }
        }

        // Only call resumeFlutter when RETURNING from a nested screen
        // On first resume (initial load), let Flutter's initState handle the initial load
        if (generation > 0 && !isFirstResume) {
            Log.d(TAG, "Returning to generation $generation, calling resumeFlutter")
            ReelsModule.resumeFlutter(generation)
        } else if (isFirstResume) {
            Log.d(TAG, "First resume for generation $generation, skipping resumeFlutter (initState will load)")
            isFirstResume = false
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

        // Unregister this activity
        ReelsFlutterSDK.clearCurrentActivity(this)

        // Pause Flutter resources
        ReelsModule.pauseFlutter()

        // Track screen pause
        ReelsModule.notifyScreenStateChanged("flutter_reels", "unfocused")
    }
    
    override fun onDestroy() {
        Log.d(TAG, "🗑️ FlutterReelsActivity destroyed")

        // Set flag to prevent engine creation during destruction
        isDestroying = true

        // Clean up generation data if activity is truly finishing (not just recreating)
        if (isFinishing) {
            val generation = intent.getIntExtra(EXTRA_GENERATION, 0)
            if (generation > 0) {
                // Clean up collect data
                ReelsModule.cleanupGeneration(generation)
                Log.d(TAG, "✅ Activity finishing, cleaned up collect data for generation #$generation")

                // DO NOT clean up Flutter engine - keep it alive for reuse
                // This follows iOS approach where engines are kept alive and reused
                // Cleaning up engines causes issues when returning to previous generations
                Log.d(TAG, "ℹ️ Keeping Flutter engine alive for generation #$generation (reusable)")
            }
        } else {
            Log.d(TAG, "⚠️ Activity destroyed but not finishing (config change?) - keeping data and engine")
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