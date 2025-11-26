---
title: Android Integration Guide
type: integration
tags: [android, integration, kotlin, gradle]
---

# 🤖 Android Integration Guide

> [!info] Complete Android Integration
> Step-by-step guide to integrate Reels SDK into your Android application using Kotlin

## Prerequisites

Before integrating the Reels SDK, ensure you have:

| Requirement | Version | Purpose |
|-------------|---------|---------|
| **Android SDK** | 21+ | Min platform (Android 5.0) |
| **Target SDK** | 35 | Latest Android |
| **Kotlin** | 1.9+ | Programming language |
| **Gradle** | 8.0+ | Build tool |
| **Android Studio** | Latest | Development environment |
| **Flutter SDK** | 3.35.6 | Build-time requirement (CI/CD version) |
| **JDK** | 17 | Build requirement |

## Integration Overview

```mermaid
graph TB
    START[Start Integration] --> CLONE[Clone SDK Repository]
    CLONE --> CHOOSE{Choose Method}

    CHOOSE -->|Production| GIT[Git + Gradle]
    CHOOSE -->|Development| LOCAL[Local Folder Import]

    GIT --> GIT_STEPS[Configure settings.gradle<br/>with sourceControl]
    LOCAL --> LOCAL_STEPS[Run init-android.sh<br/>Configure settings.gradle]

    GIT_STEPS --> DEPS[Add Dependency]
    LOCAL_STEPS --> DEPS

    DEPS --> SYNC[Gradle Sync]
    SYNC --> INIT[Initialize SDK]
    INIT --> USE[Use in App]

    style START fill:#87CEEB
    style GIT fill:#FFB6C1
    style LOCAL fill:#90EE90
    style USE fill:#FFD700
```

## Integration Methods

### Method 1: Local Folder Import (Recommended for Development)

This method is **recommended** for active development as it provides immediate access to SDK changes and faster builds.

#### Step 1: Clone the SDK

```bash
# Navigate to your workspace
cd ~/Workspace

# Clone the SDK repository
git clone https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git

# Navigate into the SDK
cd reels-sdk
```

#### Step 2: Run Initialization Script

```bash
# Run the Android initialization script
./scripts/init-android.sh /path/to/reels-sdk

# Example:
./scripts/init-android.sh ~/Workspace/reels-sdk
```

**What the script does:**
- ✅ Verifies Flutter installation
- ✅ Runs `flutter pub get` to generate `.android` platform files
- ✅ Checks that all required files are present
- ✅ Provides step-by-step integration instructions

#### Step 3: Update settings.gradle

Add the following to your `settings.gradle`:

```gradle
rootProject.name = 'YourApp'
include ':app'

// ===== Reels SDK - Local Folder Import =====

// Include reels_android module
include ':reels_android'
project(':reels_android').projectDir = new File('/absolute/path/to/reels-sdk/reels_android')

// Include Flutter module from reels-sdk
setBinding(new Binding([gradle: this]))
evaluate(new File(
    '/absolute/path/to/reels-sdk/reels_flutter/.android/include_flutter.groovy'
))

// ============================================
```

> [!warning] Important
> - Use **absolute paths** for both `reels_android` and `reels_flutter`
> - Ensure the `.android` directory exists in `reels_flutter` (created by `flutter pub get`)

#### Step 4: Add Dependency in app/build.gradle

```gradle
dependencies {
    // Your existing dependencies...

    // Reels SDK
    implementation project(':reels_android')
}
```

#### Step 5: Sync Gradle

```bash
cd /path/to/your-android-app
./gradlew clean build
```

Or in Android Studio: **File → Sync Project with Gradle Files**

#### Step 6: Build and Run

Build your project in Android Studio. The SDK should compile successfully.

**Advantages of Local Folder Import:**
- ✅ No Git authentication issues
- ✅ Immediate access to SDK updates
- ✅ Faster build times
- ✅ Easy debugging and code navigation
- ✅ Works in corporate environments with firewall restrictions
- ✅ Simpler setup for active development

### Method 2: Git + Gradle (Recommended for Production)

This method is recommended for **production builds** and CI/CD pipelines.

#### Step 1: Configure Git Repository in settings.gradle

Add to your `settings.gradle`:

```gradle
rootProject.name = 'YourApp'
include ':app'

// Configure source control for Reels SDK
sourceControl {
    gitRepository(uri("https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git")) {
        producesModule("com.rakuten.room:reels-sdk")
    }
}
```

#### Step 2: Add Dependency in app/build.gradle

```gradle
dependencies {
    // Reels SDK via Git
    implementation 'com.rakuten.room:reels-sdk:1.0.0'
}
```

