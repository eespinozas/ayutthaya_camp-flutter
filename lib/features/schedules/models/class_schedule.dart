import 'package:cloud_firestore/cloud_firestore.dart';

class ClassSchedule {
  final String? id;
  final String time; // "07:00", "08:00", etc.
  final String instructor; // "Francisco Poveda"
  final String type; // "Muay Thai", "Boxing", etc.
  final int capacity; // Capacidad máxima (ej: 15)
  final List<int> daysOfWeek; // [1,2,3,4,5,6,7] = Lun-Dom, 1=Lunes, 7=Domingo
  final bool active; // Si la clase está activa
  final int displayOrder; // Orden de visualización
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClassSchedule({
    this.id,
    required this.time,
    required this.instructor,
    required this.type,
    this.capacity = 15,
    required this.daysOfWeek,
    this.active = true,
    this.displayOrder = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'instructor': instructor,
      'type': type,
      'capacity': capacity,
      'daysOfWeek': daysOfWeek,
      'active': active,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory ClassSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ClassSchedule(
      id: doc.id,
      time: data['time'] ?? '',
      instructor: data['instructor'] ?? '',
      type: data['type'] ?? '',
      capacity: data['capacity'] ?? 15,
      daysOfWeek: List<int>.from(data['daysOfWeek'] ?? [1, 2, 3, 4, 5, 6, 7]),
      active: data['active'] ?? true,
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Helper: Verificar si la clase es en un día específico
  bool isOnDay(int dayOfWeek) {
    return daysOfWeek.contains(dayOfWeek);
  }

  // Helper: Obtener hora como DateTime (para comparaciones)
  DateTime getTimeAsDateTime(DateTime date) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
