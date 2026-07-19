import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../bookings/models/booking.dart';
import '../../../../core/services/ranking_service.dart';

/// Historial de clases de un alumno (vista admin).
///
/// Muestra todas sus reservas (pasadas y futuras) con su estado, más un
/// resumen: asistidas, no asistidas y el rango actual del ranking.
class AdminAlumnoHistorialPage extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const AdminAlumnoHistorialPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  /// Query por userId + createdAt: usa el índice compuesto existente.
  /// El orden por fecha de clase se resuelve en cliente (volúmenes chicos).
  Stream<List<Booking>> _bookingsStream() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
          bookings.sort((a, b) {
            final byDate = b.classDate.compareTo(a.classDate);
            if (byDate != 0) return byDate;
            return b.scheduleTime.compareTo(a.scheduleTime);
          });
          return bookings;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              userEmail,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        centerTitle: false,
      ),
      // El formato de fechas 'es_ES' se inicializa por página (no hay
      // inicialización global en main).
      body: FutureBuilder<void>(
        future: initializeDateFormatting('es_ES', null),
        builder: (context, localeSnapshot) {
          if (localeSnapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
            );
          }
          return _buildBody();
        },
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<Booking>>(
      stream: _bookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error al cargar historial: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final bookings = snapshot.data ?? [];

        final asistidas = bookings
            .where((b) => b.status == BookingStatus.attended)
            .length;
        final noAsistidas = bookings
            .where(
              (b) =>
                  b.status == BookingStatus.noShow ||
                  b.status == BookingStatus.rejected,
            )
            .length;
        final pendientes = bookings
            .where((b) => b.status == BookingStatus.pendingApproval)
            .length;
        final rango = RankingService.rangoDesdeClases(asistidas);

        return Column(
          children: [
            // Resumen
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6A00).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.military_tech,
                        color: Color(0xFFFF6A00),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rango.nombre,
                        style: const TextStyle(
                          color: Color(0xFFFF6A00),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$asistidas clases válidas',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStat('Total', '${bookings.length}', Colors.white),
                      _buildStat('Asistidas', '$asistidas', Colors.green),
                      _buildStat('No asistió', '$noAsistidas', Colors.red),
                      if (pendientes > 0)
                        _buildStat('Pendientes', '$pendientes', Colors.amber),
                    ],
                  ),
                ],
              ),
            ),

            // Historial
            Expanded(
              child: bookings.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.white24),
                          SizedBox(height: 16),
                          Text(
                            'Este alumno aún no tiene\nreservas registradas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) =>
                          _buildBookingTile(bookings[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  ({Color color, String text, IconData icon}) _statusInfo(Booking booking) {
    switch (booking.status) {
      case BookingStatus.attended:
        return (color: Colors.green, text: 'Asistió', icon: Icons.check_circle);
      case BookingStatus.noShow:
        return (color: Colors.red, text: 'No asistió', icon: Icons.cancel);
      case BookingStatus.rejected:
        return (color: Colors.red, text: 'Rechazada', icon: Icons.block);
      case BookingStatus.pendingApproval:
        return (
          color: Colors.amber,
          text: 'Esperando aprobación',
          icon: Icons.hourglass_top,
        );
      case BookingStatus.cancelled:
        return (
          color: Colors.orange,
          text: 'Cancelada',
          icon: Icons.event_busy,
        );
      case BookingStatus.confirmed:
        return booking.isPast()
            ? (
                color: Colors.grey,
                text: 'Sin resolver',
                icon: Icons.help_outline,
              )
            : (
                color: const Color(0xFFFF6A00),
                text: 'Agendada',
                icon: Icons.event_available,
              );
    }
  }

  Widget _buildBookingTile(Booking booking) {
    final status = _statusInfo(booking);
    final fecha = DateFormat(
      'EEE dd MMM yyyy',
      'es_ES',
    ).format(booking.classDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: status.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: status.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$fecha · ${booking.scheduleTime}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.scheduleType,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.text,
              style: TextStyle(
                color: status.color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
