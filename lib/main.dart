import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'bloc/inactivity_bloc.dart';
import 'screens/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const MethodChannel _securityChannel =
MethodChannel('com.example.secure_wipe_app/security');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {}

  bool usbActive = false;
  try {
    usbActive = await _securityChannel.invokeMethod('isUsbDebuggingEnabled');
  } catch (_) {}

  runApp(SecureWipeApp(usbDebuggingDetected: usbActive));
}

class SecureWipeApp extends StatefulWidget {
  final bool usbDebuggingDetected;
  const SecureWipeApp({super.key, required this.usbDebuggingDetected});

  @override
  State<SecureWipeApp> createState() => _SecureWipeAppState();
}

class _SecureWipeAppState extends State<SecureWipeApp>
    with WidgetsBindingObserver {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.usbDebuggingDetected) {
      _scheduleDialog();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkUsb();
    }
  }

  Future<void> _checkUsb() async {
    bool usbActive = false;
    try {
      usbActive =
      await _securityChannel.invokeMethod('isUsbDebuggingEnabled');
    } catch (_) {}

    if (usbActive && !_dialogShown) {
      _scheduleDialog();
    }
  }

  void _scheduleDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBlockDialog();
    });
  }

  void _showBlockDialog() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null || _dialogShown) return;
    _dialogShown = true;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.gpp_bad, color: Colors.redAccent, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text('Entorno No Seguro',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
          content: const Text(
            'Se ha detectado que la Depuración USB está activa.\n\n'
                'Por políticas de seguridad esta aplicación no puede '
                'ejecutarse en un entorno de depuración.\n\n'
                'Desactívala en:\nAjustes → Opciones de desarrollador → Depuración USB',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _securityChannel.invokeMethod('exitApp');
              },
              child: const Text('Cerrar Aplicación',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).then((_) => _dialogShown = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InactivityBloc(),
      child: _buildApp(),
    );
  }

  Widget _buildApp() {
    return Builder(builder: (context) {
      final bloc = context.read<InactivityBloc>();
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => bloc.add(UserInteracted()),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            bloc.add(UserInteracted());
            return false;
          },
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Secure Wipe App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1A237E),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const LoginScreen(),
          ),
        ),
      );
    });
  }
}