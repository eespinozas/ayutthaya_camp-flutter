import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/presentation/widgets/membership_guard.dart';
import '../../../bookings/viewmodels/booking_viewmodel.dart';
import '../../../bookings/models/booking.dart';

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
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Future<void> _cancelClass(Booking booking) async {
    // Validar que falten más de 24 horas para la clase
    final now = DateTime.now();
    final timeParts = booking.scheduleTime.split(':');
    final classDateTime = DateTime(
      booking.classDate.year,
      booking.classDate.month,
      booking.classDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    final hoursUntilClass = classDateTime.difference(now).inHours;

    if (hoursUntilClass < 24) {
      // No se puede cancelar porque faltan menos de 24 horas
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'No se puede cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            'Para cancelar una clase debes hacerlo con al menos 24 horas de anticipación.\n\n'
            'Tu clase es el ${DateFormat('dd MMM yyyy', 'es_ES').format(booking.classDate)} '
            'a las ${_formatTime(booking.scheduleTime)}.\n\n'
            'Faltan ${hoursUntilClass} horas para tu clase.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Cancelar Reserva',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de cancelar tu clase de ${booking.scheduleType} del ${DateFormat('dd MMM yyyy', 'es_ES').format(booking.classDate)} a las ${_formatTime(booking.scheduleTime)}?\n\n'
          'Faltan $hoursUntilClass horas para tu clase.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

    if (confirmed != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      ),
    );

    final bookingVM = context.read<BookingViewModel>();
    final success = await bookingVM.cancelBooking(
      booking.id!,
      'Cancelado por el usuario',
    );

    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada exitosamente'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingVM.errorMessage ?? 'Error al cancelar'),
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

    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: const Center(
          child: Text(
            'Debes iniciar sesión para ver tus clases',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return MembershipGuard(
      pageName: 'Mis Clases',
      child: Scaffold(
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
          _buildBookingsList(user.uid, BookingStatus.confirmed),
          _buildCompletedList(user.uid),
          _buildBookingsList(user.uid, BookingStatus.cancelled),
        ],
      ),
      ),
    );
  }

  Widget _buildBookingsList(String userId, BookingStatus status) {
    final bookingVM = context.watch<BookingViewModel>();

    return StreamBuilder<List<Booking>>(
      stream: bookingVM.getUserBookings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        if (snapshot.hasError) {
          // Log detallado del error
          debugPrint('❌ ERROR EN MIS_CLASES_PAGE - StreamBuilder (Bookings):');
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

        final allBookings = snapshot.data ?? [];

        debugPrint('📋 MIS_CLASES - Total bookings recibidas: ${allBookings.length}');
        for (var booking in allBookings) {
          debugPrint('   Booking: ${booking.scheduleType} - ${booking.classDate} - Status: ${booking.status.name}');
          debugPrint('   isFuture: ${booking.isFuture()}, isToday: ${booking.isToday()}, isPast: ${booking.isPast()}');
        }

        final filteredBookings = allBookings.where((booking) {
          if (status == BookingStatus.confirmed) {
            // Incluir clases futuras Y clases de hoy
            final shouldInclude = booking.status == BookingStatus.confirmed &&
                                  (booking.isFuture() || booking.isToday());
            debugPrint('   Filtering ${booking.scheduleType}: status=${booking.status.name}, isFuture=${booking.isFuture()}, isToday=${booking.isToday()}, included=$shouldInclude');
            return shouldInclude;
          }
          return booking.status == status;
        }).toList();

        debugPrint('📋 Bookings filtradas ($status): ${filteredBookings.length}');

        if (filteredBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == BookingStatus.confirmed
                      ? Icons.event_available
                      : status == BookingStatus.cancelled
                          ? Icons.event_busy
                          : Icons.check_circle_outline,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  status == BookingStatus.confirmed
                      ? 'No tienes clases próximas'
                      : status == BookingStatus.cancelled
                          ? 'No tienes clases canceladas'
                          : 'Aún no has completado ninguna clase',
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
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) {
            final booking = filteredBookings[index];
            return _buildBookingCard(booking);
          },
        );
      },
    );
  }

  Widget _buildCompletedList(String userId) {
    final bookingVM = context.watch<BookingViewModel>();

    return StreamBuilder<List<Booking>>(
      stream: bookingVM.getUserBookings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        if (snapshot.hasError) {
          // Log detallado del error
          debugPrint('❌ ERROR EN MIS_CLASES_PAGE - StreamBuilder (Completed):');
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
                    'Error al cargar clases completadas',
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

        final allBookings = snapshot.data ?? [];
        final completedBookings = allBookings.where((booking) {
          return booking.status == BookingStatus.attended ||
              booking.status == BookingStatus.noShow;
        }).toList();

        if (completedBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.white24,
                ),
                SizedBox(height: 16),
                Text(
                  'Aún no has completado ninguna clase',
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
          padding: const EdgeInsets.all(16),
          itemCount: completedBookings.length,
          itemBuilder: (context, index) {
            final booking = completedBookings[index];
            return _buildBookingCard(booking);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isUpcoming = booking.status == BookingStatus.confirmed && booking.isFuture();
    final isAttended = booking.status == BookingStatus.attended;
    final isNoShow = booking.status == BookingStatus.noShow;
    final isCancelled = booking.status == BookingStatus.cancelled;

    // Verificar si se puede cancelar (más de 24 horas de anticipación)
    final now = DateTime.now();
    final timeParts = booking.scheduleTime.split(':');
    final classDateTime = DateTime(
      booking.classDate.year,
      booking.classDate.month,
      booking.classDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    final hoursUntilClass = classDateTime.difference(now).inHours;
    final canCancel = hoursUntilClass >= 24;

    Color statusColor = Colors.orangeAccent;
    String statusText = 'Confirmada';
    IconData statusIcon = Icons.check_circle;

    if (isAttended) {
      statusColor = Colors.green;
      statusText = 'Asistió';
      statusIcon = Icons.check_circle;
    } else if (isNoShow) {
      statusColor = Colors.red;
      statusText = 'No asistió';
      statusIcon = Icons.cancel;
    } else if (isCancelled) {
      statusColor = Colors.orange;
      statusText = 'Cancelada';
      statusIcon = Icons.event_busy;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con fecha y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd MMM yyyy', 'es_ES').format(booking.classDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(booking.scheduleTime),
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
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

            // Detalles de la clase
            Row(
              children: [
                Icon(Icons.sports_kabaddi, color: Colors.white60, size: 20),
                const SizedBox(width: 8),
                Text(
                  booking.scheduleType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, color: Colors.white60, size: 20),
                const SizedBox(width: 8),
                Text(
                  booking.instructor,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            // Indicador de confirmación de asistencia
            if (booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: booking.userConfirmedAttendance
                      ? Colors.green.withOpacity(0.15)
                      : booking.missedConfirmationWindow()
                          ? Colors.red.withOpacity(0.15)
                          : booking.canConfirmAttendance()
                              ? Colors.orange.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: booking.userConfirmedAttendance
                        ? Colors.green.withOpacity(0.4)
                        : booking.missedConfirmationWindow()
                            ? Colors.red.withOpacity(0.4)
                            : booking.canConfirmAttendance()
                                ? Colors.orange.withOpacity(0.4)
                                : Colors.grey.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      booking.userConfirmedAttendance
                          ? Icons.check_circle
                          : booking.missedConfirmationWindow()
                              ? Icons.cancel
                              : booking.canConfirmAttendance()
                                  ? Icons.schedule
                                  : Icons.event,
                      color: booking.userConfirmedAttendance
                          ? Colors.green
                          : booking.missedConfirmationWindow()
                              ? Colors.red
                              : booking.canConfirmAttendance()
                                  ? Colors.orange
                                  : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.getConfirmationStatusText(),
                        style: TextStyle(
                          color: booking.userConfirmedAttendance
                              ? Colors.green
                              : booking.missedConfirmationWindow()
                                  ? Colors.red
                                  : booking.canConfirmAttendance()
                                      ? Colors.orange
                                      : Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Botón confirmar si está en ventana de confirmación
              if (booking.canConfirmAttendance() && !booking.userConfirmedAttendance) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final bookingVM = context.read<BookingViewModel>();
                      final success = await bookingVM.confirmAttendance(booking.id!);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Asistencia confirmada'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Confirmar Asistencia'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],

            // Botón cancelar (solo para próximas)
            if (isUpcoming) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: canCancel ? () => _cancelClass(booking) : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: canCancel ? Colors.red : Colors.grey,
                    side: BorderSide(color: canCancel ? Colors.red : Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    canCancel ? Icons.cancel_outlined : Icons.lock_clock,
                    size: 20,
                  ),
                  label: Text(
                    canCancel
                        ? 'Cancelar Reserva'
                        : 'Cancelación no disponible (menos de 24h)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
