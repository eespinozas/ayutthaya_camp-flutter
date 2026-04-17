import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/payment.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/config/app_constants.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Formatos de archivo permitidos para comprobantes
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  /// Verificar si existe un pago duplicado según el tipo:
  /// - Matrícula: 1 vez al AÑO
  /// - Mensualidad: 1 vez al MES
  Future<Map<String, dynamic>> _checkDuplicatePayment(String userId, PaymentType type) async {
    try {
      final now = DateTime.now();

      // ✅ FIX #4: Para MATRÍCULA, validar membresía activa y fecha de última matrícula
      if (type == PaymentType.enrollment) {
        debugPrint('🔍 Verificando condiciones para nueva matrícula...');

        // Verificar estado de membresía actual
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final membershipStatus = userData['membershipStatus'] ?? 'none';

          // Si tiene membresía activa, bloquear
          if (membershipStatus == 'active') {
            return {
              'allowed': false,
              'message': 'Ya tienes una membresía activa.\n\n'
                  'Para extender tu plan, realiza un pago de mensualidad en lugar de matrícula.',
            };
          }

          // Si tiene pago pendiente, bloquear
          if (membershipStatus == 'pending') {
            return {
              'allowed': false,
              'message': 'Ya tienes un pago de matrícula pendiente de aprobación.\n\n'
                  'Por favor espera la revisión del administrador antes de enviar otro comprobante.',
            };
          }

          // Verificar fecha de última matrícula (solo si fue aprobada)
          final enrollmentDate = userData['enrollmentDate'] as Timestamp?;
          if (enrollmentDate != null) {
            final lastEnrollment = enrollmentDate.toDate();
            final daysSinceEnrollment = now.difference(lastEnrollment).inDays;

            debugPrint('   Última matrícula: $lastEnrollment');
            debugPrint('   Días desde última matrícula: $daysSinceEnrollment');

            if (daysSinceEnrollment < MembershipConstants.minDaysForRenewEnrollment) {
              final daysRemaining = MembershipConstants.minDaysForRenewEnrollment - daysSinceEnrollment;
              return {
                'allowed': false,
                'message': 'Solo puedes renovar tu matrícula después de 1 año.\n\n'
                    'Tu última matrícula fue el ${lastEnrollment.day}/${lastEnrollment.month}/${lastEnrollment.year}.\n'
                    'Podrás renovar en $daysRemaining días.',
              };
            }
          }
        }

        debugPrint('✅ Usuario puede realizar nueva matrícula');
        return {'allowed': true};
      }

      // Para MENSUALIDAD: Verificar en el mes actual (lógica original)
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      debugPrint('🔍 Verificando pagos duplicados de mensualidad:');
      debugPrint('   Desde: $startDate');
      debugPrint('   Hasta: $endDate');

      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      debugPrint('   Pagos encontrados: ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) {
        final existingPayment = Payment.fromFirestore(snapshot.docs.first);

        if (existingPayment.status == PaymentStatus.pending) {
          return {
            'allowed': false,
            'message': 'Ya tienes un pago de mensualidad pendiente de revisión este mes.\n\n'
                'Por favor espera a que sea revisado antes de enviar otro.',
          };
        } else if (existingPayment.status == PaymentStatus.approved) {
          return {
            'allowed': false,
            'message': 'Ya realizaste el pago de mensualidad este mes.\n\n'
                'Solo puedes pagar una vez por mes.',
          };
        } else if (existingPayment.status == PaymentStatus.rejected) {
          // Si fue rechazado, permitir crear uno nuevo
          debugPrint('✅ Pago anterior rechazado, se permite crear nuevo pago');
          return {'allowed': true};
        }

        return {
          'allowed': false,
          'message': 'Ya existe un registro de pago de mensualidad este mes.',
        };
      }

      return {'allowed': true};
    } catch (e) {
      debugPrint('⚠️ Error verificando pagos duplicados: $e');
      // En caso de error, ser conservadores y no permitir
      return {
        'allowed': false,
        'message': 'Error al verificar pagos anteriores. Por favor intenta nuevamente.',
      };
    }
  }

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

      // Verificar si ya existe un pago duplicado (matrícula: anual, mensualidad: mensual)
      debugPrint('🔍 Verificando pagos duplicados...');
      final paymentCheck = await _checkDuplicatePayment(userId, type);
      if (paymentCheck['allowed'] == false) {
        debugPrint('⚠️ ${paymentCheck['message']}');
        throw Exception(paymentCheck['message']);
      }
      debugPrint('✅ No hay pagos duplicados, continuando...');

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

      // Notificar a admins sobre nuevo pago pendiente
      try {
        final paymentTypeText = type == PaymentType.enrollment ? 'Matrícula' : 'Mensualidad';
        await NotificationService().sendNotificationToAdmins(
          title: '💳 Nuevo Comprobante de Pago',
          body: '$userName subió comprobante de $paymentTypeText - Plan: $plan',
          data: {
            'type': 'new_payment',
            'paymentId': docRef.id,
            'userId': userId,
            'paymentType': type.name,
            'plan': plan,
            'amount': amount.toString(),
          },
        );
        debugPrint('✅ Notificación de nuevo pago enviada a admins');
      } catch (e) {
        debugPrint('⚠️ Error enviando notificación de nuevo pago: $e');
        // No lanzar error, el pago ya se creó
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
      // Obtener datos del pago antes de actualizar
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      final paymentData = paymentDoc.data();

      if (paymentData == null) {
        throw Exception('Pago no encontrado');
      }

      // Actualizar estado del pago
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.rejected.name,
        'rejectionReason': reason,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // ✅ FIX #3: Notificar al usuario del rechazo
      if (MembershipConstants.notifyUserOnPaymentRejection) {
        final userId = paymentData['userId'] as String;
        final paymentType = paymentData['type'] as String;
        final paymentTypeText = paymentType == 'enrollment' ? 'matrícula' : 'mensualidad';

        await NotificationService().sendNotificationToUser(
          userId: userId,
          title: '❌ Pago Rechazado',
          body: 'Tu comprobante de $paymentTypeText ha sido rechazado.\n\n'
              'Motivo: $reason\n\n'
              'Por favor sube un nuevo comprobante válido.',
          data: {
            'type': 'payment_rejected',
            'paymentId': paymentId,
            'reason': reason,
            'paymentType': paymentType,
          },
        );

        debugPrint('✅ Usuario notificado del rechazo: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error al rechazar pago: $e');
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

  /// Eliminar pago fallido (para permitir reintento)
  Future<void> deleteFailedPayment(String paymentId) async {
    try {
      debugPrint('Eliminando pago fallido: $paymentId');
      await _firestore.collection('payments').doc(paymentId).delete();
      debugPrint('✅ Pago fallido eliminado');
    } catch (e) {
      debugPrint('❌ Error eliminando pago fallido: $e');
      throw Exception('Error al eliminar pago: $e');
    }
  }

  /// Verificar si hay pagos fallidos recientes para un usuario
  Future<List<Payment>> getFailedPayments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: PaymentStatus.failed.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo pagos fallidos: $e');
      return [];
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
