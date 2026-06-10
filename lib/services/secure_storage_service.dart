import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _keyNombreCompleto = 'sens_nombre_completo';
  static const String _keyCurp           = 'sens_curp';
  static const String _keyNumeroTarjeta  = 'sens_numero_tarjeta';
  static const String _keyTokenAcceso    = 'sens_token_acceso';
  static const String _keyFcmToken       = 'fcm_token_usuario';
  static const String _keyUserEmail      = 'session_email';

  Future<void> cargarDatosDePrueba(String email) async {
    await _storage.write(key: _keyNombreCompleto, value: 'Juan García López');
    await _storage.write(key: _keyCurp,           value: 'GALJ900101HCHRPN01');
    await _storage.write(key: _keyNumeroTarjeta,  value: '4111-1111-1111-1111');
    await _storage.write(key: _keyTokenAcceso,    value: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.demo_$email');
    await _storage.write(key: _keyUserEmail,      value: email);
  }

  Future<void> guardarFcmToken(String token) async {
    await _storage.write(key: _keyFcmToken, value: token);
  }

  Future<String?> getNombreCompleto() async => _storage.read(key: _keyNombreCompleto);
  Future<String?> getCurp()          async => _storage.read(key: _keyCurp);
  Future<String?> getNumeroTarjeta() async => _storage.read(key: _keyNumeroTarjeta);
  Future<String?> getTokenAcceso()   async => _storage.read(key: _keyTokenAcceso);
  Future<String?> getFcmToken()      async => _storage.read(key: _keyFcmToken);
  Future<String?> getUserEmail()     async => _storage.read(key: _keyUserEmail);

  Future<Map<String, String>> getTodosLosDatosSensibles() async {
    return {
      'Nombre Completo':   (await getNombreCompleto()) ?? '(vacío)',
      'CURP':              (await getCurp())           ?? '(vacío)',
      'Número de Tarjeta': (await getNumeroTarjeta())  ?? '(vacío)',
      'Token de Acceso':   (await getTokenAcceso())    ?? '(vacío)',
    };
  }

  Future<void> wipeAllSensitiveData() async {
    await _storage.delete(key: _keyNombreCompleto);
    await _storage.delete(key: _keyCurp);
    await _storage.delete(key: _keyNumeroTarjeta);
    await _storage.delete(key: _keyTokenAcceso);
  }

  Future<void> cerrarSesion() async {
    await _storage.delete(key: _keyUserEmail);
  }

  Future<bool> haySesionActiva() async {
    final email = await _storage.read(key: _keyUserEmail);
    return email != null && email.isNotEmpty;
  }
}