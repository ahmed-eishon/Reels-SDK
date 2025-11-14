Pod::Spec.new do |spec|
  spec.name                  = 'ReelsSDK'
  spec.version               = File.read(File.join(__dir__, 'VERSION')).strip
  spec.summary               = 'Video reels SDK for iOS with Flutter integration'
  spec.description           = <<-DESC
    ReelsSDK provides a Flutter-based video reels experience for iOS applications.
    Features include video playback, engagement buttons (like, share), analytics tracking,
    and type-safe platform communication using Pigeon.
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

  # Download and extract pre-built Flutter frameworks from GitHub releases
  # Skipped in local development mode (when .reelsdk-dev file exists)
  spec.prepare_command = <<-CMD
    set -e

    # Check for local development marker file
    if [ -f ".reelsdk-dev" ]; then
      echo "================================================"
      echo "[OK] Local Development Mode"
      echo "================================================"
      echo "Using locally built frameworks"
      echo "Skipping GitHub release download"
      echo ""

      # Link local Debug frameworks to expected location
      # This allows vendored_frameworks to work in both modes
      if [ -d "reels_flutter/.ios/Flutter/Debug" ]; then
        if [ ! -L "Frameworks/Release" ]; then
          echo "Creating symlink to local frameworks..."
          mkdir -p Frameworks
          ln -sf "$(pwd)/reels_flutter/.ios/Flutter/Debug" Frameworks/Release
          echo "[OK] Linked: Frameworks/Release -> reels_flutter/.ios/Flutter/Debug"
        fi
      fi
      echo ""
      exit 0
    fi

    # Distribution mode - download pre-built frameworks
    echo "================================================"
    echo "ReelsSDK Distribution Mode"
    echo "================================================"

    FRAMEWORKS_DIR="Frameworks/Release"
    VERSION=$(cat VERSION)

    # Check if already downloaded
    if [ -d "$FRAMEWORKS_DIR" ] && [ -f "$FRAMEWORKS_DIR/.downloaded-v$VERSION" ]; then
      echo "[OK] Frameworks v$VERSION already downloaded"
      exit 0
    fi

    echo "Downloading Flutter frameworks v$VERSION..."
    echo ""

    # Construct download URLs
    GITHUB_URL="https://github.com/ahmed-eishon/Reels-SDK/releases/download/v${VERSION}-ios/ReelsSDK-Frameworks-Release-${VERSION}.zip"
    GITPUB_URL="https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk/releases/download/v${VERSION}-ios/ReelsSDK-Frameworks-Release-${VERSION}.zip"

    # Try GitHub first, fallback to GitPub
    echo "Trying: $GITHUB_URL"
    if curl -L -f -o frameworks.zip "$GITHUB_URL" 2>/dev/null; then
      echo "[OK] Downloaded from GitHub"
    elif curl -L -f -o frameworks.zip "$GITPUB_URL" 2>/dev/null; then
      echo "[OK] Downloaded from GitPub"
    else
      echo "================================================"
      echo "[ERROR] Failed to download frameworks"
      echo "================================================"
      echo ""
      echo "Possible causes:"
      echo "  1. Release v${VERSION}-ios does not exist"
      echo "  2. Release asset 'ReelsSDK-Frameworks-Release-${VERSION}.zip' not found"
      echo "  3. No internet connection or access denied"
      echo ""
      echo "Solutions:"
      echo "  - Check releases: https://github.com/ahmed-eishon/Reels-SDK/releases"
      echo "  - Or build locally:"
      echo "      cd reels_flutter"
      echo "      flutter build ios-framework --release --output=../Frameworks/Release"
      echo "      touch .reelsdk-dev  # Enable local dev mode"
      echo ""
      exit 1
    fi

    # Extract frameworks
    echo ""
    echo "Extracting frameworks..."
    mkdir -p "$FRAMEWORKS_DIR"
    unzip -q -o frameworks.zip -d "$FRAMEWORKS_DIR"
    rm frameworks.zip

    # Mark as downloaded for this version
    touch "$FRAMEWORKS_DIR/.downloaded-v$VERSION"

    echo "[OK] Frameworks ready"
    echo ""
    ls -1 "$FRAMEWORKS_DIR"/*.xcframework 2>/dev/null | xargs -n1 basename
    echo ""
  CMD

  # Vendored frameworks
  # In local dev: uses reels_flutter/.ios/Flutter/Debug (built by dev scripts)
  # In distribution: uses Frameworks/Release (downloaded by prepare_command)
  spec.vendored_frameworks = 'Frameworks/Release/*.xcframework'

  # Preserve Flutter source for reference
  spec.preserve_paths = 'reels_flutter/**/*'

  # Exclude build artifacts and development files
  spec.exclude_files = [
    'reels_flutter/.dart_tool/**/*',
    'reels_flutter/build/**/*',
    'reels_flutter/.ios/**/*',
    'reels_flutter/.android/**/*',
    'Frameworks/Debug/**/*',
    '.reelsdk-dev'
  ]
end
