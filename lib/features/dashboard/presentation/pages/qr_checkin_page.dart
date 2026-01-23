import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../bookings/services/booking_service.dart';
import 'qr_scanner_page.dart';

class QRCheckInPage extends StatefulWidget {
  const QRCheckInPage({super.key});

  @override
  State<QRCheckInPage> createState() => _QRCheckInPageState();
}

class _QRCheckInPageState extends State<QRCheckInPage> {
  final BookingService _bookingService = BookingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text(
          'Check-in por QR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2A2A2A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icono principal
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 120,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 32),

            // Título
            const Text(
              'Registra tu asistencia',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Descripción
            const Text(
              'Escanea el código QR en el gimnasio para registrar tu asistencia a la clase',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // Instrucciones
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orangeAccent,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Cómo funciona',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionItem(
                    '1',
                    'Detección automática',
                    'El sistema detecta automáticamente qué clase está activa en el momento del escaneo',
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    '2',
                    'Ventana de 20 minutos',
                    'Si escaneas dentro de los primeros 20 minutos de iniciada una clase, se registra tu asistencia automáticamente',
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    '3',
                    'Después de 20 minutos',
                    'Si escaneas 20 minutos después de iniciada la clase, se tomará esa clase como no asistida',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón de escaneo
            ElevatedButton.icon(
              onPressed: _processing ? null : _scanQR,
              icon: _processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.qr_code_scanner),
              label: Text(
                _processing ? 'Procesando...' : 'Escanear código QR',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.orangeAccent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _scanQR() async {
    // Navegar a la página del escáner
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const QRScannerPage(),
      ),
    );

    // Si no hay resultado, el usuario canceló
    if (result == null) return;

    // Verificar que sea del tipo correcto (acepta tanto el nuevo como el antiguo)
    if (result['type'] != 'gym_checkin' && result['type'] != 'attendance_checkin') {
      _showErrorDialog('Este código QR no es válido para check-in de asistencia');
      return;
    }

    // Procesar el check-in
    await _processCheckIn(result);
  }

  Future<void> _processCheckIn(Map<String, dynamic> qrData) async {
    setState(() {
      _processing = true;
    });

    try {
      // Obtener información del usuario actual
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener datos del usuario desde Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'Usuario';
      final userEmail = userData['email'] ?? user.email ?? '';

      // Procesar el check-in (nueva firma simplificada)
      final result = await _bookingService.processQRCheckIn(
        userId: user.uid,
        userName: userName,
        userEmail: userEmail,
      );

      setState(() {
        _processing = false;
      });

      // Mostrar resultado
      if (result['success'] == true) {
        _showSuccessDialog(result);
      } else {
        _showErrorDialog(result['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      setState(() {
        _processing = false;
      });
      _showErrorDialog('Error al procesar check-in: $e');
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    final action = result['action'];
    final classTime = result['classTime'];
    final classType = result['classType'];
    final message = result['message'];

    String title;
    IconData icon;
    Color iconColor;

    switch (action) {
      case 'marked_attended':
      case 'created_and_attended':
        title = 'Asistencia Registrada';
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'already_attended':
        title = 'Ya Registrado';
        icon = Icons.info;
        iconColor = Colors.blue;
        break;
      case 'marked_no_show':
      case 'created_no_show':
        title = 'No Asistencia Registrada';
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'already_no_show':
        title = 'Ya Marcada Como No Asistida';
        icon = Icons.info;
        iconColor = Colors.orange;
        break;
      case 'booked_next_class':
        title = 'Agendado en Siguiente Clase';
        icon = Icons.calendar_today;
        iconColor = Colors.orange;
        break;
      case 'already_booked_next':
        title = 'Ya Agendado';
        icon = Icons.info;
        iconColor = Colors.blue;
        break;
      default:
        title = 'Éxito';
        icon = Icons.check_circle;
        iconColor = Colors.green;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            if (classType != null && classTime != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: action == 'marked_no_show' || action == 'created_no_show' || action == 'already_no_show'
                      ? Colors.red.withOpacity(0.2)
                      : Colors.orangeAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: action == 'marked_no_show' || action == 'created_no_show' || action == 'already_no_show'
                      ? Border.all(color: Colors.red.withOpacity(0.3))
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      classType,
                      style: TextStyle(
                        color: action == 'marked_no_show' || action == 'created_no_show' || action == 'already_no_show'
                            ? Colors.red
                            : Colors.orangeAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      classTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver al dashboard
            },
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
