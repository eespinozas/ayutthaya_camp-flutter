import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../bookings/models/booking.dart';
import '../../../payments/models/payment.dart';

class AdminReportesViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // DAILY REPORT DATA
  // ---------------------------------------------------------------------------
  Stream<Map<String, dynamic>> getDailyReport(DateTime selectedDate) {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final endOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      59,
      59,
    );

    debugPrint('');
    debugPrint('📊 DAILY REPORT');
    debugPrint('   Date: $selectedDate');
    debugPrint('   Range: $startOfDay - $endOfDay');

    // Combine multiple streams into one
    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      try {
        // Get all bookings for the day
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();

        final bookings = bookingsSnapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList();

        // Get payments for the day
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .where('status', isEqualTo: 'approved')
            .get();

        final payments = paymentsSnapshot.docs
            .map((doc) => Payment.fromFirestore(doc))
            .toList();

        // Get new users registered on the day
        final newUsersSnapshot = await _firestore
            .collection('users')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();

        // Calculate metrics
        final totalBookings = bookings.length;
        final attendedBookings = bookings.where((b) => b.status == BookingStatus.attended).length;
        final newUsers = newUsersSnapshot.docs.length;
        final totalIncome = payments.fold<double>(0, (total, payment) => total + payment.amount).toInt();

        // Get schedules for the day to calculate capacity
        final weekday = selectedDate.weekday;
        final schedulesSnapshot = await _firestore
            .collection('class_schedules')
            .where('daysOfWeek', arrayContains: weekday)
            .get();

        final totalCapacity = schedulesSnapshot.docs.fold<int>(
          0,
          (total, doc) => total + ((doc.data()['capacity'] as int?) ?? 15),
        );
        final classesTotal = schedulesSnapshot.docs.length;

        // Calculate attendance rate
        final attendanceRate = totalCapacity > 0
            ? (attendedBookings / totalCapacity * 100).toInt()
            : 0;

        // Group bookings by schedule (class time)
        final classesBySchedule = <String, Map<String, dynamic>>{};
        for (var booking in bookings) {
          final scheduleId = booking.scheduleId;
          if (!classesBySchedule.containsKey(scheduleId)) {
            // Get schedule info
            final scheduleDoc = await _firestore
                .collection('class_schedules')
                .doc(scheduleId)
                .get();

            if (scheduleDoc.exists) {
              final scheduleData = scheduleDoc.data()!;
              classesBySchedule[scheduleId] = {
                'hora': scheduleData['time'] ?? 'N/A',
                'inscritos': 0,
                'asistieron': 0,
                'capacidad': scheduleData['capacity'] ?? 15,
              };
            }
          }

          if (classesBySchedule.containsKey(scheduleId)) {
            classesBySchedule[scheduleId]!['inscritos'] =
                (classesBySchedule[scheduleId]!['inscritos'] as int) + 1;

            if (booking.status == BookingStatus.attended) {
              classesBySchedule[scheduleId]!['asistieron'] =
                  (classesBySchedule[scheduleId]!['asistieron'] as int) + 1;
            }
          }
        }

        // Sort classes by time
        final classesList = classesBySchedule.values.toList();
        classesList.sort((a, b) => (a['hora'] as String).compareTo(b['hora'] as String));

        // Count completed classes (classes with at least one booking)
        final completedClasses = classesList.length;

        debugPrint('   ✅ Total Bookings: $totalBookings');
        debugPrint('   ✅ Attended: $attendedBookings');
        debugPrint('   ✅ New Users: $newUsers');
        debugPrint('   ✅ Income: $totalIncome');
        debugPrint('   ✅ Classes: $completedClasses/$classesTotal');

        return {
          'totalAsistencias': attendedBookings,
          'clasesCompletadas': completedClasses,
          'clasesTotales': classesTotal,
          'alumnosNuevos': newUsers,
          'pagosRecibidos': totalIncome,
          'tasaAsistencia': attendanceRate,
          'clases': classesList,
        };
      } catch (e) {
        debugPrint('❌ Error getting daily report: $e');
        return {
          'totalAsistencias': 0,
          'clasesCompletadas': 0,
          'clasesTotales': 0,
          'alumnosNuevos': 0,
          'pagosRecibidos': 0,
          'tasaAsistencia': 0,
          'clases': [],
        };
      }
    });
  }

  // ---------------------------------------------------------------------------
  // WEEKLY REPORT DATA
  // ---------------------------------------------------------------------------
  Stream<Map<String, dynamic>> getWeeklyReport(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    debugPrint('');
    debugPrint('📊 WEEKLY REPORT');
    debugPrint('   Week: $weekStart - $weekEnd');

    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      try {
        // Get all bookings for the week
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
            .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
            .get();

        final bookings = bookingsSnapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList();

        // Get payments for the week
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
            .where('status', isEqualTo: 'approved')
            .get();

        final payments = paymentsSnapshot.docs
            .map((doc) => Payment.fromFirestore(doc))
            .toList();

        // Get new users for the week
        final newUsersSnapshot = await _firestore
            .collection('users')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
            .get();

        // Get active users (those with active membership)
        final activeUsersSnapshot = await _firestore
            .collection('users')
            .where('membershipStatus', isEqualTo: 'active')
            .get();

        // Calculate metrics
        final attendedBookings = bookings.where((b) => b.status == BookingStatus.attended).length;
        final totalIncome = payments.fold<double>(0, (total, payment) => total + payment.amount).toInt();
        final newUsers = newUsersSnapshot.docs.length;
        final activeUsers = activeUsersSnapshot.docs.length;

        // Calculate daily attendance for bar chart
        final dailyAttendance = <String, Map<String, dynamic>>{};
        final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

        for (int i = 0; i < 7; i++) {
          final currentDay = weekStart.add(Duration(days: i));
          final dayKey = '${currentDay.year}-${currentDay.month}-${currentDay.day}';

          dailyAttendance[dayKey] = {
            'dia': dayNames[i],
            'fecha': currentDay.day.toString(),
            'asistencias': 0,
            'capacidad': 75, // Will be calculated properly
          };
        }

        // Count attendance per day
        for (var booking in bookings) {
          if (booking.status == BookingStatus.attended) {
            final bookingDate = booking.classDate;
            final dayKey = '${bookingDate.year}-${bookingDate.month}-${bookingDate.day}';

            if (dailyAttendance.containsKey(dayKey)) {
              dailyAttendance[dayKey]!['asistencias'] =
                  (dailyAttendance[dayKey]!['asistencias'] as int) + 1;
            }
          }
        }

        // Find most and least popular classes by schedule
        final attendanceBySchedule = <String, Map<String, dynamic>>{};
        for (var booking in bookings.where((b) => b.status == BookingStatus.attended)) {
          final scheduleId = booking.scheduleId;

          if (!attendanceBySchedule.containsKey(scheduleId)) {
            attendanceBySchedule[scheduleId] = {
              'count': 0,
              'time': booking.scheduleTime,
            };
          }

          attendanceBySchedule[scheduleId]!['count'] =
              (attendanceBySchedule[scheduleId]!['count'] as int) + 1;
        }

        // Sort by attendance
        final sortedSchedules = attendanceBySchedule.entries.toList()
          ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));

        final mostPopular = sortedSchedules.isNotEmpty
            ? {
                'hora': sortedSchedules.first.value['time'],
                'asistenciaPromedio': (sortedSchedules.first.value['count'] as int) / 7.0,
                'capacidad': 15,
              }
            : {
                'hora': 'N/A',
                'asistenciaPromedio': 0.0,
                'capacidad': 15,
              };

        final leastPopular = sortedSchedules.length > 1
            ? {
                'hora': sortedSchedules.last.value['time'],
                'asistenciaPromedio': (sortedSchedules.last.value['count'] as int) / 7.0,
                'capacidad': 15,
              }
            : {
                'hora': 'N/A',
                'asistenciaPromedio': 0.0,
                'capacidad': 15,
              };

        // Calculate average daily attendance
        final avgDailyAttendance = attendedBookings / 7;

        // Get previous week data for comparison
        final prevWeekStart = weekStart.subtract(const Duration(days: 7));
        final prevWeekEnd = prevWeekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

        final prevBookingsSnapshot = await _firestore
            .collection('bookings')
            .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(prevWeekStart))
            .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(prevWeekEnd))
            .get();

        final prevAttended = prevBookingsSnapshot.docs
            .where((doc) => (doc.data()['status'] as String?) == 'attended')
            .length;

        final comparison = prevAttended > 0
            ? ((attendedBookings - prevAttended) / prevAttended * 100).toInt()
            : 0;

        final trend = comparison > 0 ? 'up' : comparison < 0 ? 'down' : 'stable';

        debugPrint('   ✅ Total Attended: $attendedBookings');
        debugPrint('   ✅ Avg Daily: ${avgDailyAttendance.toInt()}');
        debugPrint('   ✅ Active Users: $activeUsers');
        debugPrint('   ✅ New Users: $newUsers');
        debugPrint('   ✅ Income: $totalIncome');
        debugPrint('   ✅ Trend: $trend ($comparison%)');

        return {
          'totalAsistencias': attendedBookings,
          'promedioAsistenciaDiaria': avgDailyAttendance.toInt(),
          'alumnosActivos': activeUsers,
          'alumnosNuevos': newUsers,
          'ingresosSemana': totalIncome,
          'comparacionSemanaAnterior': comparison,
          'asistenciaPorDia': dailyAttendance.values.toList(),
          'claseMasPopular': mostPopular,
          'claseMenosPopular': leastPopular,
          'tendencia': trend,
        };
      } catch (e) {
        debugPrint('❌ Error getting weekly report: $e');
        return {
          'totalAsistencias': 0,
          'promedioAsistenciaDiaria': 0,
          'alumnosActivos': 0,
          'alumnosNuevos': 0,
          'ingresosSemana': 0,
          'comparacionSemanaAnterior': 0,
          'asistenciaPorDia': [],
          'claseMasPopular': {'hora': 'N/A', 'asistenciaPromedio': 0.0, 'capacidad': 15},
          'claseMenosPopular': {'hora': 'N/A', 'asistenciaPromedio': 0.0, 'capacidad': 15},
          'tendencia': 'stable',
        };
      }
    });
  }

  // ---------------------------------------------------------------------------
  // MONTHLY REPORT DATA
  // ---------------------------------------------------------------------------
  Stream<Map<String, dynamic>> getMonthlyReport(DateTime selectedMonth) {
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final monthEnd = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0, // Last day of the month
      23,
      59,
      59,
    );

    debugPrint('');
    debugPrint('📊 MONTHLY REPORT');
    debugPrint('   Month: ${monthStart.month}/${monthStart.year}');
    debugPrint('   Range: $monthStart - $monthEnd');

    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      try {
        // Get all bookings for the month
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
            .get();

        final bookings = bookingsSnapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList();

        // Get payments for the month
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
            .where('status', isEqualTo: 'approved')
            .get();

        final payments = paymentsSnapshot.docs
            .map((doc) => Payment.fromFirestore(doc))
            .toList();

        // Get active users
        final activeUsersSnapshot = await _firestore
            .collection('users')
            .where('membershipStatus', isEqualTo: 'active')
            .get();

        // Get new users for the month
        final newUsersSnapshot = await _firestore
            .collection('users')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
            .get();

        // Get inactive users (cancelled or expired in this month)
        final inactiveUsersSnapshot = await _firestore
            .collection('users')
            .where('membershipStatus', whereIn: ['cancelled', 'expired'])
            .get();

        // Calculate metrics
        final attendedBookings = bookings.where((b) => b.status == BookingStatus.attended).length;
        final activeUsers = activeUsersSnapshot.docs.length;
        final newUsers = newUsersSnapshot.docs.length;
        final inactiveUsers = inactiveUsersSnapshot.docs.length;

        // Calculate retention rate
        final totalUsers = activeUsers + inactiveUsers;
        final retentionRate = totalUsers > 0
            ? (activeUsers / totalUsers * 100).toInt()
            : 100;

        // Calculate income breakdown
        final monthlyPayments = payments.where((p) => p.type == PaymentType.monthly).toList();
        final enrollmentPayments = payments.where((p) => p.type == PaymentType.enrollment).toList();

        final monthlyIncome = monthlyPayments.fold<double>(0, (total, p) => total + p.amount).toInt();
        final enrollmentIncome = enrollmentPayments.fold<double>(0, (total, p) => total + p.amount).toInt();
        final totalIncome = monthlyIncome + enrollmentIncome;

        // Calculate average daily attendance
        final daysInMonth = monthEnd.day;
        final avgDailyAttendance = daysInMonth > 0
            ? (attendedBookings / daysInMonth).toInt()
            : 0;

        // Calculate average occupancy by schedule time
        final attendanceBySchedule = <String, Map<String, dynamic>>{};
        for (var booking in bookings.where((b) => b.status == BookingStatus.attended)) {
          final scheduleTime = booking.scheduleTime;

          if (!attendanceBySchedule.containsKey(scheduleTime)) {
            attendanceBySchedule[scheduleTime] = {
              'hora': scheduleTime,
              'count': 0,
            };
          }

          attendanceBySchedule[scheduleTime]!['count'] =
              (attendanceBySchedule[scheduleTime]!['count'] as int) + 1;
        }

        // Calculate average occupancy percentage per schedule
        final scheduleOccupancy = attendanceBySchedule.entries.map((entry) {
          final avgAttendance = (entry.value['count'] as int) / daysInMonth;
          final occupancyPercent = (avgAttendance / 15 * 100).toInt(); // Assuming capacity of 15

          return {
            'hora': entry.key,
            'ocupacion': occupancyPercent.clamp(0, 100),
          };
        }).toList();

        // Sort by time
        scheduleOccupancy.sort((a, b) => (a['hora'] as String).compareTo(b['hora'] as String));

        // Calculate attendance by day of week
        final attendanceByWeekday = <int, int>{};
        for (int i = 1; i <= 7; i++) {
          attendanceByWeekday[i] = 0;
        }

        for (var booking in bookings.where((b) => b.status == BookingStatus.attended)) {
          final weekday = booking.classDate.weekday;
          attendanceByWeekday[weekday] = (attendanceByWeekday[weekday] ?? 0) + 1;
        }

        // Get top 3 days
        final dayNames = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
        final sortedDays = attendanceByWeekday.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topDays = sortedDays.take(3).map((entry) {
          return {
            'dia': dayNames[entry.key],
            'asistencias': entry.value,
          };
        }).toList();

        debugPrint('   ✅ Total Attended: $attendedBookings');
        debugPrint('   ✅ Avg Daily: $avgDailyAttendance');
        debugPrint('   ✅ Active Users: $activeUsers');
        debugPrint('   ✅ New Users: $newUsers');
        debugPrint('   ✅ Total Income: $totalIncome');
        debugPrint('   ✅ Retention: $retentionRate%');

        return {
          'totalAsistencias': attendedBookings,
          'promedioAsistenciaDiaria': avgDailyAttendance,
          'alumnosActivos': activeUsers,
          'alumnosNuevos': newUsers,
          'alumnosInactivos': inactiveUsers,
          'ingresosMensualidad': monthlyIncome,
          'ingresosMatricula': enrollmentIncome,
          'ingresosTotal': totalIncome,
          'tasaRetencion': retentionRate,
          'clasesOcupacionPromedio': scheduleOccupancy,
          'diasConMasAsistencia': topDays,
        };
      } catch (e) {
        debugPrint('❌ Error getting monthly report: $e');
        return {
          'totalAsistencias': 0,
          'promedioAsistenciaDiaria': 0,
          'alumnosActivos': 0,
          'alumnosNuevos': 0,
          'alumnosInactivos': 0,
          'ingresosMensualidad': 0,
          'ingresosMatricula': 0,
          'ingresosTotal': 0,
          'tasaRetencion': 0,
          'clasesOcupacionPromedio': [],
          'diasConMasAsistencia': [],
        };
      }
    });
  }
}
