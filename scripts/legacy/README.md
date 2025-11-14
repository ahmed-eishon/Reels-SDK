# Legacy Scripts

This directory contains the original scripts from before the reorganization.

## ⚠️ Deprecated

These scripts are kept for backwards compatibility and as a failsafe during the migration period.

**These scripts will be removed in a future release.**

## Migration Guide

### Old Script → New Script Mapping

#### iOS Scripts:

| Old Script | New Script | Notes |
|------------|------------|-------|
| `build-flutter-frameworks.sh` | `sdk/ios/build-frameworks.sh` | SDK-only, no app dependencies |
| `clean-install-ios.sh` | `sdk/ios/setup.sh` | SDK setup and verification |
| `verify-ios.sh` | `sdk/ios/verify.sh` | SDK verification only |
| `build-room-ios.sh` | `dev/ios/build-room.sh` | Now configurable with flags |
| `clean-build-room-ios.sh` | `dev/ios/clean-build-room.sh` | Now configurable with flags |
| `init-ios.sh` | `integration/ios/init-client.sh` | Client integration helper |

#### Android Scripts:

| Old Script | New Script | Notes |
|------------|------------|-------|
| `clean-install-android.sh` | `sdk/android/setup.sh` | SDK setup and verification |
| `verify-android.sh` | `sdk/android/verify.sh` | SDK verification only |
| `init-android.sh` | `integration/android/init-client.sh` | Client integration helper |

#### Release:

| Old Script | New Script | Notes |
|------------|------------|-------|
| `release.sh` | `release.sh` | Remains at root level |

## New Features in Reorganized Scripts

### 1. **Shared Library**
All new scripts use `lib/common.sh` for:
- Consistent logging (colored output, emojis)
- Time tracking
- Common validation functions
- Path resolution utilities

### 2. **Better Organization**
- `sdk/` - Pure SDK operations (platform-agnostic)
- `dev/` - Development workflows with room-ios
- `integration/` - External project integration
- `lib/` - Shared utilities

### 3. **Configurability**
New scripts support:
- Environment variables
- Command-line flags
- Interactive mode (coming soon)
- Configuration files (coming soon)

### 4. **Better Error Handling**
- Descriptive error messages
- Step-by-step progress indicators
- Time tracking for each operation
- Log file generation

## How to Use Legacy Scripts

If you need to use a legacy script temporarily:

```bash
# From SDK root
./scripts/legacy/build-room-ios.sh

# Or add to PATH temporarily
export PATH="$PATH:/path/to/reels-sdk/scripts/legacy"
build-room-ios.sh
```

## When Will These Be Removed?

Legacy scripts will be removed after:
1. All new scripts are fully tested
2. Documentation is updated
3. Team members have migrated to new scripts
4. At least one release cycle has passed

Expected removal: **Version 1.1.0 or later**

## Need Help?

If you encounter issues with the new scripts:
1. Check the script documentation: `scripts/sdk/ios/README.md`, etc.
2. Check the common library docs: `scripts/lib/README.md`
3. Use the legacy scripts temporarily
4. Report issues to the team

## Migration Checklist

- [ ] Update CI/CD pipelines to use new script paths
- [ ] Update local development workflows
- [ ] Update documentation references
- [ ] Test new scripts in your environment
- [ ] Remove references to legacy scripts from docs

---

**Last Updated:** November 14, 2025
