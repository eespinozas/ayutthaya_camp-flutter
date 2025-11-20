import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
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
  // Último pago
  // -------------------------
  num? ultimoPagoMonto;
  String? ultimoPagoPlan;
  String? ultimoPagoEstado;

  // -------------------------
  // Cargando / error
  // -------------------------
  bool loading = true;
  String? errorMsg;

  DashboardViewModel() {
    _cargarDashboard();
  }

  // ---------------------------------------------------------------------------
  // GETTER: ¿El usuario está ACTIVO?
  // ---------------------------------------------------------------------------
  bool get estaActivo {
    final tienePlan = (planNombre != null && planNombre != 'sin_plan');
    final pagoAprobado = (ultimoPagoEstado != null &&
        ultimoPagoEstado!.toLowerCase() == 'pagado');
    final clasesDisponibles = (clasesRestantes ?? 0) > 0;

    // Lógica simple para esta etapa.
    // Cuando conectes con Firestore/Backend, esto cambiará a:
    // return userData['estado'] == 'aprobado';
    return (tienePlan && pagoAprobado) || clasesDisponibles;
  }

  // ---------------------------------------------------------------------------
  // Carga inicial del Dashboard
  // ---------------------------------------------------------------------------
  Future<void> _cargarDashboard() async {
    try {
      loading = true;
      notifyListeners();

      // === SIMULACIÓN ===
      // (Esto lo reemplazaremos cuando conectemos con backend real)
      await Future.delayed(const Duration(milliseconds: 500));

      planNombre = 'sin_plan';
      clasesRestantes = 0;
      vigenciaHastaStr = '—';

      resumenAgendadas = 0;
      resumenAsistidas = 0;
      resumenNoAsistidas = 0;

      ultimoPagoMonto = 0;
      ultimoPagoPlan = 'sin_plan';
      ultimoPagoEstado = '—';

      loading = false;
      errorMsg = null;
      notifyListeners();

    } catch (e) {
      loading = false;
      errorMsg = 'No se pudo cargar el dashboard';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Recargar manual (ej: pull-to-refresh)
  // ---------------------------------------------------------------------------
  Future<void> reload() async {
    await _cargarDashboard();
  }
}
