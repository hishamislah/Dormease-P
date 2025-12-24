# Firebase Setup for DormEase

This document provides instructions for setting up Firebase for the DormEase app.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Firebase CLI installed

## Setup Steps

### 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name your project "dormease-app" (or your preferred name)
4. Follow the setup wizard to create the project

### 2. Register Your App with Firebase

#### For Android:

1. In the Firebase console, click the Android icon
2. Enter your app's package name (e.g., `com.example.dormease`)
3. Register the app
4. Download the `google-services.json` file
5. Place it in the `android/app` directory of your Flutter project

#### For iOS:

1. In the Firebase console, click the iOS icon
2. Enter your app's bundle ID (e.g., `com.example.dormease`)
3. Register the app
4. Download the `GoogleService-Info.plist` file
5. Place it in the `ios/Runner` directory of your Flutter project

### 3. Update Firebase Configuration

1. Open `lib/firebase_options.dart`
2. Replace the placeholder values with your actual Firebase project values:
   - `apiKey`
   - `appId`
   - `messagingSenderId`
   - `projectId`
   - `iosClientId` (for iOS)

### 4. Set Up Firestore Database

1. In the Firebase console, go to "Firestore Database"
2. Click "Create database"
3. Start in production mode
4. Choose a location closest to your users
5. Create the following collections:
   - `rooms`
   - `tenants`
   - `tickets`

### 5. Set Up Firestore Security Rules

1. Go to "Firestore Database" > "Rules"
2. Update the rules to:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // For development only
    }
  }
}
```

**Note:** For production, implement proper authentication and security rules.

### 6. Install FlutterFire CLI (Optional)

For easier Firebase configuration:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This will automatically set up your Firebase configuration files.

## Testing Firebase Connection

1. Run the app
2. Check the console for "Firebase initialized successfully" message
3. Verify data is being saved to and retrieved from Firestore

## Troubleshooting

- If you encounter build errors, ensure all Firebase dependencies are correctly added to `pubspec.yaml`
- For iOS, make sure you've updated your `Info.plist` with required Firebase configurations
- For Android, verify the `google-services.json` is in the correct location

## Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview)
- [Firebase Documentation](https://firebase.google.com/docs)