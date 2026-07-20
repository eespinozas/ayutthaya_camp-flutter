/**
 * Notificaciones push (FCM)
 *
 * Migradas del index.js original (que nunca se desplegaba: el build usa
 * este árbol TypeScript). Flujo:
 *  - La app escribe en `notifications` -> sendImmediateNotification envía.
 *  - La app agenda en `scheduled_notifications` ->
 *    processScheduledNotifications (cada minuto) envía los vencidos.
 *  - cleanupOldNotifications borra los enviados hace más de 30 días.
 */

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import {logger} from "firebase-functions";

// ============================================================================
// 1. Notificaciones inmediatas: se dispara al crear un doc en `notifications`
// ============================================================================
export const sendImmediateNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Evento sin datos, omitiendo");
      return null;
    }

    const notification = snapshot.data();
    logger.info("📨 Nueva notificación:", event.params.notificationId);

    try {
      if (notification.sent) {
        logger.warn("Notificación ya enviada, omitiendo");
        return null;
      }
      if (!notification.fcmToken) {
        await snapshot.ref.update({
          sent: false,
          error: "Sin fcmToken",
          errorAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return null;
      }

      const message: admin.messaging.Message = {
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

      const response = await admin.messaging().send(message);
      logger.info("✅ Notificación enviada:", response);

      await snapshot.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        response: response,
      });
      return {success: true, messageId: response};
    } catch (error) {
      const msg = error instanceof Error ? error.message : String(error);
      logger.error("❌ Error enviando notificación:", msg);
      await snapshot.ref.update({
        sent: false,
        error: msg,
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return {success: false, error: msg};
    }
  },
);

// ============================================================================
// 2. Recordatorios programados: corre cada minuto
// ============================================================================
export const processScheduledNotifications = onSchedule(
  {
    schedule: "* * * * *",
    timeZone: "America/Santiago",
  },
  async () => {
    try {
      const now = admin.firestore.Timestamp.now();
      const fiveMinutesAgo = admin.firestore.Timestamp.fromMillis(
        now.toMillis() - 5 * 60 * 1000,
      );

      const snapshot = await admin
        .firestore()
        .collection("scheduled_notifications")
        .where("sent", "==", false)
        .where("scheduledFor", "<=", now)
        .where("scheduledFor", ">=", fiveMinutesAgo)
        .limit(50)
        .get();

      if (snapshot.empty) return;

      logger.info(`📋 ${snapshot.size} recordatorios para enviar`);
      const promises: Promise<unknown>[] = [];

      for (const doc of snapshot.docs) {
        const reminder = doc.data();

        const userDoc = await admin
          .firestore()
          .collection("users")
          .doc(reminder.userId)
          .get();

        const fcmToken = userDoc.exists ? userDoc.data()?.fcmToken : null;
        if (!fcmToken) {
          await doc.ref.update({
            sent: false,
            error: userDoc.exists ?
              "FCM token no disponible" :
              "Usuario no encontrado",
            errorAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          continue;
        }

        const message: admin.messaging.Message = {
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

        promises.push(
          admin
            .messaging()
            .send(message)
            .then((response) =>
              doc.ref.update({
                sent: true,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                response: response,
              }),
            )
            .catch((error) =>
              doc.ref.update({
                sent: false,
                error: error.message,
                errorAt: admin.firestore.FieldValue.serverTimestamp(),
              }),
            ),
        );
      }

      await Promise.all(promises);
      logger.info(`✅ ${promises.length} recordatorios procesados`);
    } catch (error) {
      logger.error("❌ Error procesando recordatorios:", error);
    }
  },
);

// ============================================================================
// 3. Limpieza diaria de notificaciones enviadas (> 30 días)
// ============================================================================
export const cleanupOldNotifications = onSchedule(
  {
    schedule: "0 2 * * *",
    timeZone: "America/Santiago",
  },
  async () => {
    try {
      const thirtyDaysAgo = admin.firestore.Timestamp.fromMillis(
        Date.now() - 30 * 24 * 60 * 60 * 1000,
      );

      const [notifications, reminders] = await Promise.all([
        admin
          .firestore()
          .collection("notifications")
          .where("sent", "==", true)
          .where("sentAt", "<=", thirtyDaysAgo)
          .limit(500)
          .get(),
        admin
          .firestore()
          .collection("scheduled_notifications")
          .where("sent", "==", true)
          .where("sentAt", "<=", thirtyDaysAgo)
          .limit(500)
          .get(),
      ]);

      const deletes = [
        ...notifications.docs.map((d) => d.ref.delete()),
        ...reminders.docs.map((d) => d.ref.delete()),
      ];
      await Promise.all(deletes);
      logger.info(`🧹 ${deletes.length} notificaciones antiguas eliminadas`);
    } catch (error) {
      logger.error("❌ Error en limpieza:", error);
    }
  },
);
