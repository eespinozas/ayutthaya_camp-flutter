import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/schedule_override.dart';

/// Gestión de deshabilitaciones puntuales de horarios (colección
/// `schedule_overrides`). Lectura para cualquier usuario autenticado,
/// escritura solo admin (ver firestore.rules).
class ScheduleOverrideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('schedule_overrides');

  /// IDs de horarios deshabilitados en [date], en tiempo real.
  Stream<Set<String>> disabledScheduleIdsForDate(DateTime date) {
    final dateKey = ScheduleOverride.dateKeyFor(date);
    return _collection
        .where('dateKey', isEqualTo: dateKey)
        .where('disabled', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['scheduleId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toSet());
  }

  /// ¿Está deshabilitado este horario en esta fecha? (lookup directo)
  Future<bool> isDisabled(String scheduleId, DateTime date) async {
    final doc =
        await _collection.doc(ScheduleOverride.docIdFor(scheduleId, date)).get();
    return doc.exists && (doc.data()?['disabled'] ?? false) == true;
  }

  /// Override vigente (o null) para un horario + fecha.
  Future<ScheduleOverride?> getOverride(
      String scheduleId, DateTime date) async {
    final doc =
        await _collection.doc(ScheduleOverride.docIdFor(scheduleId, date)).get();
    if (!doc.exists) return null;
    return ScheduleOverride.fromFirestore(doc);
  }

  /// Deshabilitar [scheduleId] en [date] (admin).
  Future<void> disableSchedule({
    required String scheduleId,
    required DateTime date,
    required String adminId,
    String? reason,
  }) async {
    final override = ScheduleOverride(
      scheduleId: scheduleId,
      dateKey: ScheduleOverride.dateKeyFor(date),
      disabled: true,
      reason: (reason ?? '').trim().isEmpty ? null : reason!.trim(),
      createdBy: adminId,
      createdAt: DateTime.now(),
    );

    await _collection
        .doc(ScheduleOverride.docIdFor(scheduleId, date))
        .set(override.toMap());
    debugPrint('✅ Horario $scheduleId deshabilitado para ${override.dateKey}');
  }

  /// Rehabilitar [scheduleId] en [date] (admin): elimina el override.
  Future<void> enableSchedule(String scheduleId, DateTime date) async {
    await _collection.doc(ScheduleOverride.docIdFor(scheduleId, date)).delete();
    debugPrint(
        '✅ Horario $scheduleId rehabilitado para ${ScheduleOverride.dateKeyFor(date)}');
  }
}
