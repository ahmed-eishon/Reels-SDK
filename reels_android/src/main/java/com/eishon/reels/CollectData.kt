package com.eishon.reels

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

/**
 * Data class representing collect/video context to pass to Flutter reels screen.
 * This allows opening reels for a specific video/collect with all its metadata.
 *
 * Usage:
 * ```kotlin
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
 * ```
 */
@Parcelize
data class CollectData(
    val id: String,
    val content: String? = null,
    val name: String? = null,
    val likes: Long? = null,
    val comments: Long? = null,
    val recollects: Long? = null,
    val isLiked: Boolean? = null,
    val isCollected: Boolean? = null,
    val trackingTag: String? = null,
    val userId: String? = null,
    val userName: String? = null,
    val userProfileImage: String? = null,
    val itemName: String? = null,
    val itemImageUrl: String? = null,
    val imageUrl: String? = null
) : Parcelable {

    /**
     * Convert to map for passing through Intent extras
     */
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "content" to content,
            "name" to name,
            "likes" to likes,
            "comments" to comments,
            "recollects" to recollects,
            "isLiked" to isLiked,
            "isCollected" to isCollected,
            "trackingTag" to trackingTag,
            "userId" to userId,
            "userName" to userName,
            "userProfileImage" to userProfileImage,
            "itemName" to itemName,
            "itemImageUrl" to itemImageUrl,
            "imageUrl" to imageUrl
        )
    }

    companion object {
        /**
         * Create CollectData from map
         */
        fun fromMap(map: Map<String, Any?>): CollectData {
            return CollectData(
                id = map["id"] as? String ?: "",
                content = map["content"] as? String,
                name = map["name"] as? String,
                likes = (map["likes"] as? Number)?.toLong(),
                comments = (map["comments"] as? Number)?.toLong(),
                recollects = (map["recollects"] as? Number)?.toLong(),
                isLiked = map["isLiked"] as? Boolean,
                isCollected = map["isCollected"] as? Boolean,
                trackingTag = map["trackingTag"] as? String,
                userId = map["userId"] as? String,
                userName = map["userName"] as? String,
                userProfileImage = map["userProfileImage"] as? String,
                itemName = map["itemName"] as? String,
                itemImageUrl = map["itemImageUrl"] as? String,
                imageUrl = map["imageUrl"] as? String
            )
        }
    }
}
