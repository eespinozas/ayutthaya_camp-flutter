import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class AgendarPage extends StatefulWidget {
  const AgendarPage({super.key});

  @override
  State<AgendarPage> createState() => _AgendarPageState();
}

class _AgendarPageState extends State<AgendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('es_ES', null);
    setState(() {
      _localeInitialized = true;
    });
  }

  // Mock data - en producción esto vendrá de tu base de datos
  List<Map<String, dynamic>> _getClassesForDay(DateTime day) {
    // Por ahora retornamos horarios fijos
    // TODO: Obtener desde la base de datos/API
    final schedules = ['07:00', '08:00', '09:30', '18:00', '19:30'];

    final classes = <Map<String, dynamic>>[];

    for (int i = 0; i < schedules.length; i++) {
      final time = schedules[i];
      final hour = int.parse(time.split(':')[0]);
      final minute = time.split(':')[1];

      // Formatear la hora en formato 12h
      String formattedTime;
      if (hour < 12) {
        formattedTime = '$hour:$minute AM';
      } else if (hour == 12) {
        formattedTime = '12:$minute PM';
      } else {
        formattedTime = '${hour - 12}:$minute PM';
      }

      classes.add({
        'id': '${day.toString()}_$i',
        'name': 'Muay Thai',
        'instructor': 'Francisco Poveda',
        'time': formattedTime,
        'duration': 60,
        'capacity': 15,
        'enrolled': (i * 2) % 12, // Mock de espacios ocupados
        'level': 'Todos los niveles',
      });
    }

    return classes;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _bookClass(Map<String, dynamic> classData) {
    // Aquí iría la lógica para reservar la clase
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Confirmar Reserva',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Deseas reservar ${classData['name']} con ${classData['instructor']} el ${DateFormat('dd/MM/yyyy', 'es_ES').format(_selectedDay!)} a las ${classData['time']}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Clase "${classData['name']}" reservada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.black),
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
            'Agendar Clase',
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

    final classes = _selectedDay != null ? _getClassesForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Agendar Clase',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Calendario
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              locale: 'es_ES',
              startingDayOfWeek: StartingDayOfWeek.monday,
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              // Estilos del calendario
              calendarStyle: CalendarStyle(
                // Días
                defaultTextStyle: const TextStyle(color: Colors.white70),
                weekendTextStyle: const TextStyle(color: Colors.orangeAccent),
                outsideTextStyle: const TextStyle(color: Colors.white24),

                // Día seleccionado
                selectedDecoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),

                // Día de hoy
                todayDecoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),

                // Marcadores
                markerDecoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white70),
                weekendStyle: TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Título de clases disponibles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedDay != null
                      ? 'Clases disponibles - ${DateFormat('dd MMM yyyy', 'es_ES').format(_selectedDay!)}'
                      : 'Selecciona un día',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Lista de clases
          Expanded(
            child: classes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay clases disponibles\npara este día',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: classes.length + 1, // +1 para el botón de QR
                    itemBuilder: (context, index) {
                      // Si es el último item, mostrar el botón de QR
                      if (index == classes.length) {
                        return _buildQRButton();
                      }

                      final classData = classes[index];
                      final isFull = classData['enrolled'] >= classData['capacity'];
                      final availableSpots = classData['capacity'] - classData['enrolled'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isFull ? Colors.red.withOpacity(0.3) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          classData['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
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
                                              classData['instructor'],
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
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
                                      color: Colors.orangeAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      classData['time'],
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildInfoChip(
                                    Icons.access_time,
                                    '${classData['duration']} min',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    Icons.fitness_center,
                                    classData['level'],
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    Icons.people,
                                    '$availableSpots disponibles',
                                    color: isFull ? Colors.red : Colors.green,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isFull ? null : () => _bookClass(classData),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFull
                                        ? Colors.grey.shade800
                                        : Colors.orangeAccent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    isFull ? 'CLASE LLENA' : 'RESERVAR CLASE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isFull ? Colors.white38 : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Método para encontrar la siguiente clase disponible según la hora actual
  Map<String, dynamic>? _getNextAvailableClass() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;

    final schedules = ['07:00', '08:00', '09:30', '18:00', '19:30'];

    for (final schedule in schedules) {
      final parts = schedule.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final scheduleTimeInMinutes = hour * 60 + minute;

      // Si la clase es en el futuro (con 10 minutos de margen)
      if (scheduleTimeInMinutes > currentTimeInMinutes + 10) {
        // Formatear la hora en formato 12h
        String formattedTime;
        if (hour < 12) {
          formattedTime = '$hour:${parts[1]} AM';
        } else if (hour == 12) {
          formattedTime = '12:${parts[1]} PM';
        } else {
          formattedTime = '${hour - 12}:${parts[1]} PM';
        }

        return {
          'name': 'Muay Thai',
          'instructor': 'Francisco Poveda',
          'time': formattedTime,
          'timeRaw': schedule,
          'duration': 60,
          'level': 'Todos los niveles',
        };
      }
    }

    // Si no hay clase disponible hoy, retornar la primera clase del día siguiente
    return {
      'name': 'Muay Thai',
      'instructor': 'Francisco Poveda',
      'time': '07:00 AM',
      'timeRaw': '07:00',
      'duration': 60,
      'level': 'Todos los niveles',
      'nextDay': true,
    };
  }

  Widget _buildQRButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Divider(color: Colors.white12, height: 40),
          const Text(
            '¿Llegaste al gimnasio sin reserva?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _showQRModal,
            borderRadius: BorderRadius.circular(60),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orangeAccent.shade400,
                    Colors.orangeAccent.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 60,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Escanea para agendar automáticamente',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showQRModal() {
    final nextClass = _getNextAvailableClass();
    if (nextClass == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Agendamiento Rápido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Información de la clase
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: Colors.orangeAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nextClass['name'],
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
                          nextClass['instructor'],
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
                          Icons.access_time,
                          color: Colors.white60,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${nextClass['time']} - ${nextClass['duration']} min',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    if (nextClass['nextDay'] == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orangeAccent,
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orangeAccent,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'No hay más clases hoy. Primera clase mañana.',
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Código QR
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: jsonEncode({
                    'type': 'quick_booking',
                    'gym': 'Ayutthaya Camp',
                    'class': nextClass['name'],
                    'instructor': nextClass['instructor'],
                    'time': nextClass['timeRaw'],
                    'timestamp': DateTime.now().toIso8601String(),
                  }),
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Escanea este código en el gimnasio\npara agendar automáticamente',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Botón de cerrar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orangeAccent,
                    side: const BorderSide(color: Colors.orangeAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
