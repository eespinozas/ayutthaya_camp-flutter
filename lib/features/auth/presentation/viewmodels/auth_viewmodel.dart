import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/notification_service.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estado de carga/errores
  bool _loading = false;
  String? _error;
  bool get loading => _loading;
  String? get error => _error;

  // Estado de sesión
  bool _isCheckingSession = false;
  User? _user;
  String _userRole = 'student'; // 'student' o 'admin'
  String _membershipStatus = 'none'; // none, pending, active, expired, frozen
  DateTime? _expirationDate;

  bool get isCheckingSession => _isCheckingSession;
  bool get isLoggedIn => _user != null;
  User? get currentUser => _user;
  String get userRole => _userRole;
  bool get isAdmin => _userRole == 'admin';
  String get membershipStatus => _membershipStatus;
  DateTime? get expirationDate => _expirationDate;

  /// Verificar si el usuario tiene membresía activa
  bool get hasActiveMembership => _membershipStatus == 'active';

  /// Verificar si el usuario necesita pagar matrícula
  bool get needsEnrollment => _membershipStatus == 'none' || _membershipStatus == 'pending';

  /// Verificar si la membresía expiró
  bool get isMembershipExpired => _membershipStatus == 'expired';

  AuthViewModel() {
    // Escuchar cambios de autenticación
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        // Esperar a que se cargue el rol antes de notificar
        await _loadUserRole(user.uid);
      } else {
        _userRole = 'student';
        _membershipStatus = 'none';
        _expirationDate = null;
      }
      // Solo notificar si no estamos en checkSession
      if (!_isCheckingSession) {
        notifyListeners();
      }
    });
  }

  /// Cargar rol y estado de membresía del usuario desde Firestore
  Future<void> _loadUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userRole = data['role'] ?? 'student';
        _membershipStatus = data['membershipStatus'] ?? 'none';

        // Cargar fecha de expiración si existe
        if (data['expirationDate'] != null) {
          _expirationDate = (data['expirationDate'] as Timestamp).toDate();
        } else {
          _expirationDate = null;
        }

        notifyListeners();
      } else {
        // Si el documento no existe y el email empieza con "admin", crear como admin
        final userEmail = _user?.email ?? '';
        if (userEmail.startsWith('admin')) {
          await _firestore.collection('users').doc(userId).set({
            'email': userEmail,
            'name': _user?.displayName ?? '',
            'role': 'admin',
            'membershipStatus': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          _userRole = 'admin';
          _membershipStatus = 'active';
          notifyListeners();
          debugPrint('Admin user document created for $userEmail');
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// Actualizar estado de membresía localmente (para refrescar después de un pago)
  Future<void> refreshMembershipStatus() async {
    if (_user != null) {
      await _loadUserRole(_user!.uid);
    }
  }

  /// Chequear sesión al iniciar la app
  Future<void> checkSession() async {
    try {
      _isCheckingSession = true;
      notifyListeners();

      _user = _auth.currentUser;
      if (_user != null) {
        await _user?.reload();
        _user = _auth.currentUser;
        // Esperar a que se cargue completamente el rol antes de continuar
        await _loadUserRole(_user!.uid);
      } else {
        _userRole = 'student';
        _membershipStatus = 'none';
        _expirationDate = null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error en checkSession: $e');
    } finally {
      _isCheckingSession = false;
      // Notificar después de que todo esté cargado
      notifyListeners();
    }
  }

  /// Registro con Firebase Auth + crear documento en Firestore
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      // 1. Crear usuario en Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Actualizar displayName si se proporcionó
      if (displayName != null && displayName.isNotEmpty) {
        await cred.user?.updateDisplayName(displayName);
      }

      // 3. Enviar email de verificación
      await cred.user?.sendEmailVerification();

      // 4. Crear documento del usuario en Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'name': displayName ?? '',
        'role': 'student',
        'membershipStatus': 'none', // none, pending, active, expired, frozen
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _user = cred.user;
      _userRole = 'student';

      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'El email ya está registrado';
          break;
        case 'weak-password':
          _error = 'La contraseña es muy débil';
          break;
        case 'invalid-email':
          _error = 'Email inválido';
          break;
        default:
          _error = e.message ?? 'Error al registrar';
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Login con Firebase Auth (detecta rol automáticamente)
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      // Login con Firebase
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = cred.user;

      // Cargar rol desde Firestore y esperar a que termine
      await _loadUserRole(cred.user!.uid);

      // Guardar FCM token del usuario
      try {
        await NotificationService().saveUserToken(cred.user!.uid);
      } catch (e) {
        debugPrint('⚠️ Error guardando FCM token: $e');
      }

      // Pequeña pausa para asegurar que todo está sincronizado
      await Future.delayed(const Duration(milliseconds: 100));

      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          _error = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          _error = 'Email inválido';
          break;
        case 'user-disabled':
          _error = 'Usuario deshabilitado';
          break;
        case 'too-many-requests':
          _error = 'Demasiados intentos, intenta más tarde';
          break;
        default:
          _error = e.message ?? 'Error al iniciar sesión';
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      _loading = true;
      notifyListeners();
      await _auth.signOut();
      _user = null;
      _userRole = 'student';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Reenviar email de verificación
  Future<bool> resendVerificationEmail() async {
    try {
      _loading = true;
      notifyListeners();

      if (_user == null) {
        _error = 'No hay usuario autenticado';
        return false;
      }

      await _user!.sendEmailVerification();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