#### Step 3: Sync Gradle

```bash
./gradlew clean build
```

#### Step 4: Update to New Versions

```gradle
// In app/build.gradle, update version
implementation 'com.rakuten.room:reels-sdk:1.1.0'
```

```bash
# Sync project
./gradlew clean build
```

**Advantages of Git + Gradle:**
- ✅ Version control via Git tags
- ✅ Easy updates with version number
- ✅ CI/CD friendly
- ✅ Standard Gradle workflow

**Disadvantages:**
- ⚠️ Requires Git authentication
- ⚠️ May have issues in corporate environments
- ⚠️ Slower build times

### Method 3: Maven Repository Integration (Recommended for Released Versions)

This method is recommended for using **stable releases** without needing the SDK source code. The SDK is distributed as a complete Maven repository with proper dependency management.

#### Maven Repository Structure

```mermaid
graph TD
    A[ReelsSDK-Android-Debug-0.1.4.zip] --> B[maven-repo/]
    B --> C[com/rakuten/reels_android/0.1.4/]
    B --> D[com/example/reels_flutter/]
    B --> E[io/flutter/]
    B --> F[androidx/media3/]

    C --> C1[reels_android-0.1.4.aar]
    C --> C2[reels_android-0.1.4.pom]

    D --> D1[flutter_debug-1.0.aar]
    D --> D2[flutter_debug-1.0.pom]

    E --> E1[flutter_embedding_debug-1.0.0-xxx.aar]
    E --> E2[armeabi_v7a_debug-1.0.0-xxx.aar]
    E --> E3[arm64_v8a_debug-1.0.0-xxx.aar]
    E --> E4[x86_64_debug-1.0.0-xxx.aar]

    F --> F1[media3-exoplayer-1.1.1.aar]
    F --> F2[media3-common-1.1.1.aar]

    style C fill:#e1f5ff
    style C1 fill:#b3e0ff
    style C2 fill:#b3e0ff
```

#### Step 1: Download Released Maven Package

Download the Maven repository package from the GitHub Releases page:

```bash
# Navigate to your project directory
cd /path/to/your-android-app

# Download the release (replace VERSION with actual version, e.g., 0.1.4)
VERSION="0.1.4"

# For Debug builds (development/testing)
curl -L -o ReelsSDK-Android-Debug-${VERSION}.zip \
  "https://github.com/ahmed-eishon/Reels-SDK/releases/download/v${VERSION}-android-debug/ReelsSDK-Android-Debug-${VERSION}.zip"

# OR for Release builds (production)
curl -L -o ReelsSDK-Android-${VERSION}.zip \
  "https://github.com/ahmed-eishon/Reels-SDK/releases/download/v${VERSION}-android/ReelsSDK-Android-${VERSION}.zip"

# Extract the downloaded package to your project's parent directory
unzip ReelsSDK-Android-Debug-${VERSION}.zip -d ..
# or
# unzip ReelsSDK-Android-${VERSION}.zip -d ..
```

**What's included in the package:**
- `maven-repo/` - Complete Maven repository with:
  - `com.rakuten:reels_android` - Native Android API (main SDK interface)
  - `com.example.reels_flutter:flutter_debug` or `flutter_release` - Flutter module
  - `io.flutter:flutter_embedding_*` - Flutter engine artifacts
  - `io.flutter:armeabi_v7a_*`, `arm64_v8a_*`, `x86_64_*` - Architecture-specific Flutter engines
  - `androidx.media3:*` - Media player dependencies
  - All transitive dependencies with proper POM files
- `README.md` - Integration instructions
- `.sha256` - Checksum file for verification

#### Step 2: Verify Checksums (Optional but Recommended)

```bash
# Verify package integrity
shasum -a 256 -c ReelsSDK-Android-Debug-${VERSION}.zip.sha256
# or
# shasum -a 256 -c ReelsSDK-Android-${VERSION}.zip.sha256
```

#### Step 3: Configure Maven Repository

Add the local Maven repository to your project. You can add it in either `settings.gradle` (recommended) or project-level `build.gradle`:

**Option A: settings.gradle (Recommended for Gradle 7.0+)**

```gradle
// settings.gradle
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()

        // ReelsSDK local Maven repository
        maven {
            url = uri("file://${rootProject.projectDir}/../ReelsSDK-Android-Debug-0.1.4/maven-repo")
        }

        // Flutter engine repository (required for Flutter dependencies)
        maven {
            url = uri("https://storage.googleapis.com/download.flutter.io")
        }
    }
}

rootProject.name = 'YourApp'
include ':app'
```

**Option B: build.gradle (Project level) for older Gradle versions**

