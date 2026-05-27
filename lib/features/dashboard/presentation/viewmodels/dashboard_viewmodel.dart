import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  // Snapshot del último userData y bookings vistos por los listeners. Ambos
  // listeners (user doc y bookings) recalculan métricas usando estos
  // snapshots compartidos: si solo cambia el user doc (ej: admin aprueba un
  // pago y aparece classesPerMonth), reusamos los bookings; si solo cambian
  // los bookings, reusamos el último userData.
  Map<String, dynamic>? _lastUserData;
  List<QueryDocumentSnapshot>? _lastBookingsDocs;

  // uid del usuario actualmente cargado. Si cambia (logout o login con otra
  // cuenta), reseteamos el estado y recargamos. Sin esto, el ViewModel —que
  // vive todo el ciclo de la app vía MultiProvider— se quedaba con los datos
  // del usuario anterior y un listener de bookings apuntando a su uid viejo,
  // así que al loguearse otra persona veía la membresía y las clases del
  // primero.
  String? _currentUid;

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
    // En vez de llamar _cargarDashboard() directo, escuchamos authStateChanges.
    // authStateChanges emite el estado actual al suscribirse, así que cubre
    // tanto el primer arranque como cualquier cambio posterior (login,
    // logout, cambio de cuenta).
    _authSubscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  void _onAuthChanged(User? user) {
    final newUid = user?.uid;
    if (newUid == _currentUid) return;

    debugPrint('🔁 DashboardViewModel: usuario cambió ($_currentUid → $newUid)');
    _currentUid = newUid;
    _resetState();

    if (newUid != null) {
      _cargarDashboard();
    } else {
      loading = false;
      notifyListeners();
    }
  }

  /// Limpia todo el estado por-usuario. Se llama cuando cambia el uid para
  /// evitar mostrar datos del usuario anterior mientras carga el nuevo.
  void _resetState() {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = null;
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    _lastUserData = null;
    _lastBookingsDocs = null;

    planNombre = null;
    clasesRestantes = null;
    vigenciaHastaStr = null;
    resumenAgendadas = null;
    resumenAsistidas = null;
    resumenNoAsistidas = null;
    ultimos3Pagos = [];
    membershipStatus = null;
    expirationDate = null;
    errorMsg = null;
    loading = true;
    notifyListeners();
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

      // Si el plan ya venció y todavía figura como active, actualizar a
      // inactive. Lo hacemos antes de pintar para que el listener del user
      // doc, configurado abajo, reciba el nuevo estado y no muestre "Activa"
      // por un instante.
      if (userData['expirationDate'] != null) {
        final expirationDateTime = (userData['expirationDate'] as Timestamp).toDate();
        final currentStatus = userData['membershipStatus'] ?? 'none';
        if (DateTime.now().isAfter(expirationDateTime) && currentStatus == 'active') {
          debugPrint('⚠️ Plan vencido — marcando inactive');
          await _firestore.collection('users').doc(user.uid).update({
            'membershipStatus': 'inactive',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          userData['membershipStatus'] = 'inactive';
        }
      }

      _applyUserData(userData);

      // Leer las bookings del usuario para calcular métricas (primera vez)
      await _calcularMetricas(user.uid, userData);

      // Leer últimos 3 pagos
      await _cargarUltimosPagos(user.uid);

      // Listeners en tiempo real: bookings (clases) y user doc (membresía,
      // plan, classesPerMonth). El listener del user doc es lo que permite
      // que el dashboard se actualice automáticamente cuando un admin
      // aprueba un pago, sin que el usuario tenga que pull-to-refresh.
      _setupBookingsListener(user.uid);
      _setupUserDocListener(user.uid);

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

      // Calcular clases restantes.
      // Si classesPerMonth está seteado -> plan limitado, calculamos restantes.
      // Si es null -> plan ilimitado o sin plan; dejamos clasesRestantes en
      // null y la UI lo muestra como ∞ (con plan) o "—" (sin plan). Antes
      // se defaulteaba a 999 y se restaban las usadas, dando "998" en pantalla.
      final classesPerMonthRaw = userData['classesPerMonth'];

      debugPrint('📊 Calculando clases restantes:');
      debugPrint('   - classesPerMonth en doc: $classesPerMonthRaw');
      debugPrint('   - Total de bookings en DB: ${bookingsSnapshot.docs.length}');

      int clasesUsadas = 0;
      for (var doc in bookingsSnapshot.docs) {
        final status = doc.data()['status'];
        debugPrint('   - Booking: status=$status');
        if (status == 'confirmed' || status == 'attended' || status == 'noShow') {
          clasesUsadas++;
        }
      }

      if (classesPerMonthRaw is int) {
        final remaining = classesPerMonthRaw - clasesUsadas;
        clasesRestantes = remaining < 0 ? 0 : remaining;
      } else {
        clasesRestantes = null; // null = ilimitado / sin plan
      }

      debugPrint('📊 Métricas calculadas:');
      debugPrint('   - Clases Totales (limit): ${classesPerMonthRaw ?? "ilimitado"}');
      debugPrint('   - Clases Usadas: $clasesUsadas');
      debugPrint('   - Clases Restantes: ${clasesRestantes ?? "∞"}');
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
  // Listeners en tiempo real
  // ---------------------------------------------------------------------------

  /// Extrae los campos de presentación del user doc y los publica. No toca
  /// los listeners — sólo actualiza estado y recalcula métricas si ya hay
  /// bookings cacheados.
  void _applyUserData(Map<String, dynamic> userData) {
    _lastUserData = userData;

    membershipStatus = userData['membershipStatus'] ?? 'none';

    if (userData['expirationDate'] != null) {
      expirationDate = (userData['expirationDate'] as Timestamp).toDate();
      vigenciaHastaStr =
          '${expirationDate!.day}/${expirationDate!.month}/${expirationDate!.year}';
    } else {
      expirationDate = null;
      vigenciaHastaStr = '—';
    }

    // planDisplayName es el snapshot que setea PaymentService al aprobar una
    // mensualidad. planName es el fallback para usuarios viejos. Si no hay
    // ninguno (típico tras pagar sólo matrícula), dejamos null y la UI
    // pinta "Sin plan".
    planNombre = (userData['planDisplayName'] as String?) ??
        (userData['planName'] as String?);

    final docs = _lastBookingsDocs;
    if (docs != null) {
      _calcularMetricasSync(docs, userData);
    } else {
      notifyListeners();
    }
  }

  void _setupBookingsListener(String userId) {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      debugPrint('🔄 Bookings actualizadas (${snapshot.docs.length}) — recalculando');
      _lastBookingsDocs = snapshot.docs;
      final userData = _lastUserData;
      if (userData != null) {
        _calcularMetricasSync(snapshot.docs, userData);
      }
    });
  }

  /// Escucha cambios del documento del usuario. Se dispara cuando un admin
  /// aprueba un pago (cambian membershipStatus, planName, classesPerMonth,
  /// expirationDate), permitiendo que el dashboard refleje el nuevo plan
  /// sin pull-to-refresh ni re-login. También refresca los últimos pagos
  /// para que el chip "Pendiente → Aprobado" se actualice junto con todo
  /// lo demás.
  void _setupUserDocListener(String userId) {
    _userDocSubscription?.cancel();
    _userDocSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      debugPrint('🔄 User doc actualizado — refrescando estado');
      _applyUserData(data);
      _cargarUltimosPagos(userId).then((_) => notifyListeners());
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

      // Mismo patrón que en _calcularMetricas: classesPerMonth null no debe
      // defaultearse a 999 (eso producía "998" en pantalla). Dejamos null
      // para que la UI lo interprete como ∞ (con plan) o "—" (sin plan).
      final classesPerMonthRaw = userData['classesPerMonth'];
      if (classesPerMonthRaw is int) {
        final remaining = classesPerMonthRaw - clasesUsadas;
        clasesRestantes = remaining < 0 ? 0 : remaining;
      } else {
        clasesRestantes = null;
      }

      debugPrint('📊 Métricas actualizadas:');
      debugPrint('   - Clases Totales (limit): ${classesPerMonthRaw ?? "ilimitado"}');
      debugPrint('   - Clases Usadas: $clasesUsadas');
      debugPrint('   - Clases Restantes: ${clasesRestantes ?? "∞"}');
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
