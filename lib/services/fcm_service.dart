import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'secure_storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _procesarMensaje(message);
}

Future<void> _procesarMensaje(RemoteMessage message) async {
  final data = message.data;
  final action = data['action'] ?? '';
  final targetEmail = data['target_email'] ?? '';

  if (action == 'WIPE_DATA') {
    final storage = SecureStorageService();
    final emailActual = await storage.getUserEmail();

    if (emailActual != null &&
        emailActual.isNotEmpty &&
        emailActual == targetEmail) {
      await storage.wipeAllSensitiveData();
    }
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final _fcm = FirebaseMessaging.instance;
  final _storage = SecureStorageService();

  VoidCallback? onWipeExecuted;

  Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    final token = await _fcm.getToken();
    if (token != null) {
      await _storage.guardarFcmToken(token);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      final action = data['action'] ?? '';
      final targetEmail = data['target_email'] ?? '';

      if (action == 'WIPE_DATA') {
        final emailActual = await _storage.getUserEmail();
        if (emailActual != null && emailActual == targetEmail) {
          await _storage.wipeAllSensitiveData();
          onWipeExecuted?.call();
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _procesarMensaje(message);
    });

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      await _procesarMensaje(initialMessage);
    }
  }
}