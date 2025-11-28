import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../payments/models/payment.dart';

class AdminPagosViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          debugPrint('      - Fields: status (Ascending), createdAt (Descending)');
          debugPrint('');
        }
      })
          .map((snapshot) {
        debugPrint('✅ Pagos pendientes recibidos: ${snapshot.docs.length}');
        return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
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
        return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
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
        return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
      });
    } catch (e) {
      debugPrint('❌ Error crítico en getRejectedPayments: $e');
      return Stream.value([]);
    }
  }

  // ---------------------------------------------------------------------------
  // Aprobar un pago
  // ---------------------------------------------------------------------------
  Future<void> approvePayment(String paymentId) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('🔄 INICIANDO APROBACIÓN DE PAGO');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('Payment ID: $paymentId');
    debugPrint('');

    try {

      // Obtener el pago
      debugPrint('⏳ Paso 1: Obteniendo documento del pago...');
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();

      if (!paymentDoc.exists) {
        debugPrint('❌ Pago no encontrado');
        throw Exception('Pago no encontrado');
      }
      debugPrint('✅ Paso 1: Pago encontrado');

      final payment = Payment.fromFirestore(paymentDoc);
      debugPrint('   - Usuario: ${payment.userName} (${payment.userId})');
      debugPrint('   - Plan: ${payment.plan}');
      debugPrint('   - Monto: \$${payment.amount}');

      final adminId = _auth.currentUser?.uid ?? 'unknown';
      debugPrint('   - Admin ID: $adminId');

      // 1. Actualizar el estado del pago
      debugPrint('');
      debugPrint('⏳ Paso 2: Actualizando estado del pago a "approved"...');
      debugPrint('   Ejecutando: payments.doc($paymentId).update()...');
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'approved',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ TIMEOUT al actualizar pago');
          throw Exception('Timeout al actualizar pago - Verifica la conexión');
        },
      );
      debugPrint('✅ Paso 2: Pago actualizado a "approved"');

      // 2. Obtener el usuario
      debugPrint('');
      debugPrint('⏳ Paso 3: Obteniendo datos del usuario...');
      final userDoc = await _firestore.collection('users').doc(payment.userId).get();

      if (!userDoc.exists) {
        debugPrint('❌ Usuario no encontrado: ${payment.userId}');
        throw Exception('Usuario no encontrado');
      }
      debugPrint('✅ Paso 3: Usuario encontrado');

      final userData = userDoc.data()!;
      debugPrint('   - Status actual: ${userData['membershipStatus']}');
      debugPrint('   - Plan actual: ${userData['planName']}');

      // 3. Calcular nueva fecha de expiración
      debugPrint('');
      debugPrint('⏳ Paso 4: Calculando fecha de expiración...');
      DateTime newExpirationDate;
      final currentStatus = userData['membershipStatus'] ?? 'none';

      if (currentStatus == 'active' && userData['expirationDate'] != null) {
        // Si ya tiene membresía activa, extender desde la fecha de expiración actual
        final currentExpiration = (userData['expirationDate'] as Timestamp).toDate();
        newExpirationDate = DateTime(
          currentExpiration.year,
          currentExpiration.month + 1, // +1 mes
          currentExpiration.day,
        );
        debugPrint('   - Extendiendo membresía existente');
        debugPrint('   - Expira actualmente: $currentExpiration');
      } else {
        // Si no tiene membresía o está vencida, comenzar desde hoy
        final now = DateTime.now();
        newExpirationDate = DateTime(
          now.year,
          now.month + 1, // +1 mes desde hoy
          now.day,
        );
        debugPrint('   - Nueva membresía desde hoy');
      }

      debugPrint('✅ Paso 4: Nueva fecha de expiración: $newExpirationDate');

      // 4. Obtener información del plan desde el pago
      debugPrint('');
      debugPrint('⏳ Paso 5: Determinando límite de clases del plan...');
      final planName = payment.plan;

      // Determinar el límite de clases basado en el nombre del plan
      int classLimit = 12; // Default: Plan Estándar

      if (planName.toLowerCase().contains('básico') || planName.contains('8')) {
        classLimit = 8;
      } else if (planName.toLowerCase().contains('estándar') || planName.toLowerCase().contains('estandar') || planName.contains('12')) {
        classLimit = 12;
      } else if (planName.toLowerCase().contains('premium') || planName.contains('20')) {
        classLimit = 20;
      } else if (planName.toLowerCase().contains('ilimitado') || planName.contains('999')) {
        classLimit = 999;
      }

      debugPrint('✅ Paso 5: Límite de clases determinado');
      debugPrint('   - Plan: $planName');
      debugPrint('   - Límite: $classLimit clases');

      // 5. Actualizar el usuario
      debugPrint('');
      debugPrint('⏳ Paso 6: Actualizando usuario en Firestore...');
      debugPrint('   Ejecutando: users.doc(${payment.userId}).update()...');
      await _firestore.collection('users').doc(payment.userId).update({
        'membershipStatus': 'active',
        'planName': planName,
        'expirationDate': Timestamp.fromDate(newExpirationDate),
        'classLimit': classLimit,
        'lastPaymentDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ TIMEOUT al actualizar usuario');
          throw Exception('Timeout al actualizar usuario - Verifica la conexión y permisos');
        },
      );

      debugPrint('✅ Paso 6: Usuario actualizado exitosamente');
      debugPrint('   - membershipStatus: active');
      debugPrint('   - planName: $planName');
      debugPrint('   - classLimit: $classLimit');
      debugPrint('   - expirationDate: $newExpirationDate');

      debugPrint('');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('✅ APROBACIÓN COMPLETADA EXITOSAMENTE');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('');

      // TODO: Enviar notificación al usuario (por email o push)

    } catch (e, stack) {
      debugPrint('❌ Error aprobando pago: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
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
