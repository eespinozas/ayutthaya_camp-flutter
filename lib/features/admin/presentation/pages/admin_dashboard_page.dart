import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';
import 'admin_qr_codes_page.dart';

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
        backgroundColor: const Color(0xFF0F0F0F),
        body: const Center(
          child: CircularProgressIndicator(
            color: const Color(0xFFFF6A00),
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
              backgroundColor: const Color(0xFF0F0F0F),
              body: const Center(
                child: CircularProgressIndicator(color: const Color(0xFFFF6A00)),
              ),
            );
          }

          if (viewModel.errorMsg != null) {
            return Scaffold(
              backgroundColor: const Color(0xFF0F0F0F),
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
            backgroundColor: const Color(0xFF0F0F0F),
            body: RefreshIndicator(
              onRefresh: viewModel.reload,
              color: const Color(0xFFFF6A00),
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header with Welcome Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6A00), Color(0xFFFF8534)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.dashboard_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Dashboard Admin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$dayName, $dateStr',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildHeaderIconButton(
                        icon: Icons.qr_code_2,
                        tooltip: 'Códigos QR',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AdminQRCodesPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderIconButton(
                        icon: Icons.notifications_outlined,
                        tooltip: 'Notificaciones',
                        badge: alertas.isNotEmpty ? '${alertas.length}' : null,
                        onPressed: () {
                          // TODO: Implementar notificaciones
                        },
                      ),
                    ],
                  ),
                ],
              ),
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
                _buildEnhancedKPICard(
                  label: 'Asistencias Hoy',
                  value: '${todayStats['totalAsistencias']}',
                  subtitle: '/${todayStats['capacidadTotalHoy']} capacidad',
                  icon: Icons.people_rounded,
                  gradientColors: const [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  percentage: (todayStats['capacidadTotalHoy'] as int?) != null && (todayStats['capacidadTotalHoy'] as int) > 0
                    ? (todayStats['totalAsistencias'] as int) / (todayStats['capacidadTotalHoy'] as int)
                    : 0.0,
                ),
                _buildEnhancedKPICard(
                  label: 'Clases Hoy',
                  value: '${todayStats['clasesCompletadas']}',
                  subtitle: '/${todayStats['clasesTotales']} total',
                  icon: Icons.fitness_center,
                  gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                  percentage: (todayStats['clasesTotales'] as int?) != null && (todayStats['clasesTotales'] as int) > 0
                    ? (todayStats['clasesCompletadas'] as int) / (todayStats['clasesTotales'] as int)
                    : 0.0,
                ),
                _buildEnhancedKPICard(
                  label: 'Nuevos Alumnos',
                  value: '${todayStats['alumnosNuevos']}',
                  subtitle: 'hoy',
                  icon: Icons.person_add_rounded,
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  showTrend: true,
                  trendUp: (todayStats['alumnosNuevos'] as int?) != null && (todayStats['alumnosNuevos'] as int) > 0,
                ),
                _buildEnhancedKPICard(
                  label: 'Ingresos Hoy',
                  value: '\$${(todayStats['pagosRecibidos']! / 1000).toStringAsFixed(1)}K',
                  subtitle: 'total recibido',
                  icon: Icons.payments_rounded,
                  gradientColors: const [Color(0xFFFF6A00), Color(0xFFFF8534)],
                  showTrend: true,
                  trendUp: (todayStats['pagosRecibidos'] as int?) != null && (todayStats['pagosRecibidos'] as int) > 0,
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
                    color: const Color(0xFF1A1A1A),
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
              return _buildInteractiveAlert(
                icon: alerta['icon'] as IconData,
                text: alerta['text'] as String,
                count: alerta['count'] as int,
                onTap: () {
                  // TODO: Navegar a la sección correspondiente
                },
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

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    String? badge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 24),
            tooltip: tooltip,
          ),
        ),
        if (badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF6A00), width: 2),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedKPICard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    double? percentage,
    bool showTrend = false,
    bool trendUp = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (showTrend)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        trendUp ? Icons.trending_up : Icons.trending_flat,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trendUp ? '+' : '~',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (percentage != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveAlert({
    required IconData icon,
    required String text,
    required int count,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6A00), Color(0xFFFF8534)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca para revisar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6A00).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFFF6A00),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
