import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_clases_viewmodel.dart';
import '../../../schedules/models/class_schedule.dart';
import '../../../bookings/models/booking.dart';

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
      child: Consumer<AdminClasesViewModel>(
        builder: (context, viewModel, child) {
          final selectedDate = viewModel.selectedDate;
          final dayName = DateFormat('EEEE', 'es_ES').format(selectedDate);
          final dateStr = DateFormat('dd MMM yyyy', 'es_ES').format(selectedDate);
          final isToday = selectedDate.year == DateTime.now().year &&
              selectedDate.month == DateTime.now().month &&
              selectedDate.day == DateTime.now().day;

          return Scaffold(
            backgroundColor: const Color(0xFF1E1E1E),
            appBar: AppBar(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Text(
                'Gestión de Clases',
                style: TextStyle(fontWeight: FontWeight.w600),
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
                            onPressed: () => viewModel.changeDate(-1),
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
                            onPressed: () => viewModel.changeDate(1),
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
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
                            foregroundColor: Colors.orangeAccent,
                            side: const BorderSide(color: Colors.orangeAccent),
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
                          child: CircularProgressIndicator(color: Colors.orangeAccent),
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

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = schedules[index];
                          return _ClassCard(
                            schedule: schedule,
                            viewModel: viewModel,
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

  const _ClassCard({
    required this.schedule,
    required this.viewModel,
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

  @override
  Widget build(BuildContext context) {
    final status = widget.viewModel.getClassStatus(widget.schedule.time);
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return StreamBuilder<List<Booking>>(
      stream: widget.viewModel.getClassBookings(widget.schedule.id!),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final attended = bookings.where((b) => b.status == BookingStatus.attended).length;
        final total = bookings.length;
        final isFull = attended == total && total > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
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
                      const SizedBox(width: 8),
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
            const Divider(
              color: Color(0xFF3A3A3A),
              height: 1,
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: Colors.orangeAccent,
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
                      final hasAttended = booking.status == BookingStatus.attended;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: hasAttended
                              ? Colors.green.withValues(alpha: 0.1)
                              : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasAttended
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.white10,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: hasAttended,
                              onChanged: (_) async {
                                try {
                                  await widget.viewModel.toggleAttendance(
                                    booking.id!,
                                    booking.status,
                                  );
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
                              activeColor: Colors.green,
                              checkColor: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.userName,
                                    style: TextStyle(
                                      color: hasAttended ? Colors.white : Colors.white70,
                                      fontSize: 14,
                                      fontWeight: hasAttended
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  // Indicador de confirmación
                                  if (booking.status == BookingStatus.confirmed)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            booking.userConfirmedAttendance
                                                ? Icons.check_circle_outline
                                                : Icons.schedule,
                                            size: 12,
                                            color: booking.userConfirmedAttendance
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
                                              color: booking.userConfirmedAttendance
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (hasAttended)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  // Quick actions
                  if (bookings.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              await widget.viewModel.markAllAttended(bookings);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Todos marcados como asistidos'),
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
                          label: const Text('Marcar Todos'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              await widget.viewModel.unmarkAll(bookings);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Todos desmarcados'),
                                    backgroundColor: Colors.orange,
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
                          icon: const Icon(Icons.remove_done, size: 16),
                          label: const Text('Desmarcar Todos'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
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
