import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/config/app_constants.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generar clave única para tracking de capacidad (formato: YYYY-MM-DD)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Crear una reserva con transacción atómica para evitar race conditions
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

      // 🔒 TRANSACCIÓN ATÓMICA: Verificar capacidad y crear booking
      String? bookingId;

      await _firestore.runTransaction((transaction) async {
        // Obtener referencia al schedule para capacidad máxima
        final scheduleRef = _firestore.collection('class_schedules').doc(booking.scheduleId);
        final scheduleSnapshot = await transaction.get(scheduleRef);

        if (!scheduleSnapshot.exists) {
          throw Exception('Horario de clase no encontrado');
        }

        final maxCapacity = scheduleSnapshot.data()?['capacity'] ?? 15;

        // Crear clave única para el contador de capacidad (formato: scheduleId_YYYY-MM-DD)
        final dateKey = _getDateKey(booking.classDate);
        final capacityRef = _firestore
            .collection('class_schedules')
            .doc(booking.scheduleId)
            .collection('capacity_tracking')
            .doc(dateKey);

        // Obtener contador actual
        final capacitySnapshot = await transaction.get(capacityRef);

        int currentBookings = 0;
        if (capacitySnapshot.exists) {
          currentBookings = capacitySnapshot.data()?['currentBookings'] ?? 0;
        }

        // Verificar si hay espacio disponible
        if (currentBookings >= maxCapacity) {
          throw Exception('Esta clase está llena (${currentBookings}/${maxCapacity})');
        }

        // Crear la reserva
        final bookingRef = _firestore.collection('bookings').doc();
        transaction.set(bookingRef, booking.toMap());
        bookingId = bookingRef.id;

        // Incrementar contador de capacidad
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

        debugPrint('✅ Booking creado: $bookingId (${currentBookings + 1}/${maxCapacity})');
      });

      if (bookingId == null) {
        throw Exception('Error: No se pudo crear la reserva');
      }

      final docRef = _firestore.collection('bookings').doc(bookingId);

      // Programar recordatorios de confirmación y notificar a admins
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

        // Notificar a admins sobre nueva reserva
        final formattedDate = '${booking.classDate.day}/${booking.classDate.month}/${booking.classDate.year}';
        await notificationService.sendNotificationToAdmins(
          title: '📅 Nueva Reserva de Clase',
          body: '${booking.userName} se registró a ${booking.scheduleType} - $formattedDate a las ${booking.scheduleTime}',
          data: {
            'type': 'new_booking',
            'bookingId': docRef.id,
            'userId': booking.userId,
            'className': booking.scheduleType,
            'classDate': booking.classDate.toIso8601String(),
            'classTime': booking.scheduleTime,
          },
        );
        debugPrint('✅ Notificación de nueva reserva enviada a admins');
      } catch (e) {
        debugPrint('⚠️ Error programando recordatorios o enviando notificaciones: $e');
        // No lanzar error, la reserva ya se creó
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear reserva: $e');
    }
  }

  /// Obtener capacidad disponible para una clase (usando contador optimizado)
  Future<int> _getAvailableCapacity(String scheduleId, DateTime classDate) async {
    // Obtener el horario para saber la capacidad máxima
    final scheduleDoc = await _firestore.collection('class_schedules').doc(scheduleId).get();
    if (!scheduleDoc.exists) {
      throw Exception('Horario no encontrado');
    }

    final maxCapacity = scheduleDoc.data()?['capacity'] ?? 15;

    // Obtener contador de capacidad
    final dateKey = _getDateKey(classDate);
    final capacityDoc = await _firestore
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

  /// Obtener número de reservas confirmadas para una clase (usando contador optimizado)
  Future<int> getBookedCount(String scheduleId, DateTime classDate) async {
    final dateKey = _getDateKey(classDate);
    final capacityDoc = await _firestore
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

  /// Cancelar una reserva (usuario) con decremento atómico del contador
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      // 🔒 TRANSACCIÓN ATÓMICA: Cancelar booking y decrementar contador
      await _firestore.runTransaction((transaction) async {
        // Obtener el booking para saber scheduleId y classDate
        final bookingRef = _firestore.collection('bookings').doc(bookingId);
        final bookingSnapshot = await transaction.get(bookingRef);

        if (!bookingSnapshot.exists) {
          throw Exception('Reserva no encontrada');
        }

        final bookingData = bookingSnapshot.data()!;
        final scheduleId = bookingData['scheduleId'] as String;
        final classDate = (bookingData['classDate'] as Timestamp).toDate();
        final currentStatus = bookingData['status'] as String;

        // Solo decrementar si el estado actual es 'confirmed'
        if (currentStatus != BookingStatus.confirmed.name) {
          throw Exception('Solo se pueden cancelar reservas confirmadas');
        }

        // Actualizar el booking a cancelado
        transaction.update(bookingRef, {
          'status': BookingStatus.cancelled.name,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancellationReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Decrementar contador de capacidad
        final dateKey = _getDateKey(classDate);
        final capacityRef = _firestore
            .collection('class_schedules')
            .doc(scheduleId)
            .collection('capacity_tracking')
            .doc(dateKey);

        final capacitySnapshot = await transaction.get(capacityRef);

        if (capacitySnapshot.exists) {
          final currentBookings = capacitySnapshot.data()?['currentBookings'] ?? 0;

          // Evitar números negativos
          final newCount = currentBookings > 0 ? currentBookings - 1 : 0;

          transaction.update(capacityRef, {
            'currentBookings': newCount,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          debugPrint('✅ Booking cancelado: $bookingId (Capacidad: $newCount)');
        }
      });

      // Cancelar recordatorios programados (fuera de la transacción)
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

  /// Procesar check-in por código QR genérico del gimnasio
  ///
  /// Lógica:
  /// - Detecta automáticamente qué clase está activa ahora (ventana de 20 min)
  /// - Si hay clase activa (0-20 min): marca asistencia
  /// - Si escanea después de 20 min de una clase: marca esa clase como no asistida
  /// - Si no hay clases hoy: error
  Future<Map<String, dynamic>> processQRCheckIn({
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      // ✅ FIX #1 y #2: Validar membresía activa y límite de clases
      if (MembershipConstants.requireActiveMembershipForQR) {
        // Obtener datos del usuario
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (!userDoc.exists) {
          return {
            'success': false,
            'message': 'Usuario no encontrado',
            'action': 'user_not_found',
          };
        }

        final userData = userDoc.data()!;
        final membershipStatus = userData['membershipStatus'] ?? 'none';

        // Validar estado de membresía
        if (membershipStatus != 'active') {
          return {
            'success': false,
            'message': _getMembershipBlockMessage(membershipStatus),
            'action': 'membership_required',
            'membershipStatus': membershipStatus,
          };
        }

        // Validar límite de clases del plan
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
      final currentDayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday

      debugPrint('🔍 Procesando QR Check-in genérico:');
      debugPrint('   - Usuario: $userName ($userId)');
      debugPrint('   - Hora actual: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
      debugPrint('   - Día: $currentDayOfWeek');

      // PASO 1: Buscar todas las clases de hoy
      final allSchedulesSnapshot = await _firestore
          .collection('class_schedules')
          .where('active', isEqualTo: true)
          .get();

      // Clasificar clases en: activas (0-20 min) y pasadas (>20 min)
      List<Map<String, dynamic>> activeClasses = [];
      List<Map<String, dynamic>> recentlyPassedClasses = [];

      for (var doc in allSchedulesSnapshot.docs) {
        final data = doc.data();
        final classDays = List<int>.from(data['daysOfWeek'] ?? []);

        // Verificar si la clase es hoy
        if (!classDays.contains(currentDayOfWeek)) continue;

        final classTime = data['time'] as String;
        final parts = classTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final classStartTime = DateTime(now.year, now.month, now.day, hour, minute);
        final minutesSinceStart = now.difference(classStartTime).inMinutes;

        // Clase activa: entre 0 y 20 minutos desde el inicio
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
          debugPrint('   ✅ Clase activa encontrada: ${data['type']} a las $classTime (${minutesSinceStart} min)');
        }
        // Clase que pasó hace poco: entre 21 minutos y hasta el final del día
        else if (minutesSinceStart > 20 && classStartTime.isBefore(now)) {
          recentlyPassedClasses.add({
            'id': doc.id,
            'time': classTime,
            'type': data['type'],
            'instructor': data['instructor'],
            'startTime': classStartTime,
            'minutesSinceStart': minutesSinceStart,
          });
          debugPrint('   ⏰ Clase pasada encontrada: ${data['type']} a las $classTime (hace ${minutesSinceStart} min)');
        }
      }

      // CASO 1: HAY CLASE(S) ACTIVA(S) - Registrar asistencia
      if (activeClasses.isNotEmpty) {
        debugPrint('📍 ${activeClasses.length} clase(s) activa(s) encontrada(s)');

        // Ordenar por tiempo más reciente (la que empezó más recientemente)
        activeClasses.sort((a, b) =>
          (b['minutesSinceStart'] as int).compareTo(a['minutesSinceStart'] as int)
        );

        final targetClass = activeClasses.first;
        final scheduleId = targetClass['id'] as String;
        final scheduleTime = targetClass['time'] as String;
        final scheduleType = targetClass['type'] as String;
        final instructor = targetClass['instructor'] as String;

        debugPrint('   → Registrando asistencia en: $scheduleType a las $scheduleTime');

        // Verificar si ya tiene booking para esta clase
        final existingBooking = await _firestore
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
              'message': 'Ya tienes registrada tu asistencia a $scheduleType de las $scheduleTime',
              'action': 'already_attended',
              'classTime': scheduleTime,
              'classType': scheduleType,
            };
          }

          // Actualizar booking existente a attended
          await _firestore.collection('bookings').doc(bookingId).update({
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
          // No tiene booking previo, crear uno nuevo como attended
          debugPrint('   - Creando nuevo booking...');

          // Verificar capacidad
          final capacity = await _getAvailableCapacity(scheduleId, today);
          if (capacity <= 0) {
            throw Exception('La clase de $scheduleType a las $scheduleTime está llena');
          }

          final booking = Booking(
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

          final docRef = await _firestore.collection('bookings').add(booking.toMap());
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

      // CASO 2: NO HAY CLASES ACTIVAS - Buscar clase más reciente que haya pasado
      if (recentlyPassedClasses.isNotEmpty) {
        debugPrint('⚠️ No hay clases activas. Buscando clase más reciente que pasó...');

        // Ordenar por la que pasó más recientemente
        recentlyPassedClasses.sort((a, b) =>
          (a['minutesSinceStart'] as int).compareTo(b['minutesSinceStart'] as int)
        );

        final mostRecentClass = recentlyPassedClasses.first;
        final scheduleId = mostRecentClass['id'] as String;
        final scheduleTime = mostRecentClass['time'] as String;
        final scheduleType = mostRecentClass['type'] as String;

        debugPrint('   → Clase más reciente: $scheduleType a las $scheduleTime (hace ${mostRecentClass['minutesSinceStart']} min)');

        // Buscar o crear booking para esta clase y marcarlo como noShow
        final existingBooking = await _firestore
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
              'message': 'Esta clase de $scheduleType ($scheduleTime) ya está marcada como no asistida',
              'action': 'already_no_show',
              'classTime': scheduleTime,
              'classType': scheduleType,
            };
          }

          // Marcar booking existente como noShow
          await _firestore.collection('bookings').doc(bookingId).update({
            'status': BookingStatus.noShow.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          return {
            'success': true,
            'message': 'La clase de $scheduleType ($scheduleTime) ha sido marcada como no asistida',
            'action': 'marked_no_show',
            'classTime': scheduleTime,
            'classType': scheduleType,
          };
        } else {
          // No tiene booking, crear uno como noShow
          debugPrint('   - No tiene booking, creando como noShow...');

          final booking = Booking(
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

          final docRef = await _firestore.collection('bookings').add(booking.toMap());
          debugPrint('❌ Booking creado como noShow: ${docRef.id}');

          return {
            'success': true,
            'message': 'La clase de $scheduleType ($scheduleTime) ha sido marcada como no asistida',
            'action': 'created_no_show',
            'classTime': scheduleTime,
            'classType': scheduleType,
          };
        }
      }

      // CASO 3: No hay clases hoy
      throw Exception(
        'No hay clases programadas para hoy o aún no ha comenzado ninguna clase'
      );

    } catch (e) {
      debugPrint('❌ Error en QR check-in: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
        'action': 'error',
      };
    }
  }

  /// Obtiene el mensaje de bloqueo según el estado de membresía
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

  /// Cuenta las clases a las que el usuario asistió este mes
  Future<int> _getAttendedClassesThisMonth(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
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
