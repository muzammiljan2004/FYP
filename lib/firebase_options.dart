// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return windows;
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
    apiKey: 'AIzaSyCptuN6Tz-K-OHxkuffQNtYzsPBu7u6VVY',
    appId: '1:279686141911:web:a25a84d877720b34385d92',
    messagingSenderId: '279686141911',
    projectId: 'wego-app-c0a8d',
    authDomain: 'wego-app-c0a8d.firebaseapp.com',
    databaseURL: 'https://wego-app-c0a8d-default-rtdb.firebaseio.com',
    storageBucket: 'wego-app-c0a8d.firebasestorage.app',
    measurementId: 'G-ZG7LS19R52',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeokS0VZMTxhCJCGjr2yRb7ZUx695y9Dg',
    appId: '1:279686141911:android:7f41a56bf060cd48385d92',
    messagingSenderId: '279686141911',
    projectId: 'wego-app-c0a8d',
    databaseURL: 'https://wego-app-c0a8d-default-rtdb.firebaseio.com',
    storageBucket: 'wego-app-c0a8d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDcfwolv-mHCiuKyiTCQYdMsGGfVrLUH8',
    appId: '1:279686141911:ios:2968705fb41a67ac385d92',
    messagingSenderId: '279686141911',
    projectId: 'wego-app-c0a8d',
    databaseURL: 'https://wego-app-c0a8d-default-rtdb.firebaseio.com',
    storageBucket: 'wego-app-c0a8d.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBDcfwolv-mHCiuKyiTCQYdMsGGfVrLUH8',
    appId: '1:279686141911:ios:2968705fb41a67ac385d92',
    messagingSenderId: '279686141911',
    projectId: 'wego-app-c0a8d',
    databaseURL: 'https://wego-app-c0a8d-default-rtdb.firebaseio.com',
    storageBucket: 'wego-app-c0a8d.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCptuN6Tz-K-OHxkuffQNtYzsPBu7u6VVY',
    appId: '1:279686141911:web:b6766c5515b555c1385d92',
    messagingSenderId: '279686141911',
    projectId: 'wego-app-c0a8d',
    authDomain: 'wego-app-c0a8d.firebaseapp.com',
    databaseURL: 'https://wego-app-c0a8d-default-rtdb.firebaseio.com',
    storageBucket: 'wego-app-c0a8d.firebasestorage.app',
    measurementId: 'G-KE0PSMDRNX',
  );
}
