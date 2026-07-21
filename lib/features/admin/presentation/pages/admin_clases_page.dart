import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_clases_viewmodel.dart';
import '../../../schedules/models/class_schedule.dart';
import '../../../bookings/models/booking.dart';
import '../../../../utils/validators.dart';

class AdminClasesPage extends StatefulWidget {
  const AdminClasesPage({super.key});

  @override
  State<AdminClasesPage> createState() => _AdminClasesPageState();
}

class _AdminClasesPageState extends State<AdminClasesPage> {
  bool _localeInitialized = false;
  late AdminClasesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AdminClasesViewModel();
    _initializeLocale();
  }

  @override
  void dispose() {
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
        backgroundColor: const Color(0xFF0F0F0F),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<AdminClasesViewModel>(
        builder: (context, viewModel, child) {
          final selectedDate = viewModel.selectedDate;
          final dayName = DateFormat('EEEE', 'es_ES').format(selectedDate);
          final dateStr = DateFormat(
            'dd MMM yyyy',
            'es_ES',
          ).format(selectedDate);
          final isToday =
              selectedDate.year == DateTime.now().year &&
              selectedDate.month == DateTime.now().month &&
              selectedDate.day == DateTime.now().day;

          return Scaffold(
            backgroundColor: const Color(0xFF0F0F0F),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1A1A1A),
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6A00), Color(0xFFFF8534)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Gestión de Clases',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              centerTitle: false,
            ),
            body: Column(
              children: [
                // Date selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF3A3A3A), width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => viewModel.changeDate(-1),
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  dayName[0].toUpperCase() +
                                      dayName.substring(1),
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
                            onPressed: () => viewModel.changeDate(1),
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (!isToday) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: viewModel.goToToday,
                          icon: const Icon(Icons.today, size: 18),
                          label: const Text('Ir a Hoy'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6A00),
                            side: const BorderSide(color: Color(0xFFFF6A00)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Classes list
                Expanded(
                  child: StreamBuilder<List<ClassSchedule>>(
                    stream: viewModel.getSchedules(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF6A00),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final schedules = snapshot.data ?? [];

                      if (schedules.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 80,
                                color: Colors.white24,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay horarios configurados',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return StreamBuilder<Set<String>>(
                        stream: viewModel.getDisabledScheduleIds(),
                        builder: (context, disabledSnapshot) {
                          final disabledIds =
                              disabledSnapshot.data ?? const <String>{};

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: schedules.length,
                            itemBuilder: (context, index) {
                              final schedule = schedules[index];
                              return _ClassCard(
                                schedule: schedule,
                                viewModel: viewModel,
                                isDisabled: disabledIds.contains(schedule.id),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatefulWidget {
  final ClassSchedule schedule;
  final AdminClasesViewModel viewModel;
  final bool isDisabled;

  const _ClassCard({
    required this.schedule,
    required this.viewModel,
    this.isDisabled = false,
  });

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  bool _expanded = false;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completada';
      case 'in_progress':
        return 'En Curso';
      default:
        return 'Programada';
    }
  }

  /// Diálogo para deshabilitar el horario en la fecha seleccionada.
  Future<void> _showDisableDialog() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final dateStr = DateFormat(
      'dd MMM yyyy',
      'es_ES',
    ).format(widget.viewModel.selectedDate);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.event_busy, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Suspender clase',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Se suspenderá la clase de las ${widget.schedule.time} '
                'solo para el $dateStr.\n\n'
                'Nadie podrá agendar ni hacer check-in QR en este horario esa fecha. '
                'Las reservas ya existentes no se modifican.',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLength: Validators.overrideReasonMaxLength,
                style: const TextStyle(color: Colors.white),
                validator: Validators.validateOverrideReason,
                decoration: InputDecoration(
                  labelText: 'Motivo (opcional)',
                  hintText: 'Ej: Pelea / evento',
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintStyle: const TextStyle(color: Colors.white30),
                  counterStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFFF6A00)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.event_busy, size: 18),
            label: const Text('Suspender'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.viewModel.disableScheduleForSelectedDate(
        widget.schedule.id!,
        reason: reasonController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Clase de las ${widget.schedule.time} suspendida para el $dateStr',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al suspender: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Diálogo de confirmación para rehabilitar el horario.
  Future<void> _showEnableDialog() async {
    final dateStr = DateFormat(
      'dd MMM yyyy',
      'es_ES',
    ).format(widget.viewModel.selectedDate);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Rehabilitar clase',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'La clase de las ${widget.schedule.time} volverá a estar '
          'disponible para agendar el $dateStr.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rehabilitar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.viewModel.enableScheduleForSelectedDate(widget.schedule.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clase de las ${widget.schedule.time} rehabilitada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rehabilitar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Registra la decisión definitiva de asistencia de un alumno.
  /// Confirmar -> asistió; Rechazar -> no asistió (o rechaza la confirmación
  /// del alumno si estaba esperando aprobación). No es reversible desde la UI.
  Future<void> _decideAttendance(
    BuildContext context,
    Booking booking, {
    required bool attended,
  }) async {
    try {
      if (attended) {
        await widget.viewModel.markAttendance(booking.id!);
      } else if (booking.status == BookingStatus.pendingApproval) {
        await widget.viewModel.rejectAttendance(booking.id!);
      } else {
        await widget.viewModel.markNoShow(booking.id!);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.viewModel.getClassStatus(widget.schedule.time);
    final statusColor = widget.isDisabled
        ? Colors.red
        : _getStatusColor(status);
    final statusText = widget.isDisabled
        ? 'Suspendida'
        : _getStatusText(status);

    return StreamBuilder<List<Booking>>(
      stream: widget.viewModel.getClassBookings(widget.schedule.id!),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final attended = bookings
            .where((b) => b.status == BookingStatus.attended)
            .length;
        final pendingApproval = bookings
            .where((b) => b.status == BookingStatus.pendingApproval)
            .length;
        final total = bookings.length;
        final isFull = attended == total && total > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Time and status
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: statusColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.schedule.time,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Attendance count
                          Row(
                            children: [
                              if (pendingApproval > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$pendingApproval por aprobar',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Icon(
                                isFull ? Icons.check_circle : Icons.people,
                                color: isFull ? Colors.green : Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$attended/$total',
                                style: TextStyle(
                                  color: isFull ? Colors.green : Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: widget.isDisabled
                                ? _showEnableDialog
                                : _showDisableDialog,
                            icon: Icon(
                              widget.isDisabled
                                  ? Icons.event_available
                                  : Icons.event_busy,
                              color: widget.isDisabled
                                  ? Colors.green
                                  : Colors.white38,
                              size: 20,
                            ),
                            tooltip: widget.isDisabled
                                ? 'Rehabilitar en esta fecha'
                                : 'Suspender en esta fecha',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Icon(
                            _expanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? attended / total : 0,
                          minHeight: 6,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFull ? Colors.green : statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const Divider(color: Color(0xFF3A3A3A), height: 1),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: Color(0xFFFF6A00),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Alumnos Inscritos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (bookings.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No hay alumnos inscritos en esta clase',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ...bookings.map((booking) {
                          final hasAttended =
                              booking.status == BookingStatus.attended;
                          final isPending =
                              booking.status == BookingStatus.pendingApproval;
                          final isRejected =
                              booking.status == BookingStatus.rejected;
                          final isNoShow =
                              booking.status == BookingStatus.noShow;
                          final isCancelled =
                              booking.status == BookingStatus.cancelled;
                          // La decisión de asistencia es definitiva: una vez
                          // confirmada o rechazada, no se puede modificar.
                          final isDecided =
                              hasAttended ||
                              isNoShow ||
                              isRejected ||
                              isCancelled;

                          final rowColor = hasAttended
                              ? Colors.green
                              : isPending
                              ? Colors.amber
                              : (isRejected || isNoShow)
                              ? Colors.red
                              : isCancelled
                              ? Colors.grey
                              : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  rowColor?.withValues(alpha: 0.1) ??
                                  const Color(0xFF0F0F0F),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    rowColor?.withValues(alpha: 0.3) ??
                                    Colors.white10,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(
                                    isPending
                                        ? Icons.hourglass_top
                                        : hasAttended
                                        ? Icons.check_circle
                                        : (isNoShow || isRejected)
                                        ? Icons.cancel
                                        : isCancelled
                                        ? Icons.block
                                        : Icons.radio_button_unchecked,
                                    color: isPending
                                        ? Colors.amber
                                        : hasAttended
                                        ? Colors.green
                                        : (isNoShow || isRejected)
                                        ? Colors.red
                                        : isCancelled
                                        ? Colors.grey
                                        : Colors.white38,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking.userName,
                                        style: TextStyle(
                                          color: hasAttended
                                              ? Colors.white
                                              : Colors.white70,
                                          fontSize: 14,
                                          fontWeight: hasAttended
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      // Indicador de confirmación
                                      if (booking.status ==
                                          BookingStatus.confirmed)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                booking.userConfirmedAttendance
                                                    ? Icons.check_circle_outline
                                                    : Icons.schedule,
                                                size: 12,
                                                color:
                                                    booking
                                                        .userConfirmedAttendance
                                                    ? Colors.green
                                                    : Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                booking.userConfirmedAttendance
                                                    ? 'Confirmó asistencia'
                                                    : 'Sin confirmar',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      booking
                                                          .userConfirmedAttendance
                                                      ? Colors.green
                                                      : Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (isPending)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Confirmó por app — esperando aprobación',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ),
                                      if (isRejected)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Confirmación rechazada',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Sin decisión aún: Confirmar (asistió) o
                                // Rechazar (no asistió). Ambas son definitivas.
                                if (!isDecided) ...[
                                  IconButton(
                                    onPressed: () => _decideAttendance(
                                      context,
                                      booking,
                                      attended: true,
                                    ),
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                    tooltip: 'Confirmar (asistió)',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _decideAttendance(
                                      context,
                                      booking,
                                      attended: false,
                                    ),
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                    tooltip: 'Rechazar (no asistió)',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 12),
                      // Confirmar todos los pendientes de decisión como
                      // asistidos (definitivo). Pide confirmación previa
                      // porque la acción no es reversible.
                      if (bookings.any(
                        (b) =>
                            b.status == BookingStatus.confirmed ||
                            b.status == BookingStatus.pendingApproval,
                      ))
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    title: const Text(
                                      '¿Confirmar a todos?',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: const Text(
                                      'Todos los alumnos sin decisión quedarán '
                                      'como asistidos. Esta acción no se puede '
                                      'deshacer.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text(
                                          'Confirmar todos',
                                          style: TextStyle(
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok != true) return;
                                try {
                                  await widget.viewModel.markAllAttended(
                                    bookings,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Todos confirmados como asistidos',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.done_all, size: 16),
                              label: const Text('Confirmar todos (asistieron)'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
