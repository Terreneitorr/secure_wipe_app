import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Eventos ────────────────────────────────────────────────────────────────
abstract class InactivityEvent {}

/// El usuario interactuó con la app (tap, scroll, teclado).
class UserInteracted extends InactivityEvent {}

/// La sesión expiró por inactividad.
class SessionExpired extends InactivityEvent {}

/// Iniciar el monitoreo (al hacer login).
class StartMonitoring extends InactivityEvent {}

/// Detener el monitoreo (al cerrar sesión manualmente).
class StopMonitoring extends InactivityEvent {}

// ── Estados ────────────────────────────────────────────────────────────────
abstract class InactivityState {}

class InactivityInitial extends InactivityState {}

/// Sesión activa — el temporizador corre en segundo plano.
class SessionActive extends InactivityState {}

/// Sesión expirada — hay que redirigir al login.
class SessionTimedOut extends InactivityState {}

// ── BLoC ───────────────────────────────────────────────────────────────────
class InactivityBloc extends Bloc<InactivityEvent, InactivityState> {
  // ── Configuración del tiempo de inactividad ─────────────────────────────
  /// 15 segundos para pruebas en clase.
  /// Cambiar a Duration(minutes: 5) para producción.
  static const _timeout = Duration(seconds: 15);

  Timer? _timer;

  InactivityBloc() : super(InactivityInitial()) {
    on<StartMonitoring>(_onStartMonitoring);
    on<UserInteracted>(_onUserInteracted);
    on<SessionExpired>(_onSessionExpired);
    on<StopMonitoring>(_onStopMonitoring);
  }

  // ── Iniciar monitoreo ───────────────────────────────────────────────────
  void _onStartMonitoring(StartMonitoring event, Emitter<InactivityState> emit) {
    _resetTimer();
    emit(SessionActive());
  }

  // ── Reiniciar timer en cada interacción ─────────────────────────────────
  void _onUserInteracted(UserInteracted event, Emitter<InactivityState> emit) {
    if (state is SessionActive) {
      _resetTimer();
    }
  }

  // ── Sesión expirada ─────────────────────────────────────────────────────
  void _onSessionExpired(SessionExpired event, Emitter<InactivityState> emit) {
    _timer?.cancel();
    emit(SessionTimedOut());
  }

  // ── Detener monitoreo (logout manual) ───────────────────────────────────
  void _onStopMonitoring(StopMonitoring event, Emitter<InactivityState> emit) {
    _timer?.cancel();
    emit(InactivityInitial());
  }

  // ── Reinicia el temporizador ────────────────────────────────────────────
  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, () {
      // Cuando el timer expira dispara SessionExpired al BLoC
      add(SessionExpired());
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
