import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.android:
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA2GFSr9YJpUmC-PoaTKE0yGodyzqYcq6w',
    appId: '1:310514488602:web:3790968da8a9cfc09a88a3',
    messagingSenderId: '310514488602',
    projectId: 'nar-rehberi',
    authDomain: 'nar-rehberi.firebaseapp.com',
    storageBucket: 'nar-rehberi.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC5acc2-V7kTa3eA3ehMeSVYpoSqdYvSOc',
    appId: '1:310514488602:android:2485248a4e7223949a88a3',
    messagingSenderId: '310514488602',
    projectId: 'nar-rehberi',
    storageBucket: 'nar-rehberi.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBb4vGonG4ag62KRULwBj7s4ysPw6gfNQo',
    appId: '1:310514488602:ios:0095634b2dc473fc9a88a3',
    messagingSenderId: '310514488602',
    projectId: 'nar-rehberi',
    iosBundleId: 'com.hisle.app',
    storageBucket: 'nar-rehberi.firebasestorage.app',
  );
}
