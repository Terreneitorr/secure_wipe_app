import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/secure_storage_service.dart';
import '../services/fcm_service.dart';
import '../bloc/inactivity_bloc.dart';
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
  final _fcm = FcmService();

  Map<String, String> _datosSensibles = {};
  String _fcmToken = 'Cargando...';
  String _userEmail = '';
  bool _wipeDone = false;
  bool _loading = true;

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
      _fcmToken = token;
      _userEmail = email;
      _loading = false;
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
            Expanded(child: Text('Wipe Remoto Ejecutado', style: TextStyle(color: Colors.white, fontSize: 18))),
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

  /// Cierre de sesión destructivo — borra la pila de navegación completa.
  Future<void> _logout({bool byInactivity = false}) async {
    await _storage.cerrarSesion();
    context.read<InactivityBloc>().add(StopMonitoring());
    if (!mounted) return;

    if (byInactivity) {
      // Navegar y mostrar aviso de expiración
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false, // Elimina TODA la pila — no se puede regresar
      );
      // Mostrar SnackBar después de navegar
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.timer_off, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(child: Text('Sesión cerrada por inactividad por seguridad.')),
                ],
              ),
              backgroundColor: Colors.orangeAccent,
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InactivityBloc, InactivityState>(
      // Escucha el estado del BLoC — cuando expira la sesión cierra automáticamente
      listener: (context, state) {
        if (state is SessionTimedOut) {
          _showInactivityDialog();
        }
      },
      child: Scaffold(
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
            // Indicador visual del timer de inactividad
            BlocBuilder<InactivityBloc, InactivityState>(
              builder: (context, state) {
                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 14),
                      SizedBox(width: 4),
                      Text('15s', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: 'Recargar datos',
              onPressed: _loadData,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              tooltip: 'Cerrar sesión',
              onPressed: () => _logout(),
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
                const SizedBox(height: 12),
                _inactivityInfoCard(),
                const SizedBox(height: 16),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInactivityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('Sesión Expirada', style: TextStyle(color: Colors.white, fontSize: 18))),
          ],
        ),
        content: const Text(
          'Tu sesión fue cerrada automáticamente por inactividad.\n\n'
              'Por razones de seguridad, la sesión se cierra tras 15 segundos sin interacción.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(byInactivity: true);
            },
            child: const Text('Entendido', style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  Widget _inactivityInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Control de inactividad activo. La sesión se cerrará automáticamente tras 15 segundos sin interacción.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ),
        ],
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
              color: Colors.greenAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
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
        color: Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.delete_forever, color: Colors.redAccent, size: 24),
          SizedBox(width: 10),
          Expanded(child: Text('⚠️  Wipe remoto ejecutado. Los datos sensibles han sido eliminados.', style: TextStyle(color: Colors.redAccent, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5))),
      ],
    );
  }

  Widget _sensitiveCard(String label, String value) {
    final isEmpty = value == '(vacío)';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEmpty ? Colors.redAccent.withOpacity(0.4) : Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(isEmpty ? Icons.no_encryption_gmailerrorred_outlined : Icons.lock_outline,
              color: isEmpty ? Colors.redAccent : Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: isEmpty ? Colors.redAccent : Colors.white, fontSize: 14, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Este token identifica tu dispositivo en Firebase.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Text(_fcmToken, style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontFamily: 'monospace'), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar Token'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent, side: const BorderSide(color: Colors.blueAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _fcmToken));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token copiado al portapapeles'), duration: Duration(seconds: 2)));
              },
            ),
          ),
        ],
      ),
    );
  }
}
