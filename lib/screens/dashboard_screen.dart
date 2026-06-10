import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/secure_storage_service.dart';
import '../services/fcm_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const MethodChannel _secureChannel =
  MethodChannel('com.example.secure_wipe_app/security');

  final _storage = SecureStorageService();
  final _fcm     = FcmService();

  Map<String, String> _datosSensibles = {};
  String _fcmToken  = 'Cargando...';
  String _userEmail = '';
  bool _wipeDone    = false;
  bool _loading     = true;

  @override
  void initState() {
    super.initState();
    _enableSecureFlag();
    _loadData();
    _fcm.onWipeExecuted = () {
      if (mounted) {
        setState(() => _wipeDone = true);
        _loadData();
        _showWipeDialog();
      }
    };
  }

  @override
  void dispose() {
    _disableSecureFlag();
    _fcm.onWipeExecuted = null;
    super.dispose();
  }

  Future<void> _enableSecureFlag() async {
    try { await _secureChannel.invokeMethod('enableSecureFlag'); } on PlatformException catch (_) {}
  }

  Future<void> _disableSecureFlag() async {
    try { await _secureChannel.invokeMethod('disableSecureFlag'); } on PlatformException catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final datos = await _storage.getTodosLosDatosSensibles();
    final token = await _storage.getFcmToken() ?? 'No disponible';
    final email = await _storage.getUserEmail() ?? '';
    setState(() {
      _datosSensibles = datos;
      _fcmToken       = token;
      _userEmail      = email;
      _loading        = false;
    });
  }

  void _showWipeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text('Wipe Remoto Ejecutado',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
        content: const Text(
          'Se recibió una notificación FCM de limpieza remota.\n\nTodos los datos sensibles han sido eliminados del almacenamiento encriptado.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _storage.cerrarSesion();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.blueAccent, size: 22),
            SizedBox(width: 8),
            Text('Panel Seguro', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Recargar datos',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.blueAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _welcomeCard(),
              const SizedBox(height: 20),
              if (_wipeDone) ...[
                _wipeBanner(),
                const SizedBox(height: 16),
              ],
              _sectionTitle(Icons.lock_outline, 'Datos Sensibles Encriptados (AES-256)'),
              const SizedBox(height: 12),
              ..._datosSensibles.entries.map((e) => _sensitiveCard(e.key, e.value)),
              const SizedBox(height: 24),
              _sectionTitle(Icons.notifications_outlined, 'Token FCM (Wipe Remoto)'),
              const SizedBox(height: 12),
              _fcmTokenCard(),
              const SizedBox(height: 24),
              _sectionTitle(Icons.info_outline, 'Cómo ejecutar el Wipe Remoto'),
              const SizedBox(height: 12),
              _instructionsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1A237E)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sesión activa', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  _userEmail.isEmpty ? 'Usuario' : _userEmail,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                SizedBox(width: 4),
                Text('FLAG_SECURE', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wipeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.delete_forever, color: Colors.redAccent, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '⚠️  Wipe remoto ejecutado. Los datos sensibles han sido eliminados.',
              style: TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _sensitiveCard(String label, String value) {
    final isEmpty = value == '(vacío)';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmpty ? Colors.redAccent.withValues(alpha: 0.4) : Colors.blueAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEmpty ? Icons.no_encryption_gmailerrorred_outlined : Icons.lock_outline,
            color: isEmpty ? Colors.redAccent : Colors.blueAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isEmpty ? Colors.redAccent : Colors.white,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isEmpty) const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
        ],
      ),
    );
  }

  Widget _fcmTokenCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Este token identifica tu dispositivo en Firebase.',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            _fcmToken,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontFamily: 'monospace'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar Token'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _fcmToken));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token copiado al portapapeles'), duration: Duration(seconds: 2)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Para enviar el wipe remoto desde Firebase Console:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),
          _step('1', 'Ve a Firebase Console → Messaging → Nueva campaña'),
          _step('2', 'Elige "Datos" (no notificación visual)'),
          _step('3', 'Agrega: action = WIPE_DATA'),
          _step('4', 'Agrega: target_email = correo_del_usuario@ejemplo.com'),
          _step('5', 'En destino elige "Token de dispositivo" y pega el FCM Token'),
          _step('6', 'Envía. La app borrará los datos automáticamente.'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
            ),
            child: const Text(
              '💡 El campo target_email asegura que SOLO ese usuario sea afectado, no todos los dispositivos.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle),
            child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }
}