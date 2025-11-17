Pod::Spec.new do |spec|
  spec.name                  = 'ReelsSDK'
  spec.module_name           = 'ReelsIOS'
  spec.version               = File.read(File.join(__dir__, 'VERSION')).strip + '-debug'
  spec.summary               = 'Video reels SDK for iOS with Flutter integration (Debug)'
  spec.description           = <<-DESC
    ReelsSDK provides a Flutter-based video reels experience for iOS applications.
    Features include video playback, engagement buttons (like, share), analytics tracking,
    and type-safe platform communication using Pigeon.

    This is the DEBUG version with symbols and debug assertions enabled.
  DESC

  spec.homepage              = 'https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk'
  spec.license               = { :type => 'Proprietary', :text => 'Copyright Rakuten' }
  spec.author                = { 'Rakuten ROOM Team' => 'room-team@rakuten.com' }

  # Debug version uses -debug suffix in tag
  base_version = File.read(File.join(__dir__, 'VERSION')).strip
  spec.source                = {
    :git => 'https://github.com/ahmed-eishon/Reels-SDK.git',
    :tag => "v#{base_version}-ios-debug"
  }

  spec.ios.deployment_target = '16.0'
  spec.swift_version         = '5.9'

  # Swift bridge source files
  spec.source_files          = 'reels_ios/Sources/ReelsIOS/**/*.swift'

  # Download and extract pre-built Debug Flutter frameworks from GitHub releases
  spec.prepare_command = <<-CMD
    set -e

    # Check for local development marker file
    if [ -f ".reelsdk-dev" ]; then
      echo "================================================"
      echo "[OK] Local Development Mode (Debug)"
      echo "================================================"
      echo "Using locally built frameworks"
      echo "Skipping GitHub release download"
      echo ""

      # Link local Debug frameworks to expected location
      if [ -d "Frameworks/Debug/Debug" ]; then
        if [ ! -L "Frameworks_Link" ] || [ "$(readlink Frameworks_Link)" != "$(pwd)/Frameworks/Debug/Debug" ]; then
          echo "Creating symlink to local frameworks..."
          rm -f Frameworks_Link
          ln -sf "$(pwd)/Frameworks/Debug/Debug" Frameworks_Link
          mv Frameworks_Link Frameworks
          echo "[OK] Linked: Frameworks -> Frameworks/Debug/Debug"
        fi
      fi
      echo ""
      exit 0
    fi

    # Distribution mode - download pre-built Debug frameworks
    echo "================================================"
    echo "ReelsSDK Debug Distribution Mode"
    echo "================================================"

    VERSION=$(cat VERSION)
    BUILD_MODE="Debug"
    FRAMEWORKS_DIR="Frameworks"

    # Check if already downloaded
    if [ -d "$FRAMEWORKS_DIR" ] && [ -f "$FRAMEWORKS_DIR/.downloaded-v$VERSION-debug" ]; then
      echo "[OK] Debug frameworks v$VERSION already downloaded"
      exit 0
    fi

    echo ""
    echo "Downloading Flutter Debug frameworks v$VERSION..."

    # Construct download URLs
    GITHUB_URL="https://github.com/ahmed-eishon/Reels-SDK/releases/download/v${VERSION}-ios-debug/ReelsSDK-Frameworks-Debug-${VERSION}.zip"

    # Download Debug frameworks
    echo "Trying: $GITHUB_URL"
    if curl -L -f -o "frameworks-debug.zip" "$GITHUB_URL"; then
      echo "[OK] Downloaded from GitHub"
    else
      echo "================================================"
      echo "[ERROR] Failed to download Debug frameworks"
      echo "================================================"
      echo ""
      echo "Release v${VERSION}-ios-debug asset not found"
      echo ""
      echo "Solutions:"
      echo "  - Check releases: https://github.com/ahmed-eishon/Reels-SDK/releases"
      echo "  - Or build locally:"
      echo "      cd reels_flutter"
      echo "      flutter build ios-framework --debug --output=../Frameworks"
      echo "      touch .reelsdk-dev  # Enable local dev mode"
      echo ""
      exit 1
    fi

    # Extract frameworks
    echo "Extracting Debug frameworks..."
    mkdir -p "$FRAMEWORKS_DIR"
    unzip -q -o "frameworks-debug.zip" -d "$FRAMEWORKS_DIR"
    rm "frameworks-debug.zip"

    # Mark as downloaded for this version
    touch "$FRAMEWORKS_DIR/.downloaded-v$VERSION-debug"

    echo "[OK] Debug frameworks ready"
    echo ""
    ls -1 "$FRAMEWORKS_DIR"/*.xcframework 2>/dev/null | xargs -n1 basename
    echo ""
    echo "================================================"
    echo "[OK] Debug Frameworks ready for use"
    echo "================================================"
  CMD

  # Vendor only Debug frameworks (without _Debug suffix in this package)
  spec.vendored_frameworks = 'Frameworks/*.xcframework'

  # Preserve Flutter source for reference and VERSION file for prepare_command
  spec.preserve_paths = ['reels_flutter/**/*', 'VERSION']

  # Exclude build artifacts and development files
  spec.exclude_files = [
    'reels_flutter/.dart_tool/**/*',
    'reels_flutter/build/**/*',
    'reels_flutter/.ios/**/*',
    'reels_flutter/.android/**/*',
    '.reelsdk-dev'
  ]
end
