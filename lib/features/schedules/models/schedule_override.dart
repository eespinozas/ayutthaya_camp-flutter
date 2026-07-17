import 'package:cloud_firestore/cloud_firestore.dart';

/// Excepción puntual de un horario en una fecha específica.
///
/// Hoy solo modela la deshabilitación (ej: viernes AM suspendido por una
/// pelea): un horario deshabilitado no acepta reservas nuevas ni check-in QR
/// en esa fecha. Las reservas ya existentes no se tocan.
///
/// Documento en `schedule_overrides` con ID determinístico
/// `{scheduleId}_{YYYY-MM-DD}` para lookups directos sin queries.
class ScheduleOverride {
  final String? id;
  final String scheduleId;
  final String dateKey; // "YYYY-MM-DD" (mismo formato que capacity_tracking)
  final bool disabled;
  final String? reason;
  final String createdBy; // uid del admin
  final DateTime createdAt;

  ScheduleOverride({
    this.id,
    required this.scheduleId,
    required this.dateKey,
    this.disabled = true,
    this.reason,
    required this.createdBy,
    required this.createdAt,
  });

  /// Clave de fecha "YYYY-MM-DD" usada en dateKey y en el ID del documento.
  static String dateKeyFor(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// ID determinístico del documento para un horario + fecha.
  static String docIdFor(String scheduleId, DateTime date) {
    return '${scheduleId}_${dateKeyFor(date)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'dateKey': dateKey,
      'disabled': disabled,
      'reason': reason,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ScheduleOverride.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduleOverride(
      id: doc.id,
      scheduleId: data['scheduleId'] ?? '',
      dateKey: data['dateKey'] ?? '',
      disabled: data['disabled'] ?? false,
      reason: data['reason'],
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
