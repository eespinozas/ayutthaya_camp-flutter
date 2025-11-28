import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../../../schedules/viewmodels/class_schedule_viewmodel.dart';
import '../../../schedules/models/class_schedule.dart';
import '../../../bookings/viewmodels/booking_viewmodel.dart';
import '../../../bookings/models/booking.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/presentation/widgets/membership_guard.dart';

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

  // Obtener clases del día desde Firebase
  List<ClassSchedule> _getSchedulesForDay(List<ClassSchedule> allSchedules, DateTime day) {
    final dayOfWeek = day.weekday; // 1 = Monday, 7 = Sunday
    return allSchedules.where((schedule) => schedule.isOnDay(dayOfWeek)).toList();
  }

  // Formatear hora en formato 12h
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

  // Verificar si una clase ya pasó (solo aplica para el día de hoy)
  bool _hasClassPassed(String time24, DateTime classDate) {
    final now = DateTime.now();

    // Solo verificar si es hoy
    final isToday = classDate.year == now.year &&
        classDate.month == now.month &&
        classDate.day == now.day;

    if (!isToday) {
      return false; // Si no es hoy, la clase no ha pasado
    }

    // Parsear la hora de la clase
    final timeParts = time24.split(':');
    final classHour = int.parse(timeParts[0]);
    final classMinute = int.parse(timeParts[1]);

    // Crear DateTime de la clase de hoy
    final classDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      classHour,
      classMinute,
    );

    // Verificar si la clase ya pasó
    return classDateTime.isBefore(now);
  }

  Widget _buildClassCounter() {
    final authVM = context.watch<AuthViewModel>();
    final bookingVM = context.watch<BookingViewModel>();
    final userId = authVM.currentUser?.uid;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _getClassLimitInfo(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final classesPerMonth = data['classesPerMonth'] as int?;
        final bookedThisMonth = data['bookedThisMonth'] as int;

        // Si es plan ilimitado, mostrar mensaje diferente
        if (classesPerMonth == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.all_inclusive,
                    size: 18,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Plan ilimitado',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Plan con límite
        final remaining = classesPerMonth - bookedThisMonth;
        final percentage = bookedThisMonth / classesPerMonth;

        Color color;
        if (percentage >= 1.0) {
          color = Colors.red;
        } else if (percentage >= 0.8) {
          color = Colors.orange;
        } else {
          color = Colors.blue;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  '$bookedThisMonth de $classesPerMonth clases usadas este mes',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (remaining > 0 && remaining <= 2) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Quedan $remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getClassLimitInfo(String userId) async {
    try {
      // Obtener información del usuario
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final classesPerMonth = userDoc.data()?['classesPerMonth'];

      // Obtener clases agendadas este mes
      final bookingVM = context.read<BookingViewModel>();
      final bookedThisMonth = await bookingVM.getUserBookedClassesThisMonth(
        userId,
        DateTime.now(),
      );

      return {
        'classesPerMonth': classesPerMonth,
        'bookedThisMonth': bookedThisMonth,
      };
    } catch (e) {
      debugPrint('Error obteniendo info de límite de clases: $e');
      return {
        'classesPerMonth': null,
        'bookedThisMonth': 0,
      };
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _bookClass(ClassSchedule schedule) async {
    final authVM = context.read<AuthViewModel>();
    final bookingVM = context.read<BookingViewModel>();
    final user = authVM.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para reservar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar si ya tiene reserva
    final hasBooking = await bookingVM.hasBookingForClass(
      user.uid,
      schedule.id!,
      _selectedDay!,
    );

    if (hasBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya tienes una reserva para esta clase'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Confirmar Reserva',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Deseas reservar ${schedule.type} con ${schedule.instructor} el ${DateFormat('dd/MM/yyyy', 'es_ES').format(_selectedDay!)} a las ${_formatTime(schedule.time)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

    if (confirmed != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      ),
    );

    // Normalizar la fecha seleccionada (solo año, mes, día)
    final normalizedDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    debugPrint('🔍 BOOKING - Fecha seleccionada original: $_selectedDay');
    debugPrint('🔍 BOOKING - Fecha normalizada: $normalizedDate');

    // Crear la reserva
    final booking = Booking(
      userId: user.uid,
      userName: user.displayName ?? user.email ?? 'Usuario',
      userEmail: user.email ?? '',
      scheduleId: schedule.id!,
      scheduleTime: schedule.time,
      scheduleType: schedule.type,
      instructor: schedule.instructor,
      classDate: normalizedDate,
      createdAt: DateTime.now(),
    );

    final success = await bookingVM.createBooking(booking);

    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clase "${schedule.type}" reservada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {}); // Refrescar para actualizar contador
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingVM.errorMessage ?? 'Error al reservar'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    final scheduleVM = context.watch<ClassScheduleViewModel>();

    return MembershipGuard(
      pageName: 'Agendar',
      child: Scaffold(
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

          // Contador de clases usadas este mes
          _buildClassCounter(),

          const SizedBox(height: 12),

          // Lista de clases desde Firebase
          Expanded(
            child: StreamBuilder<List<ClassSchedule>>(
              stream: scheduleVM.getActiveSchedules(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  // Log detallado del error
                  debugPrint('❌ ERROR EN AGENDAR_PAGE - StreamBuilder:');
                  debugPrint('Error: ${snapshot.error}');
                  debugPrint('StackTrace: ${snapshot.stackTrace}');

                  final errorMsg = snapshot.error.toString();

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error al cargar clases',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            errorMsg,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (errorMsg.contains('index'))
                            const Text(
                              'Necesitas crear un índice en Firestore.\nCopia el link del error y ábrelo en tu navegador.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                final allSchedules = snapshot.data ?? [];
                final classes = _selectedDay != null
                    ? _getSchedulesForDay(allSchedules, _selectedDay!)
                    : [];

                if (classes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.white24,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay clases disponibles\npara este día',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final schedule = classes[index];

                    // Usar un widget con estado para evitar flickering
                    return ClassScheduleCard(
                      key: ValueKey('${schedule.id}_${_selectedDay?.toString()}'),
                      schedule: schedule,
                      selectedDay: _selectedDay!,
                      onBook: () => _bookClass(schedule),
                      formatTime: _formatTime,
                      hasClassPassed: _hasClassPassed,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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

// Widget con estado para evitar flickering al hacer scroll
class ClassScheduleCard extends StatefulWidget {
  final ClassSchedule schedule;
  final DateTime selectedDay;
  final VoidCallback onBook;
  final String Function(String) formatTime;
  final bool Function(String, DateTime) hasClassPassed;

  const ClassScheduleCard({
    super.key,
    required this.schedule,
    required this.selectedDay,
    required this.onBook,
    required this.formatTime,
    required this.hasClassPassed,
  });

  @override
  State<ClassScheduleCard> createState() => _ClassScheduleCardState();
}

class _ClassScheduleCardState extends State<ClassScheduleCard> with AutomaticKeepAliveClientMixin {
  int? _bookedCount;
  bool? _alreadyBooked;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ClassScheduleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo recargar si cambió el día seleccionado
    if (oldWidget.selectedDay != widget.selectedDay || oldWidget.schedule.id != widget.schedule.id) {
      // Marcar como loading inmediatamente para evitar mostrar datos incorrectos
      setState(() {
        _isLoading = true;
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final bookingVM = context.read<BookingViewModel>();
    final authVM = context.read<AuthViewModel>();
    final userId = authVM.currentUser?.uid ?? '';

    try {
      final results = await Future.wait([
        bookingVM.getBookedCount(widget.schedule.id!, widget.selectedDay),
        bookingVM.hasUserBookedSchedule(userId, widget.schedule.id!, widget.selectedDay),
      ]);

      if (mounted) {
        setState(() {
          _bookedCount = results[0] as int;
          _alreadyBooked = results[1] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos de clase: $e');
      if (mounted) {
        setState(() {
          _bookedCount = 0;
          _alreadyBooked = false;
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Usar valores por defecto mientras carga
    final enrolled = _bookedCount ?? 0;
    final isFull = enrolled >= widget.schedule.capacity;
    final availableSpots = widget.schedule.capacity - enrolled;
    final alreadyBooked = _alreadyBooked ?? false;
    final hasPassed = widget.hasClassPassed(widget.schedule.time, widget.selectedDay);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: hasPassed ? const Color(0xFF1E1E1E) : const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isFull
              ? Colors.red.withOpacity(0.3)
              : hasPassed
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.transparent,
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
                        widget.schedule.type,
                        style: TextStyle(
                          color: hasPassed ? Colors.white30 : Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: hasPassed ? Colors.white24 : Colors.white60,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.schedule.instructor,
                            style: TextStyle(
                              color: hasPassed ? Colors.white24 : Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: hasPassed
                            ? Colors.grey.withOpacity(0.2)
                            : Colors.orangeAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.formatTime(widget.schedule.time),
                        style: TextStyle(
                          color: hasPassed ? Colors.grey : Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (hasPassed) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'FINALIZADA',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.access_time,
                  '60 min',
                  color: hasPassed ? Colors.grey : null,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.fitness_center,
                  'Todos los niveles',
                  color: hasPassed ? Colors.grey : null,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.people,
                  '$availableSpots disponibles',
                  color: hasPassed
                      ? Colors.grey
                      : isFull
                          ? Colors.red
                          : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || isFull || alreadyBooked || hasPassed) ? null : widget.onBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isLoading || isFull || alreadyBooked || hasPassed)
                      ? Colors.grey.shade800
                      : Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white38,
                        ),
                      )
                    : Text(
                        hasPassed
                            ? 'CLASE FINALIZADA'
                            : isFull
                                ? 'CLASE LLENA'
                                : alreadyBooked
                                    ? 'YA AGENDADA'
                                    : 'RESERVAR CLASE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (isFull || alreadyBooked || hasPassed) ? Colors.white38 : Colors.black,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
