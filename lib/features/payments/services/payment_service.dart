import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/payment.dart';
import '../../../core/services/notification_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Formatos de archivo permitidos para comprobantes
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  /// Crear un pago y subir el comprobante
  Future<String> createPayment({
    required String userId,
    required String userName,
    required String userEmail,
    required PaymentType type,
    required double amount,
    required String plan,
    required DateTime paymentDate,
    File? receiptFile,
    Uint8List? receiptBytes,
    String? receiptFileName,
  }) async {
    try {
      debugPrint('=== PaymentService.createPayment ===');
      debugPrint('receiptFile: ${receiptFile != null}');
      debugPrint('receiptBytes: ${receiptBytes != null}');
      debugPrint('receiptFileName: $receiptFileName');

      // Validar que al menos uno esté presente
      if (receiptFile == null && receiptBytes == null) {
        throw Exception('Se requiere un archivo o bytes del comprobante');
      }

      // Subir archivo a Firebase Storage
      debugPrint('📤 Subiendo comprobante a Firebase Storage...');
      final downloadUrl = await _uploadReceiptToStorage(
        userId: userId,
        receiptFile: receiptFile,
        receiptBytes: receiptBytes,
        receiptFileName: receiptFileName,
      );
      debugPrint('✅ Comprobante subido exitosamente: $downloadUrl');

      // Crear documento en Firestore
      final payment = Payment(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        type: type,
        amount: amount,
        plan: plan,
        paymentDate: paymentDate,
        receiptUrl: downloadUrl,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('payments').add(payment.toMap());
      debugPrint('✅ Pago creado exitosamente con ID: ${docRef.id}');

      // Si es pago de matrícula, actualizar estado del usuario a "pending"
      if (type == PaymentType.enrollment) {
        debugPrint('📝 Actualizando usuario a estado "pending" (esperando aprobación de matrícula)');
        await _firestore.collection('users').doc(userId).update({
          'membershipStatus': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ Usuario actualizado a estado "pending"');
      }

      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR en createPayment: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Error al crear pago: $e');
    }
  }

  /// Obtener pagos del usuario
  Stream<List<Payment>> getUserPayments(String userId) {
    debugPrint('PaymentService.getUserPayments - userId: $userId');

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      debugPrint('PaymentService - Snapshot recibido: ${snapshot.docs.length} documentos');

      try {
        final payments = snapshot.docs.map((doc) {
          debugPrint('Procesando documento: ${doc.id}');
          debugPrint('Data: ${doc.data()}');
          return Payment.fromFirestore(doc);
        }).toList();

        debugPrint('PaymentService - Total pagos procesados: ${payments.length}');
        return payments;
      } catch (e, stackTrace) {
        debugPrint('ERROR en getUserPayments: $e');
        debugPrint('STACK TRACE: $stackTrace');
        rethrow;
      }
    }).handleError((error, stackTrace) {
      debugPrint('ERROR en Stream getUserPayments: $error');
      debugPrint('STACK TRACE: $stackTrace');
      throw error;
    });
  }

  /// Obtener todos los pagos (admin)
  Stream<List<Payment>> getAllPayments() {
    return _firestore
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    });
  }

  /// Obtener pagos por estado (admin)
  Stream<List<Payment>> getPaymentsByStatus(PaymentStatus status) {
    return _firestore
        .collection('payments')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    });
  }

  /// Aprobar pago (admin)
  Future<void> approvePayment(String paymentId, String adminId) async {
    try {
      debugPrint('=== PaymentService.approvePayment ===');
      debugPrint('paymentId: $paymentId');
      debugPrint('adminId: $adminId');

      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();

      if (!paymentDoc.exists) {
        debugPrint('❌ ERROR: Pago no encontrado');
        throw Exception('Pago no encontrado');
      }

      final payment = Payment.fromFirestore(paymentDoc);
      debugPrint('Tipo de pago: ${payment.type.name}');
      debugPrint('Usuario: ${payment.userId}');
      debugPrint('Plan: ${payment.plan}');

      // Actualizar pago
      debugPrint('Actualizando estado del pago a "approved"...');
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.approved.name,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Pago actualizado exitosamente');

      // Actualizar usuario según tipo de pago
      if (payment.type == PaymentType.enrollment) {
        debugPrint('Procesando matrícula...');
        await _updateUserAfterEnrollment(payment.userId);
      } else {
        debugPrint('Procesando pago mensual...');
        await _updateUserAfterMonthlyPayment(payment.userId, payment.plan);
      }

      // Enviar notificación a admins
      try {
        await NotificationService().sendNotificationToAdmins(
          title: 'Nuevo Pago Aprobado',
          body: 'Se ha aprobado el pago de ${payment.userName} - Plan: ${payment.plan}',
          data: {
            'type': 'payment_approved',
            'paymentId': paymentId,
            'userId': payment.userId,
          },
        );
        debugPrint('✅ Notificación enviada a admins');
      } catch (e) {
        debugPrint('⚠️ Error enviando notificación: $e');
        // No lanzar error, el pago ya se aprobó
      }

      debugPrint('✅ Aprobación de pago completada');
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR en approvePayment: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Error al aprobar pago: $e');
    }
  }

  /// Rechazar pago (admin)
  Future<void> rejectPayment(String paymentId, String adminId, String reason) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.rejected.name,
        'rejectionReason': reason,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al rechazar pago: $e');
    }
  }

  /// Actualizar usuario después de aprobar matrícula
  Future<void> _updateUserAfterEnrollment(String userId) async {
    try {
      debugPrint('=== Actualizando usuario después de matrícula ===');
      debugPrint('userId: $userId');

      final now = DateTime.now();
      final expirationDate = now.add(const Duration(days: 30));

      debugPrint('Fecha de expiración: $expirationDate');

      await _firestore.collection('users').doc(userId).update({
        'membershipStatus': 'active',
        'enrollmentDate': FieldValue.serverTimestamp(),
        'lastPaymentDate': FieldValue.serverTimestamp(),
        'expirationDate': Timestamp.fromDate(expirationDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Usuario actualizado exitosamente con membershipStatus: active');
    } catch (e) {
      debugPrint('❌ ERROR al actualizar usuario: $e');
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  /// Actualizar usuario después de pago mensual
  Future<void> _updateUserAfterMonthlyPayment(String userId, String planName) async {
    try {
      debugPrint('=== Actualizando usuario después de pago mensual ===');
      debugPrint('userId: $userId');
      debugPrint('plan: $planName');

      // Buscar el plan en Firestore para obtener su información
      final plansQuery = await _firestore
          .collection('plans')
          .where('name', isEqualTo: planName)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (plansQuery.docs.isEmpty) {
        debugPrint('⚠️ Plan no encontrado en Firestore, usando configuración por defecto');
        // Fallback a configuración anterior
        await _updateUserWithDefaultPlan(userId, planName);
        return;
      }

      final planDoc = plansQuery.docs.first;
      final planData = planDoc.data();
      final planId = planDoc.id;
      final durationDays = planData['durationDays'] ?? 30;
      final classesPerMonth = planData['classesPerMonth']; // null = ilimitado

      debugPrint('Plan encontrado:');
      debugPrint('  - ID: $planId');
      debugPrint('  - Duración: $durationDays días');
      debugPrint('  - Clases/mes: ${classesPerMonth ?? "ilimitado"}');

      final now = DateTime.now();
      final expirationDate = now.add(Duration(days: durationDays));
      debugPrint('Nueva fecha de expiración: $expirationDate');

      // Actualizar usuario con información del plan
      final updateData = {
        'membershipStatus': 'active',
        'lastPaymentDate': FieldValue.serverTimestamp(),
        'expirationDate': Timestamp.fromDate(expirationDate),
        'planId': planId,
        'planName': planName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Agregar classesPerMonth solo si no es null (no agregar para planes ilimitados)
      if (classesPerMonth != null) {
        updateData['classesPerMonth'] = classesPerMonth;
      } else {
        // Plan ilimitado - eliminar el campo si existía
        updateData['classesPerMonth'] = FieldValue.delete();
      }

      await _firestore.collection('users').doc(userId).update(updateData);

      debugPrint('✅ Usuario actualizado exitosamente:');
      debugPrint('   - membershipStatus: active');
      debugPrint('   - planId: $planId');
      debugPrint('   - planName: $planName');
      debugPrint('   - classesPerMonth: ${classesPerMonth ?? "ilimitado"}');
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR al actualizar usuario: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  /// Actualizar usuario con configuración por defecto (fallback)
  Future<void> _updateUserWithDefaultPlan(String userId, String planName) async {
    final now = DateTime.now();
    int daysToAdd = 30;

    switch (planName.toLowerCase()) {
      case 'trimestral':
        daysToAdd = 90;
        break;
      case 'semestral':
        daysToAdd = 180;
        break;
      case 'anual':
        daysToAdd = 365;
        break;
      default:
        daysToAdd = 30;
    }

    final expirationDate = now.add(Duration(days: daysToAdd));

    await _firestore.collection('users').doc(userId).update({
      'membershipStatus': 'active',
      'lastPaymentDate': FieldValue.serverTimestamp(),
      'expirationDate': Timestamp.fromDate(expirationDate),
      'planName': planName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Usuario actualizado con configuración por defecto');
  }

  /// Verificar si el usuario tiene matrícula aprobada
  Future<bool> hasApprovedEnrollment(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: PaymentType.enrollment.name)
          .where('status', isEqualTo: PaymentStatus.approved.name)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar matrícula: $e');
    }
  }

  /// Validar formato de archivo y obtener extensión
  String _getValidatedFileExtension(File file) {
    // Obtener extensión del archivo
    final filePath = file.path;
    final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');

    debugPrint('Validando archivo: $filePath');
    debugPrint('Extensión detectada: $extension');

    // Validar que la extensión esté permitida
    if (!allowedExtensions.contains(extension)) {
      throw Exception(
        'Formato de archivo no permitido. Solo se aceptan: ${allowedExtensions.join(", ").toUpperCase()}',
      );
    }

    return extension;
  }

  /// Subir comprobante a Firebase Storage
  Future<String> _uploadReceiptToStorage({
    required String userId,
    File? receiptFile,
    Uint8List? receiptBytes,
    String? receiptFileName,
  }) async {
    try {
      // Determinar el nombre del archivo y extensión
      String fileName;
      String extension;

      if (receiptFile != null) {
        // Plataforma móvil - usar File
        extension = _getValidatedFileExtension(receiptFile);
        fileName = path.basename(receiptFile.path);
      } else if (receiptBytes != null && receiptFileName != null) {
        // Plataforma web - usar bytes
        extension = path.extension(receiptFileName).toLowerCase().replaceAll('.', '');

        // Validar extensión
        if (!allowedExtensions.contains(extension)) {
          throw Exception(
            'Formato de archivo no permitido. Solo se aceptan: ${allowedExtensions.join(", ").toUpperCase()}',
          );
        }

        fileName = receiptFileName;
      } else {
        throw Exception('No se proporcionó un archivo válido');
      }

      // Generar ruta única en Storage: receipts/{userId}/{timestamp}_{fileName}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'receipts/$userId/${timestamp}_$fileName';

      debugPrint('📁 Ruta de almacenamiento: $storagePath');

      // Referencia al archivo en Storage
      final storageRef = _storage.ref().child(storagePath);

      // Subir el archivo
      UploadTask uploadTask;
      if (receiptFile != null) {
        // Subir desde File (móvil)
        uploadTask = storageRef.putFile(receiptFile);
      } else {
        // Subir desde bytes (web)
        uploadTask = storageRef.putData(
          receiptBytes!,
          SettableMetadata(contentType: _getContentType(extension)),
        );
      }

      // Esperar a que se complete la subida
      final snapshot = await uploadTask;
      debugPrint('📤 Archivo subido: ${snapshot.totalBytes} bytes');

      // Obtener URL de descarga
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('🔗 URL de descarga: $downloadUrl');

      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR subiendo comprobante a Storage: $e');
      debugPrint('StackTrace: $stackTrace');
      throw Exception('Error al subir comprobante: $e');
    }
  }

  /// Obtener content-type según extensión
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
