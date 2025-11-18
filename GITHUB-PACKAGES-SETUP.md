# GitHub Packages Authentication Setup

## Overview

The Reels SDK Android library is published to **GitHub Packages (Maven)**. To use it in your project, you need to configure GitHub authentication.

## Quick Setup

### 1. Create a GitHub Personal Access Token (PAT)

1. Go to GitHub Settings → [Developer settings → Personal access tokens → Tokens (classic)](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give it a name (e.g., "Reels SDK Access")
4. Select the `read:packages` scope
5. Click "Generate token"
6. **Copy the token** - you won't be able to see it again!

### 2. Configure Gradle Properties

Create or edit `~/.gradle/gradle.properties`:

```properties
gpr.user=YOUR_GITHUB_USERNAME
gpr.key=YOUR_GITHUB_PAT_TOKEN
```

**Example:**
```properties
gpr.user=john.doe
gpr.key=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Add Dependency

Your `settings.gradle` and `app/build.gradle` are already configured. Just sync Gradle and build!

```bash
./gradlew clean build
```

## How It Works

### settings.gradle
```gradle
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()

        maven {
            url = uri("https://maven.pkg.github.com/ahmed-eishon/Reels-SDK")
            credentials {
                username = providers.gradleProperty("gpr.user").getOrElse("")
                password = providers.gradleProperty("gpr.key").getOrElse("")
            }
        }
    }
}
```

### app/build.gradle
```gradle
dependencies {
    implementation 'com.rakuten.room:reels-sdk:0.1.4'
}
```

## Comparison with iOS

| Platform | Package Manager | Authentication |
|----------|----------------|----------------|
| **iOS** | CocoaPods | Built-in GitHub access |
| **Android** | Maven (GitHub Packages) | GitHub PAT required |

Both provide automatic fetching and version management!

## CI/CD Setup

For GitHub Actions or CI/CD pipelines, use environment variables:

```yaml
- name: Build Android
  env:
    GITHUB_ACTOR: ${{ github.actor }}
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: ./gradlew build
```

## Troubleshooting

### "Could not resolve com.rakuten.room:reels-sdk:X.X.X"

**Cause**: Missing or invalid GitHub credentials

**Solution**:
1. Verify `~/.gradle/gradle.properties` exists and contains correct values
2. Check your PAT has `read:packages` permission
3. Ensure your GitHub username is correct

### "401 Unauthorized"

**Cause**: Invalid or expired GitHub PAT

**Solution**:
1. Generate a new PAT with `read:packages` scope
2. Update `gpr.key` in `~/.gradle/gradle.properties`

### "404 Not Found"

**Cause**: Package doesn't exist for that version

**Solution**:
1. Check available versions at: https://github.com/ahmed-eishon/Reels-SDK/packages
2. Update version number in `app/build.gradle`

## Available Versions

Check published versions at:
https://github.com/ahmed-eishon/Reels-SDK/packages

## Documentation

For full integration guide, see:
- [Android Integration Guide](docs/02-Integration/02-Android-Integration-Guide.md)
- [API Reference](docs/05-API/02-Android-API-Reference.md)

## Support

If you encounter issues:
1. Check this guide first
2. Review the [Android Integration Guide](docs/02-Integration/02-Android-Integration-Guide.md)
3. Open an issue on GitHub

---

**Last Updated**: 2025-11-18
**SDK Version**: 0.1.4
