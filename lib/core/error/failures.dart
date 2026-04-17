/// Clase base para todos los failures del dominio
///
/// Los Failures representan errores en la lógica de negocio y son parte
/// de la capa de dominio (Clean Architecture).
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure: $message${code != null ? ' (code: $code)' : ''}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message && other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

/// Error del servidor o API
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Error de conexión de red
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Error de autenticación
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Error de caché local
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Error de validación de datos
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Error de permisos
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

/// Error de timeout
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, {super.code});
}

/// Error inesperado o desconocido
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.code});
}
