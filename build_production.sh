#!/bin/bash

# DormEase Production Build Script

echo "🚀 Building DormEase for Production..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Generate app icons
echo "🎨 Generating app icons..."
flutter pub run flutter_launcher_icons

# Build Android App Bundle
echo "📦 Building Android App Bundle..."
flutter build appbundle --release

# Build Android APK
echo "📱 Building Android APK..."
flutter build apk --release --split-per-abi

# Build iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS..."
    flutter build ipa --release
fi

echo "✅ Build Complete!"
echo ""
echo "📂 Output locations:"
echo "   Android Bundle: build/app/outputs/bundle/release/app-release.aab"
echo "   Android APK: build/app/outputs/flutter-apk/"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   iOS IPA: build/ios/ipa/"
fi
