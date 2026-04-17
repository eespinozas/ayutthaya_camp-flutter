import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  // -------------------------
  // Estado principal del plan
  // -------------------------
  String? planNombre;
  int? clasesRestantes;
  String? vigenciaHastaStr;

  // -------------------------
  // Resumen de clases
  // -------------------------
  int? resumenAgendadas;
  int? resumenAsistidas;
  int? resumenNoAsistidas;

  // -------------------------
  // Últimos 3 pagos
  // -------------------------
  List<Map<String, dynamic>> ultimos3Pagos = [];

  // -------------------------
  // Estado de membresía
  // -------------------------
  String? membershipStatus;
  DateTime? expirationDate;

  // -------------------------
  // Cargando / error
  // -------------------------
  bool loading = true;
  String? errorMsg;

  DashboardViewModel() {
    _cargarDashboard();
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // GETTER: ¿El usuario está ACTIVO?
  // ---------------------------------------------------------------------------
  bool get estaActivo {
    debugPrint('🔍 DashboardViewModel.estaActivo - membershipStatus: $membershipStatus');
    return membershipStatus == 'active';
  }

  // ---------------------------------------------------------------------------
  // Carga inicial del Dashboard
  // ---------------------------------------------------------------------------
  Future<void> _cargarDashboard() async {
    try {
      loading = true;
      notifyListeners();

      final user = _auth.currentUser;
      debugPrint('🔍 DashboardViewModel._cargarDashboard - user: ${user?.email}');

      if (user == null) {
        debugPrint('❌ DashboardViewModel._cargarDashboard - No hay usuario autenticado');
        loading = false;
        errorMsg = 'Usuario no autenticado';
        notifyListeners();
        return;
      }

      // Leer datos del usuario desde Firestore
      debugPrint('🔍 Intentando leer usuario: ${user.uid}');
      debugPrint('   Email: ${user.email}');
      debugPrint('   Verificado: ${user.emailVerified}');

      DocumentSnapshot userDoc;
      try {
        userDoc = await _firestore.collection('users').doc(user.uid).get();
      } catch (e) {
        debugPrint('❌ Error al leer documento de usuario: $e');
        if (e.toString().contains('permission-denied')) {
          debugPrint('   🔒 Error de permisos! Verifica las reglas de Firestore para la colección "users"');
        }
        loading = false;
        errorMsg = 'Error al cargar datos del usuario: $e';
        notifyListeners();
        return;
      }

      debugPrint('📄 Documento existe: ${userDoc.exists}');
      if (userDoc.exists) {
        debugPrint('📦 Datos del documento: ${userDoc.data()}');
      }

      if (!userDoc.exists) {
        debugPrint('⚠️ DashboardViewModel._cargarDashboard - Usuario no existe en Firestore');
        debugPrint('   UID buscado: ${user.uid}');
        debugPrint('   Email: ${user.email}');
        debugPrint('   Creando documento de usuario...');

        // Crear el documento del usuario si no existe
        try {
          final userEmail = user.email ?? '';
          final userName = user.displayName ?? '';
          final isAdmin = userEmail.startsWith('admin');

          await _firestore.collection('users').doc(user.uid).set({
            'email': userEmail,
            'searchKey': userEmail.toLowerCase(), // Para búsquedas fáciles en Firebase Console
            'name': userName,
            'role': isAdmin ? 'admin' : 'student',
            'membershipStatus': isAdmin ? 'active' : 'none',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          debugPrint('✅ Documento de usuario creado exitosamente');

          // Volver a leer el documento recién creado
          userDoc = await _firestore.collection('users').doc(user.uid).get();

          if (!userDoc.exists) {
            debugPrint('❌ Error: No se pudo crear el documento del usuario');
            loading = false;
            errorMsg = 'Error al crear perfil de usuario';
            notifyListeners();
            return;
          }
        } catch (createError) {
          debugPrint('❌ Error al crear documento de usuario: $createError');
          loading = false;
          errorMsg = 'Error al crear perfil de usuario: $createError';
          notifyListeners();
          return;
        }
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      debugPrint('📊 DashboardViewModel._cargarDashboard - userData: $userData');

      // Extraer datos del usuario
      membershipStatus = userData['membershipStatus'] ?? 'none';
      debugPrint('✅ DashboardViewModel._cargarDashboard - membershipStatus: $membershipStatus');

      // Verificar si el plan está vencido y actualizar a "inactive" si es necesario
      if (userData['expirationDate'] != null) {
        final expirationDateTime = (userData['expirationDate'] as Timestamp).toDate();
        final now = DateTime.now();

        debugPrint('📅 Verificando vencimiento:');
        debugPrint('   - Fecha de expiración: $expirationDateTime');
        debugPrint('   - Fecha actual: $now');
        debugPrint('   - Estado actual: $membershipStatus');

        // Si el plan está vencido y el usuario está activo, marcarlo como inactive
        if (now.isAfter(expirationDateTime) && membershipStatus == 'active') {
          debugPrint('⚠️ Plan vencido! Actualizando a "inactive"');

          await _firestore.collection('users').doc(user.uid).update({
            'membershipStatus': 'inactive',
            'updatedAt': FieldValue.serverTimestamp(),
          });

          membershipStatus = 'inactive';
          debugPrint('✅ Usuario actualizado a "inactive"');
        }
      }

      if (userData['expirationDate'] != null) {
        expirationDate = (userData['expirationDate'] as Timestamp).toDate();
        vigenciaHastaStr = '${expirationDate!.day}/${expirationDate!.month}/${expirationDate!.year}';
      } else {
        vigenciaHastaStr = '—';
      }

      planNombre = userData['planName'] ??
                   (membershipStatus == 'active' ? 'Membresía Activa' : 'Sin plan');

      // Leer las bookings del usuario para calcular métricas (primera vez)
      await _calcularMetricas(user.uid, userData);

      // Leer últimos 3 pagos
      await _cargarUltimosPagos(user.uid);

      // Configurar listener para actualizaciones en tiempo real de bookings
      _setupBookingsListener(user.uid, userData);

      loading = false;
      errorMsg = null;
      notifyListeners();

    } catch (e) {
      debugPrint('❌ DashboardViewModel._cargarDashboard - Error: $e');
      loading = false;
      errorMsg = 'No se pudo cargar el dashboard: $e';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Calcular métricas de clases
  // ---------------------------------------------------------------------------
  Future<void> _calcularMetricas(String userId, Map<String, dynamic> userData) async {
    try {
      // Obtener todas las bookings del usuario
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();

      final now = DateTime.now();
      int agendadas = 0;
      int asistidas = 0;
      int noAsistidas = 0;

      for (final doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'confirmed';
        final classDate = (data['classDate'] as Timestamp).toDate();
        final scheduleTime = data['scheduleTime'] ?? '00:00';
        final userConfirmedAttendance = data['userConfirmedAttendance'] ?? false;

        // Normalizar fecha para comparación (solo año, mes, día)
        final normalizedClassDate = DateTime(classDate.year, classDate.month, classDate.day);
        final today = DateTime(now.year, now.month, now.day);

        // Combinar fecha con hora para obtener el DateTime completo de la clase
        final timeParts = scheduleTime.split(':');
        final classDateTime = DateTime(
          classDate.year,
          classDate.month,
          classDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        // Ventana de confirmación: 30 min después de la clase
        final confirmationWindowEnd = classDateTime.add(const Duration(minutes: 30));
        final missedConfirmation = now.isAfter(confirmationWindowEnd);

        if (status == 'confirmed') {
          // Verificar si pasó la ventana de confirmación sin confirmar
          if (missedConfirmation && !userConfirmedAttendance) {
            noAsistidas++;
            // Actualizar el estado en Firestore
            await _firestore.collection('bookings').doc(doc.id).update({
              'status': 'noShow',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else if (normalizedClassDate.isAfter(today) || normalizedClassDate.isAtSameMomentAs(today)) {
            // Clase de hoy o futura confirmada = agendada
            agendadas++;
          }
        } else if (status == 'attended') {
          asistidas++;
        } else if (status == 'noShow') {
          noAsistidas++;
        }
      }

      resumenAgendadas = agendadas;
      resumenAsistidas = asistidas;
      resumenNoAsistidas = noAsistidas;

      // Calcular clases restantes
      // Usar classesPerMonth del plan del usuario (null = ilimitado)
      final clasesTotales = userData['classesPerMonth'] ?? 999; // null = ilimitado, usar 999

      debugPrint('📊 Calculando clases restantes:');
      debugPrint('   - Total de bookings en DB: ${bookingsSnapshot.docs.length}');

      int clasesUsadas = 0;
      for (var doc in bookingsSnapshot.docs) {
        final status = doc.data()['status'];
        debugPrint('   - Booking: status=$status');
        if (status == 'confirmed' || status == 'attended' || status == 'noShow') {
          clasesUsadas++;
        }
      }

      clasesRestantes = clasesTotales - clasesUsadas;
      if (clasesRestantes! < 0) clasesRestantes = 0;

      debugPrint('📊 Métricas calculadas:');
      debugPrint('   - Clases Totales (limit): $clasesTotales');
      debugPrint('   - Clases Usadas: $clasesUsadas');
      debugPrint('   - Clases Restantes: $clasesRestantes');
      debugPrint('   - Agendadas: $agendadas');
      debugPrint('   - Asistidas: $asistidas');
      debugPrint('   - No Asistidas: $noAsistidas');

    } catch (e) {
      debugPrint('❌ Error calculando métricas: $e');
      // Si hay error, usar valores por defecto
      resumenAgendadas = 0;
      resumenAsistidas = 0;
      resumenNoAsistidas = 0;
      clasesRestantes = 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Cargar últimos 3 pagos
  // ---------------------------------------------------------------------------
  Future<void> _cargarUltimosPagos(String userId) async {
    try {
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      ultimos3Pagos = paymentsSnapshot.docs.map((doc) {
        final data = doc.data();

        // Mostrar el estado del pago tal cual está en Firestore
        final paymentStatus = data['status'] ?? 'pending';

        String displayStatus;
        String statusColor;

        if (paymentStatus == 'approved') {
          displayStatus = 'Aprobado';
          statusColor = 'green';
        } else if (paymentStatus == 'rejected') {
          displayStatus = 'Rechazado';
          statusColor = 'red';
        } else {
          displayStatus = 'Pendiente';
          statusColor = 'orange';
        }

        return {
          'amount': data['amount'] ?? 0,
          'plan': data['plan'] ?? 'Sin plan',
          'status': displayStatus,
          'statusColor': statusColor,
        };
      }).toList();

      debugPrint('📊 Últimos 3 pagos cargados: ${ultimos3Pagos.length}');
    } catch (e) {
      debugPrint('❌ Error cargando últimos pagos: $e');
      ultimos3Pagos = [];
    }
  }

  // ---------------------------------------------------------------------------
  // Configurar listener para actualizaciones en tiempo real
  // ---------------------------------------------------------------------------
  void _setupBookingsListener(String userId, Map<String, dynamic> userData) {
    _bookingsSubscription = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      debugPrint('🔄 Bookings actualizadas - recalculando métricas...');
      _calcularMetricasSync(snapshot.docs, userData);
    });
  }

  // ---------------------------------------------------------------------------
  // Calcular métricas de forma sincrónica (para el listener)
  // ---------------------------------------------------------------------------
  void _calcularMetricasSync(List<QueryDocumentSnapshot> docs, Map<String, dynamic> userData) {
    try {
      final now = DateTime.now();
      int agendadas = 0;
      int asistidas = 0;
      int noAsistidas = 0;

      debugPrint('📊 Calculando clases restantes:');
      debugPrint('   - Total de bookings en DB: ${docs.length}');

      int clasesUsadas = 0;
      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'confirmed';
        final classDate = (data['classDate'] as Timestamp).toDate();
        final scheduleTime = data['scheduleTime'] ?? '00:00';
        final userConfirmedAttendance = data['userConfirmedAttendance'] ?? false;

        // Normalizar fecha para comparación
        final normalizedClassDate = DateTime(classDate.year, classDate.month, classDate.day);
        final today = DateTime(now.year, now.month, now.day);

        // Combinar fecha con hora para obtener el DateTime completo de la clase
        final timeParts = scheduleTime.split(':');
        final classDateTime = DateTime(
          classDate.year,
          classDate.month,
          classDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        // Ventana de confirmación: 30 min después de la clase
        final confirmationWindowEnd = classDateTime.add(const Duration(minutes: 30));
        final missedConfirmation = now.isAfter(confirmationWindowEnd);

        if (status == 'confirmed') {
          // Verificar si pasó la ventana de confirmación sin confirmar
          if (missedConfirmation && !userConfirmedAttendance) {
            noAsistidas++;
          } else if (normalizedClassDate.isAfter(today) || normalizedClassDate.isAtSameMomentAs(today)) {
            agendadas++;
          }
          clasesUsadas++;
        } else if (status == 'attended') {
          asistidas++;
          clasesUsadas++;
        } else if (status == 'noShow') {
          noAsistidas++;
          clasesUsadas++;
        }
      }

      resumenAgendadas = agendadas;
      resumenAsistidas = asistidas;
      resumenNoAsistidas = noAsistidas;

      final clasesTotales = userData['classesPerMonth'] ?? 999; // null = ilimitado
      clasesRestantes = clasesTotales - clasesUsadas;
      if (clasesRestantes! < 0) clasesRestantes = 0;

      debugPrint('📊 Métricas actualizadas:');
      debugPrint('   - Clases Totales (limit): $clasesTotales');
      debugPrint('   - Clases Usadas: $clasesUsadas');
      debugPrint('   - Clases Restantes: $clasesRestantes');
      debugPrint('   - Agendadas: $agendadas');
      debugPrint('   - Asistidas: $asistidas');
      debugPrint('   - No Asistidas: $noAsistidas');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error calculando métricas sync: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Recargar manual (ej: pull-to-refresh)
  // ---------------------------------------------------------------------------
  Future<void> reload() async {
    await _cargarDashboard();
  }
}
