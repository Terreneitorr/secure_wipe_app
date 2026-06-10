import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web no soportado.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Plataforma no configurada.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBW1a18c5QBNVxLmmjIonFgDrdOdUdtVC0',
    appId: '1:280882272632:android:99740e064ccc5f1b9b108d',
    messagingSenderId: '280882272632',
    projectId: 'secure-wipe-app',
    storageBucket: 'secure-wipe-app.firebasestorage.app',
  );
}