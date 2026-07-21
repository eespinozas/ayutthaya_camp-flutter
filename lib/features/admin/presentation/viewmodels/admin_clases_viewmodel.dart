import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../bookings/models/booking.dart';
import '../../../schedules/models/class_schedule.dart';
import '../../../schedules/models/schedule_override.dart';
import '../../../schedules/services/schedule_override_service.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/services/chilean_holidays.dart';

class AdminClasesViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScheduleOverrideService _overrideService = ScheduleOverrideService();

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  bool loading = false;
  String? errorMsg;

  // Visibilidad de clases del admin logueado: 'all' ve todas; 'own' solo
  // aquellas donde class_schedules.instructor coincide con su instructorName.
  // Se resuelve una vez antes de emitir schedules (ver getSchedules).
  late final Future<void> _visibilityLoaded = _loadClassVisibility();
  String _classVisibility = 'all';
  String? _instructorName;

  Future<void> _loadClassVisibility() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      _classVisibility = data?['classVisibility'] ?? 'all';
      _instructorName = data?['instructorName'];
    } catch (e) {
      // Ante cualquier error se conserva 'all' para no ocultar clases al dueño
      debugPrint('⚠️ No se pudo cargar classVisibility: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Cambiar fecha seleccionada
  // ---------------------------------------------------------------------------
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void changeDate(int days) {
    _selectedDate = _selectedDate.add(Duration(days: days));
    notifyListeners();
  }

  void goToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Stream: Obtener horarios de clases (schedules) para la fecha seleccionada
  // ---------------------------------------------------------------------------
  Stream<List<ClassSchedule>> getSchedules() async* {
    // La visibilidad debe estar resuelta antes del primer emit para que un
    // admin restringido nunca vea (ni por un instante) clases ajenas.
    await _visibilityLoaded;
    yield* _schedulesStream();
  }

  Stream<List<ClassSchedule>> _schedulesStream() {
    // Obtener el día de la semana de la fecha seleccionada
    // weekday: 1=Lunes, 2=Martes, 3=Miércoles, 4=Jueves, 5=Viernes, 6=Sábado, 7=Domingo
    // Feriados de lunes a viernes usan el horario del sábado
    final weekday = ChileanHolidays.effectiveDayOfWeek(_selectedDate);
    final dayNames = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final dayName = dayNames[weekday];

    debugPrint('📡 Obteniendo schedules...');
    debugPrint('   - Fecha seleccionada: $_selectedDate');
    debugPrint('   - Día de la semana: $dayName (posición: $weekday)');

    return _firestore
        .collection('class_schedules')
        .where('daysOfWeek', arrayContains: weekday)
        .orderBy('time', descending: false)
        .snapshots()
        .handleError((error) {
          debugPrint('❌ ERROR obteniendo schedules: $error');

          // Si hay error de índice, intentar sin filtro por día
          if (error.toString().contains('index')) {
            debugPrint('');
            debugPrint('🔴 ¡FALTA ÍNDICE DE FIRESTORE!');
            debugPrint('   Colección: class_schedules');
            debugPrint('   Campos: daysOfWeek (array-contains) + time (ASC)');
            debugPrint('');
            debugPrint(
              '⚠️ FALLBACK: Obteniendo TODOS los schedules y filtrando en cliente...',
            );

            // Como alternativa, retornar todos los schedules sin filtro
            return _firestore
                .collection('class_schedules')
                .orderBy('time', descending: false)
                .snapshots();
          }

          errorMsg = 'Error cargando horarios: $error';
          notifyListeners();
        })
        .map((snapshot) {
          debugPrint('');
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('📊 SCHEDULES RECIBIDOS DE FIRESTORE');
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('Total de documentos: ${snapshot.docs.length}');
          debugPrint('Filtrando por día: $dayName (posición: $weekday)');
          debugPrint('');

          final schedules = <ClassSchedule>[];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final daysOfWeek = data['daysOfWeek'] as List<dynamic>?;

            debugPrint('Schedule ID: ${doc.id}');
            debugPrint('  - time: ${data['time']}');
            debugPrint('  - daysOfWeek: $daysOfWeek');
            debugPrint('  - capacity: ${data['capacity']}');
            debugPrint('  - instructor: ${data['instructor']}');
            debugPrint('');

            // Filtrar por día en cliente si el query no lo hizo
            if (daysOfWeek != null && !daysOfWeek.contains(weekday)) {
              debugPrint(
                '  ⚠️ SKIP: Schedule no incluye el día $weekday ($dayName)',
              );
              debugPrint('');
              continue;
            }

            try {
              final schedule = ClassSchedule.fromFirestore(doc);
              schedules.add(schedule);
            } catch (e) {
              debugPrint('❌ Error parseando schedule ${doc.id}: $e');
            }
          }

          debugPrint('Schedules parseados exitosamente: ${schedules.length}');

          // Admin restringido: solo sus propias clases
          if (_classVisibility == 'own' && _instructorName != null) {
            schedules.retainWhere((s) => s.instructor == _instructorName);
            debugPrint(
              'Filtro por instructor "$_instructorName": ${schedules.length} clases',
            );
          }

          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('');

          return schedules;
        });
  }

  // ---------------------------------------------------------------------------
  // Stream: Obtener bookings de una clase específica en la fecha seleccionada
  // ---------------------------------------------------------------------------
  Stream<List<Booking>> getClassBookings(String scheduleId) {
    // Normalizar la fecha seleccionada (solo año, mes, día)
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );

    debugPrint('📡 Obteniendo bookings para:');
    debugPrint('   - scheduleId: $scheduleId');
    debugPrint('   - Fecha: $startOfDay');

    return _firestore
        .collection('bookings')
        .where('scheduleId', isEqualTo: scheduleId)
        .where(
          'classDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('classDate', descending: false)
        .orderBy('userName', descending: false)
        .snapshots()
        .handleError((error) {
          debugPrint(
            '❌ ERROR obteniendo bookings para schedule $scheduleId: $error',
          );
          if (error.toString().contains('index')) {
            debugPrint('');
            debugPrint('🔴 ¡FALTA ÍNDICE DE FIRESTORE!');
            debugPrint('   Colección: bookings');
            debugPrint(
              '   Campos: scheduleId (==) + classDate (>=, <=) + userName (ASC)',
            );
            debugPrint('');
          }
        })
        .map((snapshot) {
          debugPrint(
            '✅ Bookings para schedule $scheduleId: ${snapshot.docs.length}',
          );
          if (snapshot.docs.isNotEmpty) {
            debugPrint('   Alumnos:');
            for (var doc in snapshot.docs) {
              final data = doc.data();
              debugPrint('   - ${data['userName']} (${data['status']})');
            }
          }
          return snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
        });
  }

  // ---------------------------------------------------------------------------
  // Overrides: deshabilitar/rehabilitar un horario en la fecha seleccionada
  // ---------------------------------------------------------------------------

  /// IDs de horarios deshabilitados en la fecha seleccionada (tiempo real).
  Stream<Set<String>> getDisabledScheduleIds() {
    return _overrideService.disabledScheduleIdsForDate(_selectedDate);
  }

  /// Override vigente para un horario en la fecha seleccionada (o null).
  Future<ScheduleOverride?> getOverride(String scheduleId) {
    return _overrideService.getOverride(scheduleId, _selectedDate);
  }

  /// Deshabilitar un horario solo para la fecha seleccionada.
  /// Las reservas existentes no se tocan; solo se bloquean las nuevas.
  Future<void> disableScheduleForSelectedDate(
    String scheduleId, {
    String? reason,
  }) async {
    final adminId = _auth.currentUser?.uid ?? 'unknown';
    await _overrideService.disableSchedule(
      scheduleId: scheduleId,
      date: _selectedDate,
      adminId: adminId,
      reason: reason,
    );
  }

  /// Rehabilitar un horario para la fecha seleccionada.
  Future<void> enableScheduleForSelectedDate(String scheduleId) async {
    await _overrideService.enableSchedule(scheduleId, _selectedDate);
  }

  // ---------------------------------------------------------------------------
  // Marcar asistencia de un alumno
  // ---------------------------------------------------------------------------
  Future<void> markAttendance(String bookingId) async {
    try {
      debugPrint('🔄 Marcando asistencia: $bookingId');

      final adminId = _auth.currentUser?.uid ?? 'unknown';

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.attended.name,
        'attendedAt': FieldValue.serverTimestamp(),
        'attendedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Asistencia marcada exitosamente');
    } catch (e) {
      debugPrint('❌ Error marcando asistencia: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Marcar NO asistencia de un alumno
  // ---------------------------------------------------------------------------
  Future<void> markNoShow(String bookingId) async {
    try {
      debugPrint('🔄 Marcando no asistencia: $bookingId');

      final adminId = _auth.currentUser?.uid ?? 'unknown';

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.noShow.name,
        'attendedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ No asistencia marcada exitosamente');
    } catch (e) {
      debugPrint('❌ Error marcando no asistencia: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Aprobar / rechazar confirmaciones pendientes (pendingApproval)
  // ---------------------------------------------------------------------------

  /// Aprobar la confirmación del alumno: pasa a attended y cuenta para el
  /// ranking (equivalente a marcar asistencia manualmente).
  Future<void> approveAttendance(String bookingId) => markAttendance(bookingId);

  /// Rechazar la confirmación del alumno: pasa a rejected (no cuenta como
  /// asistencia). Se registra qué admin decidió en attendedBy.
  Future<void> rejectAttendance(String bookingId) async {
    try {
      debugPrint('🔄 Rechazando confirmación: $bookingId');

      final adminId = _auth.currentUser?.uid ?? 'unknown';

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.rejected.name,
        'attendedBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Confirmación rechazada');
    } catch (e) {
      debugPrint('❌ Error rechazando confirmación: $e');
      rethrow;
    }
  }

  /// Estado al que vuelve una reserva cuando el admin desmarca su
  /// asistencia: si el alumno había confirmado (y el flujo de aprobación
  /// está activo) vuelve a pendiente de aprobación; si no, a agendada.
  String _revertStatusFor(Booking booking) {
    return (AppFlags.attendanceApprovalFlow && booking.userConfirmedAttendance)
        ? BookingStatus.pendingApproval.name
        : BookingStatus.confirmed.name;
  }

  // ---------------------------------------------------------------------------
  // Toggle asistencia (marcar/desmarcar)
  // ---------------------------------------------------------------------------
  Future<void> toggleAttendance(Booking booking) async {
    try {
      if (booking.status == BookingStatus.attended) {
        // Si ya estaba marcado como asistido, revertir
        await _firestore.collection('bookings').doc(booking.id).update({
          'status': _revertStatusFor(booking),
          'attendedAt': null,
          'attendedBy': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Asistencia removida');
      } else {
        // Marcar como asistido
        await markAttendance(booking.id!);
      }
    } catch (e) {
      debugPrint('❌ Error toggling asistencia: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Marcar todos los alumnos de una clase como asistentes
  // ---------------------------------------------------------------------------
  Future<void> markAllAttended(List<Booking> bookings) async {
    try {
      debugPrint(
        '🔄 Marcando todos como asistidos: ${bookings.length} bookings',
      );

      final adminId = _auth.currentUser?.uid ?? 'unknown';
      final batch = _firestore.batch();

      for (var booking in bookings) {
        // No tocar asistencias ya registradas ni reservas canceladas
        if (booking.status != BookingStatus.attended &&
            booking.status != BookingStatus.cancelled) {
          final docRef = _firestore.collection('bookings').doc(booking.id);
          batch.update(docRef, {
            'status': BookingStatus.attended.name,
            'attendedAt': FieldValue.serverTimestamp(),
            'attendedBy': adminId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      debugPrint('✅ Todos marcados como asistidos');
    } catch (e) {
      debugPrint('❌ Error marcando todos como asistidos: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Desmarcar todos los alumnos de una clase
  // ---------------------------------------------------------------------------
  Future<void> unmarkAll(List<Booking> bookings) async {
    try {
      debugPrint('🔄 Desmarcando todos: ${bookings.length} bookings');

      final batch = _firestore.batch();

      for (var booking in bookings) {
        if (booking.status == BookingStatus.attended) {
          final docRef = _firestore.collection('bookings').doc(booking.id);
          batch.update(docRef, {
            'status': _revertStatusFor(booking),
            'attendedAt': null,
            'attendedBy': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      debugPrint('✅ Todos desmarcados');
    } catch (e) {
      debugPrint('❌ Error desmarcando todos: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Obtener estado de la clase
  // ---------------------------------------------------------------------------
  String getClassStatus(String time) {
    final now = DateTime.now();
    final classTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(time.split(':')[0]),
      int.parse(time.split(':')[1]),
    );

    // Si no es el día de hoy
    if (_selectedDate.year != now.year ||
        _selectedDate.month != now.month ||
        _selectedDate.day != now.day) {
      return _selectedDate.isBefore(now) ? 'completed' : 'scheduled';
    }

    // Si es hoy, verificar la hora
    if (now.isAfter(classTime.add(const Duration(hours: 1)))) {
      return 'completed';
    } else if (now.isAfter(classTime.subtract(const Duration(minutes: 15))) &&
        now.isBefore(classTime.add(const Duration(hours: 1)))) {
      return 'in_progress';
    } else {
      return 'scheduled';
    }
  }
}
