# Android Workflow Scripts Documentation

Complete documentation for Android release workflows in GitHub Actions.

## GitHub Actions Workflows

### Workflow Comparison: Release vs Debug

The Reels SDK uses two GitHub Actions workflows for Android releases. Both workflows are **structurally identical** and build the **complete SDK** (Flutter + reels_android). The only difference is the build optimization level.

#### Workflow Files
- `.github/workflows/release-android.yml` - Release build (production)
- `.github/workflows/release-android-debug.yml` - Debug build (development)

#### Similarities (Structure)

Both workflows follow the exact same build process:

| Step | Release Workflow | Debug Workflow |
|------|------------------|----------------|
| **Trigger** | `v*.*.*-android` tag | `v*.*.*-android-debug` tag |
| **Runner** | ubuntu-latest | ubuntu-latest |
| **Java Version** | JDK 17 | JDK 17 |
| **Flutter Version** | 3.35.6 | 3.35.6 |
| **Caching** | Flutter deps + Gradle | Flutter deps + Gradle |
| **Step 1** | Build Flutter AAR | Build Flutter AAR |
| **Step 2** | Build reels_android AAR | Build reels_android AAR |
| **Step 3** | Publish to local Maven | Publish to local Maven |
| **Step 4** | Package Maven repository | Package Maven repository |
| **Step 5** | Create GitHub release | Create GitHub release |

#### Key Differences (Build Modes Only)

| Aspect | Release Workflow | Debug Workflow |
|--------|------------------|----------------|
| **Tag Pattern** | `v0.1.4-android` | `v0.1.4-android-debug` |
| **Flutter Build** | `flutter build aar --release --no-debug --no-profile` | `flutter build aar --debug --no-release --no-profile` |
| **reels_android Build** | `assembleRelease` | `assembleDebug` |
| **Maven Publish** | `publishReleasePublicationToMavenLocal` | `publishDebugPublicationToMavenLocal` |
| **Package Name** | `ReelsSDK-Android-{VERSION}.zip` | `ReelsSDK-Android-Debug-{VERSION}.zip` |
| **Release Title** | "Android Release {VERSION}" | "Android Debug {VERSION}" |
| **Optimization** | ✅ Optimized, smaller size | ❌ Debug symbols, verbose logging |
| **Use Case** | Production apps | Development & debugging |

#### Build Process Flow (Identical for Both)

```
1. Setup Environment
   ├── Checkout code
   ├── Setup JDK 17
   ├── Setup Flutter 3.35.6
   └── Cache dependencies (Flutter + Gradle)

2. Build Flutter AAR
   ├── flutter pub get
   ├── Run Pigeon code generation
   └── flutter build aar --release/--debug
   └── Output: reels_flutter/build/host/outputs/repo/

3. Build reels_android AAR
   ├── Setup Maven repo path from Flutter build
   ├── Prepare helper-reels-android project
   │   ├── Copy settings.gradle.template
   │   ├── Substitute Maven repo path
   │   └── Create local.properties with ANDROID_HOME
   ├── Build: assembleRelease/assembleDebug
   └── Publish: publishReleasePublicationToMavenLocal

4. Package Distribution
   ├── Create package directory
   ├── Copy Flutter Maven repo → package/maven-repo/
   ├── Copy reels_android from ~/.m2/ → package/maven-repo/com/rakuten/
   ├── Create README with integration instructions
   ├── Create ZIP file
   └── Generate SHA256 checksum

5. Create GitHub Release
   ├── Generate release notes with integration guide
   ├── Create GitHub release with tag
   └── Upload ZIP + checksum as release assets
```

#### Output Structure (Same for Both)

Both workflows produce identical Maven repository structure:

```
ReelsSDK-Android-{VERSION}.zip
└── ReelsSDK-Android-{VERSION}/
    ├── maven-repo/
    │   ├── com/
    │   │   ├── example/reels_flutter/
    │   │   │   ├── flutter_release/  (Release workflow)
    │   │   │   └── flutter_debug/    (Debug workflow)
    │   │   └── rakuten/reels/
    │   │       └── reels_android/
    │   │           └── {VERSION}/
    │   │               ├── reels_android-{VERSION}.aar
    │   │               ├── reels_android-{VERSION}.pom
    │   │               └── reels_android-{VERSION}-sources.jar
    │   └── io/flutter/
    │       └── (Flutter engine artifacts)
    └── README.md (Integration instructions)
```

#### Integration Usage (Same Pattern)

Both use identical Maven integration approach:

```gradle
// settings.gradle or build.gradle (project level)
repositories {
    maven {
        url "file://${rootProject.projectDir}/../ReelsSDK-Android-{VERSION}/maven-repo"
    }
    maven {
        url "https://storage.googleapis.com/download.flutter.io"
    }
}

// app/build.gradle
dependencies {
    // For Release build
    releaseImplementation 'com.rakuten.reels:reels_android:{VERSION}'

    // For Debug build
    debugImplementation 'com.rakuten.reels:reels_android:{VERSION}'
}
```

#### Triggering Workflows

To trigger both workflows for a release:

```bash
# Get version
VERSION=$(cat VERSION)

# Trigger Release workflow
git tag "v${VERSION}-android"
git push origin "v${VERSION}-android"

# Trigger Debug workflow
git tag "v${VERSION}-android-debug"
git push origin "v${VERSION}-android-debug"
```

#### Workflow Summary

✅ **Both workflows build complete SDK**
- Flutter AAR (release/debug optimized)
- reels_android AAR (release/debug optimized)
- All dependencies packaged in Maven repository

🎯 **Single difference: optimization level**
- **Release:** Production-ready (smaller, faster, no debug info)
- **Debug:** Development-ready (larger, debug symbols, verbose logging)

📦 **Both produce ready-to-use Maven repositories**
- No Flutter installation required for end users
- Standard Gradle/Maven integration
- Complete SDK with all dependencies

---

## Related Documentation

- [Android Build Process](../04-Build-Process/02-Android-Build.md)
- [Android Release Process](../05-Release-Process/02-Android-Release.md)
- [Android Integration Guide](../02-Integration/02-Android-Integration-Guide.md)
