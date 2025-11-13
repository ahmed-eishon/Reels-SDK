# Release Scripts

This directory contains scripts for creating SDK releases.

## Overview

Release scripts generate build artifacts that are **NOT** committed to git. These artifacts are created during the CI/CD pipeline and attached to GitHub releases.

## Scripts (To Be Implemented)

### 1. `build-release.sh` (TODO)
Builds all release artifacts:
- Runs `flutter build ios-framework --release`
- Generates xcframework bundles
- Creates distribution packages

### 2. `create-release.sh` (TODO)
Creates and publishes a release:
- Tags the release in git
- Creates GitHub release
- Uploads build artifacts
- Updates documentation

### 3. `validate-release.sh` (TODO)
Validates release artifacts:
- Checks framework sizes
- Verifies code signing
- Runs integration tests
- Validates package structure

## CI/CD Integration

These scripts will be called by GitHub Actions / Jenkins:

```yaml
# Example GitHub Actions workflow
steps:
  - name: Build frameworks
    run: ./scripts/release/build-release.sh

  - name: Validate release
    run: ./scripts/release/validate-release.sh

  - name: Create release
    run: ./scripts/release/create-release.sh
```

## Important Notes

1. **Build artifacts are NOT in git**: They are generated during release
2. **Use semantic versioning**: Major.Minor.Patch (e.g., 1.0.0)
3. **Test before release**: Always validate on real devices
4. **Document changes**: Update CHANGELOG.md

See `RELEASE.md` in the root directory for the complete release process.
