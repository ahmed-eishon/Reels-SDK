# Development iOS Scripts

Development workflows for building room-ios with ReelsSDK integration. These scripts are configurable and support custom schemes/simulators.

## Available Scripts

### `build-room.sh`
**Purpose:** Incremental build of room-ios (fast, no cleaning)

**Usage:**
```bash
./build-room.sh [OPTIONS]
```

**Options:**
- `--scheme, -s SCHEME` - Xcode scheme (default: 'D_Development Staging')
- `--simulator, -d DEVICE` - Simulator name (default: 'iPhone 16 Pro')
- `--full-log, -f` - Show full build log
- `--help, -h` - Show help message

**Examples:**
```bash
# Use defaults
./build-room.sh

# Custom simulator
./build-room.sh --simulator "iPhone 15 Pro"

# Custom scheme
./build-room.sh --scheme "D_Development Production"

# Both
./build-room.sh -s "D_Development Production" -d "iPhone 15 Pro"

# Show full log
./build-room.sh --full-log

# Custom room-ios location
ROOM_IOS_DIR=/custom/path ./build-room.sh
```

**What it does:**
1. Checks if Flutter frameworks exist (builds if missing)
2. Performs incremental Xcode build
3. Shows last 30 lines of output (unless --full-log)

**When to use:**
- Daily development (fastest)
- After small code changes
- Quick iteration cycles

---

### `clean-build-room.sh`
**Purpose:** Complete clean build of room-ios (slow, thorough)

**Usage:**
```bash
./clean-build-room.sh [OPTIONS]
```

**Options:**
- `--scheme, -s SCHEME` - Xcode scheme (default: 'D_Development Staging')
- `--simulator, -d DEVICE` - Simulator name (default: 'iPhone 16 Pro')
- `--full-log, -f` - Show full build log
- `--help, -h` - Show help message

**Examples:**
```bash
# Use defaults
./clean-build-room.sh

# Custom simulator
./clean-build-room.sh --simulator "iPhone 15 Pro"

# Custom scheme
./clean-build-room.sh --scheme "D_Development Production"

# Show full log
./clean-build-room.sh --full-log
```

**What it does:**
1. Cleans and rebuilds Flutter frameworks
2. Runs `pod install` in room-ios
3. Cleans Xcode build
4. Performs complete rebuild

**When to use:**
- After major changes
- Switching branches
- Build issues/corruption
- Before release testing
- After pod updates

## Configuration

### Environment Variables

**ROOM_IOS_DIR**
- Path to room-ios/ROOM directory
- Default: `../room-ios/ROOM` (sibling to reels-sdk)

```bash
# One-time use
ROOM_IOS_DIR=/path/to/room-ios/ROOM ./build-room.sh

# Permanent (add to ~/.zshrc or ~/.bashrc)
export ROOM_IOS_DIR="/Users/yourname/Rakuten/room-ios/ROOM"
```

### Command-Line Flags

All scripts support:
- `--scheme` / `-s` - Xcode build scheme
- `--simulator` / `-d` - iOS Simulator name
- `--full-log` / `-f` - Show complete build output
- `--help` / `-h` - Display help message

## Common Workflows

### Daily Development
```bash
# Quick iterative builds
./build-room.sh

# Make changes...

./build-room.sh
```

### After SDK Changes
```bash
# Full rebuild to ensure everything is fresh
./clean-build-room.sh
```

### Testing Different Schemes
```bash
# Development Staging
./build-room.sh --scheme "D_Development Staging"

# Development Production
./build-room.sh --scheme "D_Development Production"
```

### Testing Different Simulators
```bash
# iPhone 16 Pro
./build-room.sh --simulator "iPhone 16 Pro"

# iPhone 15 Pro
./build-room.sh --simulator "iPhone 15 Pro"

# iPad Pro
./build-room.sh --simulator "iPad Pro (12.9-inch)"
```

### Debugging Build Issues
```bash
# Show full build output
./build-room.sh --full-log

# Or clean build with full output
./clean-build-room.sh --full-log
```

## Features

All scripts include:
- ✅ Colored output with emojis
- ✅ Time tracking for each step
- ✅ Configurable schemes/simulators
- ✅ Auto-detects room-ios location
- ✅ Help flags
- ✅ Environment variable support
- ✅ Smart Flutter framework detection

## Speed Comparison

| Script | Speed | Use Case |
|--------|-------|----------|
| `build-room.sh` | ⚡ ~30s | Daily development |
| `clean-build-room.sh` | 🐌 ~5min | Major changes, troubleshooting |

## Available Simulators

List available simulators:
```bash
xcrun simctl list devices available | grep iPhone
```

Common simulators:
- iPhone 16 Pro
- iPhone 16
- iPhone 15 Pro
- iPhone 15
- iPhone SE (3rd generation)
- iPad Pro (12.9-inch)

## Troubleshooting

**room-ios not found:**
```bash
# Set ROOM_IOS_DIR
export ROOM_IOS_DIR="/path/to/room-ios/ROOM"

# Or pass it inline
ROOM_IOS_DIR=/path/to/room-ios/ROOM ./build-room.sh
```

**Build fails with pod errors:**
```bash
# Run clean build (includes pod install)
./clean-build-room.sh
```

**Simulator not found:**
```bash
# List available simulators
xcrun simctl list devices available

# Use exact name
./build-room.sh --simulator "iPhone 15 Pro"
```

**Want to see full build output:**
```bash
# Add --full-log flag
./build-room.sh --full-log
```

## Related Documentation

- [Library Documentation](../../lib/README.md) - Shared functions
- [SDK Scripts](../../sdk/ios/README.md) - Pure SDK operations
- [Main Scripts README](../../README.md) - Overview of all scripts
- [Build Process](../../../docs/Build-Process.md) - Complete build guide
