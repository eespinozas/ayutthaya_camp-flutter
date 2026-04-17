/// Constantes de configuración de la aplicación
/// Centraliza valores configurables para fácil ajuste
class BookingConstants {
  // Check-in con QR
  static const int checkInWindowMinutes = 20;

  // Cancelación de bookings
  static const int minHoursToCancelBooking = 24;

  // Auto no-show (para implementar en Cloud Function)
  static const int autoNoShowAfterMinutes = 20;
  static const bool enableAutoNoShow = true;

  // Recordatorios
  static const List<int> reminderMinutesBefore = [30, 15];

  // Capacidad
  static const int defaultClassCapacity = 15;
}

class MembershipConstants {
  // Validaciones de membresía para QR check-in
  static const bool requireActiveMembershipForQR = true;

  // Validaciones de membresía para reservar clases
  static const bool requireActiveMembershipForBooking = true;

  // Validar límite de clases según plan
  static const bool enforcePlanLimits = true;

  // Matrícula - Tiempo mínimo antes de renovar (en días)
  static const int minDaysForRenewEnrollment = 365; // 1 año

  // Notificaciones
  static const bool notifyUserOnPaymentApproval = true;
  static const bool notifyUserOnPaymentRejection = true;
  static const bool notifyUserOnMembershipExpiring = true;
  static const int membershipExpiringWarningDays = 7; // Notificar 7 días antes
}

class AppMessages {
  // Mensajes de error por estado de membresía
  static const String membershipNone =
      'Debes matricularte primero para acceder a las clases.\n\n'
      'Ve a la sección "Pagos" para subir tu comprobante de matrícula.';

  static const String membershipPending =
      'Tu pago de matrícula está en revisión.\n\n'
      'Por favor espera la aprobación del administrador. '
      'Te notificaremos cuando esté aprobado.';

  static const String membershipInactive =
      'Tu membresía ha vencido.\n\n'
      'Por favor renueva tu plan en la sección "Pagos" para continuar entrenando.';

  static const String membershipUnknown =
      'No tienes una membresía activa. Contacta al administrador.';
}
