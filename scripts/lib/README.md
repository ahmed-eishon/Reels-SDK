# Reels SDK - Shared Library

This directory contains shared utilities used by all Reels SDK scripts.

## Usage

To use the common library in your script:

```bash
#!/bin/bash
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common library (adjust path based on your script location)
source "$SCRIPT_DIR/../lib/common.sh"

# Or if script is in sdk/ios/ or dev/ios/:
source "$SCRIPT_DIR/../../lib/common.sh"

# Now you can use all the common functions!
log_header "My Script"
log_info "Starting process..."
track_script_start

# Your script logic here...

track_script_end
```

## Available Functions

### Logging Functions

| Function | Description | Example |
|----------|-------------|---------|
| `log_info "message"` | Blue info message with ℹ️ icon | `log_info "Processing files..."` |
| `log_success "message"` | Green success message with ✅ icon | `log_success "Build completed"` |
| `log_error "message"` | Red error message with ❌ icon | `log_error "File not found"` |
| `log_warning "message"` | Yellow warning message with ⚠️ icon | `log_warning "Deprecated feature"` |
| `log_step "num" "desc"` | Cyan step header | `log_step "1" "Installing dependencies"` |
| `log_header "text"` | Blue section header | `log_header "Build Process"` |
| `log_footer "text"` | Green section footer | `log_footer "Build Complete!"` |
| `log_command "cmd"` | Shows command being run | `log_command "flutter build"` |

### Time Tracking

| Function | Description | Example |
|----------|-------------|---------|
| `track_script_start` | Start tracking total script time | `track_script_start` |
| `track_script_end` | Show total script execution time | `track_script_end` |
| `track_step_start` | Start tracking a step | `track_step_start` |
| `track_step_end` | Show step execution time | `track_step_end` |

Example:
```bash
track_script_start

log_step "1" "Building Flutter"
track_step_start
flutter build ios-framework
track_step_end

track_script_end
```

### Validation Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `check_flutter_installed` | Verify Flutter is in PATH | 0 if installed, 1 if not |
| `check_cocoapods_installed` | Verify CocoaPods is in PATH | 0 if installed, 1 if not |
| `verify_directory_exists "path" "name"` | Check if directory exists | 0 if exists, 1 if not |
| `verify_file_exists "path" "name"` | Check if file exists | 0 if exists, 1 if not |

Example:
```bash
if ! check_flutter_installed; then
    exit 1
fi

if ! verify_directory_exists "$SDK_ROOT/reels_flutter" "Flutter module"; then
    exit 1
fi
```

### Path Resolution

| Function | Description | Returns |
|----------|-------------|---------|
| `get_sdk_root "$0"` | Find SDK root directory | Path to SDK root |
| `get_flutter_module_dir "$sdk_root"` | Get Flutter module path | Path to reels_flutter |
| `get_ios_module_dir "$sdk_root"` | Get iOS module path | Path to reels_ios |
| `get_android_module_dir "$sdk_root"` | Get Android module path | Path to reels_android |
| `get_room_ios_dir "$sdk_root"` | Get room-ios path (respects $ROOM_IOS_DIR) | Path to room-ios/ROOM |

Example:
```bash
SDK_ROOT=$(get_sdk_root "$0")
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")
IOS_DIR=$(get_ios_module_dir "$SDK_ROOT")
```

### Version Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get_sdk_version "$sdk_root"` | Read VERSION file | Version string |
| `get_flutter_version` | Get Flutter version | Flutter version string |
| `get_cocoapods_version` | Get CocoaPods version | CocoaPods version string |

### Build Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `clean_flutter_build "$flutter_dir"` | Run flutter clean | 0 on success |
| `flutter_pub_get "$flutter_dir"` | Run flutter pub get | 0 on success |
| `build_flutter_frameworks "$flutter_dir" [clean]` | Build iOS frameworks | 0 on success |

Example:
```bash
SDK_ROOT=$(get_sdk_root "$0")
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")

if ! build_flutter_frameworks "$FLUTTER_DIR" true; then
    log_error "Build failed"
    exit 1
fi
```

### Pigeon Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `regenerate_pigeon "$flutter_dir"` | Run Pigeon code generator | 0 on success |
| `verify_pigeon_files "$sdk_root"` | Check all Pigeon files exist | 0 if all exist |

### Interactive Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `confirm "prompt" [default]` | Prompt user for y/n confirmation | 0 if yes, 1 if no |

Example:
```bash
if confirm "Continue with build?" "y"; then
    log_info "Building..."
else
    log_warning "Build cancelled"
    exit 0
fi
```

### Utility Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get_ios_simulators` | List available iOS simulators | Simulator names |

## Color Variables

You can use these color variables directly:

```bash
echo -e "${GREEN}Success!${NC}"
echo -e "${RED}Error!${NC}"
echo -e "${YELLOW}Warning!${NC}"
echo -e "${BLUE}Info${NC}"
echo -e "${CYAN}Highlight${NC}"
echo -e "${MAGENTA}Special${NC}"
```

Available colors:
- `GREEN` - Success messages
- `RED` - Error messages
- `YELLOW` - Warning messages
- `BLUE` - Info messages
- `CYAN` - Highlights
- `MAGENTA` - Special emphasis
- `NC` - No Color (reset)

## Complete Example Script

```bash
#!/bin/bash
set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Start tracking
track_script_start

# Header
log_header "My Build Script"

# Get paths
SDK_ROOT=$(get_sdk_root "$0")
FLUTTER_DIR=$(get_flutter_module_dir "$SDK_ROOT")

log_info "SDK Root: $SDK_ROOT"
log_info "SDK Version: $(get_sdk_version "$SDK_ROOT")"
echo ""

# Check requirements
log_step "1" "Checking requirements"
track_step_start
check_flutter_installed || exit 1
check_cocoapods_installed || exit 1
track_step_end

# Build Flutter
log_step "2" "Building Flutter frameworks"
track_step_start
if build_flutter_frameworks "$FLUTTER_DIR" false; then
    track_step_end
else
    log_error "Build failed"
    exit 1
fi

# Success
log_footer "Build Complete!"
track_script_end
```

## Testing

To test the library:

```bash
# Create a test script
cat > /tmp/test-common.sh << 'EOF'
#!/bin/bash
source "$(dirname "$0")/../lib/common.sh"

log_header "Testing Common Library"

log_info "This is an info message"
log_success "This is a success message"
log_warning "This is a warning message"
log_error "This is an error message"

log_step "1" "Testing step logging"
log_command "flutter build ios"

track_script_start
sleep 1
track_script_end

log_footer "Test Complete!"
EOF

chmod +x /tmp/test-common.sh
/tmp/test-common.sh
```
