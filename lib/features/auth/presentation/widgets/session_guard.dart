import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/login_page.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Cierra la sesión automáticamente cuando la cuenta deja de existir,
/// p. ej. tras confirmar la eliminación de cuenta desde el correo.
///
/// Sin esto, el SDK de Firebase mantiene el token local válido hasta ~1 hora
/// después de que el backend elimina el usuario, dejando la app "logueada"
/// pero con errores de permisos. Dos señales lo resuelven:
///
/// 1. Listener sobre `users/{uid}`: el backend borra ese documento como parte
///    de la eliminación → logout en segundos con la app abierta.
/// 2. `currentUser.reload()` al volver a foreground: cubre el caso en que la
///    app estaba cerrada o sin conexión cuando se eliminó la cuenta.
///
/// Envuelve los shells autenticados (alumno y admin); no altera el flujo del
/// botón "Cerrar Sesión" (ese logout ya deja isLoggedIn en false y se omite).
class SessionGuard extends StatefulWidget {
  final Widget child;

  const SessionGuard({super.key, required this.child});

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard>
    with WidgetsBindingObserver {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userDocSub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen(
        (snap) {
          // Solo confirmaciones del servidor: un miss de cache no es señal
          // de cuenta eliminada.
          if (!snap.exists && !snap.metadata.isFromCache) {
            _forceLogout();
          }
        },
        onError: (Object e) {
          // Cuando el token expira tras el borrado, el listener recibe
          // permission-denied: también implica que la cuenta ya no existe.
          if (e is FirebaseException && e.code == 'permission-denied') {
            _forceLogout();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userDocSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _loggingOut) return;
    _checkAccountStillExists();
  }

  Future<void> _checkAccountStillExists() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'user-disabled' ||
          e.code == 'user-token-expired') {
        _forceLogout();
      }
    } catch (_) {
      // Errores de red u otros: no cerrar sesión por eso.
    }
  }

  Future<void> _forceLogout() async {
    if (_loggingOut || !mounted) return;
    _loggingOut = true;
    _userDocSub?.cancel();

    final vm = context.read<AuthViewModel>();
    if (!vm.isLoggedIn) return; // Logout manual ya en curso: nada que hacer.

    await vm.logout();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu cuenta fue eliminada. Sesión cerrada.'),
        backgroundColor: Color(0xFFFF8534),
        duration: Duration(seconds: 5),
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