```gradle
// build.gradle (Project)
allprojects {
    repositories {
        google()
        mavenCentral()

        // ReelsSDK local Maven repository
        maven {
            url "file://${rootProject.projectDir}/../ReelsSDK-Android-Debug-0.1.4/maven-repo"
        }

        // Flutter engine repository (required for Flutter dependencies)
        maven {
            url "https://storage.googleapis.com/download.flutter.io"
        }
    }
}
```

> [!tip] Repository Path
> - Adjust the path based on where you extracted the SDK package
> - The path should point to the `maven-repo` directory inside the extracted package
> - Use `file://` protocol for local filesystem paths
> - Use relative paths (`../`) for portability across different machines

#### Step 4: Add SDK Dependency

Add the ReelsSDK dependency to your `app/build.gradle`:

```gradle
// app/build.gradle
android {
    compileSdk 35

    defaultConfig {
        minSdk 21
        targetSdk 35
        // ... other config
    }
}

dependencies {
    // ReelsSDK - Native Android API
    // This single dependency brings in all required Flutter and native dependencies transitively
    debugImplementation 'com.rakuten:reels_android:0.1.4'

    // OR for Release builds
    // releaseImplementation 'com.rakuten:reels_android:0.1.4'
}
```

> [!tip] Transitive Dependencies
> - You only need to declare `com.rakuten:reels_android` as a dependency
> - Gradle automatically resolves all Flutter dependencies, engine artifacts, and media player libraries through the POM file
> - No need to manually add Flutter or Media3 dependencies

#### Step 5: Clean Settings.gradle (If Migrating)

If you were previously using local folder import or Git + Gradle, remove those configurations:

```gradle
// settings.gradle - Remove these lines if present:

// OLD: Local folder import
// include ':reels_android'
// project(':reels_android').projectDir = new File('/path/to/reels-sdk/reels_android')
// evaluate(new File('/path/to/reels-sdk/reels_flutter/.android/include_flutter.groovy'))

// OLD: Git + Gradle
// sourceControl {
//     gitRepository(uri("...")) {
//         producesModule("com.rakuten.room:reels-sdk")
//     }
// }
```

#### Step 6: Sync and Build

```bash
# Clean and rebuild
./gradlew clean
./gradlew build

# Or run from Android Studio
# File → Sync Project with Gradle Files
# Build → Clean Project
# Build → Rebuild Project
```

#### Step 7: Verify Installation

Check that the SDK and its dependencies are properly resolved:

```bash
# List dependencies
./gradlew app:dependencies --configuration debugCompileClasspath | grep -A 20 "reels_android"

# Should show dependency tree like:
# debugImplementation - com.rakuten:reels_android:0.1.4
# +--- com.example.reels_flutter:flutter_debug:1.0
# +--- io.flutter:flutter_embedding_debug:1.0.0-xxx
# +--- io.flutter:arm64_v8a_debug:1.0.0-xxx
# +--- androidx.media3:media3-exoplayer:1.1.1
# \--- ... (other transitive dependencies)
```

**Advantages of Maven Integration:**
- ✅ No Git authentication required
- ✅ Automatic dependency resolution via Gradle
- ✅ Transitive dependency management (no manual dependency tracking)
- ✅ Faster build times (pre-compiled AARs)
- ✅ Stable versioned releases
- ✅ No SDK source code needed
- ✅ Works in air-gapped/corporate environments
- ✅ Standard Maven repository structure
- ✅ Easy version upgrades (change version number only)

**Disadvantages:**
- ⚠️ Manual download and extraction required
- ⚠️ Cannot debug into SDK source code
- ⚠️ Need to re-download for updates
- ⚠️ Larger initial download size (includes all dependencies)

**When to use Maven Integration:**
- ✅ Production apps using stable releases
- ✅ Corporate environments with restricted Git access
- ✅ CI/CD pipelines with artifact caching
- ✅ Teams not actively developing the SDK
- ✅ Projects that need reproducible builds with locked versions

## SDK Usage

### Step 1: Import the SDK

```kotlin
import com.rakuten.room.reels.ReelsModule
import com.rakuten.room.reels.flutter.ReelsListener
import com.rakuten.room.reels.pigeon.ShareData
```

### Step 2: Initialize the SDK

Initialize the SDK early in your app lifecycle (in `Application` class or main `Activity`):

#### Option A: In Application Class (Recommended)

```kotlin
import android.app.Application
import com.rakuten.room.reels.ReelsModule

class MyApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // Initialize Reels SDK with access token provider
        ReelsModule.initialize(
            context = this,
            accessTokenProvider = {
                // Return access token (can be synchronous or async)
                UserSession.instance.accessToken
            }
        )
    }
}
```

