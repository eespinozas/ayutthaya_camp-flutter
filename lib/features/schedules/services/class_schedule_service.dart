import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_schedule.dart';

class ClassScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener todos los horarios activos
  Stream<List<ClassSchedule>> getActiveSchedules() {
    return _firestore
        .collection('class_schedules')
        .where('active', isEqualTo: true)
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ClassSchedule.fromFirestore(doc)).toList();
    });
  }

  /// Obtener horarios filtrados por día de la semana
  Stream<List<ClassSchedule>> getSchedulesForDay(int dayOfWeek) {
    return _firestore
        .collection('class_schedules')
        .where('active', isEqualTo: true)
        .where('daysOfWeek', arrayContains: dayOfWeek)
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ClassSchedule.fromFirestore(doc)).toList();
    });
  }

  /// Obtener todos los horarios (admin)
  Stream<List<ClassSchedule>> getAllSchedules() {
    return _firestore
        .collection('class_schedules')
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ClassSchedule.fromFirestore(doc)).toList();
    });
  }

  /// Obtener un horario por ID
  Future<ClassSchedule?> getScheduleById(String scheduleId) async {
    try {
      final doc = await _firestore.collection('class_schedules').doc(scheduleId).get();
      if (doc.exists) {
        return ClassSchedule.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener horario: $e');
    }
  }

  /// Crear un horario de clase (admin)
  Future<String> createSchedule(ClassSchedule schedule) async {
    try {
      final docRef = await _firestore.collection('class_schedules').add(schedule.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear horario: $e');
    }
  }

  /// Actualizar un horario (admin)
  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('class_schedules').doc(scheduleId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar horario: $e');
    }
  }

  /// Eliminar un horario (admin) - soft delete
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection('class_schedules').doc(scheduleId).update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al eliminar horario: $e');
    }
  }

  /// Obtener horarios agrupados por hora
  Future<Map<String, List<ClassSchedule>>> getSchedulesGroupedByTime() async {
    try {
      final snapshot = await _firestore
          .collection('class_schedules')
          .where('active', isEqualTo: true)
          .orderBy('time')
          .get();

      final schedules = snapshot.docs.map((doc) => ClassSchedule.fromFirestore(doc)).toList();

      final Map<String, List<ClassSchedule>> grouped = {};
      for (var schedule in schedules) {
        if (!grouped.containsKey(schedule.time)) {
          grouped[schedule.time] = [];
        }
        grouped[schedule.time]!.add(schedule);
      }

      return grouped;
    } catch (e) {
      throw Exception('Error al agrupar horarios: $e');
    }
  }
}
