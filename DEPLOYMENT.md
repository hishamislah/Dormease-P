# DormEase Production Deployment Guide

## Prerequisites

### Android
1. **Generate Upload Keystore**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Update key.properties**
   Edit `android/key.properties` with your keystore details:
   ```
   storePassword=<your-password>
   keyPassword=<your-password>
   keyAlias=upload
   storeFile=/Users/hishamislah/upload-keystore.jks
   ```

### iOS
1. **Apple Developer Account** - Required for App Store distribution
2. **Xcode** - Latest version installed
3. **Certificates & Provisioning Profiles** - Set up in Xcode

## Build Commands

### Quick Build (All Platforms)
```bash
./build_production.sh
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Android APK (Direct Distribution)
```bash
flutter build apk --release --split-per-abi
```
Output: `build/app/outputs/flutter-apk/`

### iOS (App Store)
```bash
flutter build ipa --release
```
Output: `build/ios/ipa/`

## Upload to Stores

### Google Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app or create new app
3. Navigate to **Production** → **Create new release**
4. Upload `app-release.aab`
5. Fill in release notes
6. Review and rollout

### Apple App Store
1. Open Xcode
2. Product → Archive
3. Window → Organizer
4. Select archive → Distribute App
5. Choose App Store Connect
6. Upload to [App Store Connect](https://appstoreconnect.apple.com)

## Version Management

Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Format: major.minor.patch+buildNumber
```

## Security Checklist
- [ ] Keystore file is NOT committed to git
- [ ] key.properties is in .gitignore
- [ ] API keys are secured
- [ ] ProGuard rules configured (if needed)
- [ ] App permissions reviewed

## Testing Before Release
```bash
# Test release build on device
flutter run --release

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Troubleshooting

### Android Signing Issues
- Verify keystore path in key.properties
- Check password correctness
- Ensure keystore file exists

### iOS Build Issues
- Update CocoaPods: `cd ios && pod install`
- Clean build: `flutter clean && cd ios && rm -rf Pods Podfile.lock`
- Check signing certificates in Xcode

## File Locations
- Android Bundle: `build/app/outputs/bundle/release/app-release.aab`
- Android APKs: `build/app/outputs/flutter-apk/`
- iOS IPA: `build/ios/ipa/`
