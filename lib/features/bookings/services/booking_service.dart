import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../../../core/services/notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crear una reserva
  Future<String> createBooking(Booking booking) async {
    try {
      // Verificar que no sea una hora pasada
      final now = DateTime.now();
      final isToday = booking.classDate.year == now.year &&
          booking.classDate.month == now.month &&
          booking.classDate.day == now.day;

      if (isToday) {
        // Parsear la hora de la clase (formato "HH:mm" como "07:00")
        final timeParts = booking.scheduleTime.split(':');
        final classHour = int.parse(timeParts[0]);
        final classMinute = int.parse(timeParts[1]);

        // Crear DateTime de la clase de hoy
        final classDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          classHour,
          classMinute,
        );

        // Si la clase ya pasó, no permitir la reserva
        if (classDateTime.isBefore(now)) {
          throw Exception('No puedes agendar una clase que ya comenzó');
        }
      }

      // Verificar límite de clases del plan del usuario
      await _checkClassLimit(booking.userId, booking.classDate);

      // Verificar que no haya duplicados (mismo usuario, mismo horario, misma fecha)
      // Buscar todas las reservas del usuario para ese scheduleId
      final existingBookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: booking.userId)
          .where('scheduleId', isEqualTo: booking.scheduleId)
          .where('status', isEqualTo: BookingStatus.confirmed.name)
          .get();

      // Verificar manualmente si hay una reserva para la misma fecha (solo día, mes, año)
      for (var doc in existingBookings.docs) {
        final data = doc.data();
        final existingDate = (data['classDate'] as Timestamp).toDate();

        if (existingDate.year == booking.classDate.year &&
            existingDate.month == booking.classDate.month &&
            existingDate.day == booking.classDate.day) {
          throw Exception('Ya tienes una reserva para esta clase en esta fecha');
        }
      }

      // Verificar capacidad disponible
      final capacity = await _getAvailableCapacity(
        booking.scheduleId,
        booking.classDate,
      );

      if (capacity <= 0) {
        throw Exception('Esta clase está llena');
      }

      // Crear la reserva
      final docRef = await _firestore.collection('bookings').add(booking.toMap());

      // Programar recordatorios de confirmación
      try {
        final notificationService = NotificationService();

        // Recordatorio 30 minutos antes
        await notificationService.scheduleClassReminder(
          bookingId: docRef.id,
          userId: booking.userId,
          className: booking.scheduleType,
          classTime: booking.scheduleTime,
          classDate: booking.classDate,
          minutesBefore: 30,
        );

        // Recordatorio 15 minutos antes
        await notificationService.scheduleClassReminder(
          bookingId: docRef.id,
          userId: booking.userId,
          className: booking.scheduleType,
          classTime: booking.scheduleTime,
          classDate: booking.classDate,
          minutesBefore: 15,
        );

        debugPrint('✅ Recordatorios programados para booking: ${docRef.id}');
      } catch (e) {
        debugPrint('⚠️ Error programando recordatorios: $e');
        // No lanzar error, la reserva ya se creó
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear reserva: $e');
    }
  }

  /// Obtener capacidad disponible para una clase
  Future<int> _getAvailableCapacity(String scheduleId, DateTime classDate) async {
    // Obtener el horario para saber la capacidad máxima
    final scheduleDoc = await _firestore.collection('class_schedules').doc(scheduleId).get();
    if (!scheduleDoc.exists) {
      throw Exception('Horario no encontrado');
    }

    final maxCapacity = scheduleDoc.data()?['capacity'] ?? 15;

    // Contar reservas confirmadas para esa clase
    final bookings = await _firestore
        .collection('bookings')
        .where('scheduleId', isEqualTo: scheduleId)
        .where('classDate', isEqualTo: Timestamp.fromDate(classDate))
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .get();

    final bookedCount = bookings.docs.length;

    return maxCapacity - bookedCount;
  }

  /// Obtener número de reservas confirmadas para una clase
  Future<int> getBookedCount(String scheduleId, DateTime classDate) async {
    final bookings = await _firestore
        .collection('bookings')
        .where('scheduleId', isEqualTo: scheduleId)
        .where('classDate', isEqualTo: Timestamp.fromDate(classDate))
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .get();

    return bookings.docs.length;
  }

  /// Obtener reservas de un usuario
  Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('classDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    });
  }

  /// Obtener reservas futuras de un usuario
  Stream<List<Booking>> getUserUpcomingBookings(String userId) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .orderBy('classDate', descending: false)
        .orderBy('scheduleTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    });
  }

  /// Obtener reservas de una clase específica (para admin)
  Stream<List<Booking>> getClassBookings(String scheduleId, DateTime classDate) {
    return _firestore
        .collection('bookings')
        .where('scheduleId', isEqualTo: scheduleId)
        .where('classDate', isEqualTo: Timestamp.fromDate(classDate))
        .orderBy('userName', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    });
  }

  /// Obtener todas las reservas de un día (para admin)
  Stream<List<Booking>> getBookingsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('bookings')
        .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('classDate', descending: false)
        .orderBy('scheduleTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    });
  }

  /// Cancelar una reserva (usuario)
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cancelar recordatorios programados
      try {
        await NotificationService().cancelClassReminders(bookingId);
        debugPrint('✅ Recordatorios cancelados para booking: $bookingId');
      } catch (e) {
        debugPrint('⚠️ Error cancelando recordatorios: $e');
        // No lanzar error, la cancelación ya se hizo
      }
    } catch (e) {
      throw Exception('Error al cancelar reserva: $e');
    }
  }

  /// Marcar asistencia (admin)
  Future<void> markAttendance(String bookingId, String adminId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.attended.name,
        'attendedAt': FieldValue.serverTimestamp(),
        'attendedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al marcar asistencia: $e');
    }
  }

  /// Marcar no asistencia (admin)
  Future<void> markNoShow(String bookingId, String adminId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.noShow.name,
        'attendedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al marcar no asistencia: $e');
    }
  }

  /// Confirmar asistencia (usuario)
  Future<void> confirmAttendance(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'userConfirmedAttendance': true,
        'attendanceConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al confirmar asistencia: $e');
    }
  }

  /// Procesar confirmaciones expiradas y marcarlas como no asistida
  Future<void> processExpiredConfirmations() async {
    try {
      final now = DateTime.now();

      // Obtener todas las reservas confirmadas que no tienen confirmación de usuario
      final bookings = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: BookingStatus.confirmed.name)
          .where('userConfirmedAttendance', isEqualTo: false)
          .get();

      for (var doc in bookings.docs) {
        final booking = Booking.fromFirestore(doc);

        // Verificar si pasó la ventana de confirmación
        if (booking.missedConfirmationWindow()) {
          // Marcar como no asistida
          await _firestore.collection('bookings').doc(doc.id).update({
            'status': BookingStatus.noShow.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          debugPrint('📌 Booking ${doc.id} marcada como no asistida (no confirmó)');
        }
      }
    } catch (e) {
      debugPrint('Error procesando confirmaciones expiradas: $e');
    }
  }

  /// Verificar si un usuario ya tiene reserva para una clase
  Future<bool> hasBookingForClass(String userId, String scheduleId, DateTime classDate) async {
    // Buscar todas las reservas del usuario para ese scheduleId
    final bookings = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('scheduleId', isEqualTo: scheduleId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .get();

    // Verificar manualmente si hay una reserva para la misma fecha (solo día, mes, año)
    for (var doc in bookings.docs) {
      final data = doc.data();
      final existingDate = (data['classDate'] as Timestamp).toDate();

      if (existingDate.year == classDate.year &&
          existingDate.month == classDate.month &&
          existingDate.day == classDate.day) {
        return true;
      }
    }

    return false;
  }

  /// Obtener estadísticas de asistencia de un usuario
  Future<Map<String, int>> getUserAttendanceStats(String userId) async {
    final bookings = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    int total = 0;
    int attended = 0;
    int noShow = 0;
    int cancelled = 0;

    for (var doc in bookings.docs) {
      final booking = Booking.fromFirestore(doc);
      total++;

      switch (booking.status) {
        case BookingStatus.attended:
          attended++;
          break;
        case BookingStatus.noShow:
          noShow++;
          break;
        case BookingStatus.cancelled:
          cancelled++;
          break;
        default:
          break;
      }
    }

    return {
      'total': total,
      'attended': attended,
      'noShow': noShow,
      'cancelled': cancelled,
      'confirmed': total - attended - noShow - cancelled,
    };
  }

  /// Verificar límite de clases según el plan del usuario
  Future<void> _checkClassLimit(String userId, DateTime classDate) async {
    try {
      // Obtener información del usuario
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final userData = userDoc.data()!;
      final classesPerMonth = userData['classesPerMonth'];

      // Si classesPerMonth es null, es plan ilimitado
      if (classesPerMonth == null) {
        return; // Plan ilimitado, no hay límite
      }

      // Contar clases agendadas en el mes actual
      final bookedThisMonth = await getUserBookedClassesThisMonth(userId, classDate);

      debugPrint('🔍 Verificando límite de clases:');
      debugPrint('   - Plan permite: $classesPerMonth clases/mes');
      debugPrint('   - Usuario ha agendado: $bookedThisMonth clases este mes');

      // Verificar si superó el límite
      if (bookedThisMonth >= classesPerMonth) {
        throw Exception(
          'Has alcanzado el límite de $classesPerMonth clases de tu plan. '
          'Ya has agendado $bookedThisMonth clases este mes.'
        );
      }
    } catch (e) {
      // Re-lanzar excepciones conocidas
      if (e.toString().contains('límite')) {
        rethrow;
      }
      // Otras excepciones
      throw Exception('Error al verificar límite de clases: $e');
    }
  }

  /// Contar cuántas clases ha agendado el usuario en el mes de la fecha dada
  Future<int> getUserBookedClassesThisMonth(String userId, DateTime referenceDate) async {
    try {
      // Obtener primer y último día del mes
      final firstDayOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);
      final lastDayOfMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0, 23, 59, 59);

      debugPrint('📅 Contando clases del mes:');
      debugPrint('   - Desde: $firstDayOfMonth');
      debugPrint('   - Hasta: $lastDayOfMonth');

      // Buscar todas las reservas confirmadas del usuario en ese mes
      final bookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
          .where('status', isEqualTo: BookingStatus.confirmed.name)
          .get();

      debugPrint('   - Total clases agendadas: ${bookings.docs.length}');

      return bookings.docs.length;
    } catch (e) {
      debugPrint('❌ Error al contar clases del mes: $e');
      throw Exception('Error al contar clases del mes: $e');
    }
  }
}
