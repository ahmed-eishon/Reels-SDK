package com.rakuten.room.reels.flutter

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import com.rakuten.room.reels.pigeon.*
import com.rakuten.room.reels.pigeon.CollectData

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
        
        private var flutterEngine: FlutterEngine? = null
        private var listener: ReelsListener? = null
        private var accessTokenProvider: (() -> String?)? = null
        private var isInitialized = false
        
        // Pigeon API instances
        private var analyticsApi: ReelsFlutterAnalyticsApi? = null
        private var buttonEventsApi: ReelsFlutterButtonEventsApi? = null
        private var stateApi: ReelsFlutterStateApi? = null
        private var navigationApi: ReelsFlutterNavigationApi? = null
        private var lifecycleApi: ReelsFlutterLifecycleApi? = null
        
        /**
         * Setup all Pigeon API handlers
         */
        private fun setupPigeonAPIs(binaryMessenger: BinaryMessenger) {
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
                    val collectData = com.rakuten.room.reels.ReelsModule.getInitialCollect(generation.toInt())
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
                    val generation = com.rakuten.room.reels.ReelsModule.getCurrentGeneration()
                    Log.d(TAG, "Current generation requested: $generation")
                    return generation.toLong()
                }

                override fun isDebugMode(): Boolean {
                    val debugMode = com.rakuten.room.reels.ReelsModule.isDebugMode()
                    Log.d(TAG, "Debug mode requested: $debugMode")
                    return debugMode
                }
            })

            // Flutter APIs: Android calls Flutter methods
            analyticsApi = ReelsFlutterAnalyticsApi(binaryMessenger)
            buttonEventsApi = ReelsFlutterButtonEventsApi(binaryMessenger)
            stateApi = ReelsFlutterStateApi(binaryMessenger)
            navigationApi = ReelsFlutterNavigationApi(binaryMessenger)
            lifecycleApi = ReelsFlutterLifecycleApi(binaryMessenger)

            // Setup navigation event listeners from Flutter
            setupNavigationEventHandlers(binaryMessenger)
        }

        /**
         * Setup handlers to receive navigation events from Flutter
         * Note: dismissReels is defined as @FlutterApi in Pigeon but used as Host API
         * We manually set up a listener similar to iOS implementation
         */
        private fun setupNavigationEventHandlers(binaryMessenger: BinaryMessenger) {
            val codec = io.flutter.plugin.common.StandardMessageCodec.INSTANCE

            // Handle dismiss reels events
            val dismissReelsChannel = io.flutter.plugin.common.BasicMessageChannel(
                binaryMessenger,
                "dev.flutter.pigeon.reels_flutter.ReelsFlutterNavigationApi.dismissReels",
                codec
            )
            dismissReelsChannel.setMessageHandler { _, reply ->
                Log.d(TAG, "Received dismiss reels request")

                // Notify listener that reels screen should be closed
                listener?.onReelsClosed()

                reply.reply(null)
            }
        }
        
        /**
         * Initialize the Flutter Reels SDK with access token provider
         */
        @JvmStatic
        fun initialize(context: Context, accessTokenProvider: (() -> String?)? = null) {
            if (isInitialized) {
                Log.d(TAG, "SDK already initialized")
                return
            }
            
            try {
                Log.d(TAG, "Initializing ReelsFlutterSDK...")
                
                // Store the access token provider
                this.accessTokenProvider = accessTokenProvider
                
                // Initialize the Flutter engine
                val engine = initializeReelsEngine(context)
                if (engine != null) {
                    // Setup Pigeon APIs after engine is ready
                    setupPigeonAPIs(engine.dartExecutor.binaryMessenger)
                    
                    // Mark as initialized
                    isInitialized = true
                    Log.d(TAG, "ReelsFlutterSDK initialized successfully")
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
         */
        @JvmStatic
        fun setListener(listener: ReelsListener?) {
            this.listener = listener
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
        fun getEngineId(): String = "reels_engine"
        
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
            lifecycleApi?.resumeAll(generation) { result ->
                if (result.isFailure) {
                    Log.e(TAG, "Failed to resume all resources: ${result.exceptionOrNull()}")
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
         * Clean up resources
         */
        @JvmStatic
        fun dispose() {
            try {
                flutterEngine?.destroy()
                flutterEngine = null
                listener = null
                accessTokenProvider = null
                analyticsApi = null
                buttonEventsApi = null
                stateApi = null
                navigationApi = null
                lifecycleApi = null
                isInitialized = false
                Log.d(TAG, "SDK disposed")
            } catch (e: Exception) {
                Log.e(TAG, "Error disposing SDK", e)
            }
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
     * Provide access token for authenticated API calls
     * (Alternative to passing accessTokenProvider in initialize)
     */
    fun getAccessToken(): String? = null
}

/**
 * Exception thrown by Reels SDK
 */
class ReelsException(message: String, cause: Throwable? = null) : RuntimeException(message, cause)