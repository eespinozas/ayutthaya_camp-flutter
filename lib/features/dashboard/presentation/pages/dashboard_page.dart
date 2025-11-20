import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';

// TODO: ajusta el import a la página real donde el alumno elige escuela/plan/sube comprobante
// import '../../seleccion_escuela/presentation/pages/seleccion_escuela_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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

    final ultimoPagoMonto = vm.ultimoPagoMonto ?? 0;
    final ultimoPagoPlan = vm.ultimoPagoPlan ?? 'sin_plan';
    final ultimoPagoEstado = vm.ultimoPagoEstado ?? '–';

    // Estado de activación del alumno
    // Si no tienes esto aún en el viewmodel, créalo:
    // bool? estaActivo;
    final bool estaActivo = vm.estaActivo ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
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
                            // Navega al flujo de matriculación / selección escuela / pago
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) {
                                  // Reemplaza esto por tu pantalla real
                                  // return const SeleccionEscuelaPage();
                                  return const _MatriculaPlaceholderPage();
                                },
                              ),
                            );
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

                      // ÚLTIMO PAGO / RESUMEN PAGOS (tarjeta pequeña)
                      _UltimoPagoCard(
                        monto: ultimoPagoMonto,
                        plan: ultimoPagoPlan,
                        estado: ultimoPagoEstado,
                        onVerTodos: () {
                          // acá luego vas a disparar ir a la pestaña Pagos del BottomNav
                          // por ahora sólo un print o un TODO
                          // print('Ver todos los pagos');
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

// último pago
class _UltimoPagoCard extends StatelessWidget {
  final num monto;
  final String plan;
  final String estado;
  final VoidCallback onVerTodos;

  const _UltimoPagoCard({
    required this.monto,
    required this.plan,
    required this.estado,
    required this.onVerTodos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // esta card se ve como "último pago / estado actual", no ocupa toda la pantalla
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row: monto + ver todos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$$monto',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: onVerTodos,
                child: const Text(
                  'Ver todos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Plan: $plan',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Estado: $estado',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
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
