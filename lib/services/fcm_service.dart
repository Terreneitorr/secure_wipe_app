import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'secure_storage_service.dart';

/// Handler de mensajes FCM en background (debe ser una función top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _procesarMensaje(message);
}

/// Procesa el mensaje recibido de FCM.
/// Si el campo [action] es "WIPE_DATA" y el [target_email] coincide
/// con el usuario activo, se borran los datos sensibles.
Future<void> _procesarMensaje(RemoteMessage message) async {
  final data = message.data;
  final action = data['action'] ?? '';
  final targetEmail = data['target_email'] ?? '';

  if (action == 'WIPE_DATA') {
    final storage = SecureStorageService();
    final emailActual = await storage.getUserEmail();

    // ── Wipe ESPECÍFICO: solo si el email objetivo coincide ────────────────
    if (emailActual != null &&
        emailActual.isNotEmpty &&
        emailActual == targetEmail) {
      await storage.wipeAllSensitiveData();
      debugPrint('🗑️  WIPE ejecutado para: $emailActual');
    } else {
      debugPrint('ℹ️  Notificación WIPE ignorada (no corresponde a este usuario)');
    }
  }
}

/// Servicio que inicializa FCM, pide permisos y escucha mensajes.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final _fcm = FirebaseMessaging.instance;
  final _storage = SecureStorageService();

  /// Callback para notificar a la UI cuando se ejecuta un wipe.
  VoidCallback? onWipeExecuted;

  Future<void> init() async {
    // Pedir permisos (Android 13+ / iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Obtener y guardar FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _storage.guardarFcmToken(token);
      debugPrint('📱 FCM Token: $token');
    }

    // Handler para mensajes en background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handler para mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      final action = data['action'] ?? '';
      final targetEmail = data['target_email'] ?? '';

      if (action == 'WIPE_DATA') {
        final emailActual = await _storage.getUserEmail();
        if (emailActual != null && emailActual == targetEmail) {
          await _storage.wipeAllSensitiveData();
          debugPrint('🗑️  WIPE en foreground ejecutado para: $emailActual');
          onWipeExecuted?.call(); // Notificar a la UI
        }
      }
    });

    // Handler cuando la app se abre desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _procesarMensaje(message);
    });

    // Revisar si la app fue abierta por una notificación terminada
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      await _procesarMensaje(initialMessage);
    }
  }
}
