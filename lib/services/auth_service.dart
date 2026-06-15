import 'package:email_validator/email_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = SecureStorageService();

  bool esEmailValido(String email) => EmailValidator.validate(email.trim());

  bool esNombreValido(String nombre) {
    return nombre.trim().length >= 3 &&
        RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(nombre.trim());
  }

  String? validarPassword(String password) {
    if (password.length < 8) return 'Mínimo 8 caracteres';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Debe incluir una mayúscula';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Debe incluir un número';
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Debe incluir un carácter especial (!@#\$...)';
    }
  }

  Future<String?> registrar({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('user_$email')) {
      return 'Este correo ya está registrado';
    }

    final hash = _simpleHash(password);
    await prefs.setString('user_$email', '$nombre|$hash|$telefono');
    await _storage.cargarDatosDePrueba(email);

  }

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
  }

  String _simpleHash(String input) {
    int hash = 0;
    for (var c in input.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return hash.toRadixString(16);
  }
}