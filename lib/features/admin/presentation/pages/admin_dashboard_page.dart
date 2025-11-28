import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es_ES', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.orangeAccent,
          ),
        ),
      );
    }

    final now = DateTime.now();
    final dayName = DateFormat('EEEE', 'es_ES').format(now);
    final dateStr = DateFormat('dd MMM yyyy', 'es_ES').format(now);

    return ChangeNotifierProvider(
      create: (_) => AdminDashboardViewModel(),
      child: Consumer<AdminDashboardViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.loading) {
            return Scaffold(
              backgroundColor: const Color(0xFF1E1E1E),
              body: const Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent),
              ),
            );
          }

          if (viewModel.errorMsg != null) {
            return Scaffold(
              backgroundColor: const Color(0xFF1E1E1E),
              body: Center(
                child: Text(
                  'Error: ${viewModel.errorMsg}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // Preparar datos para la UI
          final todayStats = {
            'totalAsistencias': viewModel.totalAsistencias,
            'clasesCompletadas': viewModel.clasesCompletadas,
            'clasesTotales': viewModel.clasesTotales,
            'alumnosNuevos': viewModel.alumnosNuevos,
            'pagosRecibidos': viewModel.pagosRecibidos,
            'capacidadTotalHoy': viewModel.capacidadTotalHoy,
          };

          // Convertir scheduleStats a lista para la UI
          final clasesToday = viewModel.scheduleStats.entries.map((e) {
            final stats = e.value;
            return {
              'time': stats['time'] ?? '',
              'enrolled': stats['enrolled'] ?? 0,
              'capacity': stats['capacity'] ?? 15,
              'attended': stats['attended'] ?? 0,
            };
          }).toList();

          // Ordenar por hora
          clasesToday.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));

          // Preparar alertas
          final alertas = <Map<String, dynamic>>[];
          if (viewModel.pendingPayments > 0) {
            alertas.add({
              'icon': Icons.payments,
              'text': '${viewModel.pendingPayments} pagos pendientes de aprobación',
              'count': viewModel.pendingPayments,
            });
          }
          if (viewModel.pendingUsers > 0) {
            alertas.add({
              'icon': Icons.person_add,
              'text': '${viewModel.pendingUsers} alumnos nuevos por aprobar',
              'count': viewModel.pendingUsers,
            });
          }
          if (viewModel.expiringMemberships > 0) {
            alertas.add({
              'icon': Icons.warning_amber,
              'text': '${viewModel.expiringMemberships} membresías vencen en 3 días',
              'count': viewModel.expiringMemberships,
            });
          }

          return Scaffold(
            backgroundColor: const Color(0xFF1E1E1E),
            body: RefreshIndicator(
              onRefresh: viewModel.reload,
              color: Colors.orangeAccent,
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dayName, $dateStr',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Implementar notificaciones
                  },
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Resumen del día - KPIs
            const Text(
              'Resumen del Día',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildKPICard(
                  label: 'Total Asistencias',
                  value: '${todayStats['totalAsistencias']}/${todayStats['capacidadTotalHoy']}',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _buildKPICard(
                  label: 'Clases',
                  value: '${todayStats['clasesCompletadas']}/${todayStats['clasesTotales']}',
                  icon: Icons.fitness_center,
                  color: Colors.green,
                ),
                _buildKPICard(
                  label: 'Nuevos Alumnos',
                  value: '${todayStats['alumnosNuevos']}',
                  icon: Icons.person_add,
                  color: Colors.purple,
                ),
                _buildKPICard(
                  label: 'Pagos Recibidos',
                  value: '\$${todayStats['pagosRecibidos']! ~/ 1000}K',
                  icon: Icons.attach_money,
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Asistencia por Clase
            const Text(
              'Asistencia por Clase (Hoy)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Builder(
              builder: (context) {
                // Calcular totales agregados
                final totalCapacity = todayStats['capacidadTotalHoy'] as int;
                final totalAttended = todayStats['totalAsistencias'] as int;

                final percentage = totalCapacity > 0 ? totalAttended / totalCapacity : 0.0;
                final isFull = totalAttended >= totalCapacity;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total del Día',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '$totalAttended/$totalCapacity',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isFull) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 12,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFull
                                ? Colors.red
                                : percentage > 0.7
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(percentage * 100).toInt()}% de ocupación',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Alertas Importantes
            Row(
              children: [
                const Text(
                  'Alertas Importantes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${alertas.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...alertas.map((alerta) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        alerta['icon'] as IconData,
                        color: Colors.orangeAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        alerta['text'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 24),
          ],
        ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPICard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
