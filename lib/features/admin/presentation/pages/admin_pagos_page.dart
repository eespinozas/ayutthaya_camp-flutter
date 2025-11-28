import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../viewmodels/admin_pagos_viewmodel.dart';
import '../../../payments/models/payment.dart';

class AdminPagosPage extends StatefulWidget {
  const AdminPagosPage({super.key});

  @override
  State<AdminPagosPage> createState() => _AdminPagosPageState();
}

class _AdminPagosPageState extends State<AdminPagosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdminPagosViewModel _viewModel;
  bool _localeInitialized = false;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _viewModel = AdminPagosViewModel();
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
    _viewModel.dispose();
    super.dispose();
  }

  void _viewReceipt(Payment payment) {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('🔍 VISUALIZANDO COMPROBANTE');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('Payment ID: ${payment.id}');
    debugPrint('User: ${payment.userName}');
    debugPrint('Receipt URL: ${payment.receiptUrl}');
    debugPrint('URL length: ${payment.receiptUrl.length}');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('');

    // Verificar si es un PDF o imagen
    final isPDF = payment.receiptUrl.toLowerCase().contains('.pdf');
    final isPendingUpload = payment.receiptUrl == 'pending_upload';

    debugPrint('isPDF: $isPDF');
    debugPrint('isPendingUpload: $isPendingUpload');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isPendingUpload
                    ? _buildPendingUploadView()
                    : isPDF
                        ? _buildPDFView(payment.receiptUrl)
                        : _buildImageView(payment.receiptUrl),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUploadView() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 80,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Comprobante pendiente de subida',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'El archivo aún no se ha subido a Storage',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFView(String url) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Comprobante PDF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Abrir PDF en una nueva ventana/pestaña
                debugPrint('Abriendo PDF: $url');
                // Para web, podrías usar: html.window.open(url, '_blank');
                // Para móvil, podrías usar url_launcher package
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copia la URL de la consola para abrir el PDF'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir PDF'),
            ),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageView(String url) {
    debugPrint('📸 Intentando cargar imagen desde: $url');

    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          debugPrint('✅ Imagen cargada exitosamente');
          return child;
        }
        debugPrint('⏳ Cargando imagen: ${loadingProgress.cumulativeBytesLoaded} / ${loadingProgress.expectedTotalBytes} bytes');
        return Container(
          height: 400,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cargando comprobante...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('');
        debugPrint('═══════════════════════════════════════════');
        debugPrint('❌ ERROR AL CARGAR IMAGEN');
        debugPrint('═══════════════════════════════════════════');
        debugPrint('Error: $error');
        debugPrint('Error type: ${error.runtimeType}');
        debugPrint('URL: $url');
        if (stackTrace != null) {
          debugPrint('StackTrace: $stackTrace');
        }
        debugPrint('═══════════════════════════════════════════');
        debugPrint('');

        return Container(
          height: 400,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error al cargar el comprobante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El archivo no está disponible o no se pudo cargar',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SelectableText(
                  'Error: ${error.toString()}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Revisa la consola para más detalles',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _approvePayment(Payment payment) {
    final typeStr = payment.type == PaymentType.enrollment ? 'Matrícula' : 'Mensualidad';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Aprobar Pago',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Aprobar el pago de $typeStr por \$${payment.amount.toInt()} de ${payment.userName}?\n\nEsto activará/extenderá su membresía automáticamente.',
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
            onPressed: _isProcessingPayment ? null : () async {
              // Cerrar el dialog de confirmación primero
              Navigator.pop(context);

              // Activar el loading overlay
              setState(() {
                _isProcessingPayment = true;
              });

              try {
                debugPrint('🔵 Iniciando aprobación de pago...');
                await _viewModel.approvePayment(payment.id!);
                debugPrint('🟢 Aprobación completada');

                if (!mounted) {
                  debugPrint('⚠️ Widget no montado, saliendo...');
                  return;
                }

                // Desactivar loading
                setState(() {
                  _isProcessingPayment = false;
                });

                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pago de ${payment.userName} aprobado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                debugPrint('🔴 Error al aprobar pago: $e');

                if (!mounted) {
                  debugPrint('⚠️ Widget no montado después de error, saliendo...');
                  return;
                }

                // Desactivar loading
                setState(() {
                  _isProcessingPayment = false;
                });

                // Mostrar error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al aprobar el pago: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Aprobar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _rejectPayment(Payment payment) {
    final reasonController = TextEditingController();
    final typeStr = payment.type == PaymentType.enrollment ? 'Matrícula' : 'Mensualidad';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Rechazar Pago',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rechazar el pago de $typeStr por \$${payment.amount.toInt()} de ${payment.userName}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Ej: Comprobante ilegible',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Color(0xFF1E1E1E),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
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
            onPressed: _isProcessingPayment ? null : () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un motivo'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Cerrar el dialog de rechazo primero
              Navigator.pop(context);

              // Activar el loading overlay
              setState(() {
                _isProcessingPayment = true;
              });

              try {
                debugPrint('🔵 Iniciando rechazo de pago...');
                await _viewModel.rejectPayment(payment.id!, reason);
                debugPrint('🟢 Rechazo completado');

                if (!mounted) {
                  debugPrint('⚠️ Widget no montado, saliendo...');
                  return;
                }

                // Desactivar loading
                setState(() {
                  _isProcessingPayment = false;
                });

                // Mostrar mensaje
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pago de ${payment.userName} rechazado'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                debugPrint('🔴 Error al rechazar pago: $e');

                if (!mounted) {
                  debugPrint('⚠️ Widget no montado después de error, saliendo...');
                  return;
                }

                // Desactivar loading
                setState(() {
                  _isProcessingPayment = false;
                });

                // Mostrar error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al rechazar el pago: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Rechazar',
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
            'Gestión de Pagos',
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

    return StreamBuilder<List<Payment>>(
      stream: _viewModel.getPendingPayments(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.length ?? 0;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFF1E1E1E),
              appBar: AppBar(
                backgroundColor: const Color(0xFF2A2A2A),
                title: Row(
                  children: [
                    const Text(
                      'Gestión de Pagos',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                centerTitle: false,
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.orangeAccent,
                  labelColor: Colors.orangeAccent,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Pendientes'),
                          if (pendingCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pendingCount',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Tab(text: 'Aprobados'),
                    const Tab(text: 'Rechazados'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPaymentListStream(_viewModel.getPendingPayments(), 'pending'),
                  _buildPaymentListStream(_viewModel.getApprovedPayments(), 'approved'),
                  _buildPaymentListStream(_viewModel.getRejectedPayments(), 'rejected'),
                ],
              ),
            ),
            // Overlay de loading
            if (_isProcessingPayment)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.orangeAccent,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Procesando...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentListStream(Stream<List<Payment>> stream, String status) {
    return StreamBuilder<List<Payment>>(
      stream: stream,
      builder: (context, snapshot) {
        // Agregar protección contra errores de estado
        if (!mounted) {
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        if (snapshot.hasError) {
          final error = snapshot.error;
          final errorStr = error.toString();

          // Logging detallado del error
          debugPrint('');
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('❌ ERROR EN ADMIN PAGOS PAGE - Status: $status');
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('Tipo de error: ${error.runtimeType}');
          debugPrint('Mensaje completo:');
          debugPrint(errorStr);
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('');

          // Verificar si es error de índice
          bool isIndexError = errorStr.contains('index') ||
                              errorStr.contains('FAILED_PRECONDITION') ||
                              errorStr.contains('requires an index');

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isIndexError ? Icons.storage : Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isIndexError
                        ? 'Falta crear índice de Firestore'
                        : 'Error cargando pagos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (isIndexError) ...[
                    const Text(
                      'Necesitas crear un índice compuesto en Firestore.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Índice requerido:',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Collection: payments\nFields:\n  • status (Ascending)\n  • createdAt (Descending)',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '👆 Revisa la consola para el enlace directo',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else ...[
                    SelectableText(
                      errorStr,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          String message;
          IconData icon;

          switch (status) {
            case 'pending':
              message = 'No hay pagos pendientes';
              icon = Icons.check_circle_outline;
              break;
            case 'approved':
              message = 'No hay pagos aprobados';
              icon = Icons.receipt_long;
              break;
            case 'rejected':
              message = 'No hay pagos rechazados';
              icon = Icons.cancel_outlined;
              break;
            default:
              message = 'No hay pagos';
              icon = Icons.payment;
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 80,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
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
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return _buildPaymentCard(payment, status);
          },
        );
      },
    );
  }

  Widget _buildPaymentCard(Payment payment, String status) {
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    Color borderColor;
    if (isPending) {
      borderColor = Colors.orange.withValues(alpha: 0.5);
    } else if (isApproved) {
      borderColor = Colors.green.withValues(alpha: 0.5);
    } else {
      borderColor = Colors.red.withValues(alpha: 0.5);
    }

    final typeStr = payment.type == PaymentType.enrollment ? 'Matrícula' : 'Mensualidad';
    final isEnrollment = payment.type == PaymentType.enrollment;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nombre y tipo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment.userEmail,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isEnrollment
                        ? Colors.purple.withValues(alpha: 0.2)
                        : Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isEnrollment ? Colors.purple : Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    typeStr,
                    style: TextStyle(
                      color: isEnrollment
                          ? Colors.purple.shade200
                          : Colors.blue.shade200,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),

            // Detalles del pago
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    icon: Icons.attach_money,
                    label: 'Monto',
                    value: '\$${payment.amount.toInt()}',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha',
                    value: DateFormat('dd MMM', 'es_ES').format(payment.paymentDate),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _buildInfoRow(
              icon: Icons.fitness_center,
              label: 'Plan',
              value: payment.plan,
            ),

            // Fecha de aprobación/rechazo
            if (isApproved && payment.reviewedAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.check_circle,
                label: 'Aprobado',
                value: DateFormat('dd MMM yyyy', 'es_ES')
                    .format(payment.reviewedAt!),
                color: Colors.green,
              ),
            ],

            if (isRejected) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.cancel,
                label: 'Rechazado',
                value: payment.reviewedAt != null
                    ? DateFormat('dd MMM yyyy', 'es_ES')
                        .format(payment.reviewedAt!)
                    : '-',
                color: Colors.red,
              ),
              if (payment.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
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

            const SizedBox(height: 16),

            // Botones de acción
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewReceipt(payment),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('Ver Comprobante'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approvePayment(payment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aprobar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _rejectPayment(payment),
                    icon: const Icon(Icons.close),
                    color: Colors.red,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: () => _viewReceipt(payment),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Ver Comprobante'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? Colors.white60,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            color: color ?? Colors.white60,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
