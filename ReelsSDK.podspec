Pod::Spec.new do |spec|
  spec.name                  = 'ReelsSDK'
  spec.module_name           = 'ReelsIOS'
  spec.version               = File.read(File.join(__dir__, 'VERSION')).strip
  spec.summary               = 'Video reels SDK for iOS with Flutter integration'
  spec.description           = <<-DESC
    ReelsSDK provides a Flutter-based video reels experience for iOS applications.
    Features include video playback, engagement buttons (like, share), analytics tracking,
    and type-safe platform communication using Pigeon.

    Automatically selects Debug or Release frameworks based on build configuration.
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

      # Link local frameworks
      if [ -d "Frameworks/Debug/Debug" ] && [ -d "Frameworks/Release/Release" ]; then
        echo "Linking local Debug and Release frameworks..."
        rm -rf Frameworks_All
        mkdir -p Frameworks_All
        cp -R Frameworks/Debug/Debug/*.xcframework Frameworks_All/
        cp -R Frameworks/Release/Release/*.xcframework Frameworks_All/
        rm -rf Frameworks
        mv Frameworks_All Frameworks
        echo "[OK] Linked local frameworks"
      fi
      echo ""
      exit 0
    fi

    # Distribution mode - download pre-built frameworks
    echo "================================================"
    echo "ReelsSDK Distribution Mode"
    echo "================================================"

    VERSION=$(cat VERSION)
    FRAMEWORKS_DIR="Frameworks"

    # Check if already downloaded
    if [ -d "$FRAMEWORKS_DIR" ] && [ -f "$FRAMEWORKS_DIR/.downloaded-v$VERSION" ]; then
      echo "[OK] Frameworks v$VERSION already downloaded"
      exit 0
    fi

    echo ""
    echo "Downloading Flutter frameworks v$VERSION..."

    # Download FULL package with all Debug and Release frameworks
    GITHUB_URL="https://github.com/ahmed-eishon/Reels-SDK/releases/download/v${VERSION}-ios/ReelsSDK-Frameworks-${VERSION}.zip"

    echo "Trying: $GITHUB_URL"
    if curl -L -f -o "frameworks.zip" "$GITHUB_URL"; then
      echo "[OK] Downloaded from GitHub"
    else
      echo "================================================"
      echo "[ERROR] Failed to download frameworks"
      echo "================================================"
      echo ""
      echo "Release v${VERSION}-ios asset not found"
      echo ""
      echo "Solutions:"
      echo "  - Check releases: https://github.com/ahmed-eishon/Reels-SDK/releases"
      echo "  - Or build locally and create .reelsdk-dev file"
      echo ""
      exit 1
    fi

    # Extract frameworks
    echo "Extracting frameworks..."
    mkdir -p "$FRAMEWORKS_DIR"
    unzip -q -o "frameworks.zip" -d "$FRAMEWORKS_DIR"
    rm "frameworks.zip"

    # Mark as downloaded for this version
    touch "$FRAMEWORKS_DIR/.downloaded-v$VERSION"

    echo "[OK] Frameworks ready"
    echo ""
    ls -1 "$FRAMEWORKS_DIR"/*.xcframework 2>/dev/null | xargs -n1 basename || echo "No frameworks found"
    echo ""
    echo "================================================"
    echo "[OK] Frameworks ready for use"
    echo "================================================"
  CMD

  # Vendor ALL frameworks (both Debug and Release variants)
  spec.vendored_frameworks = 'Frameworks/*.xcframework'

  # Script phase to symlink correct frameworks based on build configuration
  spec.script_phases = [
    {
      :name => 'Select ReelsSDK Frameworks',
      :script => <<-SCRIPT,
        set -e

        echo "[ReelsSDK] Configuration: $CONFIGURATION"

        # Determine which framework suffix to use
        if [[ "$CONFIGURATION" == *"Debug"* ]] || [[ "$CONFIGURATION" == "D_"* ]]; then
          REQUIRED_SUFFIX="_Debug"
          REMOVE_SUFFIX="_Release"
          echo "[ReelsSDK] Using Debug frameworks"
        else
          REQUIRED_SUFFIX="_Release"
          REMOVE_SUFFIX="_Debug"
          echo "[ReelsSDK] Using Release frameworks"
        fi

        # Path to vendored frameworks in Pods
        FRAMEWORKS_DIR="${PODS_ROOT}/ReelsSDK/Frameworks"

        if [ ! -d "$FRAMEWORKS_DIR" ]; then
          echo "[ReelsSDK] Warning: Frameworks directory not found"
          exit 0
        fi

        # Create symlinks for frameworks without suffix pointing to correct variant
        for framework in "$FRAMEWORKS_DIR"/*${REQUIRED_SUFFIX}.xcframework; do
          if [ -e "$framework" ]; then
            base_name=$(basename "$framework" ${REQUIRED_SUFFIX}.xcframework)
            symlink_path="$FRAMEWORKS_DIR/${base_name}.xcframework"

            # Remove existing symlink or directory
            if [ -L "$symlink_path" ] || [ -e "$symlink_path" ]; then
              rm -rf "$symlink_path"
            fi

            # Create symlink
            ln -s "$(basename "$framework")" "$symlink_path"
            echo "[ReelsSDK] Linked: ${base_name}.xcframework -> $(basename "$framework")"
          fi
        done

        echo "[ReelsSDK] Framework selection complete"
      SCRIPT
      :execution_position => :before_compile
    }
  ]

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
