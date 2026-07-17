// Constantes de configuración de la aplicación
// Centraliza valores configurables para fácil ajuste

/// Feature flags globales de la app.
///
/// [freeAccessPhase] controla la "Fase 1" de lanzamiento: acceso libre,
/// sin membresías ni pagos. Cuando está en `true`:
///  - No se exige membresía activa para agendar, ver clases ni hacer check-in QR.
///  - Se oculta el tab "Pagos" y todo lo relacionado con matrícula en el dashboard.
///
/// Para pasar al modo de pago (Fase 2) basta con cambiarlo a `false`: todo el
/// sistema de membresías/pagos vuelve a funcionar tal como está implementado.
class AppFlags {
  static const bool freeAccessPhase = true;

  /// Flujo de aprobación de asistencia: cuando el alumno confirma su hora
  /// por app, la reserva queda en `pendingApproval` hasta que el admin la
  /// apruebe (→ attended, cuenta para el ranking) o rechace (→ rejected).
  /// El check-in QR no pasa por aprobación: marca attended de inmediato.
  /// Con `false` se vuelve al flujo antiguo (confirmar = attended directo).
  static const bool attendanceApprovalFlow = true;
}

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
  static const int defaultClassCapacity = 30;
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
