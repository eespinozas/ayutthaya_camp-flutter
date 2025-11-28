import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_reportes_viewmodel.dart';

class AdminReportesPage extends StatefulWidget {
  const AdminReportesPage({super.key});

  @override
  State<AdminReportesPage> createState() => _AdminReportesPageState();
}

class _AdminReportesPageState extends State<AdminReportesPage>
    with SingleTickerProviderStateMixin {
  bool _localeInitialized = false;
  late TabController _tabController;
  late AdminReportesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _viewModel = AdminReportesViewModel();
    _initializeLocale();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
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

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Reportes y Analytics',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.orangeAccent,
            labelColor: Colors.orangeAccent,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Diario'),
              Tab(text: 'Semanal'),
              Tab(text: 'Mensual'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            _DailyReportTab(),
            _WeeklyReportTab(),
            _MonthlyReportTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB: REPORTE DIARIO
// ============================================================================
class _DailyReportTab extends StatefulWidget {
  const _DailyReportTab();

  @override
  State<_DailyReportTab> createState() => _DailyReportTabState();
}

class _DailyReportTabState extends State<_DailyReportTab> {
  DateTime _selectedDate = DateTime.now();

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AdminReportesViewModel>(context, listen: false);
    final dayName = DateFormat('EEEE', 'es_ES').format(_selectedDate);
    final dateStr = DateFormat('dd MMM yyyy', 'es_ES').format(_selectedDate);
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return StreamBuilder<Map<String, dynamic>>(
      stream: viewModel.getDailyReport(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error cargando reporte: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data ?? {
          'totalAsistencias': 0,
          'clasesCompletadas': 0,
          'clasesTotales': 0,
          'alumnosNuevos': 0,
          'pagosRecibidos': 0,
          'tasaAsistencia': 0,
          'clases': [],
        };

        return SingleChildScrollView(
      child: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF3A3A3A),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeDate(-1),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            dayName[0].toUpperCase() + dayName.substring(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeDate(1),
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ],
                ),
                if (!isToday) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _goToToday,
                    icon: const Icon(Icons.today, size: 18),
                    label: const Text('Ir a Hoy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                      side: const BorderSide(color: Colors.orangeAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPIs principales
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
                      value: '${data['totalAsistencias']}',
                      icon: Icons.people,
                      color: Colors.blue,
                      subtitle: '${data['tasaAsistencia']}% ocupación',
                    ),
                    _buildKPICard(
                      label: 'Clases',
                      value: '${data['clasesCompletadas']}/${data['clasesTotales']}',
                      icon: Icons.fitness_center,
                      color: Colors.green,
                      subtitle: 'Completadas',
                    ),
                    _buildKPICard(
                      label: 'Nuevos Alumnos',
                      value: '${data['alumnosNuevos']}',
                      icon: Icons.person_add,
                      color: Colors.purple,
                      subtitle: 'Registros',
                    ),
                    _buildKPICard(
                      label: 'Ingresos',
                      value: '\$${(data['pagosRecibidos'] / 1000).toInt()}K',
                      icon: Icons.attach_money,
                      color: Colors.orange,
                      subtitle: 'CLP',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Asistencia por clase
                const Text(
                  'Asistencia por Clase',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: (data['clases'] as List).map((clase) {
                      final inscritos = clase['inscritos'] as int;
                      final asistieron = clase['asistieron'] as int;
                      final capacidad = clase['capacidad'] as int;
                      final percentage = capacidad > 0 ? asistieron / capacidad : 0.0;
                      final ausencias = inscritos - asistieron;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    clase['hora'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$asistieron/$capacidad asistieron',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (ausencias > 0)
                                            Text(
                                              '$ausencias falta${ausencias > 1 ? 's' : ''}',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage,
                                          minHeight: 6,
                                          backgroundColor: Colors.white12,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            percentage >= 0.9
                                                ? Colors.green
                                                : percentage >= 0.7
                                                    ? Colors.orange
                                                    : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildKPICard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
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
            size: 24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB: REPORTE MENSUAL
// ============================================================================
class _MonthlyReportTab extends StatefulWidget {
  const _MonthlyReportTab();

  @override
  State<_MonthlyReportTab> createState() => _MonthlyReportTabState();
}

class _MonthlyReportTabState extends State<_MonthlyReportTab> {
  DateTime _selectedMonth = DateTime.now();

  void _changeMonth(int months) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + months,
        1,
      );
    });
  }

  void _goToCurrentMonth() {
    setState(() {
      _selectedMonth = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AdminReportesViewModel>(context, listen: false);
    final monthName = DateFormat('MMMM yyyy', 'es_ES').format(_selectedMonth);
    final isCurrentMonth = _selectedMonth.year == DateTime.now().year &&
        _selectedMonth.month == DateTime.now().month;

    return StreamBuilder<Map<String, dynamic>>(
      stream: viewModel.getMonthlyReport(_selectedMonth),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error cargando reporte: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data ?? {
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

        return SingleChildScrollView(
      child: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF3A3A3A),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        monthName[0].toUpperCase() + monthName.substring(1),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ],
                ),
                if (!isCurrentMonth) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _goToCurrentMonth,
                    icon: const Icon(Icons.today, size: 18),
                    label: const Text('Mes Actual'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                      side: const BorderSide(color: Colors.orangeAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPIs principales
                const Text(
                  'Resumen del Mes',
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
                  childAspectRatio: 1.4,
                  children: [
                    _buildKPICard(
                      label: 'Asistencias Total',
                      value: '${data['totalAsistencias']}',
                      icon: Icons.people,
                      color: Colors.blue,
                      subtitle: '~${data['promedioAsistenciaDiaria']}/día',
                    ),
                    _buildKPICard(
                      label: 'Alumnos Activos',
                      value: '${data['alumnosActivos']}',
                      icon: Icons.fitness_center,
                      color: Colors.green,
                      subtitle: '+${data['alumnosNuevos']} nuevos',
                    ),
                    _buildKPICard(
                      label: 'Ingresos Totales',
                      value: '\$${(data['ingresosTotal'] / 1000000).toStringAsFixed(1)}M',
                      icon: Icons.attach_money,
                      color: Colors.orange,
                      subtitle: 'CLP',
                    ),
                    _buildKPICard(
                      label: 'Tasa Retención',
                      value: '${data['tasaRetencion']}%',
                      icon: Icons.trending_up,
                      color: Colors.purple,
                      subtitle: '${data['alumnosInactivos']} bajas',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Desglose de ingresos
                const Text(
                  'Desglose de Ingresos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildIncomeRow(
                        'Mensualidades',
                        data['ingresosMensualidad'],
                        Colors.blue,
                        data['ingresosTotal'],
                      ),
                      const Divider(color: Color(0xFF3A3A3A)),
                      _buildIncomeRow(
                        'Matrículas',
                        data['ingresosMatricula'],
                        Colors.green,
                        data['ingresosTotal'],
                      ),
                      const Divider(color: Color(0xFF3A3A3A)),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${NumberFormat('#,###', 'es_ES').format(data['ingresosTotal'])}',
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Ocupación promedio por clase
                const Text(
                  'Ocupación Promedio por Horario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: (data['clasesOcupacionPromedio'] as List).map((clase) {
                      final ocupacion = clase['ocupacion'] as int;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                clase['hora'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: ocupacion / 100,
                                    child: Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            ocupacion >= 90
                                                ? Colors.green
                                                : ocupacion >= 70
                                                    ? Colors.orange
                                                    : Colors.blue,
                                            ocupacion >= 90
                                                ? Colors.green.shade700
                                                : ocupacion >= 70
                                                    ? Colors.orange.shade700
                                                    : Colors.blue.shade700,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 24,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      '$ocupacion%',
                                      style: TextStyle(
                                        color: ocupacion > 50
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Días con más asistencia
                const Text(
                  'Días con Mayor Asistencia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: (data['diasConMasAsistencia'] as List)
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final dia = entry.value;
                      final medals = ['🥇', '🥈', '🥉'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Text(
                              medals[index],
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dia['dia'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${dia['asistencias']} asistencias',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildKPICard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
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
            size: 24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeRow(String label, int amount, Color color, int total) {
    final percentage = (amount / total * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${NumberFormat('#,###', 'es_ES').format(amount)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB: REPORTE SEMANAL
// ============================================================================
class _WeeklyReportTab extends StatefulWidget {
  const _WeeklyReportTab();

  @override
  State<_WeeklyReportTab> createState() => _WeeklyReportTabState();
}

class _WeeklyReportTabState extends State<_WeeklyReportTab> {
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());

  static DateTime _getWeekStart(DateTime date) {
    // Lunes es el día 1, domingo es 7
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  void _changeWeek(int weeks) {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(Duration(days: weeks * 7));
    });
  }

  void _goToCurrentWeek() {
    setState(() {
      _selectedWeekStart = _getWeekStart(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AdminReportesViewModel>(context, listen: false);
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    final startStr = DateFormat('dd MMM', 'es_ES').format(_selectedWeekStart);
    final endStr = DateFormat('dd MMM yyyy', 'es_ES').format(weekEnd);

    final currentWeekStart = _getWeekStart(DateTime.now());
    final isCurrentWeek = _selectedWeekStart.year == currentWeekStart.year &&
        _selectedWeekStart.month == currentWeekStart.month &&
        _selectedWeekStart.day == currentWeekStart.day;

    return StreamBuilder<Map<String, dynamic>>(
      stream: viewModel.getWeeklyReport(_selectedWeekStart),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error cargando reporte: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data ?? {
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

        return SingleChildScrollView(
      child: Column(
        children: [
          // Week selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF3A3A3A),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeWeek(-1),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Semana',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '$startStr - $endStr',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeWeek(1),
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ],
                ),
                if (!isCurrentWeek) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _goToCurrentWeek,
                    icon: const Icon(Icons.today, size: 18),
                    label: const Text('Semana Actual'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                      side: const BorderSide(color: Colors.orangeAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPIs principales
                const Text(
                  'Resumen de la Semana',
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
                  childAspectRatio: 1.4,
                  children: [
                    _buildKPICard(
                      label: 'Asistencias Total',
                      value: '${data['totalAsistencias']}',
                      icon: Icons.people,
                      color: Colors.blue,
                      subtitle: '~${data['promedioAsistenciaDiaria']}/día',
                    ),
                    _buildKPICard(
                      label: 'Alumnos Activos',
                      value: '${data['alumnosActivos']}',
                      icon: Icons.fitness_center,
                      color: Colors.green,
                      subtitle: '+${data['alumnosNuevos']} esta semana',
                    ),
                    _buildKPICard(
                      label: 'Ingresos',
                      value: '\$${(data['ingresosSemana'] / 1000).toInt()}K',
                      icon: Icons.attach_money,
                      color: Colors.orange,
                      subtitle: 'CLP',
                    ),
                    _buildKPICard(
                      label: 'Tendencia',
                      value: data['comparacionSemanaAnterior'] > 0
                          ? '+${data['comparacionSemanaAnterior']}%'
                          : '${data['comparacionSemanaAnterior']}%',
                      icon: data['tendencia'] == 'up'
                          ? Icons.trending_up
                          : data['tendencia'] == 'down'
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      color: data['tendencia'] == 'up'
                          ? Colors.green
                          : data['tendencia'] == 'down'
                              ? Colors.red
                              : Colors.grey,
                      subtitle: 'vs semana anterior',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Asistencia diaria
                const Text(
                  'Asistencia Diaria',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Bar chart
                      SizedBox(
                        height: 200,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: (data['asistenciaPorDia'] as List).map((dia) {
                            final asistencias = dia['asistencias'] as int;
                            final capacidad = dia['capacidad'] as int;
                            final percentage = asistencias / capacidad;
                            final today = DateTime.now();
                            final diaFecha = int.parse(dia['fecha']);
                            final isToday = today.day == diaFecha;

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$asistencias',
                                      style: TextStyle(
                                        color: isToday
                                            ? Colors.orangeAccent
                                            : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: FractionallySizedBox(
                                        heightFactor: percentage,
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: isToday
                                                  ? [
                                                      Colors.orangeAccent,
                                                      Colors.orangeAccent.shade700,
                                                    ]
                                                  : [
                                                      Colors.blue,
                                                      Colors.blue.shade700,
                                                    ],
                                            ),
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      dia['dia'],
                                      style: TextStyle(
                                        color: isToday
                                            ? Colors.orangeAccent
                                            : Colors.white60,
                                        fontSize: 12,
                                        fontWeight:
                                            isToday ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      dia['fecha'],
                                      style: TextStyle(
                                        color: isToday
                                            ? Colors.orangeAccent
                                            : Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF3A3A3A)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Asistencias',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Hoy',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Análisis de horarios
                const Text(
                  'Análisis de Horarios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Clase más popular
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.3),
                        Colors.green.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Clase Más Popular',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['claseMasPopular']['hora'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${data['claseMasPopular']['asistenciaPromedio'].toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'de ${data['claseMasPopular']['capacidad']} promedio',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Clase menos popular
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.3),
                        Colors.orange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_down,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Oportunidad de Mejora',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['claseMenosPopular']['hora'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${data['claseMenosPopular']['asistenciaPromedio'].toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'de ${data['claseMenosPopular']['capacidad']} promedio',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildKPICard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
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
            size: 24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