Don't forget to add your Application class to `AndroidManifest.xml`:

```xml
<application
    android:name=".MyApplication"
    android:icon="@mipmap/ic_launcher"
    android:label="@string/app_name"
    android:theme="@style/AppTheme">
    <!-- Your activities... -->
</application>
```

#### Option B: In Activity (Alternative)

```kotlin
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import com.rakuten.room.reels.ReelsModule

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Initialize SDK
        ReelsModule.initialize(
            context = applicationContext,
            accessTokenProvider = {
                UserSession.instance.accessToken
            }
        )
    }
}
```

### Step 3: Set Event Listener

Implement the `ReelsListener` interface to receive callbacks:

```kotlin
import com.rakuten.room.reels.ReelsModule
import com.rakuten.room.reels.flutter.ReelsListener
import com.rakuten.room.reels.pigeon.ShareData
import android.content.Intent
import android.util.Log

class MainActivity : AppCompatActivity(), ReelsListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Set listener to receive SDK events
        ReelsModule.setListener(this)
    }

    // MARK: - ReelsListener Implementation

    override fun onLikeButtonClick(videoId: String, isLiked: Boolean, likeCount: Long) {
        Log.d("Reels", "Video $videoId liked: $isLiked, count: $likeCount")

        // Update your backend
        VideoAPI.updateLike(videoId, isLiked) { result ->
            when (result) {
                is Result.Success -> Log.d("Reels", "Like updated successfully")
                is Result.Error -> Log.e("Reels", "Failed to update like: ${result.error}")
            }
        }
    }

    override fun onShareButtonClick(shareData: ShareData) {
        // Present native share dialog
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, "${shareData.title}\n${shareData.videoUrl}")
            putExtra(Intent.EXTRA_SUBJECT, shareData.title)
        }

        startActivity(Intent.createChooser(shareIntent, "Share Video"))
    }

    override fun onAnalyticsEvent(eventName: String, properties: Map<String, String>) {
        // Track with your analytics service
        Analytics.track(eventName, properties)

        Log.d("Reels", "Analytics event: $eventName, properties: $properties")
    }
}
```

### Step 4: Open Reels Screen

#### Option A: Full-Screen Activity (Recommended)

```kotlin
import com.rakuten.room.reels.ReelsModule

class MainActivity : AppCompatActivity(), ReelsListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        ReelsModule.setListener(this)

        // Open reels button
        findViewById<Button>(R.id.openReelsButton).setOnClickListener {
            ReelsModule.openReels(
                context = this,
                itemId = null  // Optional: specific video ID
            )
        }

        // Open specific video
        findViewById<Button>(R.id.openVideoButton).setOnClickListener {
            ReelsModule.openReels(
                context = this,
                itemId = "video123"
            )
        }
    }

    // Implement ReelsListener methods...
}
```

#### Option B: Embedded Fragment

```kotlin
import com.rakuten.room.reels.ReelsModule

class MainActivity : AppCompatActivity(), ReelsListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        ReelsModule.setListener(this)

        // Embed reels as a fragment
        val reelsFragment = ReelsModule.createReelsFragment(initialRoute = "/")

        supportFragmentManager
            .beginTransaction()
            .replace(R.id.fragmentContainer, reelsFragment)
            .commit()
    }

    // Implement ReelsListener methods...
}
```

**Layout for Fragment:**

```xml
<!-- activity_main.xml -->
<FrameLayout
    android:id="@+id/fragmentContainer"
    android:layout_width="match_parent"
    android:layout_height="match_parent" />
```

### Step 5: Cleanup (Optional)

Clean up resources when appropriate:

```kotlin
override fun onDestroy() {
    super.onDestroy()
    ReelsModule.cleanup()
}
```

## Common Integration Patterns

### Pattern 1: Simple Button Integration

```kotlin
class HomeActivity : AppCompatActivity(), ReelsListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_home)

        ReelsModule.setListener(this)

        findViewById<Button>(R.id.watchReelsButton).setOnClickListener {
            ReelsModule.openReels(context = this)
        }
    }

    // Implement ReelsListener methods...
}
```

### Pattern 2: Menu Item Integration

```kotlin
class HomeActivity : AppCompatActivity(), ReelsListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_home)

        ReelsModule.setListener(this)
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.home_menu, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_reels -> {
                ReelsModule.openReels(context = this)
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    // Implement ReelsListener methods...
}
```

### Pattern 3: Floating Action Button

