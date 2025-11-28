package com.eishon.reels.flutter

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import com.eishon.reels.pigeon.*
import com.eishon.reels.pigeon.CollectData

/**
 * Advanced Flutter Reels SDK with Pigeon integration.
 * 
 * This SDK provides sophisticated video reels functionality with:
 * - Video player with controls
 * - Like/share functionality
 * - Analytics tracking
 * - State management
 * - Access token management
 * 
 * Usage:
 * ```
 * // Initialize once in your Application class
 * ReelsFlutterSDK.initialize(
 *     context = this,
 *     accessTokenProvider = { "user_token_123" }
 * )
 * 
 * // Set listener for events
 * ReelsFlutterSDK.setListener(object : ReelsListener {
 *     override fun onReelLiked(videoId: String, isLiked: Boolean) {
 *         Log.d("Reels", "Liked: $videoId = $isLiked")
 *     }
 *     override fun onReelShared(videoId: String) {
 *         Log.d("Reels", "Shared: $videoId")
 *     }
 * })
 * 
 * // Use with existing Flutter activities/fragments
 * val fragment = ReelsModule.createReelsFragment()
 * ```
 */
class ReelsFlutterSDK private constructor() {
    companion object {
        private const val TAG = "[ReelsSDK-Android]"
        private const val CODE_VERSION = 7  // Increment this for tracking fixes
        private const val FLUTTER_ENGINE_ID_PREFIX = "reels_flutter_engine"

        private var flutterEngineGroup: FlutterEngineGroup? = null
        private var flutterEngine: FlutterEngine? = null  // Primary engine for shared setup
        private val engineCache: MutableMap<Int, FlutterEngine> = mutableMapOf()  // Cache engines by generation
        private var listener: ReelsListener? = null
        private var rootListener: ReelsListener? = null  // The original listener from the app (e.g., MyRoomFragment)
        private var accessTokenProvider: (() -> String?)? = null
        private var isInitialized = false

        // Track the currently active FlutterReelsActivity to handle close button correctly
        private var currentActivity: java.lang.ref.WeakReference<FlutterReelsActivity>? = null

        // Pigeon API instances
        private var analyticsApi: ReelsFlutterAnalyticsApi? = null
        private var buttonEventsApi: ReelsFlutterButtonEventsApi? = null
        private var stateApi: ReelsFlutterStateApi? = null
        private var lifecycleApi: ReelsFlutterLifecycleApi? = null
        // Note: ReelsFlutterNavigationApi is now a Host API (interface), not a class
        
        /**
         * Setup all Pigeon API handlers
         * Navigation handlers are set up for each engine but use the current global listener
         */
        private fun setupPigeonAPIs(binaryMessenger: BinaryMessenger) {
            Log.d(TAG, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Log.d(TAG, "⚙️ setupPigeonAPIs() called")
            Log.d(TAG, "   Binary Messenger: ${binaryMessenger.hashCode()}")
            Log.d(TAG, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            // Host API: Provide access token to Flutter (Flutter calls, Android implements)
            ReelsFlutterTokenApi.setUp(binaryMessenger, object : ReelsFlutterTokenApi {
                override fun getAccessToken(callback: (Result<String?>) -> Unit) {
                    val token = accessTokenProvider?.invoke() ?: listener?.getAccessToken()
                    Log.d(TAG, "Token requested: ${if (token != null) "provided" else "null"}")
                    callback(Result.success(token))
                }
            })

            // Host API: Provide context data to Flutter (Flutter calls, Android implements)
            ReelsFlutterContextApi.setUp(binaryMessenger, object : ReelsFlutterContextApi {
                override fun getInitialCollect(generation: Long): CollectData? {
                    val collectData = com.eishon.reels.ReelsModule.getInitialCollect(generation.toInt())
                    Log.d(TAG, "Initial collect data requested for generation $generation: ${collectData?.id ?: "null"}")

                    return if (collectData != null) {
                        // Convert native CollectData to Pigeon CollectData
                        CollectData(
                            id = collectData.id,
                            content = collectData.content,
                            name = collectData.name,
                            likes = collectData.likes,
                            comments = collectData.comments,
                            recollects = collectData.recollects,
                            isLiked = collectData.isLiked,
                            isCollected = collectData.isCollected,
                            trackingTag = collectData.trackingTag,
                            userId = collectData.userId,
                            userName = collectData.userName,
                            userProfileImage = collectData.userProfileImage,
                            itemName = collectData.itemName,
                            itemImageUrl = collectData.itemImageUrl,
                            imageUrl = collectData.imageUrl
                        )
                    } else {
                        null
                    }
                }

                override fun getCurrentGeneration(): Long {
                    val generation = com.eishon.reels.ReelsModule.getCurrentGeneration()
                    Log.d(TAG, "Current generation requested: $generation")
                    return generation.toLong()
                }

                override fun isDebugMode(): Boolean {
                    val debugMode = com.eishon.reels.ReelsModule.isDebugMode()
                    Log.d(TAG, "Debug mode requested: $debugMode")
                    return debugMode
                }
            })

            // Flutter APIs: Android calls Flutter methods
            analyticsApi = ReelsFlutterAnalyticsApi(binaryMessenger)
            buttonEventsApi = ReelsFlutterButtonEventsApi(binaryMessenger)
            stateApi = ReelsFlutterStateApi(binaryMessenger)
            lifecycleApi = ReelsFlutterLifecycleApi(binaryMessenger)

            // Setup navigation event listeners from Flutter (Host API - Flutter calls Android)
            // Set up for each engine's messenger, but all handlers use the CURRENT global listener
            setupNavigationEventHandlers(binaryMessenger)
        }

        /**
         * Setup handlers to receive navigation events from Flutter
         * Note: dismissReels, onSwipeRight, onSwipeLeft, onUserProfileClick are defined as @FlutterApi in Pigeon
         * but we need to receive them from Flutter, so we manually set up listeners
         *
         * IMPORTANT: Each Flutter engine has its own isolated binary messenger, so handlers must be
         * registered on each engine's messenger. However, ALL handlers use the CURRENT global listener
         * (not a captured listener), which is set by whichever ReelsControllerImpl/Activity is currently active.
         * This ensures navigation events are routed to the correct activity.
         */
        private fun setupNavigationEventHandlers(binaryMessenger: BinaryMessenger) {
            val codec = io.flutter.plugin.common.StandardMessageCodec.INSTANCE

            Log.d(TAG, "🎯 Setting up navigation event handlers")
            Log.d(TAG, "   Binary Messenger: ${binaryMessenger.hashCode()}")
            Log.d(TAG, "   Handlers will use CURRENT global listener at event-receive time")

            // Handle dismiss reels events (close button)
            val dismissChannelName = "dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.dismissReels"

            val dismissReelsChannel = io.flutter.plugin.common.BasicMessageChannel(
                binaryMessenger,
                dismissChannelName,
                codec
            )
            dismissReelsChannel.setMessageHandler { _, reply ->
                Log.d(TAG, "🔔 dismissReels handler INVOKED!")
                Log.d(TAG, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                Log.d(TAG, "📱 [Navigation] Received dismiss reels request (close button)")
                Log.d(TAG, "   Binary Messenger: ${binaryMessenger.hashCode()}")

                // Get the currently active FlutterReelsActivity
                val activity = currentActivity?.get()

                if (activity != null && !activity.isFinishing && !activity.isDestroyed) {
                    Log.d(TAG, "   ✅ Found active FlutterReelsActivity")
                    Log.d(TAG, "   Activity: ${activity.javaClass.simpleName}")
                    Log.d(TAG, "   Finishing activity...")

                    try {
                        activity.finish()
                        Log.d(TAG, "   ✅ Activity finish() called successfully")
                    } catch (e: Exception) {
                        Log.e(TAG, "   ❌ Error finishing activity: ${e.message}", e)
                    }
                } else {
                    Log.w(TAG, "   ⚠️ No active FlutterReelsActivity found, falling back to listener")

                    // Fallback: try calling listener's onReelsClosed
                    val currentListener = listener
                    if (currentListener != null) {
                        try {
                            Log.d(TAG, "   Calling onReelsClosed() on listener...")
                            currentListener.onReelsClosed()
                            Log.d(TAG, "   ✅ onReelsClosed() completed")
                        } catch (e: Exception) {
                            Log.e(TAG, "   ❌ Error calling onReelsClosed(): ${e.message}", e)
                        }
                    } else {
                        Log.w(TAG, "   ⚠️ No listener set either")
                    }
                }

                reply.reply(null)
                Log.d(TAG, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            }

            // Handle swipe right events (dismiss gesture)
            val swipeRightChannel = io.flutter.plugin.common.BasicMessageChannel(
                binaryMessenger,
                "dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.onSwipeRight",
                codec
            )
            swipeRightChannel.setMessageHandler { _, reply ->
                val currentListener = listener
                Log.d(TAG, "📱 [Navigation] Received swipe right event - dismissing reels")
                Log.d(TAG, "   Using current global listener: ${if (currentListener != null) "✅ Set" else "❌ Null"}")
                currentListener?.onReelsClosed()
                currentListener?.onSwipeRight()
                reply.reply(null)
            }

            // Handle user profile click events
            val userProfileClickChannel = io.flutter.plugin.common.BasicMessageChannel(
                binaryMessenger,
                "dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.onUserProfileClick",
                codec
            )
            userProfileClickChannel.setMessageHandler { message, reply ->
                Log.d(TAG, "📱 [Navigation] Received user profile click event [CODE_VERSION=1]")

                // Message is a List: [userId, userName]
                val args = message as? List<*>
                if (args != null && args.size >= 2) {
                    val userId = args[0] as? String ?: ""
                    val userName = args[1] as? String ?: ""

                    // IMPORTANT: Capture listener at EVENT TIME, not registration time
                    // This ensures we always use the most recent listener after navigation
                    val currentListener = listener
                    Log.d(TAG, "   User ID: $userId, User Name: $userName [CODE_VERSION=1]")
                    Log.d(TAG, "   Using current global listener: ${if (currentListener != null) "✅ Set" else "❌ Null"} [CODE_VERSION=1]")
                    currentListener?.onUserProfileClick(userId, userName)
                }

                reply.reply(null)
            }

            // Handle swipe left events (open user profile)
            val swipeLeftChannel = io.flutter.plugin.common.BasicMessageChannel(
                binaryMessenger,
                "dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.onSwipeLeft",
                codec
            )
            swipeLeftChannel.setMessageHandler { message, reply ->
                Log.d(TAG, "📱 [Navigation] Received swipe left event [CODE_VERSION=1]")

                // Message is a List: [userId, userName]
                val args = message as? List<*>
                if (args != null && args.size >= 2) {
                    val userId = args[0] as? String ?: ""
                    val userName = args[1] as? String ?: ""

                    // IMPORTANT: Capture listener at EVENT TIME, not registration time
                    val currentListener = listener
                    Log.d(TAG, "   User ID: $userId, User Name: $userName [CODE_VERSION=1]")
                    Log.d(TAG, "   Using current global listener: ${if (currentListener != null) "✅ Set" else "❌ Null"} [CODE_VERSION=1]")
                    currentListener?.onSwipeLeft(userId, userName)
                }

                reply.reply(null)
            }

            Log.d(TAG, "✅ Navigation handlers registered on messenger ${binaryMessenger.hashCode()} [CODE_VERSION=1]")
        }
        
        /**
         * Initialize the Flutter Reels SDK with access token provider
         * Uses FlutterEngineGroup for efficient multi-modal support
         */
        @JvmStatic
        fun initialize(context: Context, accessTokenProvider: (() -> String?)? = null) {
            if (isInitialized) {
                Log.d(TAG, "SDK already initialized")
                return
            }

            try {
                Log.d(TAG, "Initializing ReelsFlutterSDK with FlutterEngineGroup...")

                // Store the access token provider
                this.accessTokenProvider = accessTokenProvider

                // Initialize FlutterEngineGroup for efficient multi-modal support
                flutterEngineGroup = FlutterEngineGroup(context.applicationContext)
                Log.d(TAG, "✅ FlutterEngineGroup created - enables efficient nested modals")

                // Create primary engine for shared setup and caching
                val engine = initializeReelsEngine(context)
                if (engine != null) {
                    // Cache the primary FlutterEngine for backward compatibility
                    FlutterEngineCache.getInstance().put("${FLUTTER_ENGINE_ID_PREFIX}_primary", engine)
                    Log.e(TAG, "[CODE_VERSION=2] Line 303: Primary Flutter engine cached")
                    Log.e(TAG, "[CODE_VERSION=2] Line 304: CHECKPOINT A - Before setupPigeonAPIs call")

                    // Setup Pigeon APIs after engine is ready
                    Log.e(TAG, "[CODE_VERSION=2] Line 307: About to call setupPigeonAPIs")
                    try {
                        setupPigeonAPIs(engine.dartExecutor.binaryMessenger)
                        Log.e(TAG, "[CODE_VERSION=2] Line 309: CHECKPOINT B - setupPigeonAPIs completed successfully")
                    } catch (e: Exception) {
                        Log.e(TAG, "[CODE_VERSION=2] ❌ CRITICAL ERROR in setupPigeonAPIs", e)
                        throw e
                    }
                    Log.e(TAG, "[CODE_VERSION=2] Line 314: After setupPigeonAPIs try-catch")

                    // Mark as initialized
                    isInitialized = true
                    Log.d(TAG, "✅ ReelsFlutterSDK initialized successfully with multi-modal support")

                    // Log initial engine status
                    logEngineStatus()
                } else {
                    throw ReelsException("Failed to initialize Flutter engine")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize SDK", e)
                throw ReelsException("SDK initialization failed: ${e.message}", e)
            }
        }
        
        /**
         * Initialize the Flutter engine for reels with enhanced plugin registration
         */
        private fun initializeReelsEngine(context: Context, flutterModule: String = "reels_flutter"): FlutterEngine? {
            Log.d(TAG, "Initializing Reels Flutter Engine...")
            
            try {
                val engine = FlutterEngine(context)
                
                // Pre-register plugins before Dart execution
                Log.d(TAG, "Pre-registering video player plugins...")
                registerVideoPlayerPlugins(engine, context)
                
                // Execute Dart entrypoint after plugin registration
                val dartEntrypoint = DartExecutor.DartEntrypoint.createDefault()
                engine.dartExecutor.executeDartEntrypoint(dartEntrypoint)
                
                // Warm up the engine by accessing plugins registry
                engine.plugins.has(io.flutter.plugins.videoplayer.VideoPlayerPlugin::class.java)
                
                flutterEngine = engine
                Log.d(TAG, "Reels Flutter Engine initialized successfully")
                return engine
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize Reels Flutter Engine", e)
                return null
            }
        }
        
        /**
         * Set listener for reels events
         * Also saves the first non-null listener as the root listener for multimodal navigation
         */
        @JvmStatic
        fun setListener(listener: ReelsListener?) {
            Log.d(TAG, "[CODE_VERSION=$CODE_VERSION] setListener() called - updating global listener")

            // Save the FIRST listener as root (app's listener, typically MyRoomFragment)
            // Only save if BOTH conditions are true:
            // 1. No root listener saved yet (rootListener == null)
            // 2. No current listener exists (this.listener == null) - ensures we only save the VERY FIRST call
            // This prevents FlutterReelsActivity's forwarding wrapper from overwriting the root
            if (listener != null && rootListener == null && this.listener == null) {
                rootListener = listener
                Log.d(TAG, "[CODE_VERSION=$CODE_VERSION] 🎯 Saved root listener (first ever listener)")
                Log.d(TAG, "[CODE_VERSION=$CODE_VERSION]    Type: ${listener.javaClass.simpleName}")
                Log.d(TAG, "[CODE_VERSION=$CODE_VERSION]    HashCode: ${listener.hashCode()}")
            }

            this.listener = listener
        }

        /**
         * Get the current listener
         * @return Current listener or null if not set
         */
        fun getListener(): ReelsListener? {
            return listener
        }

        /**
         * Get the root listener (the original app listener, not activity forwarding listeners)
         * This is used for multimodal navigation to ensure profile clicks work from nested activities
         * @return Root listener or null if not set
         */
        internal fun getRootListener(): ReelsListener? {
            return rootListener
        }

        /**
         * Set the currently active FlutterReelsActivity
         * This is called by FlutterReelsActivity in onResume()
         */
        internal fun setCurrentActivity(activity: FlutterReelsActivity) {
            currentActivity = java.lang.ref.WeakReference(activity)
            Log.d(TAG, "📍 Current activity set: ${activity.javaClass.simpleName}")
        }

        /**
         * Clear the current activity reference
         * This is called by FlutterReelsActivity in onPause()
         */
        internal fun clearCurrentActivity(activity: FlutterReelsActivity) {
            if (currentActivity?.get() == activity) {
                currentActivity = null
                Log.d(TAG, "📍 Current activity cleared: ${activity.javaClass.simpleName}")
            }
        }

        /**
         * Get the Flutter engine instance
         */
        @JvmStatic
        fun getFlutterEngine(): FlutterEngine? = flutterEngine
        
        /**
         * Get the Flutter engine ID for use with cached engines
         */
        @JvmStatic
        fun getEngineId(): String = FLUTTER_ENGINE_ID_PREFIX
        
        /**
         * Track analytics event
         */
        @JvmStatic
        fun trackEvent(eventName: String, properties: Map<String, String> = emptyMap()) {
            checkInitialized()
            val event = AnalyticsEvent(eventName, properties.mapKeys { it.key as String? }.mapValues { it.value as String? })
            analyticsApi?.trackEvent(event) { result ->
                if (result.isFailure) {
                    Log.e(TAG, "Failed to track event: ${result.exceptionOrNull()}")
                }
            }
        }
        
        /**
         * Notify Flutter about like button interaction
         */
        @JvmStatic
        fun notifyLikeButtonClick(videoId: String, isLiked: Boolean, likeCount: Int) {
            checkInitialized()
            buttonEventsApi?.onAfterLikeButtonClick(videoId, isLiked, likeCount.toLong()) { result ->
                if (result.isFailure) {
                    Log.e(TAG, "Failed to notify like button click: ${result.exceptionOrNull()}")
                }
            }
        }
        
        /**
         * Notify Flutter about share button interaction
         */
        @JvmStatic
        fun notifyShareButtonClick(videoId: String, videoUrl: String, title: String, description: String, thumbnailUrl: String? = null) {
            checkInitialized()
            val shareData = ShareData(videoId, videoUrl, title, description, thumbnailUrl)
            buttonEventsApi?.onShareButtonClick(shareData) { result ->
                if (result.isFailure) {
                    Log.e(TAG, "Failed to notify share button click: ${result.exceptionOrNull()}")
                } else {
                    listener?.onReelShared(videoId)
                }
            }
        }
        
        /**
         * Notify Flutter about screen state changes
         */
        @JvmStatic
        fun notifyScreenStateChanged(screenName: String, state: String) {
            checkInitialized()
            val stateData = ScreenStateData(screenName, state, System.currentTimeMillis())
            stateApi?.onScreenStateChanged(stateData) { result ->
                if (result.isFailure) {
                    Log.e(TAG, "Failed to notify screen state change: ${result.exceptionOrNull()}")
                }
            }
        }
        
        /**
         * Notify Flutter about video state changes
         */
        @JvmStatic
        fun notifyVideoStateChanged(videoId: String, state: String, position: Int? = null, duration: Int? = null) {
            checkInitialized()
            val stateData = VideoStateData(
                videoId,
                state,
                position?.toLong(),
                duration?.toLong(),
                System.currentTimeMillis()
            )
            stateApi?.onVideoStateChanged(stateData) { result ->
                if (result.isFailure) {
                    Log.e(TAG, "Failed to notify video state change: ${result.exceptionOrNull()}")
                } else {
                    if (state == "completed") {
                        listener?.onReelViewed(videoId)
                    }
                }
            }
        }

        /**
         * Pause all Flutter resources (videos, network) when screen loses focus
         */
        @JvmStatic
        fun pauseAll() {
            checkInitialized()
            lifecycleApi?.pauseAll { result ->
                if (result.isFailure) {
                    Log.e(TAG, "Failed to pause all resources: ${result.exceptionOrNull()}")
                } else {
                    Log.d(TAG, "Successfully paused all Flutter resources")
                }
            }
        }

        /**
         * Resume all Flutter resources (videos, network) when screen gains focus
         * @param generation The generation number of the screen being resumed
         */
        @JvmStatic
        fun resumeAll(generation: Long) {
            checkInitialized()

            // Get the specific engine for this generation
            val engine = engineCache[generation.toInt()]
            if (engine == null) {
                Log.w(TAG, "No engine found for generation $generation, using primary engine")
                lifecycleApi?.resumeAll(generation) { result ->
                    if (result.isFailure) {
                        Log.e(TAG, "Failed to resume all resources: ${result.exceptionOrNull()}")
                    } else {
                        Log.d(TAG, "Successfully resumed all Flutter resources for generation $generation")
                    }
                }
                return
            }

            // Create lifecycle API for this specific engine
            val generationLifecycleApi = ReelsFlutterLifecycleApi(engine.dartExecutor.binaryMessenger)
            generationLifecycleApi.resumeAll(generation) { result ->
                if (result.isFailure) {
                    Log.e(TAG, "Failed to resume all resources for generation $generation: ${result.exceptionOrNull()}")
                } else {
                    Log.d(TAG, "Successfully resumed all Flutter resources for generation $generation")
                }
            }
        }

        /**
         * Check if SDK is initialized
         */
        private fun checkInitialized() {
            if (!isInitialized) {
                throw ReelsException("SDK not initialized. Call initialize() first.")
            }
        }

        /**
         * Create a new Flutter engine for a specific generation using FlutterEngineGroup
         * This enables efficient nested modals with shared resources
         *
         * @param context Application context
         * @param generation Generation number for this modal instance
         * @param initialRoute Initial Flutter route (default: "/")
         * @return Engine ID to use with FlutterActivity.withCachedEngine()
         */
        @JvmStatic
        fun createEngineForGeneration(context: Context, generation: Int, initialRoute: String = "/"): String {
            checkInitialized()

            val engineId = "${FLUTTER_ENGINE_ID_PREFIX}_gen_$generation"

            // Check if engine already exists for this generation
            if (engineCache.containsKey(generation)) {
                Log.d(TAG, "✅ Engine already exists for generation $generation")
                return engineId
            }

            try {
                Log.d(TAG, "🎬 Creating Flutter engine for generation $generation (route: $initialRoute)")

                // Create engine from group for efficient resource sharing
                val dartEntrypoint = DartExecutor.DartEntrypoint.createDefault()
                val engine = flutterEngineGroup?.createAndRunEngine(context, dartEntrypoint, initialRoute)
                    ?: throw ReelsException("FlutterEngineGroup not initialized")

                // Register plugins for this engine
                registerVideoPlayerPlugins(engine, context)

                // Setup Pigeon APIs for this engine (analytics, state, navigation, etc.)
                // Navigation handlers are set up per-engine but use the CURRENT global listener
                Log.e(TAG, "[CODE_VERSION=2] CHECKPOINT C - Before setupPigeonAPIs call for generation $generation")
                try {
                    setupPigeonAPIs(engine.dartExecutor.binaryMessenger)
                    Log.e(TAG, "[CODE_VERSION=2] CHECKPOINT D - setupPigeonAPIs completed for generation $generation")
                } catch (e: Exception) {
                    Log.e(TAG, "[CODE_VERSION=2] ❌ ERROR in setupPigeonAPIs for generation $generation", e)
                    throw e
                }

                // Cache the engine
                engineCache[generation] = engine
                FlutterEngineCache.getInstance().put(engineId, engine)

                Log.d(TAG, "✅ Engine created and cached for generation $generation (ID: $engineId)")
                Log.d(TAG, "📊 Total engines in cache: ${engineCache.size}")

                // Log detailed engine status
                logEngineStatus()

                return engineId
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to create engine for generation $generation", e)
                throw ReelsException("Failed to create engine for generation $generation: ${e.message}", e)
            }
        }

        /**
         * Get engine ID for a specific generation
         * @param generation Generation number
         * @return Engine ID or null if not found
         */
        @JvmStatic
        fun getEngineIdForGeneration(generation: Int): String? {
            val engineId = "${FLUTTER_ENGINE_ID_PREFIX}_gen_$generation"
            val exists = engineCache.containsKey(generation)

            if (exists) {
                Log.d(TAG, "✅ Found existing engine for generation $generation")
            } else {
                Log.d(TAG, "⚠️ No engine found for generation $generation")
            }

            return if (exists) engineId else null
        }

        /**
         * Clean up engine for a specific generation
         * @param generation Generation number to cleanup
         */
        @JvmStatic
        fun cleanupEngineForGeneration(generation: Int) {
            val engineId = "${FLUTTER_ENGINE_ID_PREFIX}_gen_$generation"

            engineCache[generation]?.let { engine ->
                try {
                    Log.d(TAG, "🗑️ Cleaning up engine for generation $generation")
                    engine.destroy()
                    engineCache.remove(generation)
                    FlutterEngineCache.getInstance().remove(engineId)
                    Log.d(TAG, "✅ Engine cleaned up for generation $generation")
                    Log.d(TAG, "📊 Remaining engines: ${engineCache.size}")

                    // Log updated engine status
                    logEngineStatus()
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error cleaning up engine for generation $generation", e)
                }
            } ?: Log.w(TAG, "⚠️ No engine found for generation $generation")
        }

        /**
         * Clean up resources
         */
        @JvmStatic
        fun dispose() {
            try {
                // Cleanup all generation engines
                engineCache.keys.toList().forEach { generation ->
                    cleanupEngineForGeneration(generation)
                }

                // Cleanup primary engine
                flutterEngine?.destroy()
                FlutterEngineCache.getInstance().remove("${FLUTTER_ENGINE_ID_PREFIX}_primary")

                // Clear all references
                flutterEngine = null
                flutterEngineGroup = null
                engineCache.clear()
                listener = null
                accessTokenProvider = null
                analyticsApi = null
                buttonEventsApi = null
                stateApi = null
                lifecycleApi = null
                isInitialized = false

                Log.d(TAG, "SDK disposed and all engines cleaned up")
            } catch (e: Exception) {
                Log.e(TAG, "Error disposing SDK", e)
            }
        }

        /**
         * Log current engine status - useful for debugging
         */
        @JvmStatic
        fun logEngineStatus() {
            Log.d(TAG, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Log.d(TAG, "📊 Flutter Engine Status Report")
            Log.d(TAG, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Log.d(TAG, "SDK Initialized: $isInitialized")
            Log.d(TAG, "FlutterEngineGroup: ${if (flutterEngineGroup != null) "✅ Active" else "❌ Null"}")
            Log.d(TAG, "Primary Engine: ${if (flutterEngine != null) "✅ Active" else "❌ Null"}")
            Log.d(TAG, "Total Engines in Cache: ${engineCache.size}")

            if (engineCache.isNotEmpty()) {
                Log.d(TAG, "Active Generations:")
                engineCache.keys.sorted().forEach { generation ->
                    val engineId = "${FLUTTER_ENGINE_ID_PREFIX}_gen_$generation"
                    val engine = engineCache[generation]
                    Log.d(TAG, "  • Generation $generation (ID: $engineId) - ${if (engine != null) "✅ Active" else "❌ Null"}")
                }
            } else {
                Log.d(TAG, "No generation-specific engines active")
            }

            Log.d(TAG, "Access Token Provider: ${if (accessTokenProvider != null) "✅ Set" else "⚠️ Not set"}")
            Log.d(TAG, "Listener: ${if (listener != null) "✅ Set" else "⚠️ Not set"}")
            Log.d(TAG, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }

        /**
         * Register essential plugins for video functionality with enhanced initialization
         */
        private fun registerVideoPlayerPlugins(engine: FlutterEngine, context: Context) {
            try {
                Log.d(TAG, "Registering plugins for Flutter engine with enhanced strategy...")
                
                var registrationSuccessful = false
                
                // Approach 1: Use Flutter's built-in plugin registrant (most reliable)
                try {
                    val registrantClass = Class.forName("io.flutter.plugins.GeneratedPluginRegistrant")
                    val registerMethod = registrantClass.getMethod("registerWith", FlutterEngine::class.java)
                    registerMethod.invoke(null, engine)
                    Log.d(TAG, "Plugins registered via GeneratedPluginRegistrant (Flutter built-in)")
                    
                    // Validate registration
                    val hasVideoPlayer = try {
                        engine.plugins.has(io.flutter.plugins.videoplayer.VideoPlayerPlugin::class.java)
                    } catch (e: Exception) {
                        Log.w(TAG, "Could not validate video player plugin: ${e.message}")
                        false
                    }
                    
                    if (hasVideoPlayer) {
                        registrationSuccessful = true
                        Log.d(TAG, "Video player plugin validation: SUCCESS")
                    } else {
                        Log.w(TAG, "Video player plugin validation: FAILED, trying fallback")
                    }
                } catch (e: Exception) {
                    Log.d(TAG, "GeneratedPluginRegistrant not available: ${e.message}")
                }
                
                // Approach 2: Try app-specific registrant
                if (!registrationSuccessful) {
                    try {
                        val appRegistrantClass = Class.forName("com.rakuten.room.GeneratedPluginRegistrant")
                        val registerMethod = appRegistrantClass.getMethod("registerWith", FlutterEngine::class.java)
                        registerMethod.invoke(null, engine)
                        Log.d(TAG, "Plugins registered via app-specific GeneratedPluginRegistrant")
                        registrationSuccessful = true
                    } catch (e: Exception) {
                        Log.d(TAG, "App-specific GeneratedPluginRegistrant not available: ${e.message}")
                    }
                }
                
                // Approach 3: Register video player plugin directly with enhanced binding
                if (!registrationSuccessful) {
                    try {
                        Log.d(TAG, "Attempting direct video player plugin registration...")
                        
                        // Import the actual video player plugin class
                        val videoPlayerPlugin = io.flutter.plugins.videoplayer.VideoPlayerPlugin()
                        
                        // Add to engine with proper binding context
                        engine.plugins.add(videoPlayerPlugin)
                        
                        // Force binding initialization if possible
                        try {
                            val pluginBinding = engine.plugins.get(io.flutter.plugins.videoplayer.VideoPlayerPlugin::class.java)
                            Log.d(TAG, "Video player plugin binding: ${pluginBinding != null}")
                        } catch (e: Exception) {
                            Log.w(TAG, "Could not retrieve plugin binding: ${e.message}")
                        }

                        Log.d(TAG, "Video player plugin registered directly")
                        registrationSuccessful = true
                        
                    } catch (e: Exception) {
                        Log.e(TAG, "Direct video player plugin registration failed: ${e.message}")
                        
                        // Final fallback: reflection-based registration
                        try {
                            val videoPlayerPluginClass = Class.forName("io.flutter.plugins.videoplayer.VideoPlayerPlugin")
                            val plugin = videoPlayerPluginClass.getDeclaredConstructor().newInstance() as FlutterPlugin
                            engine.plugins.add(plugin)
                            Log.d(TAG, "Video player plugin registered via reflection fallback")
                            registrationSuccessful = true
                        } catch (reflectionException: Exception) {
                            Log.e(TAG, "Reflection fallback also failed: ${reflectionException.message}")
                        }
                    }
                }
                
                // Final validation and warming
                if (registrationSuccessful) {
                    try {
                        // Warm up the plugin by accessing the registry
                        val pluginRegistry = engine.plugins
                        Log.d(TAG, "Plugin registry warmed up, available plugins: ${pluginRegistry.javaClass.simpleName}")
                        
                        // Give the engine a moment to initialize plugins
                        Thread.sleep(100)
                        
                    } catch (e: Exception) {
                        Log.w(TAG, "Plugin warming failed but registration was successful: ${e.message}")
                    }
                } else {
                    Log.e(TAG, "CRITICAL: All plugin registration methods failed!")
                    Log.e(TAG, "Video playback will likely not work. Check dependencies and imports.")
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Fatal error during plugin registration", e)
            }
        }
    }
}

/**
 * Listener interface for reels events (callbacks from Flutter via Pigeon)
 * Matches iOS ReelsListener protocol
 */
interface ReelsListener {
    /**
     * Called when a reel video completes playback
     */
    fun onReelViewed(videoId: String) {}

    /**
     * Called after user likes/unlikes a reel
     */
    fun onReelLiked(videoId: String, isLiked: Boolean) {}

    /**
     * Called when user shares a reel
     */
    fun onReelShared(videoId: String) {}

    /**
     * Called when reels screen is closed
     */
    fun onReelsClosed() {}

    /**
     * Called on any error
     */
    fun onError(errorMessage: String) {}

    /**
     * Called when user performs a like action
     * @param videoId Video ID that was liked
     * @param isLiked Whether the video is now liked
     * @param likeCount Updated like count
     */
    fun onLikeButtonClick(videoId: String, isLiked: Boolean, likeCount: Int) {}

    /**
     * Called when user shares a video
     * @param videoId Video ID
     * @param videoUrl URL of the video
     * @param title Video title
     * @param description Video description
     * @param thumbnailUrl Optional thumbnail URL
     */
    fun onShareButtonClick(videoId: String, videoUrl: String, title: String, description: String, thumbnailUrl: String?) {}

    /**
     * Called when screen state changes
     * @param screenName Screen name
     * @param state State (appeared, disappeared, focused, unfocused)
     */
    fun onScreenStateChanged(screenName: String, state: String) {}

    /**
     * Called when video state changes
     * @param videoId Video ID
     * @param state State (playing, paused, stopped, buffering, completed)
     * @param position Current position in seconds (optional)
     * @param duration Total duration in seconds (optional)
     */
    fun onVideoStateChanged(videoId: String, state: String, position: Int?, duration: Int?) {}

    /**
     * Called when user swipes left (opens user's My Room)
     * @param userId User ID to navigate to
     * @param userName User name for display
     */
    fun onSwipeLeft(userId: String, userName: String) {}

    /**
     * Called when user swipes right
     */
    fun onSwipeRight() {}

    /**
     * Called when user clicks on profile/user image
     * @param userId User ID
     * @param userName User name
     */
    fun onUserProfileClick(userId: String, userName: String) {}

    /**
     * Called when analytics event is tracked
     * @param eventName Event name
     * @param properties Event properties
     */
    fun onAnalyticsEvent(eventName: String, properties: Map<String, String>) {}

    /**
     * Provide access token for authenticated API calls
     * (Alternative to passing accessTokenProvider in initialize)
     */
    fun getAccessToken(): String? = null
}

/**
 * Exception thrown by Reels SDK
 */
class ReelsException(message: String, cause: Throwable? = null) : RuntimeException(message, cause)