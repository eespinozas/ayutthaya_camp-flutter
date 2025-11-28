const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const {logger} = require("firebase-functions");

admin.initializeApp();

// =============================================================================
// FUNCIÓN 1: Enviar notificaciones inmediatas
// Se dispara cuando se crea un documento en la colección "notifications"
// =============================================================================
exports.sendImmediateNotification = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
      const notificationId = event.params.notificationId;
      const notification = event.data.data();

      logger.info("📨 Nueva notificación creada:", notificationId);

      try {
        // Verificar que no se haya enviado ya
        if (notification.sent) {
          logger.warn("⚠️ Notificación ya enviada, omitiendo...");
          return null;
        }

        // Construir el mensaje FCM
        const message = {
          token: notification.fcmToken,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: notification.data || {},
          android: {
            notification: {
              sound: "default",
              channelId: "default",
              priority: "high",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        // Enviar la notificación
        const response = await admin.messaging().send(message);
        logger.info("✅ Notificación enviada exitosamente:", response);

        // Marcar como enviada
        await event.data.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          response: response,
        });

        return {success: true, messageId: response};
      } catch (error) {
        logger.error("❌ Error enviando notificación:", error);

        // Guardar el error en el documento
        await event.data.ref.update({
          sent: false,
          error: error.message,
          errorAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {success: false, error: error.message};
      }
    },
);

// =============================================================================
// FUNCIÓN 2: Procesar recordatorios programados
// Se ejecuta cada minuto para revisar recordatorios pendientes
// =============================================================================
exports.processScheduledNotifications = onSchedule(
    {
      schedule: "* * * * *", // Cada minuto
      timeZone: "America/Santiago", // Zona horaria de Chile
    },
    async (event) => {
      logger.info("⏰ Procesando recordatorios programados...");

      try {
        const now = admin.firestore.Timestamp.now();
        const fiveMinutesAgo = admin.firestore.Timestamp.fromMillis(
            now.toMillis() - (5 * 60 * 1000),
        );

        // Obtener recordatorios pendientes que ya pasó su hora
        const snapshot = await admin.firestore()
            .collection("scheduled_notifications")
            .where("sent", "==", false)
            .where("scheduledFor", "<=", now)
            .where("scheduledFor", ">=", fiveMinutesAgo) // No más de 5 min atrasados
            .limit(50) // Procesar máximo 50 por ejecución
            .get();

        logger.info(`📋 Encontrados ${snapshot.size} recordatorios para enviar`);

        if (snapshot.empty) {
          logger.info("✅ No hay recordatorios pendientes");
          return null;
        }

        const promises = [];

        for (const doc of snapshot.docs) {
          const reminder = doc.data();

          // Obtener el FCM token del usuario
          const userDoc = await admin.firestore()
              .collection("users")
              .doc(reminder.userId)
              .get();

          if (!userDoc.exists) {
            logger.warn(`⚠️ Usuario no encontrado: ${reminder.userId}`);
            await doc.ref.update({
              sent: false,
              error: "Usuario no encontrado",
              errorAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            continue;
          }

          const fcmToken = userDoc.data().fcmToken;

          if (!fcmToken) {
            logger.warn(`⚠️ Usuario sin FCM token: ${reminder.userId}`);
            await doc.ref.update({
              sent: false,
              error: "FCM token no disponible",
              errorAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            continue;
          }

          // Construir mensaje FCM
          const message = {
            token: fcmToken,
            notification: {
              title: reminder.title,
              body: reminder.body,
            },
            data: reminder.data || {},
            android: {
              notification: {
                sound: "default",
                channelId: "class_reminders",
                priority: "high",
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                  category: "CLASS_REMINDER",
                },
              },
            },
          };

          // Enviar notificación
          const sendPromise = admin.messaging().send(message)
              .then((response) => {
                logger.info(`✅ Recordatorio enviado: ${doc.id}`, response);
                return doc.ref.update({
                  sent: true,
                  sentAt: admin.firestore.FieldValue.serverTimestamp(),
                  response: response,
                });
              })
              .catch((error) => {
                logger.error(`❌ Error enviando recordatorio ${doc.id}:`, error);
                return doc.ref.update({
                  sent: false,
                  error: error.message,
                  errorAt: admin.firestore.FieldValue.serverTimestamp(),
                });
              });

          promises.push(sendPromise);
        }

        // Esperar a que se envíen todos
        await Promise.all(promises);

        logger.info(`✅ Procesamiento completado. ${promises.length} recordatorios procesados`);
        return {processed: promises.length};
      } catch (error) {
        logger.error("❌ Error procesando recordatorios:", error);
        return {success: false, error: error.message};
      }
    },
);

// =============================================================================
// FUNCIÓN 3: Limpiar notificaciones antiguas (opcional)
// Se ejecuta diariamente para eliminar notificaciones enviadas hace más de 30 días
// =============================================================================
exports.cleanupOldNotifications = onSchedule(
    {
      schedule: "0 2 * * *", // Todos los días a las 2 AM
      timeZone: "America/Santiago",
    },
    async (event) => {
      logger.info("🧹 Limpiando notificaciones antiguas...");

      try {
        const thirtyDaysAgo = admin.firestore.Timestamp.fromMillis(
            Date.now() - (30 * 24 * 60 * 60 * 1000),
        );

        // Limpiar notificaciones enviadas
        const notificationsSnapshot = await admin.firestore()
            .collection("notifications")
            .where("sent", "==", true)
            .where("sentAt", "<=", thirtyDaysAgo)
            .limit(500)
            .get();

        // Limpiar recordatorios enviados o con error
        const remindersSnapshot = await admin.firestore()
            .collection("scheduled_notifications")
            .where("sent", "==", true)
            .where("sentAt", "<=", thirtyDaysAgo)
            .limit(500)
            .get();

        const deletePromises = [];

        notificationsSnapshot.forEach((doc) => {
          deletePromises.push(doc.ref.delete());
        });

        remindersSnapshot.forEach((doc) => {
          deletePromises.push(doc.ref.delete());
        });

        await Promise.all(deletePromises);

        logger.info(`✅ Limpieza completada. ${deletePromises.length} documentos eliminados`);
        return {deleted: deletePromises.length};
      } catch (error) {
        logger.error("❌ Error limpiando notificaciones:", error);
        return {success: false, error: error.message};
      }
    },
);
