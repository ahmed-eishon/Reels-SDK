#!/bin/bash

# Test script for helper-reels-android build approach
# This simulates what the CI workflow does

set -e  # Exit on error

echo "========================================"
echo "Testing helper-reels-android build"
echo "========================================"
echo ""

# Get the script directory and navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

echo "📂 Project root: $PROJECT_ROOT"
echo ""

# Step 1: Build Flutter AAR
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Building Flutter AAR (Debug)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd reels_flutter
flutter pub get
flutter pub run pigeon --input pigeons/messages.dart
flutter build aar --debug --no-release --no-profile
echo "✅ Flutter AAR built successfully"
echo ""

# Step 2: Setup Maven repository path
cd "$PROJECT_ROOT"
MAVEN_REPO="$PROJECT_ROOT/reels_flutter/build/host/outputs/repo"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Maven Repository Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Maven repo location: $MAVEN_REPO"
echo ""

# Verify Flutter AAR was built
if [ ! -d "$MAVEN_REPO" ]; then
    echo "❌ Error: Maven repo not found at $MAVEN_REPO"
    exit 1
fi

echo "📦 Flutter AAR files:"
find "$MAVEN_REPO" -name "*.aar" | head -5
echo ""

# Step 3: Prepare helper project
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Preparing helper-reels-android"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$PROJECT_ROOT/helper-reels-android"

# Create settings.gradle from template
cp settings.gradle.template settings.gradle

# Substitute Maven repo path
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|MAVEN_REPO_PLACEHOLDER|${MAVEN_REPO}|g" settings.gradle
else
    # Linux
    sed -i "s|MAVEN_REPO_PLACEHOLDER|${MAVEN_REPO}|g" settings.gradle
fi

# Create local.properties from template with ANDROID_HOME
if [ -z "$ANDROID_HOME" ]; then
    echo "❌ Error: ANDROID_HOME environment variable not set"
    exit 1
fi

cp local.properties.template local.properties
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|ANDROID_SDK_PLACEHOLDER|${ANDROID_HOME}|g" local.properties
else
    # Linux
    sed -i "s|ANDROID_SDK_PLACEHOLDER|${ANDROID_HOME}|g" local.properties
fi

echo "✅ Helper project prepared"
echo ""

# Show the substituted settings.gradle snippet
echo "📄 settings.gradle (Maven repo section):"
grep -A 2 "maven {" settings.gradle | grep -A 2 "file://"
echo ""

# Step 4: Build reels_android AAR
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Building reels_android AAR (Debug)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./gradlew :reels_android:clean :reels_android:assembleDebug --stacktrace

echo ""
echo "✅ reels_android AAR built successfully"
echo ""

# Step 5: Show build outputs
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 5: Build Outputs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$PROJECT_ROOT"

echo "📦 reels_android AAR files:"
find reels_android/build/outputs -name "*.aar" -type f
echo ""

# Cleanup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Cleanup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$PROJECT_ROOT/helper-reels-android"
rm -f settings.gradle local.properties
echo "✅ Cleaned up generated files (settings.gradle, local.properties)"
echo ""

echo "========================================"
echo "✅ Build test completed successfully!"
echo "========================================"
echo ""
echo "Summary:"
echo "  • Flutter AAR: $MAVEN_REPO"
echo "  • reels_android AAR: $PROJECT_ROOT/reels_android/build/outputs/aar/"
