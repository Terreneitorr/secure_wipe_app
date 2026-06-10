import 'package:email_validator/email_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

/// Servicio de autenticación local (sin backend).
/// Las cuentas se guardan en SharedPreferences (no sensible: solo email y hash).
/// La contraseña se hashea antes de guardar.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = SecureStorageService();

  // ─── Validaciones ──────────────────────────────────────────────────────────

  /// Valida que el email tenga formato correcto.
  bool esEmailValido(String email) => EmailValidator.validate(email.trim());

  /// Valida nombre: mínimo 3 chars, solo letras y espacios.
  bool esNombreValido(String nombre) {
    return nombre.trim().length >= 3 &&
        RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(nombre.trim());
  }

  /// Valida contraseña: mín 8 chars, al menos 1 mayúscula, 1 número, 1 especial.
  String? validarPassword(String password) {
    if (password.length < 8) return 'Mínimo 8 caracteres';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Debe incluir una mayúscula';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Debe incluir un número';
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Debe incluir un carácter especial (!@#\$...)';
    }
    return null; // válida
  }

  // ─── Registro ──────────────────────────────────────────────────────────────

  Future<String?> registrar({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Verificar si ya existe
    if (prefs.containsKey('user_$email')) {
      return 'Este correo ya está registrado';
    }

    // Guardar usuario (contraseña hasheada simple para demo)
    final hash = _simpleHash(password);
    await prefs.setString('user_$email', '$nombre|$hash|$telefono');

    // Cargar datos sensibles automáticamente
    await _storage.cargarDatosDePrueba(email);

    return null; // sin error
  }

  // ─── Login ─────────────────────────────────────────────────────────────────

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final datos = prefs.getString('user_$email');

    if (datos == null) return 'Correo no registrado';

    final partes = datos.split('|');
    final hashGuardado = partes[1];
    if (_simpleHash(password) != hashGuardado) return 'Contraseña incorrecta';

    await _storage.cargarDatosDePrueba(email);
    return null; // éxito
  }

  // ─── Utilidades ───────────────────────────────────────────────────────────

  /// Hash muy simple para demo. En producción usar bcrypt o argon2.
  String _simpleHash(String input) {
    int hash = 0;
    for (var c in input.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
