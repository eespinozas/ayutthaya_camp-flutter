import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _usersSubscription;
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  StreamSubscription<QuerySnapshot>? _paymentsSubscription;
  StreamSubscription<QuerySnapshot>? _schedulesSubscription;

  // -------------------------
  // Estado del Dashboard
  // -------------------------
  bool loading = true;
  String? errorMsg;

  // KPIs del día
  int totalAsistencias = 0;
  int clasesCompletadas = 0;
  int clasesTotales = 0;
  int alumnosNuevos = 0;
  int pagosRecibidos = 0;
  int capacidadTotalHoy = 0;

  // Alertas
  int pendingUsers = 0;
  int activeUsers = 0;
  int pendingPayments = 0;
  int expiringMemberships = 0;

  // Asistencia por clase
  Map<String, Map<String, dynamic>> scheduleStats = {};

  AdminDashboardViewModel() {
    _setupListeners();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _paymentsSubscription?.cancel();
    _schedulesSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Configurar listeners para actualizaciones en tiempo real
  // ---------------------------------------------------------------------------
  void _setupListeners() {
    loading = true;
    notifyListeners();

    // Listener para usuarios
    _usersSubscription = _firestore
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      _processUsersData(snapshot.docs);
      _checkIfAllDataLoaded();
    });

    // Listener para bookings
    _bookingsSubscription = _firestore
        .collection('bookings')
        .snapshots()
        .listen((snapshot) {
      _processBookingsData(snapshot.docs);
      _checkIfAllDataLoaded();
    });

    // Listener para payments
    _paymentsSubscription = _firestore
        .collection('payments')
        .snapshots()
        .listen((snapshot) {
      _processPaymentsData(snapshot.docs);
      _checkIfAllDataLoaded();
    });

    // Listener para schedules
    _schedulesSubscription = _firestore
        .collection('class_schedules')
        .snapshots()
        .listen((snapshot) {
      _processSchedulesData(snapshot.docs);
      _checkIfAllDataLoaded();
    });
  }

  // ---------------------------------------------------------------------------
  // Verificar si todos los datos están cargados
  // ---------------------------------------------------------------------------
  int _loadedCollections = 0;
  void _checkIfAllDataLoaded() {
    _loadedCollections++;
    if (_loadedCollections >= 4 && loading) {
      loading = false;
      notifyListeners();
      debugPrint('✅ AdminDashboard - Todos los datos cargados');
    }
  }

  // ---------------------------------------------------------------------------
  // Procesar datos de usuarios
  // ---------------------------------------------------------------------------
  void _processUsersData(List<QueryDocumentSnapshot> docs) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Filtrar estudiantes
      final students = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role'] ?? 'student';
        return role == 'student';
      }).toList();

      // Usuarios pendientes (han pagado matrícula y esperan aprobación)
      pendingUsers = students.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['membershipStatus'] ?? 'none';
        return status == 'pending';
      }).length;

      // Usuarios activos
      activeUsers = students.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['membershipStatus'] ?? 'none';
        return status == 'active';
      }).length;

      // Membresías que vencen en 3 días
      expiringMemberships = students.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['expirationDate'] == null) return false;
        if (data['expirationDate'] is! Timestamp) return false;
        final expDate = (data['expirationDate'] as Timestamp).toDate();
        final diff = expDate.difference(now).inDays;
        return diff >= 0 && diff <= 3;
      }).length;

      // Alumnos nuevos hoy
      alumnosNuevos = 0;
      for (var doc in students) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          final createdDate = (data['createdAt'] as Timestamp).toDate();
          final normalizedDate = DateTime(
            createdDate.year,
            createdDate.month,
            createdDate.day,
          );
          if (normalizedDate.isAtSameMomentAs(today)) {
            alumnosNuevos++;
          }
        }
      }

      debugPrint('📊 AdminDashboard - Usuarios procesados:');
      debugPrint('   - Pendientes: $pendingUsers');
      debugPrint('   - Activos: $activeUsers');
      debugPrint('   - Vencen pronto: $expiringMemberships');
      debugPrint('   - Nuevos hoy: $alumnosNuevos');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error procesando usuarios: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Procesar datos de bookings
  // ---------------------------------------------------------------------------
  void _processBookingsData(List<QueryDocumentSnapshot> docs) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Filtrar bookings de hoy
      final todayBookings = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['classDate'] == null || data['classDate'] is! Timestamp) {
          return false;
        }
        final classDate = (data['classDate'] as Timestamp).toDate();
        final normalizedDate = DateTime(
          classDate.year,
          classDate.month,
          classDate.day,
        );
        return normalizedDate.isAtSameMomentAs(today);
      }).toList();

      // Total asistencias hoy
      totalAsistencias = todayBookings.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'confirmed';
        return status == 'attended';
      }).length;

      // Clases únicas de hoy (schedules únicos con al menos una asistencia)
      final uniqueSchedulesWithAttendance = <String>{};
      for (var booking in todayBookings) {
        final data = booking.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'confirmed';
        if (status == 'attended') {
          uniqueSchedulesWithAttendance.add(data['scheduleId'] as String);
        }
      }
      clasesCompletadas = uniqueSchedulesWithAttendance.length;

      // Calcular estadísticas por horario
      final tempScheduleStats = <String, Map<String, dynamic>>{};
      for (var booking in todayBookings) {
        final data = booking.data() as Map<String, dynamic>;
        final scheduleId = data['scheduleId'] as String;
        final status = data['status'] ?? 'confirmed';

        if (!tempScheduleStats.containsKey(scheduleId)) {
          tempScheduleStats[scheduleId] = {
            'enrolled': 0,
            'attended': 0,
            'time': data['scheduleTime'] ?? '',
          };
        }

        tempScheduleStats[scheduleId]!['enrolled'] =
            (tempScheduleStats[scheduleId]!['enrolled'] as int) + 1;

        if (status == 'attended') {
          tempScheduleStats[scheduleId]!['attended'] =
              (tempScheduleStats[scheduleId]!['attended'] as int) + 1;
        }
      }

      scheduleStats = tempScheduleStats;

      debugPrint('📊 AdminDashboard - Bookings procesados:');
      debugPrint('   - Asistencias hoy: $totalAsistencias');
      debugPrint('   - Clases completadas: $clasesCompletadas');
      debugPrint('   - Horarios con bookings: ${scheduleStats.length}');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error procesando bookings: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Procesar datos de pagos
  // ---------------------------------------------------------------------------
  void _processPaymentsData(List<QueryDocumentSnapshot> docs) {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('💰 PROCESANDO PAGOS - DASHBOARD');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('Total documentos de pagos: ${docs.length}');
      debugPrint('');

      int pendingCount = 0;
      int approvedCount = 0;
      int rejectedCount = 0;
      double totalPagosMes = 0;

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        // Validar que los campos de fecha sean Timestamp antes de convertir
        DateTime? createdAt;
        if (data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          } else {
            debugPrint('⚠️ Pago ${doc.id}: createdAt no es Timestamp, es ${data['createdAt'].runtimeType}');
          }
        }

        DateTime? reviewedAt;
        if (data['reviewedAt'] != null) {
          if (data['reviewedAt'] is Timestamp) {
            reviewedAt = (data['reviewedAt'] as Timestamp).toDate();
          } else {
            debugPrint('⚠️ Pago ${doc.id}: reviewedAt no es Timestamp, es ${data['reviewedAt'].runtimeType}');
          }
        }

        debugPrint('Pago ID: ${doc.id}');
        debugPrint('  - Status: $status');
        debugPrint('  - Amount: \$${amount.toInt()} CLP');
        debugPrint('  - CreatedAt: $createdAt');
        debugPrint('  - ReviewedAt: $reviewedAt');

        // Contar por status
        if (status == 'pending') {
          pendingCount++;
          debugPrint('  ⚠️ PENDIENTE');
        } else if (status == 'approved') {
          approvedCount++;
          // Sumar pagos aprobados del mes actual usando reviewedAt
          if (reviewedAt != null && reviewedAt.isAfter(startOfMonth)) {
            totalPagosMes += amount;
            debugPrint('  ✅ APROBADO (incluido en total del mes)');
          } else {
            debugPrint('  ✅ APROBADO (mes anterior o sin fecha de revisión)');
          }
        } else if (status == 'rejected') {
          rejectedCount++;
          debugPrint('  ❌ RECHAZADO');
        }
        debugPrint('');
      }

      pendingPayments = pendingCount;
      pagosRecibidos = totalPagosMes.toInt();

      debugPrint('RESUMEN:');
      debugPrint('  - Pendientes: $pendingPayments');
      debugPrint('  - Aprobados: $approvedCount');
      debugPrint('  - Rechazados: $rejectedCount');
      debugPrint('  - Total recibido este mes: \$$pagosRecibidos CLP');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error procesando pagos: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Procesar datos de horarios
  // ---------------------------------------------------------------------------
  void _processSchedulesData(List<QueryDocumentSnapshot> docs) {
    try {
      // Filtrar schedules por el día de la semana actual
      final now = DateTime.now();
      final weekday = now.weekday; // 1=Lunes, 2=Martes, ..., 7=Domingo

      final schedulesForToday = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final daysOfWeek = data['daysOfWeek'] as List<dynamic>?;

        // Si el schedule tiene daysOfWeek definido, verificar si incluye el día actual
        if (daysOfWeek != null) {
          return daysOfWeek.contains(weekday);
        }

        // Si no tiene daysOfWeek, asumir que aplica todos los días
        return true;
      }).toList();

      clasesTotales = schedulesForToday.length;

      // Calcular capacidad total del día
      capacidadTotalHoy = 0;

      // Actualizar capacidades en scheduleStats solo para los schedules de hoy
      for (var doc in schedulesForToday) {
        final data = doc.data() as Map<String, dynamic>;
        final scheduleId = doc.id;
        final capacity = (data['capacity'] as int?) ?? 15;

        // Sumar a la capacidad total del día
        capacidadTotalHoy += capacity;

        if (scheduleStats.containsKey(scheduleId)) {
          scheduleStats[scheduleId]!['capacity'] = capacity;
        }
      }

      debugPrint('📊 AdminDashboard - Horarios procesados:');
      debugPrint('   - Día de la semana: $weekday');
      debugPrint('   - Horarios del día: $clasesTotales');
      debugPrint('   - Capacidad total del día: $capacidadTotalHoy');
      debugPrint('   - Total horarios en BD: ${docs.length}');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error procesando horarios: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Recargar manual
  // ---------------------------------------------------------------------------
  Future<void> reload() async {
    _loadedCollections = 0;
    loading = true;
    notifyListeners();
    // Los listeners se encargarán de recargar automáticamente
  }
}
