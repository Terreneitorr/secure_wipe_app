import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../bloc/inactivity_bloc.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const MethodChannel _secureChannel =
  MethodChannel('com.example.secure_wipe_app/security');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePass = true;
  bool _isLoading = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _enableSecureFlag();
    FcmService().init();
    // Detener monitoreo al llegar al login
    context.read<InactivityBloc>().add(StopMonitoring());
  }

  @override
  void dispose() {
    _disableSecureFlag();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _enableSecureFlag() async {
    try { await _secureChannel.invokeMethod('enableSecureFlag'); } on PlatformException catch (_) {}
  }
  Future<void> _disableSecureFlag() async {
    try { await _secureChannel.invokeMethod('disableSecureFlag'); } on PlatformException catch (_) {}
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = ''; });

    final error = await _authService.login(
      email: _emailController.text.trim(),
      password: _passController.text,
    );

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
    } else {
      if (!mounted) return;
      // Iniciar monitoreo de inactividad al hacer login exitoso
      context.read<InactivityBloc>().add(StartMonitoring());
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, size: 60, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 20),
                    const Text('Acceso Seguro',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 6, alignment: WrapAlignment.center,
                      children: [
                        _badge(Icons.security, 'FLAG_SECURE', Colors.redAccent),
                        _badge(Icons.cloud_outlined, 'FCM Wipe', Colors.blueAccent),
                        _badge(Icons.timer_outlined, 'Auto-logout 15s', Colors.orangeAccent),
                      ],
                    ),
                    const SizedBox(height: 36),
                    _buildField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      hint: 'usuario@ejemplo.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo requerido';
                        if (!EmailValidator.validate(v.trim())) return 'Correo no válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _passController,
                      label: 'Contraseña',
                      hint: 'Tu contraseña',
                      icon: Icons.key_outlined,
                      obscure: _obscurePass,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white54),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo requerido';
                        if (v.length < 8) return 'Mínimo 8 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    if (_errorMsg.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿No tienes cuenta?', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text('Crear cuenta', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
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
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white24)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
            errorStyle: const TextStyle(color: Colors.orangeAccent),
          ),
        ),
      ],
    );
  }
}
