import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de almacenamiento encriptado.
/// Usa AES/KeyStore en Android para cifrar los datos en reposo.
/// Los 4 campos sensibles se borran con [wipeAllSensitiveData].
class SecureStorageService {
  static final SecureStorageService _instance =
  SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // AES-256 vía EncryptedSharedPreferences
    ),
  );

  // ─── Claves de los 4 campos sensibles ─────────────────────────────────────
  static const String _keyNombreCompleto  = 'sens_nombre_completo';
  static const String _keyCurp            = 'sens_curp';
  static const String _keyNumeroTarjeta   = 'sens_numero_tarjeta';
  static const String _keyTokenAcceso     = 'sens_token_acceso';

  // Clave adicional: FCM token del usuario (necesario para wipe específico)
  static const String _keyFcmToken        = 'fcm_token_usuario';

  // Clave de sesión (no sensible, solo indica si hay sesión activa)
  static const String _keyUserEmail       = 'session_email';

  // ─── Escritura de datos sensibles ─────────────────────────────────────────

  /// Carga automática de datos de prueba al registrar/iniciar sesión.
  Future<void> cargarDatosDePrueba(String email) async {
    await _storage.write(key: _keyNombreCompleto,  value: 'Juan García López');
    await _storage.write(key: _keyCurp,            value: 'GALJ900101HCHRPN01');
    await _storage.write(key: _keyNumeroTarjeta,   value: '4111-1111-1111-1111');
    await _storage.write(key: _keyTokenAcceso,     value: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.demo_token_$email');
    await _storage.write(key: _keyUserEmail,       value: email);
  }

  Future<void> guardarFcmToken(String token) async {
    await _storage.write(key: _keyFcmToken, value: token);
  }

  // ─── Lectura ──────────────────────────────────────────────────────────────

  Future<String?> getNombreCompleto()  async => _storage.read(key: _keyNombreCompleto);
  Future<String?> getCurp()           async => _storage.read(key: _keyCurp);
  Future<String?> getNumeroTarjeta()  async => _storage.read(key: _keyNumeroTarjeta);
  Future<String?> getTokenAcceso()    async => _storage.read(key: _keyTokenAcceso);
  Future<String?> getFcmToken()       async => _storage.read(key: _keyFcmToken);
  Future<String?> getUserEmail()      async => _storage.read(key: _keyUserEmail);

  /// Devuelve un mapa con todos los datos sensibles para mostrar en pantalla.
  Future<Map<String, String>> getTodosLosDatosSensibles() async {
    return {
      'Nombre Completo':  (await getNombreCompleto())  ?? '(vacío)',
      'CURP':             (await getCurp())            ?? '(vacío)',
      'Número de Tarjeta':(await getNumeroTarjeta())   ?? '(vacío)',
      'Token de Acceso':  (await getTokenAcceso())     ?? '(vacío)',
    };
  }

  /// ⚠️  WIPE: borra los 4 campos sensibles de forma permanente.
  /// Se llama desde [FcmService] al recibir la notificación de borrado remoto.
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
