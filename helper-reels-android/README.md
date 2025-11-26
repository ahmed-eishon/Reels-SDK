# Helper Reels Android

This is a minimal Android Gradle wrapper project used by CI/CD workflows to build the `reels_android` module.

## Purpose

The `reels_android` module cannot be built standalone because it:
1. Uses version catalog references (e.g., `libs.androidx.appcompat`)
2. Requires plugin configuration from a parent project
3. Depends on the Flutter AAR from `reels_flutter` module

This helper project provides the necessary Gradle configuration to build `reels_android` in CI/CD.

## Structure

```
helper-reels-android/
├── build.gradle                    # Root build script with plugin classpaths
├── settings.gradle.template        # Template for settings.gradle with Maven repo placeholder
└── README.md                       # This file
```

## How It Works

During CI/CD builds:

1. The template `settings.gradle.template` is copied to `settings.gradle`
2. The placeholder `MAVEN_REPO_PLACEHOLDER` is replaced with the actual Flutter AAR Maven repository path
3. The workflow runs: `./gradlew :reels_android:assembleDebug` (or `assembleRelease`)
4. This builds the `reels_android` module with access to:
   - Version catalog definitions
   - Flutter AAR dependencies
   - Android Gradle Plugin

## Version Catalog

The `settings.gradle.template` defines a version catalog that matches the dependencies used in `reels_android`:

- `androidGradlePlugin`: 8.7.3
- `kotlin`: 2.1.0
- AndroidX libraries (appcompat, fragment-ktx, activity-ktx, etc.)
- Test libraries (junit, espresso)

## Maintenance

When updating dependencies in `reels_android/build.gradle`, ensure the version catalog in `settings.gradle.template` is also updated to match.
