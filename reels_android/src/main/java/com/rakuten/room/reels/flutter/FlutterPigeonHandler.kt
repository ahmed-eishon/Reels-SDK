package com.rakuten.room.reels.flutter

import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast
import io.flutter.embedding.engine.FlutterEngine
import com.rakuten.reels.pigeon.*
import com.rakuten.room.reels.ReelsModule
import com.rakuten.room.reels.CollectData as NativeCollectData

/**
 * Pigeon-based handler for type-safe communication between Android and Flutter
 * Replaces the old method channel implementation with generated APIs
 */
class FlutterPigeonHandler(private val context: Context) : ReelsHostApi {
    
    private var flutterApi: ReelsFlutterApi? = null
    
    fun setupPigeonApi(flutterEngine: FlutterEngine) {
        // Setup Host API - Android methods that Flutter can call
        ReelsHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, this)
        
        // Setup Flutter API - Flutter methods that Android can call
        flutterApi = ReelsFlutterApi(flutterEngine.dartExecutor.binaryMessenger)
    }
    
    // Implementation of ReelsHostApi methods
    
    override fun getUserProfile(): UserProfile {
        // Return mock user profile data
        return UserProfile(
            id = "12345",
            name = "Room User",
            avatar = "https://example.com/avatar.jpg",
            reelsCount = 42L,
            followersCount = 1500L,
            followingCount = 234L
        )
    }
    
    override fun shareReel(reelId: String, title: String, description: String?) {
        // Implement native sharing functionality using Android's share intent
        val shareText = buildString {
            append("Check out this reel: $title")
            if (description != null) {
                append("\n$description")
            }
            append("\nReel ID: $reelId")
        }
        
        val shareIntent = Intent().apply {
            action = Intent.ACTION_SEND
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, shareText)
        }
        
        val chooserIntent = Intent.createChooser(shareIntent, "Share Reel")
        chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(chooserIntent)
        
        println("Sharing reel: $reelId - $title")
    }
    
    override fun openNativeScreen(screenName: String, params: Map<String, Any?>) {
        // Navigate to native Android screens
        when (screenName) {
            "profile" -> {
                openProfileScreen(params)
            }
            "settings" -> {
                openSettingsScreen(params)
            }
            "home" -> {
                openHomeScreen(params)
            }
            else -> {
                println("Unknown screen: $screenName")
            }
        }
    }
    
    override fun logAnalyticsEvent(eventName: String, parameters: Map<String, Any?>) {
        // Implement analytics logging
        println("Analytics Event: $eventName with parameters: $parameters")
        
        // Here you would integrate with your analytics service like:
        // Firebase Analytics, Adobe Analytics, etc.
        // Example:
        // FirebaseAnalytics.getInstance(context).logEvent(eventName, Bundle().apply {
        //     parameters.forEach { (key, value) ->
        //         when (value) {
        //             is String -> putString(key, value)
        //             is Number -> putDouble(key, value.toDouble())
        //             is Boolean -> putBoolean(key, value)
        //         }
        //     }
        // })
    }
    
    override fun showToast(message: String) {
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }
    
    override fun getAppPreferences(): AppPreferences {
        // Return mock app preferences
        // In a real app, you'd read from SharedPreferences or other storage
        return AppPreferences(
            darkMode = false,
            language = "en",
            notificationsEnabled = true,
            autoPlayVideos = true
        )
    }
    
    override fun saveAppPreferences(preferences: AppPreferences) {
        // Save preferences to SharedPreferences or other storage
        println("Saving preferences: darkMode=${preferences.darkMode}, language=${preferences.language}")
        
        // Example SharedPreferences usage:
        // val prefs = context.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
        // prefs.edit().apply {
        //     putBoolean("dark_mode", preferences.darkMode)
        //     putString("language", preferences.language)
        //     putBoolean("notifications_enabled", preferences.notificationsEnabled)
        //     putBoolean("auto_play_videos", preferences.autoPlayVideos)
        //     apply()
        // }
    }
    
    override fun getReels(page: Long, limit: Long): List<ReelData> {
        // Return mock reels data
        // In a real app, you'd fetch from your backend API
        return (1..limit.toInt()).map { index ->
            val reelIndex = (page * limit + index).toInt()
            ReelData(
                id = "reel_$reelIndex",
                title = "Sample Reel $reelIndex",
                description = "This is a sample reel description for reel $reelIndex",
                videoUrl = "https://example.com/reel_$reelIndex.mp4",
                thumbnailUrl = "https://example.com/thumbnail_$reelIndex.jpg",
                likeCount = (100..5000).random().toLong(),
                viewCount = (1000..50000).random().toLong(),
                isLiked = (0..1).random() == 1
            )
        }
    }
    
    override fun toggleReelLike(reelId: String, isLiked: Boolean) {
        // Handle like/unlike functionality
        println("Toggle like for reel $reelId: $isLiked")
        
        // In a real app, you'd update the backend and local storage
        // Then potentially call Flutter to update the UI:
        // sendReelLikeUpdate(reelId, isLiked)
    }
    
    override fun reportContent(reelId: String, reason: String) {
        // Handle content reporting
        println("Reported content - Reel: $reelId, Reason: $reason")
        
        // In a real app, you'd send this to your moderation system
        showToast("Content reported successfully")
    }
    
    override fun navigateBack() {
        // Handle navigation back to native screens
        if (context is android.app.Activity) {
            context.finish()
        }
    }

    override fun getInitialCollect(generation: Long): CollectData? {
        try {
            val nativeCollectData = ReelsModule.getInitialCollect(generation.toInt())

            return if (nativeCollectData != null) {
                Log.d("FlutterPigeonHandler", "getInitialCollect($generation) -> returning: ${nativeCollectData.id}")
                // Convert native CollectData to Pigeon CollectData
                CollectData(
                    id = nativeCollectData.id,
                    content = nativeCollectData.content,
                    name = nativeCollectData.name,
                    likes = nativeCollectData.likes,
                    comments = nativeCollectData.comments,
                    recollects = nativeCollectData.recollects,
                    isLiked = nativeCollectData.isLiked,
                    isCollected = nativeCollectData.isCollected,
                    trackingTag = nativeCollectData.trackingTag,
                    userId = nativeCollectData.userId,
                    userName = nativeCollectData.userName,
                    userProfileImage = nativeCollectData.userProfileImage,
                    itemName = nativeCollectData.itemName,
                    itemImageUrl = nativeCollectData.itemImageUrl,
                    imageUrl = nativeCollectData.imageUrl
                )
            } else {
                Log.d("FlutterPigeonHandler", "getInitialCollect($generation) -> returning: null")
                null
            }
        } catch (e: Exception) {
            Log.e("FlutterPigeonHandler", "Error in getInitialCollect", e)
            return null
        }
    }

    // Helper methods for native screen navigation
    
    private fun openProfileScreen(params: Map<String, Any?>) {
        println("Opening native profile screen with params: $params")
        // Implement navigation to profile screen
        // Example: context.startActivity(Intent(context, ProfileActivity::class.java))
    }
    
    private fun openSettingsScreen(params: Map<String, Any?>) {
        println("Opening native settings screen with params: $params")
        // Implement navigation to settings screen
        // Example: context.startActivity(Intent(context, SettingsActivity::class.java))
    }
    
    private fun openHomeScreen(params: Map<String, Any?>) {
        println("Opening native home screen with params: $params")
        // Implement navigation to home screen
        // Example: context.startActivity(Intent(context, MainActivity::class.java))
    }
    
    // Methods to send data from Android to Flutter
    
    fun sendUserProfileUpdate(profile: UserProfile) {
        flutterApi?.onUserProfileUpdated(profile) { result ->
            if (result.isFailure) {
                println("Failed to send user profile update: ${result.exceptionOrNull()}")
            }
        }
    }
    
    fun sendPreferencesUpdate(preferences: AppPreferences) {
        flutterApi?.onPreferencesChanged(preferences) { result ->
            if (result.isFailure) {
                println("Failed to send preferences update: ${result.exceptionOrNull()}")
            }
        }
    }
    
    fun triggerRefresh() {
        flutterApi?.refreshReels { result ->
            if (result.isFailure) {
                println("Failed to trigger refresh: ${result.exceptionOrNull()}")
            }
        }
    }
    
    fun navigateToFlutterScreen(screenName: String, params: Map<String, Any?> = emptyMap()) {
        flutterApi?.navigateToScreen(screenName, params) { result ->
            if (result.isFailure) {
                println("Failed to navigate to Flutter screen: ${result.exceptionOrNull()}")
            }
        }
    }
    
    fun updateFlutterTheme(isDarkMode: Boolean) {
        flutterApi?.updateTheme(isDarkMode) { result ->
            if (result.isFailure) {
                println("Failed to update Flutter theme: ${result.exceptionOrNull()}")
            }
        }
    }
    
    fun handleDeepLink(url: String, params: Map<String, Any?> = emptyMap()) {
        flutterApi?.handleDeepLink(url, params) { result ->
            if (result.isFailure) {
                println("Failed to handle deep link: ${result.exceptionOrNull()}")
            }
        }
    }
    
    fun showFlutterMessage(message: String, type: String = "info") {
        flutterApi?.showMessage(message, type) { result ->
            if (result.isFailure) {
                println("Failed to show Flutter message: ${result.exceptionOrNull()}")
            }
        }
    }
    
    fun updateReelData(reels: List<ReelData>) {
        flutterApi?.updateReelData(reels) { result ->
            if (result.isFailure) {
                println("Failed to update reel data: ${result.exceptionOrNull()}")
            }
        }
    }
    
    fun cleanup() {
        // Clean up Pigeon APIs - we don't need to call setUp with null for cleanup
        // The APIs will be cleaned up when the Flutter engine is destroyed
        flutterApi = null
    }
}