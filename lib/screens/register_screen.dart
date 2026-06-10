import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const MethodChannel _secureChannel =
  MethodChannel('com.example.secure_wipe_app/security');

  final _formKey       = GlobalKey<FormState>();
  final _nombreCtrl    = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _telefonoCtrl  = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  final _authService   = AuthService();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;
  String _errorMsg     = '';

  @override
  void initState() {
    super.initState();
    _enableSecureFlag();
  }

  @override
  void dispose() {
    _disableSecureFlag();
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _enableSecureFlag() async {
    try { await _secureChannel.invokeMethod('enableSecureFlag'); } on PlatformException catch (_) {}
  }
  Future<void> _disableSecureFlag() async {
    try { await _secureChannel.invokeMethod('disableSecureFlag'); } on PlatformException catch (_) {}
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = ''; });

    final error = await _authService.registrar(
      nombre:   _nombreCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      telefono: _telefonoCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cuenta creada. ¡Bienvenido!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF1A237E), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),

                  // Header
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.person_add_outlined,
                            size: 50, color: Colors.blueAccent),
                        SizedBox(height: 12),
                        Text('Crear Cuenta',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Todos los campos son obligatorios',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Nombre completo ─────────────────────────────
                  _buildField(
                    controller: _nombreCtrl,
                    label: 'Nombre completo',
                    hint: 'Ej: María López García',
                    icon: Icons.person_outline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Campo requerido';
                      if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(v.trim())) {
                        return 'Solo letras y espacios';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Correo electrónico ──────────────────────────
                  _buildField(
                    controller: _emailCtrl,
                    label: 'Correo electrónico',
                    hint: 'usuario@dominio.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Campo requerido';
                      if (!EmailValidator.validate(v.trim())) {
                        return 'Formato de correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Teléfono ────────────────────────────────────
                  _buildField(
                    controller: _telefonoCtrl,
                    label: 'Teléfono (10 dígitos)',
                    hint: 'Ej: 9611234567',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v.length != 10) return 'Debe tener exactamente 10 dígitos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Contraseña ──────────────────────────────────
                  _buildField(
                    controller: _passCtrl,
                    label: 'Contraseña',
                    hint: 'Mín. 8 chars, mayúscula, número, especial',
                    icon: Icons.lock_outline,
                    obscure: _obscurePass,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white54, size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      return _authService.validarPassword(v);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Requisitos de contraseña
                  _passwordHints(),
                  const SizedBox(height: 16),

                  // ── Confirmar contraseña ────────────────────────
                  _buildField(
                    controller: _confirmCtrl,
                    label: 'Confirmar contraseña',
                    hint: 'Repite la contraseña',
                    icon: Icons.lock_outline,
                    obscure: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white54, size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Error
                  if (_errorMsg.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMsg,
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Botón registrar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                          : const Text('Crear Cuenta',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordHints() {
    final pass = _passCtrl.text;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _hint('Mínimo 8 caracteres', pass.length >= 8),
          _hint('Al menos 1 mayúscula', pass.contains(RegExp(r'[A-Z]'))),
          _hint('Al menos 1 número', pass.contains(RegExp(r'[0-9]'))),
          _hint('Al menos 1 carácter especial',
              pass.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))),
        ],
      ),
    );
  }

  Widget _hint(String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: ok ? Colors.greenAccent : Colors.white38),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12, color: ok ? Colors.greenAccent : Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    // Rebuild hints when password changes
    if (controller == _passCtrl) {
      controller.addListener(() => setState(() {}));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white24)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: Colors.blueAccent, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5)),
            errorStyle: const TextStyle(color: Colors.orangeAccent),
          ),
        ),
      ],
    );
  }
}
