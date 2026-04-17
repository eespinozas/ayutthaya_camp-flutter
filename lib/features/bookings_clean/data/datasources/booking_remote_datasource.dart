import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/booking_entity.dart';
import '../models/booking_model.dart';

/// Booking Remote Data Source Interface
abstract class BookingRemoteDataSource {
  Future<String> createBooking(BookingModel booking);
  Future<void> cancelBooking(String bookingId, String reason);
  Future<void> markAttendance(String bookingId, String adminId);
  Future<void> markNoShow(String bookingId, String adminId);
  Future<void> confirmAttendance(String bookingId);
  Stream<List<BookingModel>> getUserBookings(String userId);
  Stream<List<BookingModel>> getUserUpcomingBookings(String userId);
  Stream<List<BookingModel>> getClassBookings(String scheduleId, DateTime classDate);
  Stream<List<BookingModel>> getBookingsByDate(DateTime date);
  Future<bool> hasBookingForClass(String userId, String scheduleId, DateTime classDate);
  Future<int> getBookedCount(String scheduleId, DateTime classDate);
  Future<Map<String, int>> getUserAttendanceStats(String userId);
  Future<int> getUserBookedClassesThisMonth(String userId, DateTime referenceDate);
  Future<Map<String, dynamic>> processQRCheckIn(String userId, String userName, String userEmail);
  Future<void> processExpiredConfirmations();
}

