import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para enviar emails transaccionales personalizados
/// mediante Cloud Functions y Resend
class AuthEmailService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Envía email de verificación personalizado con template HTML profesional
  ///
  /// Throws [Exception] si:
  /// - El usuario no está autenticado
  /// - El email ya está verificado
  /// - Ocurre un error al enviar el email
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    if (user.emailVerified) {
      throw Exception('El email ya está verificado');
    }

    try {
      final callable = _functions.httpsCallable('sendVerificationEmail');
      final result = await callable.call<Map<String, dynamic>>({
        'email': user.email,
      });

      final success = result.data['success'] as bool;
      final message = result.data['message'] as String;

      if (!success) {
        throw Exception(message);
      }

      print('✅ Email de verificación enviado: $message');
    } on FirebaseFunctionsException catch (e) {
      print('❌ Error: ${e.code} - ${e.message}');
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      print('❌ Error inesperado: $e');
      throw Exception('Error al enviar email de verificación');
    }
  }

  /// Envía email de recuperación de contraseña personalizado
  ///
  /// [email] - Email del usuario que solicita recuperación
  ///
  /// Throws [Exception] si:
  /// - El email es inválido
  /// - Ocurre un error al enviar el email
  ///
  /// Nota: Por seguridad, siempre devuelve éxito aunque el email no exista
  /// para prevenir enumeración de usuarios
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty || !_isValidEmail(email)) {
      throw Exception('Email inválido');
    }

    try {
      final callable = _functions.httpsCallable('sendPasswordResetEmail');
      final result = await callable.call<Map<String, dynamic>>({
        'email': email,
      });

      final success = result.data['success'] as bool;
      final message = result.data['message'] as String;

      if (!success) {
        throw Exception(message);
      }

      print('✅ Email de recuperación enviado: $message');
    } on FirebaseFunctionsException catch (e) {
      print('❌ Error: ${e.code} - ${e.message}');
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      print('❌ Error inesperado: $e');
      throw Exception('Error al enviar email de recuperación');
    }
  }

  /// Valida formato de email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Convierte códigos de error de Firebase a mensajes amigables
  String _getErrorMessage(String code) {
    switch (code) {
      case 'unauthenticated':
        return 'Debes iniciar sesión primero';
      case 'invalid-argument':
        return 'Email inválido';
      case 'permission-denied':
        return 'No tienes permiso para realizar esta acción';
      case 'internal':
        return 'Error del servidor. Intenta nuevamente';
      case 'resource-exhausted':
        return 'Demasiadas solicitudes. Intenta más tarde';
      case 'deadline-exceeded':
        return 'La solicitud tardó demasiado. Intenta nuevamente';
      case 'unavailable':
        return 'Servicio no disponible. Intenta más tarde';
      default:
        return 'Error desconocido. Intenta nuevamente';
    }
  }
}
