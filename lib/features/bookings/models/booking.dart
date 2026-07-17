import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/attendance_window.dart';

enum BookingStatus {
  confirmed,       // Reserva agendada
  pendingApproval, // Alumno confirmó por app; espera aprobación del admin
  attended,        // Asistencia validada (check-in QR o aprobación del admin)
  cancelled,       // Usuario canceló
  noShow,          // No asistió (no confirmó dentro de la ventana)
  rejected,        // Admin rechazó la confirmación del alumno
}

class Booking {
  final String? id;
  final String userId;
  final String userName;
  final String userEmail;
  final String scheduleId;         // ID del horario de clase
  final String scheduleTime;       // "07:00"
  final String scheduleType;       // "Muay Thai"
  final String instructor;         // "Francisco Poveda"
  final DateTime classDate;        // Fecha de la clase (ej: 2025-01-15)
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime? attendedAt;      // Cuando se marcó asistencia
  final String? attendedBy;        // Admin que marcó asistencia
  final DateTime? attendanceConfirmedAt; // Cuando el alumno confirmó asistencia
  final bool userConfirmedAttendance; // Si el usuario confirmó su asistencia

  Booking({
    this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.scheduleId,
    required this.scheduleTime,
    required this.scheduleType,
    required this.instructor,
    required this.classDate,
    this.status = BookingStatus.confirmed,
    required this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.attendedAt,
    this.attendedBy,
    this.attendanceConfirmedAt,
    this.userConfirmedAttendance = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'scheduleId': scheduleId,
      'scheduleTime': scheduleTime,
      'scheduleType': scheduleType,
      'instructor': instructor,
      'classDate': Timestamp.fromDate(classDate),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
      'attendedAt': attendedAt != null ? Timestamp.fromDate(attendedAt!) : null,
      'attendedBy': attendedBy,
      'attendanceConfirmedAt': attendanceConfirmedAt != null ? Timestamp.fromDate(attendanceConfirmedAt!) : null,
      'userConfirmedAttendance': userConfirmedAttendance,
    };
  }

  // Create from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Leer directamente el Timestamp y convertir la fecha
    final firestoreDate = (data['classDate'] as Timestamp).toDate();
    // Crear fecha en zona local usando los componentes de la fecha UTC
    final classDate = DateTime(firestoreDate.year, firestoreDate.month, firestoreDate.day);

    debugPrint('🔍 Booking.fromFirestore - ID: ${doc.id}');
    debugPrint('   Firestore date (UTC): $firestoreDate');
    debugPrint('   Local date: $classDate');
    debugPrint('   Status: ${data['status']}');

    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      scheduleId: data['scheduleId'] ?? '',
      scheduleTime: data['scheduleTime'] ?? '',
      scheduleType: data['scheduleType'] ?? '',
      instructor: data['instructor'] ?? '',
      classDate: classDate,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.confirmed,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
      attendedAt: data['attendedAt'] != null
          ? (data['attendedAt'] as Timestamp).toDate()
          : null,
      attendedBy: data['attendedBy'],
      attendanceConfirmedAt: data['attendanceConfirmedAt'] != null
          ? (data['attendanceConfirmedAt'] as Timestamp).toDate()
          : null,
      userConfirmedAttendance: data['userConfirmedAttendance'] ?? false,
    );
  }

  // Helper: Verificar si es hoy
  bool isToday() {
    final now = DateTime.now();
    return classDate.year == now.year &&
        classDate.month == now.month &&
        classDate.day == now.day;
  }

  // Helper: Verificar si es en el futuro
  bool isFuture() {
    final now = DateTime.now();
    return classDate.isAfter(DateTime(now.year, now.month, now.day));
  }

  // Helper: Verificar si es en el pasado
  bool isPast() {
    final now = DateTime.now();
    return classDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  // Copy with
  Booking copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? scheduleId,
    String? scheduleTime,
    String? scheduleType,
    String? instructor,
    DateTime? classDate,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    DateTime? attendedAt,
    String? attendedBy,
    DateTime? attendanceConfirmedAt,
    bool? userConfirmedAttendance,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      scheduleType: scheduleType ?? this.scheduleType,
      instructor: instructor ?? this.instructor,
      classDate: classDate ?? this.classDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      attendedAt: attendedAt ?? this.attendedAt,
      attendedBy: attendedBy ?? this.attendedBy,
      attendanceConfirmedAt: attendanceConfirmedAt ?? this.attendanceConfirmedAt,
      userConfirmedAttendance: userConfirmedAttendance ?? this.userConfirmedAttendance,
    );
  }

  // Helper: DateTime de inicio de la clase (fecha + hora del horario)
  DateTime get classStartDateTime {
    final timeParts = scheduleTime.split(':');
    return DateTime(
      classDate.year,
      classDate.month,
      classDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  // Helper: momento en que se habilita la confirmación de asistencia
  DateTime confirmationOpensAt() =>
      AttendanceWindow.opensAt(classStartDateTime);

  // Helper: momento en que se cierra la confirmación
  DateTime confirmationClosesAt({bool esPrimeraClaseDelDia = false}) =>
      AttendanceWindow.closesAt(
        classStartDateTime,
        esPrimeraClaseDelDia: esPrimeraClaseDelDia,
      );

  // Helper: Verificar si puede confirmar asistencia.
  // Ventana: 15 min antes del inicio hasta 15 min después del término
  // (primera clase del día: 60 min; el resto: 90 min).
  bool canConfirmAttendance({bool esPrimeraClaseDelDia = false}) {
    if (status != BookingStatus.confirmed) return false;
    if (userConfirmedAttendance) return false; // Ya confirmada

    return AttendanceWindow.isOpen(
      classStartDateTime,
      esPrimeraClaseDelDia: esPrimeraClaseDelDia,
    );
  }

  // Helper: Verificar si pasó la ventana de confirmación
  bool missedConfirmationWindow({bool esPrimeraClaseDelDia = false}) {
    if (status != BookingStatus.confirmed) return false;
    if (userConfirmedAttendance) return false;

    return AttendanceWindow.isClosed(
      classStartDateTime,
      esPrimeraClaseDelDia: esPrimeraClaseDelDia,
    );
  }

  // Helper: Obtener texto del estado de confirmación
  String getConfirmationStatusText({bool esPrimeraClaseDelDia = false}) {
    if (status == BookingStatus.cancelled) return 'Cancelada';
    if (status == BookingStatus.attended) return 'Asistió';
    if (status == BookingStatus.noShow) return 'No asistió';
    if (status == BookingStatus.pendingApproval) return 'Esperando aprobación';
    if (status == BookingStatus.rejected) return 'Confirmación rechazada';

    if (userConfirmedAttendance) return 'Asistencia confirmada';
    if (missedConfirmationWindow(esPrimeraClaseDelDia: esPrimeraClaseDelDia)) {
      return 'No confirmada';
    }
    if (canConfirmAttendance(esPrimeraClaseDelDia: esPrimeraClaseDelDia)) {
      return 'Pendiente confirmación';
    }

    return 'Agendada';
  }
}