/// Booking Remote Data Source Implementation (Firebase)
class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore firestore;
  final NotificationService? notificationService;

  BookingRemoteDataSourceImpl({
    required this.firestore,
    this.notificationService,
  });

  /// Generate date key for capacity tracking (format: YYYY-MM-DD)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<String> createBooking(BookingModel booking) async {
    try {
      // Verify not past time
      final now = DateTime.now();
      final isToday = booking.classDate.year == now.year &&
          booking.classDate.month == now.month &&
          booking.classDate.day == now.day;

      if (isToday) {
        final timeParts = booking.scheduleTime.split(':');
        final classHour = int.parse(timeParts[0]);
        final classMinute = int.parse(timeParts[1]);

        final classDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          classHour,
          classMinute,
        );

        if (classDateTime.isBefore(now)) {
          throw Exception('No puedes agendar una clase que ya comenzó');
        }
      }

      // Verify class limit
      await _checkClassLimit(booking.userId, booking.classDate);

      // Check for duplicates
      final existingBookings = await firestore
          .collection('bookings')
          .where('userId', isEqualTo: booking.userId)
          .where('scheduleId', isEqualTo: booking.scheduleId)
          .where('status', isEqualTo: BookingStatus.confirmed.name)
          .get();

      for (var doc in existingBookings.docs) {
        final data = doc.data();
        final existingDate = (data['classDate'] as Timestamp).toDate();

        if (existingDate.year == booking.classDate.year &&
            existingDate.month == booking.classDate.month &&
            existingDate.day == booking.classDate.day) {
          throw Exception('Ya tienes una reserva para esta clase en esta fecha');
        }
      }

      // Atomic transaction: verify capacity and create booking
      String? bookingId;

      await firestore.runTransaction((transaction) async {
        final scheduleRef = firestore.collection('class_schedules').doc(booking.scheduleId);
        final scheduleSnapshot = await transaction.get(scheduleRef);

        if (!scheduleSnapshot.exists) {
          throw Exception('Horario de clase no encontrado');
        }

        final maxCapacity = scheduleSnapshot.data()?['capacity'] ?? 15;
        final dateKey = _getDateKey(booking.classDate);
        final capacityRef = firestore
            .collection('class_schedules')
            .doc(booking.scheduleId)
            .collection('capacity_tracking')
            .doc(dateKey);

        final capacitySnapshot = await transaction.get(capacityRef);

        int currentBookings = 0;
        if (capacitySnapshot.exists) {
          currentBookings = capacitySnapshot.data()?['currentBookings'] ?? 0;
        }

        if (currentBookings >= maxCapacity) {
          throw Exception('Esta clase está llena ($currentBookings/$maxCapacity)');
        }

        final bookingRef = firestore.collection('bookings').doc();
        transaction.set(bookingRef, booking.toJson());
        bookingId = bookingRef.id;

        transaction.set(
          capacityRef,
          {
            'currentBookings': currentBookings + 1,
            'maxCapacity': maxCapacity,
            'lastUpdated': FieldValue.serverTimestamp(),
            'scheduleId': booking.scheduleId,
            'classDate': Timestamp.fromDate(booking.classDate),
          },
          SetOptions(merge: true),
        );

        debugPrint('✅ Booking creado: $bookingId (${currentBookings + 1}/$maxCapacity)');
      });

      if (bookingId == null) {
        throw Exception('Error: No se pudo crear la reserva');
      }

      // Schedule reminders and notify admins (outside transaction)
      if (notificationService != null) {
        try {
          await notificationService!.scheduleClassReminder(
            bookingId: bookingId!,
            userId: booking.userId,
            className: booking.scheduleType,
            classTime: booking.scheduleTime,
            classDate: booking.classDate,
            minutesBefore: 30,
          );

          await notificationService!.scheduleClassReminder(
            bookingId: bookingId!,
            userId: booking.userId,
            className: booking.scheduleType,
            classTime: booking.scheduleTime,
            classDate: booking.classDate,
            minutesBefore: 15,
          );

          debugPrint('✅ Recordatorios programados para booking: $bookingId');

          final formattedDate =
              '${booking.classDate.day}/${booking.classDate.month}/${booking.classDate.year}';
          await notificationService!.sendNotificationToAdmins(
            title: '📅 Nueva Reserva de Clase',
            body:
                '${booking.userName} se registró a ${booking.scheduleType} - $formattedDate a las ${booking.scheduleTime}',
            data: {
              'type': 'new_booking',
              'bookingId': bookingId!,
              'userId': booking.userId,
              'className': booking.scheduleType,
              'classDate': booking.classDate.toIso8601String(),
              'classTime': booking.scheduleTime,
            },
          );
          debugPrint('✅ Notificación de nueva reserva enviada a admins');
        } catch (e) {
          debugPrint('⚠️ Error programando recordatorios o enviando notificaciones: $e');
        }
      }

      return bookingId!;
    } catch (e) {
      throw Exception('Error al crear reserva: $e');
    }
  }

  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await firestore.runTransaction((transaction) async {
        final bookingRef = firestore.collection('bookings').doc(bookingId);
        final bookingSnapshot = await transaction.get(bookingRef);

        if (!bookingSnapshot.exists) {
          throw Exception('Reserva no encontrada');
        }

        final bookingData = bookingSnapshot.data()!;
        final scheduleId = bookingData['scheduleId'] as String;
        final classDate = (bookingData['classDate'] as Timestamp).toDate();
        final currentStatus = bookingData['status'] as String;

        if (currentStatus != BookingStatus.confirmed.name) {
          throw Exception('Solo se pueden cancelar reservas confirmadas');
        }

        transaction.update(bookingRef, {
          'status': BookingStatus.cancelled.name,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancellationReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final dateKey = _getDateKey(classDate);
        final capacityRef = firestore
            .collection('class_schedules')
            .doc(scheduleId)
            .collection('capacity_tracking')
            .doc(dateKey);

        final capacitySnapshot = await transaction.get(capacityRef);

        if (capacitySnapshot.exists) {
          final currentBookings = capacitySnapshot.data()?['currentBookings'] ?? 0;
          final newCount = currentBookings > 0 ? currentBookings - 1 : 0;

          transaction.update(capacityRef, {
            'currentBookings': newCount,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          debugPrint('✅ Booking cancelado: $bookingId (Capacidad: $newCount)');
        }
      });

      // Cancel reminders (outside transaction)
      if (notificationService != null) {
        try {
          await notificationService!.cancelClassReminders(bookingId);
          debugPrint('✅ Recordatorios cancelados para booking: $bookingId');
        } catch (e) {
          debugPrint('⚠️ Error cancelando recordatorios: $e');
        }
      }
    } catch (e) {
      throw Exception('Error al cancelar reserva: $e');
    }
  }

  @override
  Future<void> markAttendance(String bookingId, String adminId) async {
    try {
      await firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.attended.name,
        'attendedAt': FieldValue.serverTimestamp(),
        'attendedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al marcar asistencia: $e');
    }
  }

  @override
  Future<void> markNoShow(String bookingId, String adminId) async {
    try {
      await firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.noShow.name,
        'attendedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al marcar no asistencia: $e');
    }
  }

  @override
  Future<void> confirmAttendance(String bookingId) async {
    try {
      await firestore.collection('bookings').doc(bookingId).update({
        'userConfirmedAttendance': true,
        'attendanceConfirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al confirmar asistencia: $e');
    }
  }

  @override
  Stream<List<BookingModel>> getUserBookings(String userId) {
    return firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('classDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<BookingModel>> getUserUpcomingBookings(String userId) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .orderBy('classDate', descending: false)
        .orderBy('scheduleTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<BookingModel>> getClassBookings(String scheduleId, DateTime classDate) {
    return firestore
        .collection('bookings')
        .where('scheduleId', isEqualTo: scheduleId)
        .where('classDate', isEqualTo: Timestamp.fromDate(classDate))
        .orderBy('userName', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<List<BookingModel>> getBookingsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return firestore
        .collection('bookings')
        .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('classDate', descending: false)
        .orderBy('scheduleTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<bool> hasBookingForClass(String userId, String scheduleId, DateTime classDate) async {
    final bookings = await firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('scheduleId', isEqualTo: scheduleId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .get();

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

  @override
  Future<int> getBookedCount(String scheduleId, DateTime classDate) async {
    final dateKey = _getDateKey(classDate);
    final capacityDoc = await firestore
        .collection('class_schedules')
        .doc(scheduleId)
        .collection('capacity_tracking')
        .doc(dateKey)
        .get();

    if (capacityDoc.exists) {
      return capacityDoc.data()?['currentBookings'] ?? 0;
    }

    return 0;
  }

  @override
  Future<Map<String, int>> getUserAttendanceStats(String userId) async {
    final bookings = await firestore.collection('bookings').where('userId', isEqualTo: userId).get();

    int total = 0;
    int attended = 0;
    int noShow = 0;
    int cancelled = 0;

    for (var doc in bookings.docs) {
      final booking = BookingModel.fromFirestore(doc);
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

  @override
  Future<int> getUserBookedClassesThisMonth(String userId, DateTime referenceDate) async {
    try {
      final firstDayOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);
      final lastDayOfMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0, 23, 59, 59);

      final bookings = await firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth))
          .where('status', isEqualTo: BookingStatus.confirmed.name)
          .get();

      return bookings.docs.length;
    } catch (e) {
      debugPrint('❌ Error al contar clases del mes: $e');
      throw Exception('Error al contar clases del mes: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> processQRCheckIn(
      String userId, String userName, String userEmail) async {
    try {
      // Validate active membership
      if (MembershipConstants.requireActiveMembershipForQR) {
        final userDoc = await firestore.collection('users').doc(userId).get();

        if (!userDoc.exists) {
          return {
            'success': false,
            'message': 'Usuario no encontrado',
            'action': 'user_not_found',
          };
        }

        final userData = userDoc.data()!;
        final membershipStatus = userData['membershipStatus'] ?? 'none';

        if (membershipStatus != 'active') {
          return {
            'success': false,
            'message': _getMembershipBlockMessage(membershipStatus),
            'action': 'membership_required',
            'membershipStatus': membershipStatus,
          };
        }

        // Validate plan limits
        if (MembershipConstants.enforcePlanLimits) {
          final plan = userData['plan'];
          if (plan != null && plan['classesPerMonth'] != null) {
            final classesThisMonth = await _getAttendedClassesThisMonth(userId);
            final limit = plan['classesPerMonth'] as int;

            if (classesThisMonth >= limit) {
              return {
                'success': false,
                'message': 'Has alcanzado tu límite de $limit clases este mes.\n\n'
                    'Actualiza tu plan para continuar entrenando.',
                'action': 'limit_reached',
                'classesUsed': classesThisMonth,
                'classesLimit': limit,
              };
            }

            debugPrint('✅ Clases usadas este mes: $classesThisMonth/$limit');
          }
        }
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final currentDayOfWeek = now.weekday;

      debugPrint('🔍 Procesando QR Check-in genérico:');
      debugPrint('   - Usuario: $userName ($userId)');
      debugPrint('   - Hora actual: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
      debugPrint('   - Día: $currentDayOfWeek');

      // Find all active classes today
      final allSchedulesSnapshot = await firestore
          .collection('class_schedules')
          .where('active', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> activeClasses = [];
      List<Map<String, dynamic>> recentlyPassedClasses = [];

      for (var doc in allSchedulesSnapshot.docs) {
        final data = doc.data();
        final classDays = List<int>.from(data['daysOfWeek'] ?? []);

        if (!classDays.contains(currentDayOfWeek)) continue;

        final classTime = data['time'] as String;
        final parts = classTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final classStartTime = DateTime(now.year, now.month, now.day, hour, minute);
        final minutesSinceStart = now.difference(classStartTime).inMinutes;

        if (minutesSinceStart >= 0 && minutesSinceStart <= 20) {
          activeClasses.add({
            'id': doc.id,
            'time': classTime,
            'type': data['type'],
            'instructor': data['instructor'],
            'capacity': data['capacity'] ?? 15,
            'startTime': classStartTime,
            'minutesSinceStart': minutesSinceStart,
          });
          debugPrint('   ✅ Clase activa encontrada: ${data['type']} a las $classTime ($minutesSinceStart min)');
        } else if (minutesSinceStart > 20 && classStartTime.isBefore(now)) {
          recentlyPassedClasses.add({
            'id': doc.id,
            'time': classTime,
            'type': data['type'],
            'instructor': data['instructor'],
            'startTime': classStartTime,
            'minutesSinceStart': minutesSinceStart,
          });
          debugPrint(
              '   ⏰ Clase pasada encontrada: ${data['type']} a las $classTime (hace $minutesSinceStart min)');
        }
      }

      // CASE 1: Active class(es) found - Register attendance
      if (activeClasses.isNotEmpty) {
        debugPrint('📍 ${activeClasses.length} clase(s) activa(s) encontrada(s)');

        activeClasses.sort((a, b) =>
            (b['minutesSinceStart'] as int).compareTo(a['minutesSinceStart'] as int));

        final targetClass = activeClasses.first;
        final scheduleId = targetClass['id'] as String;
        final scheduleTime = targetClass['time'] as String;
        final scheduleType = targetClass['type'] as String;
        final instructor = targetClass['instructor'] as String;

        debugPrint('   → Registrando asistencia en: $scheduleType a las $scheduleTime');

        final existingBooking = await firestore
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .where('scheduleId', isEqualTo: scheduleId)
            .where('classDate', isEqualTo: Timestamp.fromDate(today))
            .limit(1)
            .get();

        if (existingBooking.docs.isNotEmpty) {
          final bookingId = existingBooking.docs.first.id;
          final existingData = existingBooking.docs.first.data();
          final currentStatus = existingData['status'];

          if (currentStatus == BookingStatus.attended.name) {
            return {
              'success': true,
              'message':
                  'Ya tienes registrada tu asistencia a $scheduleType de las $scheduleTime',
              'action': 'already_attended',
              'classTime': scheduleTime,
              'classType': scheduleType,
            };
          }

          await firestore.collection('bookings').doc(bookingId).update({
            'status': BookingStatus.attended.name,
            'attendedAt': FieldValue.serverTimestamp(),
            'userConfirmedAttendance': true,
            'attendanceConfirmedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          return {
            'success': true,
            'message': 'Asistencia registrada exitosamente',
            'action': 'marked_attended',
            'classTime': scheduleTime,
            'classType': scheduleType,
          };
        } else {
          debugPrint('   - Creando nuevo booking...');

          final capacity = await _getAvailableCapacity(scheduleId, today);
          if (capacity <= 0) {
            throw Exception('La clase de $scheduleType a las $scheduleTime está llena');
          }

          final booking = BookingModel(
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            scheduleId: scheduleId,
            scheduleTime: scheduleTime,
            scheduleType: scheduleType,
            instructor: instructor,
            classDate: today,
            status: BookingStatus.attended,
            createdAt: now,
            userConfirmedAttendance: true,
            attendanceConfirmedAt: now,
            attendedAt: now,
          );

          final docRef = await firestore.collection('bookings').add(booking.toJson());
          debugPrint('✅ Booking creado y marcado como attended: ${docRef.id}');

          return {
            'success': true,
            'message': 'Asistencia registrada exitosamente',
            'action': 'created_and_attended',
            'classTime': scheduleTime,
            'classType': scheduleType,
          };
        }
      }

      // CASE 2: No active classes - Find most recent passed class
      if (recentlyPassedClasses.isNotEmpty) {
        debugPrint('⚠️ No hay clases activas. Buscando clase más reciente que pasó...');

        recentlyPassedClasses.sort((a, b) =>
            (a['minutesSinceStart'] as int).compareTo(b['minutesSinceStart'] as int));

        final mostRecentClass = recentlyPassedClasses.first;
        final scheduleId = mostRecentClass['id'] as String;
        final scheduleTime = mostRecentClass['time'] as String;
        final scheduleType = mostRecentClass['type'] as String;

        debugPrint(
            '   → Clase más reciente: $scheduleType a las $scheduleTime (hace ${mostRecentClass['minutesSinceStart']} min)');

        final existingBooking = await firestore
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .where('scheduleId', isEqualTo: scheduleId)
            .where('classDate', isEqualTo: Timestamp.fromDate(today))
            .limit(1)
            .get();

        if (existingBooking.docs.isNotEmpty) {
          final bookingId = existingBooking.docs.first.id;
          final existingData = existingBooking.docs.first.data();
          final currentStatus = existingData['status'];

          if (currentStatus == BookingStatus.noShow.name) {
            return {
              'success': true,
              'message':
                  'Esta clase de $scheduleType ($scheduleTime) ya está marcada como no asistida',
              'action': 'already_no_show',
              'classTime': scheduleTime,
              'classType': scheduleType,
            };
          }

          await firestore.collection('bookings').doc(bookingId).update({
            'status': BookingStatus.noShow.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          return {
            'success': true,
            'message':
                'La clase de $scheduleType ($scheduleTime) ha sido marcada como no asistida',
            'action': 'marked_no_show',
            'classTime': scheduleTime,
            'classType': scheduleType,
          };
        } else {
          debugPrint('   - No tiene booking, creando como noShow...');

          final booking = BookingModel(
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            scheduleId: scheduleId,
            scheduleTime: scheduleTime,
            scheduleType: scheduleType,
            instructor: mostRecentClass['instructor'] as String,
            classDate: today,
            status: BookingStatus.noShow,
            createdAt: now,
          );

          final docRef = await firestore.collection('bookings').add(booking.toJson());
          debugPrint('❌ Booking creado como noShow: ${docRef.id}');

          return {
            'success': true,
            'message':
                'La clase de $scheduleType ($scheduleTime) ha sido marcada como no asistida',
            'action': 'created_no_show',
            'classTime': scheduleTime,
            'classType': scheduleType,
          };
        }
      }

      // CASE 3: No classes today
      throw Exception(
          'No hay clases programadas para hoy o aún no ha comenzado ninguna clase');
    } catch (e) {
      debugPrint('❌ Error en QR check-in: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
        'action': 'error',
      };
    }
  }

  @override
  Future<void> processExpiredConfirmations() async {
    try {
      final bookings = await firestore
          .collection('bookings')
          .where('status', isEqualTo: BookingStatus.confirmed.name)
          .where('userConfirmedAttendance', isEqualTo: false)
          .get();

      for (var doc in bookings.docs) {
        final booking = BookingModel.fromFirestore(doc);

        if (booking.missedConfirmationWindow) {
          await firestore.collection('bookings').doc(doc.id).update({
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

  // Helper methods

  Future<void> _checkClassLimit(String userId, DateTime classDate) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final userData = userDoc.data()!;
      final classesPerMonth = userData['classesPerMonth'];

      if (classesPerMonth == null) {
        return; // Unlimited plan
      }

      final bookedThisMonth = await getUserBookedClassesThisMonth(userId, classDate);

      debugPrint('🔍 Verificando límite de clases:');
      debugPrint('   - Plan permite: $classesPerMonth clases/mes');
      debugPrint('   - Usuario ha agendado: $bookedThisMonth clases este mes');

      if (bookedThisMonth >= classesPerMonth) {
        throw Exception(
            'Has alcanzado el límite de $classesPerMonth clases de tu plan. '
            'Ya has agendado $bookedThisMonth clases este mes.');
      }
    } catch (e) {
      if (e.toString().contains('límite')) {
        rethrow;
      }
      throw Exception('Error al verificar límite de clases: $e');
    }
  }

  Future<int> _getAvailableCapacity(String scheduleId, DateTime classDate) async {
    final scheduleDoc = await firestore.collection('class_schedules').doc(scheduleId).get();
    if (!scheduleDoc.exists) {
      throw Exception('Horario no encontrado');
    }

    final maxCapacity = scheduleDoc.data()?['capacity'] ?? 15;

    final dateKey = _getDateKey(classDate);
    final capacityDoc = await firestore
        .collection('class_schedules')
        .doc(scheduleId)
        .collection('capacity_tracking')
        .doc(dateKey)
        .get();

    int bookedCount = 0;
    if (capacityDoc.exists) {
      bookedCount = capacityDoc.data()?['currentBookings'] ?? 0;
    }

    return maxCapacity - bookedCount;
  }

  String _getMembershipBlockMessage(String status) {
    switch (status) {
      case 'none':
        return AppMessages.membershipNone;
      case 'pending':
        return AppMessages.membershipPending;
      case 'inactive':
        return AppMessages.membershipInactive;
      default:
        return AppMessages.membershipUnknown;
    }
  }

  Future<int> _getAttendedClassesThisMonth(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final snapshot = await firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: BookingStatus.attended.name)
          .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error contando clases del mes: $e');
      return 0;
    }
  }
}
