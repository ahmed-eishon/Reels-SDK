# Reels SDK Scripts

Organized build and development scripts for the Reels SDK.

## 📂 Directory Structure

```
scripts/
├── lib/                                   # Shared utilities (NEW!)
│   ├── common.sh                         # Shared functions library
│   ├── README.md                         # Library documentation
│   └── test.sh                           # Test script
│
├── sdk/                                   # SDK-level operations (NEW!)
│   ├── ios/                              # iOS SDK scripts (coming soon)
│   └── android/                          # Android SDK scripts (coming soon)
│
├── dev/                                   # Development workflows (NEW!)
│   ├── ios/                              # iOS development scripts (coming soon)
│   └── android/                          # Android development scripts (coming soon)
│
├── integration/                           # Client integration (NEW!)
│   ├── ios/                              # iOS integration helpers (coming soon)
│   └── android/                          # Android integration helpers (coming soon)
│
├── legacy/                                # Old scripts (DEPRECATED)
│   ├── README.md                         # Migration guide
│   └── *.sh                              # Original scripts (failsafe)
│
├── logs/                                  # Build logs (gitignored)
│
└── release.sh                             # Release script

# Old scripts (at root - DEPRECATED, use legacy/ or new structure)
├── build-flutter-frameworks.sh           → sdk/ios/build-frameworks.sh
├── build-room-ios.sh                     → dev/ios/build-room.sh
├── clean-build-room-ios.sh               → dev/ios/clean-build-room.sh
├── clean-install-ios.sh                  → sdk/ios/setup.sh
├── verify-ios.sh                         → sdk/ios/verify.sh
└── init-ios.sh                           → integration/ios/init-client.sh
```

## 🎯 Quick Start

### SDK Setup (No app dependencies)
```bash
# Coming soon: sdk/ios/setup.sh
# For now use: ./clean-install-ios.sh
```

### Development with room-ios
```bash
# Coming soon: dev/ios/build-room.sh
# For now use: ./build-room-ios.sh
```

### Clean Build
```bash
# Coming soon: dev/ios/clean-build-room.sh
# For now use: ./clean-build-room-ios.sh
```

## 📚 New Features

### 1. Shared Library (`lib/common.sh`)

All new scripts use a shared library with:
- **Logging**: `log_info()`, `log_success()`, `log_error()`, `log_warning()`
- **Time Tracking**: `track_script_start()`, `track_script_end()`
- **Validation**: `check_flutter_installed()`, `verify_directory_exists()`
- **Path Resolution**: `get_sdk_root()`, `get_flutter_module_dir()`
- **Build Functions**: `build_flutter_frameworks()`, `regenerate_pigeon()`

See [lib/README.md](lib/README.md) for complete documentation.

### 2. Better Organization

**`sdk/` - Pure SDK Operations**
- No app dependencies (scheme/simulator)
- Platform-agnostic where possible
- Quick verification and setup

**`dev/` - Development Workflows**
- room-ios integration
- Configurable builds (scheme, simulator)
- Interactive options (coming soon)

**`integration/` - Client Integration**
- Help integrate SDK into external apps
- Podfile generation
- Setup verification

### 3. Improved UX

- ✅ Colored output with emojis
- ✅ Time tracking for operations
- ✅ Step-by-step progress indicators
- ✅ Better error messages
- ✅ Consistent formatting

## 🔄 Migration Status

### Phase 1: ✅ COMPLETE
- ✅ Created directory structure
- ✅ Created shared library (`lib/common.sh`)
- ✅ Backed up old scripts to `legacy/`
- ✅ Created documentation

### Phase 2: 🚧 IN PROGRESS
- [ ] Migrate SDK scripts to `sdk/ios/`
- [ ] Migrate dev scripts to `dev/ios/`
- [ ] Migrate integration scripts to `integration/ios/`
- [ ] Add Android equivalents

### Phase 3: 📅 PLANNED
- [ ] Add configuration support
- [ ] Add interactive mode
- [ ] Add better error handling
- [ ] Generate build logs

### Phase 4: 📅 PLANNED
- [ ] Update documentation
- [ ] Update CI/CD
- [ ] Remove old scripts from root

## 📖 Documentation

- [Library Documentation](lib/README.md) - Shared functions and utilities
- [Legacy Scripts](legacy/README.md) - Old scripts and migration guide
- [Build Process](../docs/Build-Process.md) - Complete build documentation

## ⚠️ Important Notes

### Current State
- **Old scripts at root level still work** (backwards compatible)
- **Use `legacy/` folder for failsafe** if new scripts have issues
- **New directory structure is ready** for new scripts

### Using Old Scripts
```bash
# Option 1: Use from root (current working directory)
./build-room-ios.sh

# Option 2: Use from legacy folder
./legacy/build-room-ios.sh
```

### Using New Library (for script developers)
```bash
#!/bin/bash
set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Use library functions
log_header "My Script"
SDK_ROOT=$(get_sdk_root "$0")
track_script_start

# Your script logic...

track_script_end
log_footer "Complete!"
```

## 🆘 Need Help?

- Check library docs: [lib/README.md](lib/README.md)
- Check legacy migration: [legacy/README.md](legacy/README.md)
- Run library tests: `./lib/test.sh`
- Use legacy scripts temporarily

## 🔗 Related Documentation

- [Build Process](../docs/Build-Process.md)
- [iOS Integration Guide](../docs/02-Integration/01-iOS-Integration-Guide.md)
- [Android Integration Guide](../docs/02-Integration/02-Android-Integration-Guide.md)

---

**Last Updated:** November 14, 2025
**Status:** Phase 1 Complete - Ready for Phase 2
