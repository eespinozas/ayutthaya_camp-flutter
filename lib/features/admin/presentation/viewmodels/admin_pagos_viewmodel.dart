import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../payments/models/payment.dart';
import '../../../payments/services/payment_service.dart';

class AdminPagosViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PaymentService _paymentService = PaymentService();

  // Streams de pagos por estado
  Stream<List<Payment>> getPendingPayments() {
    try {
      debugPrint('📡 Iniciando stream de pagos pendientes...');
      return _firestore
          .collection('payments')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('❌ ERROR en getPendingPayments:');
            debugPrint('   Tipo: ${error.runtimeType}');
            debugPrint('   Mensaje: $error');
            if (error.toString().contains('index')) {
              debugPrint('');
              debugPrint('🔴 ¡FALTA ÍNDICE DE FIRESTORE!');
              debugPrint('   Colección: payments');
              debugPrint('   Campos: status (==) + createdAt (DESCENDING)');
              debugPrint('');
              debugPrint('   Para crear el índice:');
              debugPrint('   1. Copia el enlace del error si aparece');
              debugPrint('   2. O ejecuta: firebase firestore:indexes');
              debugPrint('   3. O crea manualmente en Firebase Console:');
              debugPrint('      - Collection: payments');
              debugPrint(
                '      - Fields: status (Ascending), createdAt (Descending)',
              );
              debugPrint('');
            }
          })
          .map((snapshot) {
            debugPrint('✅ Pagos pendientes recibidos: ${snapshot.docs.length}');
            return snapshot.docs
                .map((doc) => Payment.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      debugPrint('❌ Error crítico en getPendingPayments: $e');
      return Stream.value([]);
    }
  }

  Stream<List<Payment>> getApprovedPayments() {
    try {
      debugPrint('📡 Iniciando stream de pagos aprobados...');
      return _firestore
          .collection('payments')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('❌ ERROR en getApprovedPayments:');
            debugPrint('   Tipo: ${error.runtimeType}');
            debugPrint('   Mensaje: $error');
            if (error.toString().contains('index')) {
              debugPrint('');
              debugPrint('🔴 ¡FALTA ÍNDICE DE FIRESTORE!');
              debugPrint('   Colección: payments');
              debugPrint('   Campos: status (==) + createdAt (DESCENDING)');
              debugPrint('');
            }
          })
          .map((snapshot) {
            debugPrint('✅ Pagos aprobados recibidos: ${snapshot.docs.length}');
            return snapshot.docs
                .map((doc) => Payment.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      debugPrint('❌ Error crítico en getApprovedPayments: $e');
      return Stream.value([]);
    }
  }

  Stream<List<Payment>> getRejectedPayments() {
    try {
      debugPrint('📡 Iniciando stream de pagos rechazados...');
      return _firestore
          .collection('payments')
          .where('status', isEqualTo: 'rejected')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('❌ ERROR en getRejectedPayments:');
            debugPrint('   Tipo: ${error.runtimeType}');
            debugPrint('   Mensaje: $error');
            if (error.toString().contains('index')) {
              debugPrint('');
              debugPrint('🔴 ¡FALTA ÍNDICE DE FIRESTORE!');
              debugPrint('   Colección: payments');
              debugPrint('   Campos: status (==) + createdAt (DESCENDING)');
              debugPrint('');
            }
          })
          .map((snapshot) {
            debugPrint('✅ Pagos rechazados recibidos: ${snapshot.docs.length}');
            return snapshot.docs
                .map((doc) => Payment.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      debugPrint('❌ Error crítico en getRejectedPayments: $e');
      return Stream.value([]);
    }
  }

  // Delega a PaymentService.approvePayment, que distingue enrollment vs
  // monthly y, para monthly, copia classesPerMonth/durationDays/planId del
  // plan en Firestore al user doc. La implementación previa que vivía acá
  // escribía classLimit (que nadie lee) en lugar de classesPerMonth y
  // hardcodeaba límites por substring del nombre, por lo que planes recién
  // aprobados se veían como "Sin plan" / ∞ clases en el dashboard.
  Future<void> approvePayment(String paymentId) async {
    final adminId = _auth.currentUser?.uid ?? 'unknown';
    await _paymentService.approvePayment(paymentId, adminId);
  }

  // ---------------------------------------------------------------------------
  // Rechazar un pago
  // ---------------------------------------------------------------------------
  Future<void> rejectPayment(String paymentId, String reason) async {
    try {
      debugPrint('🔄 Rechazando pago: $paymentId');
      debugPrint('   - Motivo: $reason');

      if (reason.trim().isEmpty) {
        throw Exception('Debe proporcionar un motivo de rechazo');
      }

      final adminId = _auth.currentUser?.uid ?? 'unknown';

      // Actualizar el estado del pago
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Pago rechazado exitosamente');

      // TODO: Enviar notificación al usuario informando el rechazo
      // con el motivo para que pueda corregir y enviar nuevamente
    } catch (e) {
      debugPrint('❌ Error rechazando pago: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Obtener un pago específico
  // ---------------------------------------------------------------------------
  Future<Payment?> getPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return Payment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo pago: $e');
      return null;
    }
  }
}
