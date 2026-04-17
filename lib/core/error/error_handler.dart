import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'failures.dart';

/// Manejo centralizado de errores
///
/// Convierte excepciones técnicas en mensajes amigables para usuarios
/// y registra errores para debugging.
class ErrorHandler {
  /// Convierte cualquier error en un mensaje amigable para el usuario
  ///
  /// Ejemplo:
  /// ```dart
  /// try {
  ///   await loginUser();
  /// } catch (e) {
  ///   final message = ErrorHandler.getUserMessage(e);
  ///   showSnackBar(message); // "Contraseña incorrecta"
  /// }
  /// ```
  static String getUserMessage(dynamic error) {
    // Failures (capa de dominio)
    if (error is Failure) {
      return error.message;
    }

    // Firebase Auth
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthMessage(error.code);
    }

    // Firestore
    if (error is FirebaseException) {
      return _getFirestoreMessage(error.code);
    }

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return 'Sin conexión a internet. Verifica tu red.';
    }

    // Timeout errors
    if (error.toString().contains('TimeoutException')) {
      return 'La operación tardó demasiado. Intenta nuevamente.';
    }

    // Generic error
    return 'Error inesperado. Si persiste, contacta soporte.';
  }

  /// Registra errores para debugging
  ///
  /// En desarrollo: imprime en consola
  /// En producción: envía a Crashlytics (TODO)
  ///
  /// Ejemplo:
  /// ```dart
  /// try {
  ///   await riskyOperation();
  /// } catch (e, stackTrace) {
  ///   ErrorHandler.logError(e, stackTrace, context: 'PaymentService.processPayment');
  /// }
  /// ```
  static void logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('❌ ERROR${context != null ? ' en $context' : ''}');
      debugPrint('───────────────────────────────────────────────────');
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace:');
        debugPrint(stackTrace.toString());
      }
      debugPrint('═══════════════════════════════════════════════════');
    }

    // TODO: En producción, enviar a Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Mensajes específicos de Firebase Auth
  static String _getFirebaseAuthMessage(String code) {
    switch (code) {
      // Login errors
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Intenta nuevamente.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tus datos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';

      // Register errors
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Inicia sesión.';
      case 'weak-password':
        return 'Contraseña muy débil. Usa al menos 6 caracteres.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';

      // Rate limiting
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';

      // Network
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexión.';

      // Generic
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      case 'requires-recent-login':
        return 'Por seguridad, inicia sesión nuevamente.';

      default:
        return 'Error de autenticación ($code).';
    }
  }

  /// Mensajes específicos de Firestore
  static String _getFirestoreMessage(String code) {
    switch (code) {
      // Permissions
      case 'permission-denied':
        return 'No tienes permisos para realizar esta acción.';
      case 'unauthenticated':
        return 'Debes iniciar sesión para continuar.';

      // Data
      case 'not-found':
        return 'Documento no encontrado.';
      case 'already-exists':
        return 'Este documento ya existe.';
      case 'out-of-range':
        return 'Valor fuera de rango válido.';

      // Server
      case 'internal':
        return 'Error interno del servidor.';
      case 'unavailable':
        return 'Servicio no disponible. Intenta más tarde.';
      case 'deadline-exceeded':
      case 'cancelled':
        return 'Operación cancelada. Intenta nuevamente.';

      // Quota
      case 'resource-exhausted':
        return 'Límite de operaciones excedido. Intenta más tarde.';

      // Other
      case 'failed-precondition':
        return 'Operación no permitida en el estado actual.';
      case 'aborted':
        return 'Operación abortada. Intenta nuevamente.';
      case 'unimplemented':
        return 'Funcionalidad no implementada.';
      case 'data-loss':
        return 'Pérdida de datos. Contacta soporte urgente.';

      default:
        return 'Error de base de datos ($code).';
    }
  }

  /// Obtiene un ícono apropiado para el tipo de error
  static getErrorIcon(dynamic error) {
    // TODO: Implementar si se necesita
    return null;
  }
}
