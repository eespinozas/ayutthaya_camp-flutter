import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class MisClasesPage extends StatefulWidget {
  const MisClasesPage({super.key});

  @override
  State<MisClasesPage> createState() => _MisClasesPageState();
}

class _MisClasesPageState extends State<MisClasesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es_ES', null);
    setState(() {
      _localeInitialized = true;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock data - en producción esto vendrá de tu base de datos
  List<Map<String, dynamic>> _getReservedClasses() {
    // TODO: Obtener desde la base de datos/API las clases reservadas del usuario
    final now = DateTime.now();

    return [
      {
        'id': '1',
        'name': 'Muay Thai',
        'instructor': 'Francisco Poveda',
        'date': now.add(const Duration(days: 1)),
        'time': '07:00 AM',
        'duration': 60,
        'level': 'Todos los niveles',
        'status': 'upcoming', // upcoming, completed, cancelled
        'location': 'Sala Principal',
      },
      {
        'id': '2',
        'name': 'Muay Thai',
        'instructor': 'Francisco Poveda',
        'date': now.add(const Duration(days: 2)),
        'time': '18:00 PM',
        'duration': 60,
        'level': 'Todos los niveles',
        'status': 'upcoming',
        'location': 'Sala Principal',
      },
      {
        'id': '3',
        'name': 'Muay Thai',
        'instructor': 'Francisco Poveda',
        'date': now.add(const Duration(days: 5)),
        'time': '09:30 AM',
        'duration': 60,
        'level': 'Todos los niveles',
        'status': 'upcoming',
        'location': 'Sala Principal',
      },
      {
        'id': '4',
        'name': 'Muay Thai',
        'instructor': 'Francisco Poveda',
        'date': now.subtract(const Duration(days: 2)),
        'time': '07:00 AM',
        'duration': 60,
        'level': 'Todos los niveles',
        'status': 'completed',
        'location': 'Sala Principal',
        'attended': true,
      },
      {
        'id': '5',
        'name': 'Muay Thai',
        'instructor': 'Francisco Poveda',
        'date': now.subtract(const Duration(days: 5)),
        'time': '18:00 PM',
        'duration': 60,
        'level': 'Todos los niveles',
        'status': 'completed',
        'location': 'Sala Principal',
        'attended': true,
      },
      {
        'id': '6',
        'name': 'Muay Thai',
        'instructor': 'Francisco Poveda',
        'date': now.subtract(const Duration(days: 7)),
        'time': '19:30 PM',
        'duration': 60,
        'level': 'Todos los niveles',
        'status': 'completed',
        'location': 'Sala Principal',
        'attended': false, // Falta
      },
      {
        'id': '7',
        'name': 'Muay Thai',
        'instructor': 'Francisco Poveda',
        'date': now.add(const Duration(days: 10)),
        'time': '08:00 AM',
        'duration': 60,
        'level': 'Todos los niveles',
        'status': 'cancelled',
        'location': 'Sala Principal',
        'cancelledAt': now.subtract(const Duration(days: 1)),
      },
    ];
  }

  List<Map<String, dynamic>> _filterClassesByStatus(String status) {
    return _getReservedClasses()
        .where((classData) => classData['status'] == status)
        .toList();
  }

  void _cancelClass(Map<String, dynamic> classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Cancelar Reserva',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de cancelar tu clase de ${classData['name']} del ${DateFormat('dd MMM yyyy', 'es_ES').format(classData['date'])} a las ${classData['time']}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Aquí llamar a la API/BD para cancelar la reserva
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reserva cancelada exitosamente'),
                  backgroundColor: Colors.orange,
                ),
              );
              setState(() {
                // En producción, esto actualizaría el estado desde la BD
                classData['status'] = 'cancelled';
                classData['cancelledAt'] = DateTime.now();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Sí, Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Mis Clases',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.orangeAccent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Mis Clases',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Próximas'),
            Tab(text: 'Completadas'),
            Tab(text: 'Canceladas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClassList('upcoming'),
          _buildClassList('completed'),
          _buildClassList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildClassList(String status) {
    final classes = _filterClassesByStatus(status);

    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'upcoming'
                  ? Icons.event_available
                  : status == 'completed'
                      ? Icons.check_circle_outline
                      : Icons.event_busy,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              status == 'upcoming'
                  ? 'No tienes clases próximas'
                  : status == 'completed'
                      ? 'Aún no has completado ninguna clase'
                      : 'No tienes clases canceladas',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final classData = classes[index];
        return _buildClassCard(classData, status);
      },
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData, String status) {
    final date = classData['date'] as DateTime;
    final isUpcoming = status == 'upcoming';
    final isCompleted = status == 'completed';
    final attended = classData['attended'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con fecha y estado
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd MMM yyyy', 'es_ES').format(date),
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classData['time'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: attended
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: attended ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          attended ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: attended ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          attended ? 'Asistió' : 'Falta',
                          style: TextStyle(
                            color: attended ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const Divider(color: Colors.white12, height: 24),

            // Información de la clase
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  classData['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.person,
                  color: Colors.white60,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  classData['instructor'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white60,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  classData['location'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time,
                  color: Colors.white60,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${classData['duration']} min',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            // Botón de cancelar solo para clases próximas
            if (isUpcoming) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelClass(classData),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: const Text(
                    'Cancelar Reserva',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
