// ⚠️  IMPORTANTE: Este archivo se genera con el comando:
//   flutterfire configure
// Después de asociar tu proyecto Firebase a esta app.
// Sustituye los valores de ejemplo con los reales de tu consola Firebase.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web no está soportado en esta práctica.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma.',
        );
    }
  }

  // ─── Reemplaza TODOS los valores con los de tu proyecto Firebase ───────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY_AQUI',
    appId: '1:TU_APP_ID_AQUI',
    messagingSenderId: 'TU_SENDER_ID_AQUI',
    projectId: 'TU_PROJECT_ID_AQUI',
    storageBucket: 'TU_PROJECT_ID_AQUI.appspot.com',
  );
}
