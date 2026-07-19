import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/services/attendance_window.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import 'perfil_page.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../bookings/viewmodels/booking_viewmodel.dart';
import '../../../bookings/models/booking.dart';
import '../../../schedules/viewmodels/class_schedule_viewmodel.dart';
import '../../../../core/services/chilean_holidays.dart';

// TODO: ajusta el import a la página real donde el alumno elige escuela/plan/sube comprobante
// import '../../seleccion_escuela/presentation/pages/seleccion_escuela_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToPagos;

  const DashboardPage({
    super.key,
    this.onNavigateToPagos,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isRefreshing = false;

  // Horarios de las clases de hoy: permiten saber si una reserva es de la
  // primera clase del día (dura 60 min) o de las demás (90 min), lo que
  // define la ventana del botón "Confirmar Asistencia".
  List<String> _horariosHoy = const [];

  @override
  void initState() {
    super.initState();
    _loadHorariosHoy();
  }

  Future<void> _loadHorariosHoy() async {
    try {
      final schedules = await context
          .read<ClassScheduleViewModel>()
          .getSchedulesForDay(ChileanHolidays.effectiveDayOfWeek(DateTime.now()))
          .first;
      if (mounted) {
        setState(() {
          _horariosHoy = schedules.map((s) => s.time).toList();
        });
      }
    } catch (e) {
      debugPrint('No se pudieron cargar los horarios de hoy: $e');
    }
  }

  /// Función para actualizar el dashboard
  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    final vm = context.read<DashboardViewModel>();
    await vm.reload();

    setState(() => _isRefreshing = false);

    // Mostrar mensaje de actualización
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Dashboard actualizado'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

    if (vm.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6A00),
          ),
        ),
      );
    }

    if (vm.errorMsg != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Text(
            vm.errorMsg!,
            style: const TextStyle(color: Color(0xFFEF4444)),
          ),
        ),
      );
    }

    // Datos del alumno / plan
    final planNombre = vm.planNombre ?? 'sin_plan';
    final clasesRestantes = vm.clasesRestantes ?? 0;
    final vigenciaHasta = vm.vigenciaHastaStr ?? '–';

    final agendadas = vm.resumenAgendadas ?? 0;
    final asistidas = vm.resumenAsistidas ?? 0;
    final noAsistidas = vm.resumenNoAsistidas ?? 0;

    final ultimos3Pagos = vm.ultimos3Pagos;

    // Estado de activación del alumno
    final bool estaActivo = vm.estaActivo;

    // Debug logs
    debugPrint('📊 DASHBOARD - Estado actual:');
    debugPrint('   membershipStatus: ${vm.membershipStatus}');
    debugPrint('   estaActivo: $estaActivo');
    debugPrint('   expirationDate: ${vm.expirationDate}');
    debugPrint('   ultimos3Pagos count: ${ultimos3Pagos.length}');
    if (ultimos3Pagos.isNotEmpty) {
      debugPrint('   Primer pago: ${ultimos3Pagos[0]}');
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFFF8534)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.fitness_center, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            // Flexible + ellipsis evita que el texto del título se solape
            // con el chip de membresía y el icono de perfil cuando el ancho
            // de la AppBar no alcanza para ambos (iPhone SE / mini).
            const Flexible(
              child: Text(
                'AYUTTHAYA CAMP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Indicador de actualización
          if (_isRefreshing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFFFF6A00),
                ),
              ),
            ),
          // Indicador de estado de membresía (oculto en Fase 1 de acceso libre)
          if (!AppFlags.freeAccessPhase) ...[
            _MembershipStatusChip(
              estaActivo: estaActivo,
              membershipStatus: vm.membershipStatus,
              onTap: () {
                widget.onNavigateToPagos?.call();
              },
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PerfilPage(),
                ),
              );
            },
            tooltip: 'Mi Perfil',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return RefreshIndicator(
              onRefresh: _refreshData,
              color: const Color(0xFFFF6A00),
              backgroundColor: const Color(0xFF1A1A1A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ================================
                      // BANNER DE ACTIVACIÓN DE CUENTA
                      // (oculto en Fase 1 de acceso libre)
                      // ================================
                      if (!AppFlags.freeAccessPhase && !estaActivo)
                        _AccountActivationCard(
                          onActivate: () {
                            // Navega al tab de Pagos para matricularse
                            widget.onNavigateToPagos?.call();
                          },
                        ),

                      // HEADER DEL PLAN (oculto en Fase 1 de acceso libre)
                      if (!AppFlags.freeAccessPhase) ...[
                        const SizedBox(height: 16),
                        _PlanHeader(
                          planNombre: planNombre,
                          clasesRestantes: clasesRestantes,
                          vigenciaHasta: vigenciaHasta,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // RESUMEN CLASES (fila de 3)
                      _ResumenClasesRow(
                        agendadas: agendadas,
                        asistidas: asistidas,
                        noAsistidas: noAsistidas,
                      ),

                      const SizedBox(height: 24),

                      // MIS CLASES DE HOY
                      _TodayClassesSection(horariosHoy: _horariosHoy),

                      const SizedBox(height: 24),

                      // ÚLTIMOS 3 PAGOS (oculto en Fase 1 de acceso libre)
                      if (!AppFlags.freeAccessPhase)
                        Builder(
                          builder: (context) {
                            debugPrint('🎨 Renderizando _Ultimos3PagosCard con ${ultimos3Pagos.length} pagos');
                            return _Ultimos3PagosCard(
                              pagos: ultimos3Pagos,
                              onVerTodos: () {
                                // Navega al tab de Pagos
                                widget.onNavigateToPagos?.call();
                              },
                            );
                          },
                        ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET: CHIP DE ESTADO DE MEMBRESÍA (EN EL APPBAR)
// -----------------------------------------------------------------------------
class _MembershipStatusChip extends StatelessWidget {
  final bool estaActivo;
  final String? membershipStatus;
  final VoidCallback onTap;

  const _MembershipStatusChip({
    required this.estaActivo,
    required this.membershipStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar color, icono y texto basado en el estado
    Color bgColor;
    Color textColor;
    IconData icon;
    String statusText;

    if (estaActivo) {
      bgColor = Colors.green.withValues(alpha: 0.2);
      textColor = Colors.green;
      icon = Icons.check_circle;
      statusText = 'Membresía Activa';
    } else if (membershipStatus == 'expired') {
      bgColor = Colors.red.withValues(alpha: 0.2);
      textColor = Colors.red;
      icon = Icons.cancel;
      statusText = 'Vencida';
    } else if (membershipStatus == 'pending') {
      bgColor = Colors.orange.withValues(alpha: 0.2);
      textColor = Colors.orange;
      icon = Icons.pending;
      statusText = 'Pendiente';
    } else {
      bgColor = Colors.grey.withValues(alpha: 0.2);
      textColor = Colors.grey;
      icon = Icons.info_outline;
      statusText = 'Sin plan';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: textColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: textColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET: BANNER DE ACTIVACIÓN (CTA "Matricularme ahora")
// -----------------------------------------------------------------------------
class _AccountActivationCard extends StatelessWidget {
  final VoidCallback onActivate;

  const _AccountActivationCard({
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6A00).withValues(alpha: 0.25),
            const Color(0xFFFF8534).withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6A00),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6A00), Color(0xFFFF8534)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activa tu Membresía',
                      style: TextStyle(
                        color: Color(0xFFFF6A00),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Completa tu matrícula para empezar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: const Color(0xFFFF6A00).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onActivate,
              child: const Text(
                'MATRICULARME AHORA',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGETS TUSYA (PlanHeader, InfoChip, etc) SIN CAMBIOS VISUALES
// -----------------------------------------------------------------------------

class _PlanHeader extends StatelessWidget {
  final String planNombre;
  final int clasesRestantes;
  final String vigenciaHasta;

  const _PlanHeader({
    required this.planNombre,
    required this.clasesRestantes,
    required this.vigenciaHasta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF1A1A1A).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6A00).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(
            label: 'Plan',
            value: planNombre,
            icon: Icons.fitness_center,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _InfoChip(
            label: 'Clases',
            value: '$clasesRestantes',
            icon: Icons.confirmation_num_outlined,
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _InfoChip(
            label: 'Vigencia',
            value: vigenciaHasta,
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6A00).withValues(alpha: 0.25),
                const Color(0xFFFF8534).withValues(alpha: 0.15),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6A00).withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFFFF6A00), size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// tarjetas métricas
class _ResumenClasesRow extends StatelessWidget {
  final int agendadas;
  final int asistidas;
  final int noAsistidas;

  const _ResumenClasesRow({
    required this.agendadas,
    required this.asistidas,
    required this.noAsistidas,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ResumenBox(
            label: 'Agendadas',
            valor: agendadas,
            background: Colors.amber.shade700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ResumenBox(
            label: 'Asistidas',
            valor: asistidas,
            background: Colors.green.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ResumenBox(
            label: 'No Asistidas',
            valor: noAsistidas,
            background: Colors.red.shade600,
          ),
        ),
      ],
    );
  }
}

class _ResumenBox extends StatelessWidget {
  final String label;
  final int valor;
  final Color background;

  const _ResumenBox({
    required this.label,
    required this.valor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    // Definir gradientes según el color
    List<Color> gradientColors;
    IconData icon;

    // Comparación exacta: 'No Asistidas' también contiene 'Asistidas',
    // por lo que un contains() la pintaría de verde.
    if (label == 'Agendadas') {
      gradientColors = [const Color(0xFFFBBF24), const Color(0xFFF59E0B)];
      icon = Icons.event_available;
    } else if (label == 'Asistidas') {
      gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
      icon = Icons.check_circle;
    } else {
      gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 10),
          Text(
            '$valor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// últimos 3 pagos
class _Ultimos3PagosCard extends StatelessWidget {
  final List<Map<String, dynamic>> pagos;
  final VoidCallback onVerTodos;

  const _Ultimos3PagosCard({
    required this.pagos,
    required this.onVerTodos,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 _Ultimos3PagosCard.build - pagos.length: ${pagos.length}');
    if (pagos.isNotEmpty) {
      debugPrint('   Pagos: $pagos');
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments, color: Color(0xFFFF6A00), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Últimos Pagos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onVerTodos,
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    color: Color(0xFFFF6A00),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pagos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No hay pagos registrados',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...pagos.map((pago) {
              debugPrint('   🎨 Renderizando pago individual: $pago');
              final statusColor = pago['statusColor'] == 'green'
                  ? Colors.green
                  : pago['statusColor'] == 'orange'
                      ? Colors.orange
                      : Colors.red;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pago['plan'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${pago['amount']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        pago['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PLACEHOLDER TEMPORAL PARA LA PANTALLA DE MATRÍCULA
// (para que compile hasta que metas tu flujo real)
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// WIDGET: MIS CLASES DE HOY
// -----------------------------------------------------------------------------
class _TodayClassesSection extends StatelessWidget {
  /// Horarios de hoy, para saber si cada reserva es de la primera clase
  /// del día (define la duración de la ventana de confirmación).
  final List<String> horariosHoy;

  const _TodayClassesSection({this.horariosHoy = const []});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final bookingVM = context.watch<BookingViewModel>();
    final userId = authVM.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.today,
              color: Colors.orangeAccent,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Mis Clases de Hoy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Booking>>(
          stream: bookingVM.getUserBookings(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    color: Colors.orangeAccent,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final allBookings = snapshot.data ?? [];

            // Filtrar clases de hoy
            final todayBookings = allBookings.where((booking) {
              return booking.isToday() &&
                     (booking.status == BookingStatus.confirmed ||
                      booking.userConfirmedAttendance);
            }).toList();

            // Ordenar por hora
            todayBookings.sort((a, b) => a.scheduleTime.compareTo(b.scheduleTime));

            if (todayBookings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.white24,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No tienes clases agendadas para hoy',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: todayBookings.map((booking) {
                return _TodayClassCard(
                  booking: booking,
                  esPrimeraClaseDelDia: AttendanceWindow.esPrimeraClaseDelDia(
                    booking.scheduleTime,
                    horariosHoy,
                  ),
                  onConfirm: () async {
                    final success = await bookingVM.confirmAttendance(booking.id!);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Asistencia confirmada'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET: TARJETA DE CLASE DEL DÍA
// -----------------------------------------------------------------------------
class _TodayClassCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onConfirm;
  final bool esPrimeraClaseDelDia;

  const _TodayClassCard({
    required this.booking,
    required this.onConfirm,
    this.esPrimeraClaseDelDia = false,
  });

  String _formatTime(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];

    if (hour < 12) {
      return hour == 0 ? '12:$minute AM' : '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }

  Color _getStatusColor() {
    if (booking.status == BookingStatus.pendingApproval) return Colors.amber;
    if (booking.status == BookingStatus.rejected) return Colors.red;
    if (booking.userConfirmedAttendance) return Colors.green;
    if (booking.canConfirmAttendance(esPrimeraClaseDelDia: esPrimeraClaseDelDia)) {
      return Colors.orange;
    }
    if (booking.missedConfirmationWindow(esPrimeraClaseDelDia: esPrimeraClaseDelDia)) {
      return Colors.red;
    }
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (booking.status == BookingStatus.pendingApproval) {
      return Icons.hourglass_top;
    }
    if (booking.status == BookingStatus.rejected) return Icons.block;
    if (booking.userConfirmedAttendance) return Icons.check_circle;
    if (booking.canConfirmAttendance(esPrimeraClaseDelDia: esPrimeraClaseDelDia)) {
      return Icons.schedule;
    }
    if (booking.missedConfirmationWindow(esPrimeraClaseDelDia: esPrimeraClaseDelDia)) {
      return Icons.cancel;
    }
    return Icons.event;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final canConfirm =
        booking.canConfirmAttendance(esPrimeraClaseDelDia: esPrimeraClaseDelDia);
    final confirmed = booking.userConfirmedAttendance;
    // Clase de hoy aún sin abrir su ventana: botón visible pero deshabilitado
    // indicando desde cuándo se puede confirmar.
    final preVentana = !confirmed &&
        booking.status == BookingStatus.confirmed &&
        !canConfirm &&
        !booking.missedConfirmationWindow(
          esPrimeraClaseDelDia: esPrimeraClaseDelDia,
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatTime(booking.scheduleTime),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.scheduleType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.instructor,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                _getStatusIcon(),
                color: statusColor,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.getConfirmationStatusText(
                    esPrimeraClaseDelDia: esPrimeraClaseDelDia,
                  ),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if ((canConfirm || preVentana) && !confirmed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canConfirm ? onConfirm : null,
                icon: Icon(canConfirm ? Icons.check : Icons.lock_clock, size: 20),
                label: Text(
                  canConfirm
                      ? 'Confirmar Asistencia'
                      : 'Disponible desde las ${_formatTime('${booking.confirmationOpensAt().hour.toString().padLeft(2, '0')}:${booking.confirmationOpensAt().minute.toString().padLeft(2, '0')}')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
