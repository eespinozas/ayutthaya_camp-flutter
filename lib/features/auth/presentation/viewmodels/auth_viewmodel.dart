// lib/features/auth/presentation/viewmodels/auth_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../../domain/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repo;

  // ---- Estado de carga/errores (ya tenías) ----
  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  // ---- NUEVO: estado de sesión ----
  bool _isCheckingSession = false;
  User? _user;

  /// Getters usados por tu builder
  bool get isCheckingSession => _isCheckingSession;
  bool get isLoggedIn => _user != null;
  User? get currentUser => _user;

  AuthViewModel(this.repo);

  /// Registro vía backend + login con custom token
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final cred = await repo.registerAndSignIn(
        email: email,
        password: password,
        displayName: displayName,
        profile: {
          // cualquier dato extra inicial para Firestore:
          'estado': 'pending',
          'remaining': 0,
          'escuelas': [],
        },
      );

      // NUEVO: persistimos user local
      _user = cred.user;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Chequear sesión al iniciar la app.
  /// Úsalo una vez tras montar los providers (postFrameCallback).
  Future<void> checkSession() async {
    try {
      _isCheckingSession = true;
      notifyListeners();

      // Leer usuario actual y forzar refresh opcional
      _user = FirebaseAuth.instance.currentUser;
      await _user?.reload();
      _user = FirebaseAuth.instance.currentUser;

      // Escuchar cambios de auth en caliente (login/logout)
      // Importante: si llamas varias veces a checkSession, este listener
      // puede suscribirse de nuevo. Idealmente llama una sola vez al iniciar.
      FirebaseAuth.instance.authStateChanges().listen((u) {
        _user = u;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isCheckingSession = false;
      notifyListeners();
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      _loading = true;
      notifyListeners();
      await FirebaseAuth.instance.signOut();
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
