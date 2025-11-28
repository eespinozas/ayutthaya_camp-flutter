import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../payments/viewmodels/payment_viewmodel.dart';
import '../../../payments/models/payment.dart';
import '../../../plans/viewmodels/plan_viewmodel.dart';
import '../../../plans/models/plan.dart';

class PagosPage extends StatefulWidget {
  const PagosPage({super.key});

  @override
  State<PagosPage> createState() => _PagosPageState();
}

class _PagosPageState extends State<PagosPage> {
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

  void _showPaymentModal(String paymentType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentReceiptModal(
        paymentType: paymentType,
        onSubmit: (amount, date, file, bytes, fileName, planId, planName) {
          _handlePaymentSubmit(paymentType, amount, date, file, bytes, fileName, planId, planName);
        },
      ),
    );
  }

  Future<void> _handlePaymentSubmit(
      String type,
      double amount,
      DateTime date,
      File? file,
      Uint8List? bytes,
      String? fileName,
      String? planId,
      String planName) async {
    if (file == null && bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un comprobante'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final paymentVM = context.read<PaymentViewModel>();

    final user = authVM.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Colors.orangeAccent,
        ),
      ),
    );

    final paymentType =
        type == 'Matrícula' ? PaymentType.enrollment : PaymentType.monthly;

    final success = await paymentVM.createPayment(
      userId: user.uid,
      userName: user.displayName ?? user.email ?? 'Usuario',
      userEmail: user.email ?? '',
      type: paymentType,
      amount: amount,
      plan: planName,
      paymentDate: date,
      receiptFile: file,
      receiptBytes: bytes,
      receiptFileName: fileName,
    );

    // Cerrar loading
    if (mounted) Navigator.of(context).pop();

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comprobante de $type enviado exitosamente. Espera la aprobación del administrador.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${paymentVM.error ?? "No se pudo enviar el pago"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            'Pagos',
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
    final paymentVM = context.watch<PaymentViewModel>();
    final user = authVM.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Pagos',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
        ),
        body: const Center(
          child: Text(
            'Debes iniciar sesión para ver tus pagos',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Datos reales del AuthViewModel
    final status = authVM.membershipStatus;
    final expiryDate = authVM.expirationDate;
    final isEnrolled = status != 'none';
    final daysUntilExpiry = expiryDate != null
        ? expiryDate.difference(DateTime.now()).inDays
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Pagos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Estado de Membresía
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    status == 'active'
                        ? Colors.green.shade700
                        : status == 'expired'
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                    status == 'active'
                        ? Colors.green.shade900
                        : status == 'expired'
                            ? Colors.red.shade900
                            : Colors.orange.shade900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estado de Membresía',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              status == 'active'
                                  ? Icons.check_circle
                                  : status == 'expired'
                                      ? Icons.cancel
                                      : Icons.pending,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status == 'active'
                                  ? 'Activa'
                                  : status == 'expired'
                                      ? 'Vencida'
                                      : 'Pendiente',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isEnrolled) ...[
                    _buildInfoRow(
                      Icons.card_membership,
                      'Estado',
                      status == 'active'
                          ? 'Membresía Activa'
                          : status == 'expired'
                              ? 'Membresía Expirada'
                              : 'Pago Pendiente',
                    ),
                    if (expiryDate != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Vence',
                        DateFormat('dd MMM yyyy', 'es_ES').format(expiryDate),
                      ),
                    ],
                    if (daysUntilExpiry <= 7 && daysUntilExpiry > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tu membresía vence en $daysUntilExpiry ${daysUntilExpiry == 1 ? 'día' : 'días'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white70,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aún no te has matriculado en el gimnasio',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (!isEnrolled)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPaymentModal('Matrícula'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.how_to_reg, size: 24),
                        label: const Text(
                          'Matricularse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (isEnrolled) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (status == 'expired' || daysUntilExpiry <= 0)
                            ? () => _showPaymentModal('Mensualidad')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (status == 'expired' || daysUntilExpiry <= 0)
                              ? Colors.orangeAccent
                              : Colors.grey.shade700,
                          foregroundColor: (status == 'expired' || daysUntilExpiry <= 0)
                              ? Colors.black
                              : Colors.white38,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          (status == 'expired' || daysUntilExpiry <= 0)
                              ? Icons.payment
                              : Icons.lock_clock,
                          size: 24,
                        ),
                        label: Text(
                          (status == 'expired' || daysUntilExpiry <= 0)
                              ? 'Pagar Mensualidad'
                              : 'Membresía vigente',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Historial de Pagos
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Historial de Pagos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Historial de pagos con StreamBuilder
            StreamBuilder<List<Payment>>(
              stream: paymentVM.getUserPayments(user.uid),
              builder: (context, snapshot) {
                // LOG: Estado de conexión
                debugPrint('=== HISTORIAL DE PAGOS ===');
                debugPrint('ConnectionState: ${snapshot.connectionState}');
                debugPrint('HasError: ${snapshot.hasError}');
                debugPrint('Error: ${snapshot.error}');
                debugPrint('HasData: ${snapshot.hasData}');
                debugPrint('Data: ${snapshot.data}');
                debugPrint('UserId: ${user.uid}');

                if (snapshot.connectionState == ConnectionState.waiting) {
                  debugPrint('Esperando datos...');
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.orangeAccent,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint('ERROR COMPLETO: ${snapshot.error}');
                  debugPrint('STACK TRACE: ${snapshot.stackTrace}');
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Error al cargar pagos: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final payments = snapshot.data ?? [];

                if (payments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.white24,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No tienes pagos registrados',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _buildPaymentCard(payment);
                  },
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final isApproved = payment.status == PaymentStatus.approved;
    final isPending = payment.status == PaymentStatus.pending;
    final isRejected = payment.status == PaymentStatus.rejected;

    Color statusColor;
    String statusText;

    if (isApproved) {
      statusColor = Colors.green.shade600;
      statusText = 'Aprobado';
    } else if (isRejected) {
      statusColor = Colors.red.shade600;
      statusText = 'Rechazado';
    } else {
      statusColor = Colors.amber.shade700;
      statusText = 'Pendiente';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${payment.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                payment.type == PaymentType.enrollment
                    ? Icons.how_to_reg
                    : Icons.fitness_center,
                color: Colors.white60,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                payment.plan,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white60,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMM yyyy', 'es_ES').format(payment.paymentDate),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payment.type == PaymentType.enrollment ? 'Matrícula' : 'Mensualidad',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (isRejected && payment.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Motivo: ${payment.rejectionReason}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Modal para subir comprobante de pago
class PaymentReceiptModal extends StatefulWidget {
  final String paymentType;
  final Function(double amount, DateTime date, File? file, Uint8List? bytes, String? fileName, String? planId, String planName) onSubmit;

  const PaymentReceiptModal({
    super.key,
    required this.paymentType,
    required this.onSubmit,
  });

  @override
  State<PaymentReceiptModal> createState() => _PaymentReceiptModalState();
}

class _PaymentReceiptModalState extends State<PaymentReceiptModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _receiptImage;
  Uint8List? _receiptBytes; // Para web
  String? _receiptFileName; // Para web
  final ImagePicker _picker = ImagePicker();
  Plan? _selectedPlan;
  double? _registrationPrice;
  bool _loadingRegistrationPrice = false;

  @override
  void initState() {
    super.initState();
    // Resetear plan seleccionado al abrir el modal
    _selectedPlan = null;

    if (widget.paymentType == 'Matrícula') {
      _loadRegistrationPrice();
    }
  }

  Future<void> _loadRegistrationPrice() async {
    setState(() {
      _loadingRegistrationPrice = true;
    });

    try {
      final planVM = context.read<PlanViewModel>();
      final price = await planVM.getRegistrationPrice();

      if (mounted) {
        setState(() {
          _registrationPrice = price;
          _loadingRegistrationPrice = false;
          if (price != null) {
            _amountController.text = price.toStringAsFixed(0);
          }
        });
      }
    } catch (e) {
      debugPrint('Error al cargar precio de matrícula: $e');
      if (mounted) {
        setState(() {
          _loadingRegistrationPrice = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // En web, cargar bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _receiptBytes = bytes;
            _receiptFileName = image.name;
            _receiptImage = null;
          });
        } else {
          // En móvil, usar File
          setState(() {
            _receiptImage = File(image.path);
            _receiptBytes = null;
            _receiptFileName = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // En web, cargar bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _receiptBytes = bytes;
            _receiptFileName = image.name;
            _receiptImage = null;
          });
        } else {
          // En móvil, usar File
          setState(() {
            _receiptImage = File(image.path);
            _receiptBytes = null;
            _receiptFileName = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al tomar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDocument() async {
    try {
      debugPrint('=== _pickDocument iniciado ===');
      debugPrint('Plataforma: ${kIsWeb ? "Web" : "Móvil"}');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: kIsWeb, // Solo cargar bytes en web
      );

      debugPrint('Resultado de FilePicker: $result');

      if (result != null) {
        debugPrint('Archivos seleccionados: ${result.files.length}');
        debugPrint('Primer archivo - Nombre: ${result.files.single.name}');
        debugPrint('Primer archivo - Extension: ${result.files.single.extension}');
        debugPrint('Primer archivo - Size: ${result.files.single.size}');

        if (kIsWeb) {
          // En web, usar bytes
          final bytes = result.files.single.bytes;
          debugPrint('Bytes disponibles: ${bytes != null}');

          if (bytes != null) {
            debugPrint('✅ Archivo seleccionado exitosamente (web): ${result.files.single.name}');

            setState(() {
              _receiptBytes = bytes;
              _receiptFileName = result.files.single.name;
              _receiptImage = null; // Limpiar el File
            });

            debugPrint('✅ Estado actualizado con bytes (${bytes.length} bytes)');
          } else {
            debugPrint('❌ ERROR: Bytes del archivo son null');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: No se pudo leer el archivo'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // En móvil, usar path
          final path = result.files.single.path;
          debugPrint('Path disponible: ${path != null}');

          if (path != null) {
            debugPrint('✅ Archivo seleccionado exitosamente (móvil): $path');

            setState(() {
              _receiptImage = File(path);
              _receiptBytes = null; // Limpiar bytes
              _receiptFileName = null;
            });

            debugPrint('✅ Estado actualizado con File');
          } else {
            debugPrint('❌ ERROR: Path del archivo es null');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: No se pudo obtener la ruta del archivo'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        debugPrint('Usuario canceló la selección de archivo');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR en _pickDocument: $e');
      debugPrint('StackTrace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar documento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDurationText(int durationDays) {
    switch (durationDays) {
      case 30:
        return 'Mensual';
      case 90:
        return 'Trimestral';
      case 180:
        return 'Semestral';
      case 365:
        return 'Anual';
      default:
        return '$durationDays días';
    }
  }

  Widget _buildReceiptPreview() {
    // Determinar si es PDF
    bool isPdf = false;
    String fileName = '';

    if (_receiptBytes != null && _receiptFileName != null) {
      // Archivo desde web (bytes)
      isPdf = _receiptFileName!.toLowerCase().endsWith('.pdf');
      fileName = _receiptFileName!;
    } else if (_receiptImage != null) {
      // Archivo desde móvil (File)
      isPdf = _receiptImage!.path.toLowerCase().endsWith('.pdf');
      fileName = _receiptImage!.path.split('/').last;
    }

    if (isPdf) {
      // Mostrar ícono de PDF
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orangeAccent, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf,
                size: 80,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Documento PDF seleccionado',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  fileName,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mostrar imagen
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: _receiptBytes != null
                ? MemoryImage(_receiptBytes!) // Web
                : FileImage(_receiptImage!) as ImageProvider, // Móvil
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_receiptImage == null && _receiptBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un comprobante'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (widget.paymentType == 'Mensualidad' && _selectedPlan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un plan'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final amount = double.parse(_amountController.text);
      final planName = widget.paymentType == 'Matrícula'
          ? 'Matrícula'
          : (_selectedPlan?.name ?? 'Sin plan');
      final planId = _selectedPlan?.id;

      // Pasar tanto File como bytes, dependiendo de la plataforma
      widget.onSubmit(amount, _selectedDate, _receiptImage, _receiptBytes, _receiptFileName, planId, planName);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.95,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: bottomInset + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subir Comprobante',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                    widget.paymentType,
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Para matrícula: precio fijo + selector de plan
                if (widget.paymentType == 'Matrícula') ...[
                  if (_loadingRegistrationPrice)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.orangeAccent,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Cargando información...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  else if (_registrationPrice != null) ...[
                    // Precio de matrícula (solo lectura)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.how_to_reg,
                                color: Colors.orangeAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Matrícula',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${_registrationPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de plan
                    Consumer<PlanViewModel>(
                      builder: (context, planVM, _) {
                        return StreamBuilder<List<Plan>>(
                          stream: planVM.getActivePlans(),
                          builder: (context, snapshot) {
                            debugPrint('=== SELECTOR DE PLANES (MATRÍCULA) ===');
                            debugPrint('ConnectionState: ${snapshot.connectionState}');
                            debugPrint('HasError: ${snapshot.hasError}');
                            debugPrint('PlansCount: ${snapshot.data?.length ?? 0}');

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Error al cargar planes: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'No hay planes disponibles',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              );
                            }

                            final plans = snapshot.data!;

                            // Asegurarnos de que el plan seleccionado sea del mismo stream
                            // para evitar problemas de referencia
                            Plan? currentSelectedPlan;
                            if (_selectedPlan != null) {
                              try {
                                currentSelectedPlan = plans.firstWhere(
                                  (p) => p.id == _selectedPlan!.id,
                                );
                              } catch (e) {
                                currentSelectedPlan = null;
                              }
                            }

                            return DropdownButtonFormField<Plan>(
                              value: currentSelectedPlan,
                              decoration: InputDecoration(
                                hintText: 'Seleccionar Plan',
                                hintStyle: const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(Icons.card_membership, color: Colors.orangeAccent),
                                filled: true,
                                fillColor: const Color(0xFF2A2A2A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              dropdownColor: const Color(0xFF2A2A2A),
                              style: const TextStyle(color: Colors.white),
                              items: plans.map((plan) {
                                return DropdownMenuItem<Plan>(
                                  value: plan,
                                  child: Text(
                                    '${plan.name} - \$${plan.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (Plan? value) {
                                debugPrint('Plan seleccionado: ${value?.name} - \$${value?.price}');
                                setState(() {
                                  _selectedPlan = value;
                                  if (value != null) {
                                    // Calcular total: matrícula + plan
                                    final total = _registrationPrice! + value.price;
                                    _amountController.text = total.toStringAsFixed(0);
                                  } else {
                                    _amountController.text = _registrationPrice!.toStringAsFixed(0);
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor selecciona un plan';
                                }
                                return null;
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Resumen del total
                    if (_selectedPlan != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orangeAccent.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Desglose
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Matrícula:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '\$${_registrationPrice!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_selectedPlan!.name}:',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '\$${_selectedPlan!.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL A PAGAR:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${(_registrationPrice! + _selectedPlan!.price).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Error al cargar el precio de matrícula',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // Para mensualidad: selector de plan
                if (widget.paymentType == 'Mensualidad') ...[
                  Consumer<PlanViewModel>(
                    builder: (context, planVM, _) {
                      return StreamBuilder<List<Plan>>(
                        stream: planVM.getActivePlans(),
                        builder: (context, snapshot) {
                          debugPrint('=== SELECTOR DE PLANES ===');
                          debugPrint('ConnectionState: ${snapshot.connectionState}');
                          debugPrint('HasError: ${snapshot.hasError}');
                          debugPrint('Error: ${snapshot.error}');
                          debugPrint('HasData: ${snapshot.hasData}');
                          debugPrint('PlansCount: ${snapshot.data?.length ?? 0}');

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            debugPrint('ERROR cargando planes: ${snapshot.error}');
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Error al cargar planes: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            debugPrint('No hay planes disponibles');
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'No hay planes disponibles',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          final plans = snapshot.data!;
                          debugPrint('Planes encontrados: ${plans.length}');
                          for (var plan in plans) {
                            debugPrint('  - ${plan.name}: \$${plan.price}');
                          }

                          // Asegurarnos de que el plan seleccionado sea del mismo stream
                          // para evitar problemas de referencia
                          Plan? currentSelectedPlan;
                          if (_selectedPlan != null) {
                            try {
                              currentSelectedPlan = plans.firstWhere(
                                (p) => p.id == _selectedPlan!.id,
                              );
                            } catch (e) {
                              currentSelectedPlan = null;
                            }
                          }

                          return Column(
                            children: [
                              DropdownButtonFormField<Plan>(
                                value: currentSelectedPlan,
                                decoration: InputDecoration(
                                  hintText: 'Seleccionar Plan',
                                  hintStyle: const TextStyle(color: Colors.white60),
                                  prefixIcon: const Icon(Icons.card_membership, color: Colors.orangeAccent),
                                  filled: true,
                                  fillColor: const Color(0xFF2A2A2A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                dropdownColor: const Color(0xFF2A2A2A),
                                style: const TextStyle(color: Colors.white),
                                items: plans.map((plan) {
                                  return DropdownMenuItem<Plan>(
                                    value: plan,
                                    child: Text(
                                      '${plan.name} - \$${plan.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (Plan? value) {
                                  debugPrint('Plan seleccionado: ${value?.name} - \$${value?.price}');
                                  setState(() {
                                    _selectedPlan = value;
                                    if (value != null) {
                                      _amountController.text = value.price.toStringAsFixed(0);
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Por favor selecciona un plan';
                                  }
                                  return null;
                                },
                              ),
                              if (_selectedPlan != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orangeAccent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total a pagar:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '\$${_selectedPlan!.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Selector de fecha
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.orangeAccent,
                              onPrimary: Colors.black,
                              surface: Color(0xFF2A2A2A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.orangeAccent),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha del pago',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMMM yyyy', 'es_ES').format(_selectedDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Comprobante
                const Text(
                  'Comprobante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (_receiptImage == null && _receiptBytes == null) ...[
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orangeAccent,
                                side: const BorderSide(color: Colors.orangeAccent),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galería'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDocument,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orangeAccent,
                                side: const BorderSide(color: Colors.orangeAccent),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.description),
                              label: const Text('Documento'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _takePhoto,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            side: const BorderSide(color: Colors.orangeAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Mostrar archivo seleccionado (imagen o PDF)
                  _buildReceiptPreview(),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _receiptImage = null;
                        _receiptBytes = null;
                        _receiptFileName = null;
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Eliminar archivo',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Botón de enviar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Enviar Comprobante',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }
}
