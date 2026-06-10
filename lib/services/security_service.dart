import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static const MethodChannel _channel =
  MethodChannel('com.example.secure_wipe_app/security');

  Future<bool> isUsbDebuggingEnabled() async {
    // En modo debug local nunca bloqueamos
    if (kDebugMode) return false;

    try {
      final bool result =
      await _channel.invokeMethod('isUsbDebuggingEnabled');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error: ${e.message}');
      return true; // si falla, consideramos inseguro
    }
  }
}