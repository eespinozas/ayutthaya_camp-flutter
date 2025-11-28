import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import 'perfil_page.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../bookings/viewmodels/booking_viewmodel.dart';
import '../../../bookings/models/booking.dart';

// TODO: ajusta el import a la página real donde el alumno elige escuela/plan/sube comprobante
// import '../../seleccion_escuela/presentation/pages/seleccion_escuela_page.dart';

class DashboardPage extends StatelessWidget {
  final VoidCallback? onNavigateToPagos;

  const DashboardPage({
    super.key,
    this.onNavigateToPagos,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

    if (vm.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (vm.errorMsg != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: Center(
          child: Text(
            vm.errorMsg!,
            style: const TextStyle(color: Colors.redAccent),
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
    // Si no tienes esto aún en el viewmodel, créalo:
    // bool? estaActivo;
    final bool estaActivo = vm.estaActivo ?? false;

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
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        title: const Text(
          'Inicio',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              color: Colors.white70,
              size: 28,
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
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ================================
                      // BANNER DE ACTIVACIÓN DE CUENTA
                      // ================================
                      if (!estaActivo)
                        _AccountActivationCard(
                          onActivate: () {
                            // Navega al tab de Pagos para matricularse
                            onNavigateToPagos?.call();
                          },
                        ),

                      const SizedBox(height: 16),

                      // HEADER DEL PLAN
                      _PlanHeader(
                        planNombre: planNombre,
                        clasesRestantes: clasesRestantes,
                        vigenciaHasta: vigenciaHasta,
                      ),

                      const SizedBox(height: 24),

                      // RESUMEN CLASES (fila de 3)
                      _ResumenClasesRow(
                        agendadas: agendadas,
                        asistidas: asistidas,
                        noAsistidas: noAsistidas,
                      ),

                      const SizedBox(height: 24),

                      // MIS CLASES DE HOY
                      _TodayClassesSection(),

                      const SizedBox(height: 24),

                      // ÚLTIMOS 3 PAGOS
                      Builder(
                        builder: (context) {
                          debugPrint('🎨 Renderizando _Ultimos3PagosCard con ${ultimos3Pagos.length} pagos');
                          return _Ultimos3PagosCard(
                            pagos: ultimos3Pagos,
                            onVerTodos: () {
                              // Navega al tab de Pagos
                              onNavigateToPagos?.call();
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 48),
                    ],
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
// WIDGET: BANNER DE ACTIVACIÓN (CTA "Matricularme ahora")
// -----------------------------------------------------------------------------
class _AccountActivationCard extends StatelessWidget {
  final VoidCallback onActivate;

  const _AccountActivationCard({
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    // Paleta amarilla/alerta sobre fondo oscuro:
    final bg = Colors.amber.shade100;
    final border = Colors.amber.shade400;
    final iconColor = Colors.amber.shade800;
    final textColor = Colors.amber.shade900;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // fila icono + título
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_rounded, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tu cuenta no está activa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Para poder reservar clases y completar tu perfil, primero debes matricularte y subir tu comprobante de pago.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: textColor,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onActivate,
              child: const Text(
                'Matricularme ahora',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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
    final textColor = Colors.white;
    final subtle = Colors.white70;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        runSpacing: 16,
        spacing: 32,
        children: [
          _InfoChip(
            label: 'Plan',
            value: planNombre,
            icon: Icons.fitness_center,
            textColor: textColor,
            subtle: subtle,
          ),
          _InfoChip(
            label: 'Clases restantes',
            value: '$clasesRestantes',
            icon: Icons.confirmation_num_outlined,
            textColor: textColor,
            subtle: subtle,
          ),
          _InfoChip(
            label: 'Vigencia',
            value: vigenciaHasta,
            icon: Icons.schedule,
            textColor: textColor,
            subtle: subtle,
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
  final Color textColor;
  final Color subtle;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.textColor,
    required this.subtle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade800,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: subtle,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$valor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Últimos Pagos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: onVerTodos,
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
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
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        pago['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PLACEHOLDER TEMPORAL PARA LA PANTALLA DE MATRÍCULA
// (para que compile hasta que metas tu flujo real)
// -----------------------------------------------------------------------------
class _MatriculaPlaceholderPage extends StatelessWidget {
  const _MatriculaPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        title: const Text('Activar membresía'),
      ),
      body: const Center(
        child: Text(
          'Seleccionar escuela / plan / subir comprobante',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET: MIS CLASES DE HOY
// -----------------------------------------------------------------------------
class _TodayClassesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final bookingVM = context.watch<BookingViewModel>();
    final userId = authVM.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Icon(
                      Icons.event_busy,
                      size: 48,
                      color: Colors.white24,
                    ),
                    SizedBox(height: 12),
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
              );
            }

            return Column(
              children: todayBookings.map((booking) {
                return _TodayClassCard(
                  booking: booking,
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

  const _TodayClassCard({
    required this.booking,
    required this.onConfirm,
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
    if (booking.userConfirmedAttendance) return Colors.green;
    if (booking.canConfirmAttendance()) return Colors.orange;
    if (booking.missedConfirmationWindow()) return Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (booking.userConfirmedAttendance) return Icons.check_circle;
    if (booking.canConfirmAttendance()) return Icons.schedule;
    if (booking.missedConfirmationWindow()) return Icons.cancel;
    return Icons.event;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final canConfirm = booking.canConfirmAttendance();
    final confirmed = booking.userConfirmedAttendance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
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
                  color: Colors.orangeAccent.withOpacity(0.2),
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
                  booking.getConfirmationStatusText(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (canConfirm && !confirmed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check, size: 20),
                label: const Text(
                  'Confirmar Asistencia',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
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
