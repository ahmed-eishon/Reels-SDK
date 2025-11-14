# SDK iOS Scripts

Pure SDK operations with no app dependencies. These scripts work directly with the Reels SDK and don't require room-ios or any other host application.

## Available Scripts

### `build-frameworks.sh`
**Purpose:** Build Flutter frameworks for iOS (Debug/Profile/Release)

**Usage:**
```bash
./build-frameworks.sh [--clean]
```

**Options:**
- `--clean`, `-c` - Clean before building

**What it does:**
- Builds Flutter frameworks in `.ios/Flutter/` directory
- No scheme or simulator dependencies
- Can be used by any iOS app

**When to use:**
- After Flutter code changes
- When frameworks are missing
- Before manual framework integration

---

### `setup.sh`
**Purpose:** Complete SDK setup and verification

**Usage:**
```bash
./setup.sh
```

**What it does:**
1. Cleans Flutter build artifacts
2. Runs `flutter pub get`
3. Regenerates iOS platform files
4. Regenerates Pigeon code
5. Verifies all SDK components

**When to use:**
- First-time SDK setup
- After `flutter clean`
- After switching branches
- When SDK is corrupted
- Before distributing SDK

---

### `verify.sh`
**Purpose:** Verify SDK integrity and structure

**Usage:**
```bash
./verify.sh
```

**What it does:**
- Checks VERSION file
- Validates ReelsSDK.podspec
- Verifies Swift Package structure
- Counts Swift source files
- Verifies Pigeon generated files
- Shows integration instructions

**When to use:**
- Before release
- CI/CD validation
- Troubleshooting SDK issues
- After major changes

---

### `generate-pigeon.sh`
**Purpose:** Regenerate Pigeon platform channel code

**Usage:**
```bash
./generate-pigeon.sh
```

**What it does:**
- Runs Pigeon code generator
- Generates platform channels for iOS, Android, and Flutter
- Verifies all generated files

**When to use:**
- After modifying `pigeons/messages.dart`
- When platform channels are out of sync
- After updating Pigeon version

---

### `package-frameworks.sh`
**Purpose:** Package Flutter frameworks for distribution

**Usage:**
```bash
./package-frameworks.sh [Debug|Release]
```

**Options:**
- `Debug` - Package Debug frameworks
- `Release` - Package Release frameworks (default)

**What it does:**
- Verifies frameworks exist
- Creates zip archive
- Generates checksum and manifest
- Ready for GitHub release upload

**When to use:**
- Before creating a release
- Manual framework distribution
- Testing release packages

**Examples:**
```bash
# Package Release frameworks (default)
./package-frameworks.sh

# Package Debug frameworks
./package-frameworks.sh Debug
```

---

### `prepare-release.sh`
**Purpose:** Create new SDK release with GitHub Actions automation

**Usage:**
```bash
./prepare-release.sh [VERSION]
```

**What it does:**
1. Verifies git status and SDK integrity
2. Validates podspec
3. Creates git tag
4. Pushes tag to GitHub
5. Triggers GitHub Actions to build and release

**When to use:**
- Creating a new release
- After updating VERSION file

**Examples:**
```bash
# Use VERSION file
./prepare-release.sh

# Specify version
./prepare-release.sh 1.0.0
```

**What happens after:**
- GitHub Actions builds Debug + Release frameworks
- Packages them into zip files
- Creates GitHub Release automatically
- Uploads framework zips as assets
- Users can install via CocoaPods (no Flutter required!)

## Common Workflows

### Initial SDK Setup
```bash
# Complete setup from scratch
./setup.sh
```

### After Modifying Platform Channels
```bash
# Regenerate Pigeon code
./generate-pigeon.sh

# Verify everything is correct
./verify.sh
```

### Creating a Release
```bash
# 1. Update VERSION file
echo "1.0.0" > ../../../VERSION

# 2. Commit changes
git add .
git commit -m "Prepare release v1.0.0"
git push

# 3. Prepare and push release
./prepare-release.sh 1.0.0

# GitHub Actions will automatically:
#  - Build Debug + Release frameworks
#  - Package into zips
#  - Create GitHub Release
#  - Upload framework assets
```

### Before Release (Manual Check)
```bash
# Verify SDK integrity
./verify.sh

# If issues found, run setup
./setup.sh

# Package frameworks locally (optional)
./package-frameworks.sh Release
```

### Building Frameworks Only
```bash
# Quick build
./build-frameworks.sh

# Clean build
./build-frameworks.sh --clean
```

## Features

All scripts include:
- ✅ Colored output with emojis
- ✅ Time tracking for each step
- ✅ Clear error messages
- ✅ Step-by-step progress indicators
- ✅ Path auto-detection
- ✅ Validation checks

## Environment Variables

These scripts don't require environment variables as they work purely with the SDK.

## Related Documentation

- [Library Documentation](../../lib/README.md) - Shared functions used by these scripts
- [Main Scripts README](../../README.md) - Overview of all scripts
- [iOS Integration Guide](../../../docs/02-Integration/01-iOS-Integration-Guide.md)

## Troubleshooting

**Flutter frameworks not building:**
```bash
# Check Flutter installation
flutter doctor

# Try clean build
./build-frameworks.sh --clean
```

**Pigeon code generation fails:**
```bash
# Update Pigeon
cd ../../reels_flutter
flutter pub upgrade pigeon

# Regenerate
cd ../scripts/sdk/ios
./generate-pigeon.sh
```

**Verification fails:**
```bash
# Run full setup
./setup.sh

# Then verify again
./verify.sh
```
