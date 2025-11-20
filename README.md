# Reels SDK

A multi-platform SDK for integrating video reels functionality into iOS and Android applications using Flutter.

## 🎯 Features

- 🎥 **Video Reels Player** - Vertical swipeable video experience
- 📱 **Native Integration** - Seamless iOS (Swift) and Android (Kotlin) bridges
- 🔄 **Type-Safe Communication** - Pigeon-generated platform channels
- 💙 **Engagement Features** - Like, share, and comment functionality
- 📊 **Analytics Tracking** - Built-in event tracking support
- 🎨 **Clean Architecture** - Maintainable and testable codebase
- 🔄 **Independent Screen Lifecycle** - Each screen presentation is completely independent
- 🎯 **Resource Management** - Proper video player and resource cleanup

## 📋 Requirements

### iOS
- iOS 16.0+
- Swift 5.9+
- CocoaPods
- Xcode 15.0+

### Android
- Android SDK 21+
- Kotlin 1.9+
- Gradle 8.0+

### Flutter
- Flutter 3.35.6+
- Dart SDK 3.5.0+

## 🚀 Quick Start

### iOS Integration
```ruby
# Add to Podfile
pod 'ReelsSDK', :git => '<repository-url>', :tag => '0.1.4'
```

### Android Integration
```gradle
// Add to settings.gradle
maven {
    url "path/to/ReelsSDK-Android-0.1.4/maven-repo"
}

// Add to app/build.gradle
dependencies {
    implementation 'com.rakuten.reels:reels_android:0.1.4'
}
```

## 📚 Documentation

Complete documentation is available in the [`docs/`](./docs/) folder:

### Getting Started
- **[SDK Overview](./docs/01-Overview/01-SDK-Overview.md)** - Features, architecture, and quick start
- **[iOS Integration Guide](./docs/02-Integration/01-iOS-Integration-Guide.md)** - Step-by-step iOS setup
- **[Android Integration Guide](./docs/02-Integration/02-Android-Integration-Guide.md)** - Step-by-step Android setup

### Development
- **[Android Local Development](./docs/06-Dev-Process/01-Android-Local-Development.md)** - Local folder-based development setup
- **[Architecture Overview](./docs/03-Architecture/00-Overview.md)** - SDK architecture and design patterns
- **[Technology Stack](./docs/01-Overview/02-Technology-Stack.md)** - Dependencies and versions

### Build & Release
- **[iOS Build Process](./docs/04-Build-Process/01-iOS-Build.md)** - Building iOS frameworks
- **[Android Build Process](./docs/04-Build-Process/02-Android-Build.md)** - Building Android AARs
- **[iOS Release Process](./docs/05-Release-Process/01-iOS-Release.md)** - Release workflows
- **[Android Release Process](./docs/05-Release-Process/02-Android-Release.md)** - Release workflows

### Scripts & Tools
- **[Scripts Overview](./docs/07-Scripts/00-Overview.md)** - Build and development scripts
- **[Android Local Scripts](./docs/07-Scripts/Android/01-Local-Scripts.md)** - Development scripts
- **[Android Workflow Scripts](./docs/07-Scripts/Android/02-Workflow-Scripts.md)** - GitHub Actions workflows

## 📖 Documentation Index

For complete documentation structure, see **[docs/README.md](./docs/README.md)**

## 🔄 Version

Current version: **0.1.4**

See [VERSIONS.md](./VERSIONS.md) for detailed version information.

## 📂 Project Structure

```
reels-sdk/
├── reels_flutter/          # Flutter module (UI and business logic)
├── reels_ios/              # iOS native bridge (Swift)
├── reels_android/          # Android native bridge (Kotlin)
├── helper-reels-android/   # Android build wrapper project
├── docs/                   # Complete documentation
├── scripts/                # Build and development scripts
└── README.md               # This file
```

## 🛠️ Development Scripts

### Android Development
```bash
# Setup for local development
./scripts/dev/android/clean-install-android.sh

# Build AARs (debug or release)
./scripts/sdk/android/build-reels-android-aar.sh [debug|release]
```

### iOS Development
```bash
# Build frameworks
./scripts/sdk/ios/build-frameworks.sh [--clean]
```

## 📞 Support

For issues, questions, or contributions, please refer to the documentation or contact the development team.

## 📄 License

Internal Rakuten project - see license details with the organization.
