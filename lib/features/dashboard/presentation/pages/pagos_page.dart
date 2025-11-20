import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PagosPage extends StatefulWidget {
  const PagosPage({super.key});

  @override
  State<PagosPage> createState() => _PagosPageState();
}

class _PagosPageState extends State<PagosPage> {
  // Mock data - en producción esto vendrá de tu base de datos
  // Estado de membresía del usuario
  final Map<String, dynamic> membershipStatus = {
    'isEnrolled': true, // Si está matriculado
    'status': 'active', // active, expired, pending
    'plan': 'Plan 3x Semana',
    'expiryDate': DateTime.now().add(const Duration(days: 15)), // Vence en 15 días
    'monthlyFee': 35000,
  };

  final List<Map<String, dynamic>> paymentHistory = [
    {
      'id': '1',
      'amount': 35000,
      'plan': 'Plan 3x Semana',
      'status': 'Pagado',
      'date': DateTime(2025, 10, 1),
      'type': 'Mensualidad',
      'receiptUrl': null,
    },
    {
      'id': '2',
      'amount': 20000,
      'plan': 'Matrícula',
      'status': 'Pendiente',
      'date': DateTime(2025, 9, 15),
      'type': 'Matrícula',
      'receiptUrl': null,
    },
    {
      'id': '3',
      'amount': 50000,
      'plan': 'Plan Ilimitado',
      'status': 'Pagado',
      'date': DateTime(2025, 9, 1),
      'type': 'Mensualidad',
      'receiptUrl': null,
    },
  ];

  void _showPaymentModal(String paymentType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentReceiptModal(
        paymentType: paymentType,
        onSubmit: (amount, date, file) {
          // TODO: Aquí subirás el comprobante a tu servidor/Firebase Storage
          _handlePaymentSubmit(paymentType, amount, date, file);
        },
      ),
    );
  }

  void _handlePaymentSubmit(
      String type, double amount, DateTime date, File? file) {
    // TODO: Implementar lógica para guardar en BD y subir archivo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comprobante de $type enviado exitosamente'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    setState(() {
      // Simulamos agregar el pago al historial
      paymentHistory.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'amount': amount,
        'plan': type == 'Matrícula' ? 'Matrícula' : membershipStatus['plan'],
        'status': 'Pendiente',
        'date': date,
        'type': type,
        'receiptUrl': file?.path,
      });

      if (type == 'Matrícula') {
        membershipStatus['isEnrolled'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEnrolled = membershipStatus['isEnrolled'] as bool;
    final status = membershipStatus['status'] as String;
    final expiryDate = membershipStatus['expiryDate'] as DateTime;
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

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
                      'Plan Actual',
                      membershipStatus['plan'],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Vence',
                      DateFormat('dd MMM yyyy', 'es_ES').format(expiryDate),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.payments,
                      'Mensualidad',
                      '\$${membershipStatus['monthlyFee']}',
                    ),
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
                        onPressed: () => _showPaymentModal('Mensualidad'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.payment, size: 24),
                        label: const Text(
                          'Pagar Mensualidad',
                          style: TextStyle(
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

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: paymentHistory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final payment = paymentHistory[index];
                return _buildPaymentCard(payment);
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

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final isPaid = payment['status'] == 'Pagado';
    final date = payment['date'] as DateTime;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
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
                '\$${payment['amount']}',
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
                  color: isPaid ? Colors.green.shade600 : Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment['status'],
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
                payment['type'] == 'Matrícula'
                    ? Icons.how_to_reg
                    : Icons.fitness_center,
                color: Colors.white60,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                payment['plan'],
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
                DateFormat('dd MMM yyyy', 'es_ES').format(date),
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
                  payment['type'],
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Modal para subir comprobante de pago
class PaymentReceiptModal extends StatefulWidget {
  final String paymentType;
  final Function(double amount, DateTime date, File? file) onSubmit;

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
  final ImagePicker _picker = ImagePicker();

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
        setState(() {
          _receiptImage = File(image.path);
        });
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
        setState(() {
          _receiptImage = File(image.path);
        });
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_receiptImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un comprobante'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final amount = double.parse(_amountController.text);
      widget.onSubmit(amount, _selectedDate, _receiptImage);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
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

                // Campo de monto
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.orangeAccent),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el monto';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingresa un monto válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

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

                if (_receiptImage == null) ...[
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
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_receiptImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _receiptImage = null;
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Eliminar imagen',
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
    );
  }
}
