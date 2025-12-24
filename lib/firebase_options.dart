import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyANJ0-zF2asTQAxGJ1Yw3UdLKJwQNkdZb8',
    appId: '1:383548751444:android:7a43523a49985c07fc77c1',
    messagingSenderId: '383548751444',
    projectId: 'hostel-ease-c19ce',
    authDomain: 'hostel-ease-c19ce.firebaseapp.com',
    storageBucket: 'hostel-ease-c19ce.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyANJ0-zF2asTQAxGJ1Yw3UdLKJwQNkdZb8',
    appId: '1:383548751444:android:7a43523a49985c07fc77c1',
    messagingSenderId: '383548751444',
    projectId: 'hostel-ease-c19ce',
    storageBucket: 'hostel-ease-c19ce.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyANJ0-zF2asTQAxGJ1Yw3UdLKJwQNkdZb8',
    appId: '1:383548751444:android:7a43523a49985c07fc77c1',
    messagingSenderId: '383548751444',
    projectId: 'hostel-ease-c19ce',
    storageBucket: 'hostel-ease-c19ce.firebasestorage.app',
    iosClientId: '383548751444-app.apps.googleusercontent.com',
    iosBundleId: 'com.dormease.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyANJ0-zF2asTQAxGJ1Yw3UdLKJwQNkdZb8',
    appId: '1:383548751444:android:7a43523a49985c07fc77c1',
    messagingSenderId: '383548751444',
    projectId: 'hostel-ease-c19ce',
    storageBucket: 'hostel-ease-c19ce.firebasestorage.app',
    iosClientId: '383548751444-app.apps.googleusercontent.com',
    iosBundleId: 'com.dormease.app',
  );
}