import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Servicio para manejar notificaciones push con Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    try {
      // Solicitar permisos
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('📱 Permisos de notificación: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Notificaciones autorizadas');

        // Obtener token FCM
        String? token = await _messaging.getToken();
        debugPrint('🔑 FCM Token: $token');

        // Configurar handlers
        _setupMessageHandlers();

        return;
      }

      debugPrint('❌ Notificaciones no autorizadas');
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones: $e');
    }
  }

  /// Configurar handlers para mensajes
  void _setupMessageHandlers() {
    // Mensaje cuando app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Mensaje recibido (foreground):');
      debugPrint('   Título: ${message.notification?.title}');
      debugPrint('   Cuerpo: ${message.notification?.body}');
      debugPrint('   Data: ${message.data}');

      // Aquí puedes mostrar un diálogo o notificación local
    });

    // Mensaje cuando app está en background y usuario toca notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Mensaje abierto (background):');
      debugPrint('   Data: ${message.data}');

      // Navegar a una página específica según el tipo de notificación
      _handleNotificationTap(message.data);
    });

    // Verificar si la app se abrió desde una notificación
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('🚀 App iniciada desde notificación:');
        debugPrint('   Data: ${message.data}');
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Manejar tap en notificación
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    debugPrint('👆 Notificación tocada - Tipo: $type');

    // Aquí puedes navegar a páginas específicas según el tipo
    switch (type) {
      case 'payment_approved':
        // Navegar a lista de alumnos o pagos
        break;
      case 'class_reminder':
        // Navegar a mis clases
        break;
      default:
        break;
    }
  }

  /// Guardar FCM token del usuario en Firestore
  Future<void> saveUserToken(String userId) async {
    try {
      String? token = await _messaging.getToken();

      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ FCM Token guardado para usuario: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error guardando FCM token: $e');
    }
  }

  /// Enviar notificación a un usuario específico
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Obtener el FCM token del usuario
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        debugPrint('⚠️ Usuario $userId no tiene FCM token');
        return;
      }

      // Crear documento de notificación para procesamiento
      await _firestore.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      debugPrint('✅ Notificación creada para usuario: $userId');
    } catch (e) {
      debugPrint('❌ Error enviando notificación: $e');
    }
  }

  /// Enviar notificación a todos los admins
  Future<void> sendNotificationToAdmins({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Obtener todos los admins
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (var doc in adminsSnapshot.docs) {
        final fcmToken = doc.data()['fcmToken'];

        if (fcmToken != null) {
          await _firestore.collection('notifications').add({
            'userId': doc.id,
            'fcmToken': fcmToken,
            'title': title,
            'body': body,
            'data': data ?? {},
            'createdAt': FieldValue.serverTimestamp(),
            'sent': false,
          });
        }
      }

      debugPrint('✅ Notificaciones creadas para ${adminsSnapshot.docs.length} admins');
    } catch (e) {
      debugPrint('❌ Error enviando notificaciones a admins: $e');
    }
  }

  /// Programar recordatorio de clase (30 o 15 minutos antes)
  Future<void> scheduleClassReminder({
    required String bookingId,
    required String userId,
    required String className,
    required String classTime,
    required DateTime classDate,
    required int minutesBefore, // 30 o 15
  }) async {
    try {
      final timeParts = classTime.split(':');
      final classDateTime = DateTime(
        classDate.year,
        classDate.month,
        classDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final reminderTime = classDateTime.subtract(Duration(minutes: minutesBefore));

      // Crear documento de recordatorio programado
      await _firestore.collection('scheduled_notifications').add({
        'bookingId': bookingId,
        'userId': userId,
        'title': 'Recordatorio de Clase',
        'body': 'Tu clase de $className es en $minutesBefore minutos. No olvides confirmar tu asistencia.',
        'data': {
          'type': 'class_reminder',
          'bookingId': bookingId,
          'minutesBefore': minutesBefore,
        },
        'scheduledFor': Timestamp.fromDate(reminderTime),
        'sent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('⏰ Recordatorio programado para $minutesBefore min antes: $reminderTime');
    } catch (e) {
      debugPrint('❌ Error programando recordatorio: $e');
    }
  }

  /// Cancelar recordatorios de una clase
  Future<void> cancelClassReminders(String bookingId) async {
    try {
      final reminders = await _firestore
          .collection('scheduled_notifications')
          .where('bookingId', isEqualTo: bookingId)
          .where('sent', isEqualTo: false)
          .get();

      for (var doc in reminders.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ Recordatorios cancelados para booking: $bookingId');
    } catch (e) {
      debugPrint('❌ Error cancelando recordatorios: $e');
    }
  }
}