```kotlin
class HomeActivity : AppCompatActivity(), ReelsListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_home)

        ReelsModule.setListener(this)

        findViewById<FloatingActionButton>(R.id.fab_reels).setOnClickListener {
            ReelsModule.openReels(context = this)
        }
    }

    // Implement ReelsListener methods...
}
```

### Pattern 4: ViewPager/TabLayout Integration

```kotlin
class MainActivity : AppCompatActivity(), ReelsListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        ReelsModule.setListener(this)

        setupViewPager()
    }

    private fun setupViewPager() {
        val viewPager = findViewById<ViewPager2>(R.id.viewPager)
        val adapter = MainPagerAdapter(this)

        // Add reels fragment as a tab
        adapter.addFragment(HomeFragment(), "Home")
        adapter.addFragment(ReelsModule.createReelsFragment(), "Reels")
        adapter.addFragment(ProfileFragment(), "Profile")

        viewPager.adapter = adapter
    }

    // Implement ReelsListener methods...
}
```

## Troubleshooting

### Issue 1: "Unresolved reference: ReelsModule"

**Solution:**
1. Ensure you added the dependency in `app/build.gradle`
2. Sync Gradle: File → Sync Project with Gradle Files
3. Clean and rebuild: Build → Clean Project → Rebuild Project

### Issue 2: "No signature of method: build_xxx.include_flutter()"

**Solution:**
1. Verify `.android` directory exists in `reels_flutter`
2. Run: `cd reels_flutter && flutter pub get`
3. Ensure `include_flutter.groovy` exists
4. Use correct path in `settings.gradle`

### Issue 3: Flutter engine crash on launch

**Solution:**
1. Ensure minSdkVersion is 21 or higher
2. Check that Flutter dependencies are resolved
3. Clean build: `./gradlew clean`
4. Invalidate caches: File → Invalidate Caches / Restart

### Issue 4: Git authentication issues

**Solution:**
- Use **Local Folder Import** method instead
- This avoids Git authentication entirely

### Issue 5: "Duplicate class" errors

**Solution:**
1. Ensure you're not including Flutter dependencies twice
2. Check that you only have one `:reels_android` include
3. Clean project: `./gradlew clean`

## Permissions

The SDK requires the following permissions (automatically added):

```xml
<!-- Already included in SDK's AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

If your app needs additional permissions (e.g., for camera, storage), add them to your app's `AndroidManifest.xml`.

## ProGuard / R8 Rules

If using ProGuard or R8, add these rules:

```proguard
# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Reels SDK
-keep class com.rakuten.room.reels.** { *; }
-keepclassmembers class com.rakuten.room.reels.** { *; }

# Pigeon
-keepattributes Signature
-keepattributes *Annotation*
```

## Best Practices

### ✅ Do's

- ✅ Initialize SDK in `Application.onCreate()`
- ✅ Set listener before opening reels
- ✅ Use application context for initialization
- ✅ Implement all `ReelsListener` methods
- ✅ Handle errors gracefully
- ✅ Test on real devices, not just emulators
- ✅ Use local folder import for development
- ✅ Use Git + Gradle for production

### ❌ Don'ts

- ❌ Don't initialize multiple times
- ❌ Don't open reels without setting listener
- ❌ Don't use activity context for initialization
- ❌ Don't forget to handle lifecycle events
- ❌ Don't modify generated Pigeon code
- ❌ Don't include Flutter dependencies manually

## Version Updates

### Updating SDK (Local Folder)

```bash
# Navigate to SDK folder
cd /path/to/reels-sdk

# Pull latest changes
git pull origin master

# Checkout desired version
git checkout v1.1.0

# Sync Gradle in your Android project
cd /path/to/your-android-app
./gradlew clean build
```

### Updating SDK (Git + Gradle)

```gradle
// Update version in app/build.gradle
implementation 'com.rakuten.room:reels-sdk:1.1.0'
```

```bash
# Sync project
./gradlew clean build
```

## Build Configuration

### Minimum build.gradle Configuration

**app/build.gradle:**

```gradle
android {
    compileSdk 35

    defaultConfig {
        applicationId "com.yourcompany.yourapp"
        minSdk 21
        targetSdk 35
        versionCode 1
        versionName "1.0"
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation project(':reels_android')
    // or
    // implementation 'com.rakuten.room:reels-sdk:1.0.0'
}
```

## Next Steps

- [[08-Android-Usage-Examples|📖 Android Usage Examples]]
- [[../05-API/02-Android-API-Reference|📖 Android API Reference]]
- [[../03-Architecture/04-Android-Bridge|📖 Android Bridge Architecture]]

---

Back to [[../00-MOC-Reels-SDK|Main Hub]]

#android #integration #kotlin #gradle
