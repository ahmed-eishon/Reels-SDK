Pod::Spec.new do |spec|
  spec.name                  = 'ReelsSDK'
  spec.module_name           = 'ReelsIOS'
  spec.version               = File.read(File.join(__dir__, 'VERSION')).strip
  spec.summary               = 'Video reels SDK for iOS with Flutter integration'
  spec.description           = <<-DESC
    ReelsSDK provides a Flutter-based video reels experience for iOS applications.
    Features include video playback, engagement buttons (like, share), analytics tracking,
    and type-safe platform communication using Pigeon.

    Use tag v{VERSION}-ios-debug for Debug builds or v{VERSION}-ios for Release builds.
  DESC

  spec.homepage              = 'https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk'
  spec.license               = { :type => 'Proprietary', :text => 'Copyright Rakuten' }
  spec.author                = { 'Rakuten ROOM Team' => 'room-team@rakuten.com' }

  spec.source                = {
    :git => 'https://github.com/ahmed-eishon/Reels-SDK.git',
    :tag => "v#{spec.version}-ios"
  }

  spec.ios.deployment_target = '16.0'
  spec.swift_version         = '5.9'

  # Swift bridge source files
  spec.source_files          = 'reels_ios/Sources/ReelsIOS/**/*.swift'

  # Download pre-built Flutter frameworks from GitHub releases
  # Detects Debug or Release based on git tag suffix
  spec.prepare_command = <<-CMD
    set -e

    VERSION=$(cat VERSION)
    FRAMEWORKS_DIR="Frameworks"

    # Check if already downloaded
    if [ -d "$FRAMEWORKS_DIR" ] && [ -f "$FRAMEWORKS_DIR/.downloaded-v$VERSION" ]; then
      echo "[ReelsSDK] Frameworks v$VERSION already downloaded"
      exit 0
    fi

    # Detect if this is a debug or release build based on git tag
    CURRENT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
    if echo "$CURRENT_TAG" | grep -q "debug"; then
      BUILD_TYPE="Debug"
      ZIP_NAME="ReelsSDK-Frameworks-Debug-${VERSION}.zip"
      echo "[ReelsSDK] Detected Debug build from tag: $CURRENT_TAG"
    else
      BUILD_TYPE="Release"
      ZIP_NAME="ReelsSDK-Frameworks-${VERSION}.zip"
      echo "[ReelsSDK] Detected Release build from tag: $CURRENT_TAG"
    fi

    # Download frameworks package
    GITHUB_URL="https://github.com/ahmed-eishon/Reels-SDK/releases/download/${CURRENT_TAG}/${ZIP_NAME}"

    echo "[ReelsSDK] Downloading $BUILD_TYPE frameworks v$VERSION..."
    echo "[ReelsSDK] URL: $GITHUB_URL"

    if curl -L -f -o "frameworks.zip" "$GITHUB_URL"; then
      echo "[ReelsSDK] Download successful, extracting..."
      mkdir -p "$FRAMEWORKS_DIR"
      unzip -q -o "frameworks.zip" -d "$FRAMEWORKS_DIR"
      rm "frameworks.zip"
      touch "$FRAMEWORKS_DIR/.downloaded-v$VERSION"
      echo "[ReelsSDK] $BUILD_TYPE frameworks ready"
    else
      echo "[ReelsSDK] ERROR: Failed to download frameworks"
      echo "[ReelsSDK] Please check: $GITHUB_URL"
      exit 1
    fi
  CMD

  # Vendor the 6 Flutter frameworks (no suffixes)
  spec.vendored_frameworks = [
    'Frameworks/App.xcframework',
    'Frameworks/Flutter.xcframework',
    'Frameworks/FlutterPluginRegistrant.xcframework',
    'Frameworks/package_info_plus.xcframework',
    'Frameworks/video_player_avfoundation.xcframework',
    'Frameworks/wakelock_plus.xcframework'
  ]

  # Preserve Flutter source for reference and VERSION file
  spec.preserve_paths = ['reels_flutter/**/*', 'VERSION']

  # Exclude build artifacts
  spec.exclude_files = [
    'reels_flutter/.dart_tool/**/*',
    'reels_flutter/build/**/*',
    'reels_flutter/.ios/**/*',
    'reels_flutter/.android/**/*'
  ]
end
