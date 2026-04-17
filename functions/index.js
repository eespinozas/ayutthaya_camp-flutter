const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const {logger} = require("firebase-functions");
const {Resend} = require("resend");

admin.initializeApp();

// Configurar Resend con API Key
const RESEND_API_KEY = process.env.RESEND_API_KEY || "";
const RESEND_FROM_EMAIL = process.env.RESEND_FROM_EMAIL || "Ayutthaya Camp <no-responder@ayutthayacamp.cl>";

let resend;
if (RESEND_API_KEY) {
  resend = new Resend(RESEND_API_KEY);
  logger.info("✅ Resend configurado correctamente");
} else {
  logger.warn("⚠️ RESEND_API_KEY no configurada");
}

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

// =============================================================================
// FUNCIÓN 4: Enviar email de verificación con SendGrid
// =============================================================================
exports.sendVerificationEmail = onCall(async (request) => {
  logger.info("📧 Enviando email de verificación...");

  try {
    const {email} = request.data;

    if (!email) {
      throw new Error("Email es requerido");
    }

    // Generar link de verificación de Firebase
    const actionCodeSettings = {
      url: "https://ayutthayacamp.cl/email-verified",
      handleCodeInApp: true,
    };

    const verificationLink = await admin.auth()
        .generateEmailVerificationLink(email, actionCodeSettings);

    // Template HTML profesional
    const htmlContent = `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #FF6B00 0%, #FF8C00 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #ffffff; padding: 30px; border: 1px solid #e0e0e0; }
          .button { display: inline-block; padding: 14px 30px; background: #FF6B00; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🏋️ Bienvenido a ACMApp</h1>
          </div>
          <div class="content">
            <h2>Verifica tu dirección de correo electrónico</h2>
            <p>Gracias por registrarte en ACMApp. Para completar tu registro y acceder a todas las funcionalidades, necesitamos verificar tu dirección de correo electrónico.</p>
            <p style="text-align: center;">
              <a href="${verificationLink}" class="button">Verificar mi correo</a>
            </p>
            <p>O copia y pega este enlace en tu navegador:</p>
            <p style="word-break: break-all; background: #f5f5f5; padding: 10px; border-radius: 5px; font-size: 12px;">${verificationLink}</p>
            <p><strong>Este enlace expirará en 24 horas.</strong></p>
            <p>Si no creaste esta cuenta, puedes ignorar este correo de forma segura.</p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Ayutthaya Camp. Todos los derechos reservados.</p>
            <p>Este es un correo automático, por favor no respondas a este mensaje.</p>
          </div>
        </div>
      </body>
    </html>
    `;

    // Enviar email con Resend
    await resend.emails.send({
      from: RESEND_FROM_EMAIL,
      to: email,
      subject: "Verifica tu correo electrónico - ACMApp",
      html: htmlContent,
    });

    logger.info(`✅ Email de verificación enviado a: ${email}`);
    return {
      success: true,
      message: "Email de verificación enviado exitosamente",
    };
  } catch (error) {
    logger.error("❌ Error enviando email de verificación:", error);
    throw new Error(`Error al enviar email: ${error.message}`);
  }
});

// =============================================================================
// FUNCIÓN 5: Enviar email de recuperación de contraseña con SendGrid
// =============================================================================
exports.sendPasswordResetEmail = onCall(async (request) => {
  logger.info("🔑 Enviando email de recuperación de contraseña...");

  try {
    const {email} = request.data;

    if (!email) {
      throw new Error("Email es requerido");
    }

    // Verificar que el usuario existe
    try {
      await admin.auth().getUserByEmail(email);
    } catch (error) {
      // Por seguridad, no revelar si el email existe o no
      logger.info(`Usuario no encontrado: ${email}`);
      return {
        success: true,
        message: "Si el correo existe, recibirás instrucciones",
      };
    }

    // Generar link de recuperación
    const actionCodeSettings = {
      url: "https://ayutthayacamp.cl/login",
      handleCodeInApp: false,
    };

    const resetLink = await admin.auth()
        .generatePasswordResetLink(email, actionCodeSettings);

    // Template HTML profesional
    const htmlContent = `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #FF6B00 0%, #FF8C00 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #ffffff; padding: 30px; border: 1px solid #e0e0e0; }
          .button { display: inline-block; padding: 14px 30px; background: #FF6B00; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; margin: 20px 0; }
          .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🔐 Recuperación de Contraseña</h1>
          </div>
          <div class="content">
            <h2>Restablecer tu contraseña</h2>
            <p>Recibimos una solicitud para restablecer la contraseña de tu cuenta en ACMApp.</p>
            <p style="text-align: center;">
              <a href="${resetLink}" class="button">Restablecer Contraseña</a>
            </p>
            <p>O copia y pega este enlace en tu navegador:</p>
            <p style="word-break: break-all; background: #f5f5f5; padding: 10px; border-radius: 5px; font-size: 12px;">${resetLink}</p>
            <div class="warning">
              <strong>⚠️ Importante:</strong>
              <ul>
                <li>Este enlace expirará en 1 hora</li>
                <li>Solo se puede usar una vez</li>
                <li>Si no solicitaste este cambio, ignora este correo y tu contraseña permanecerá sin cambios</li>
              </ul>
            </div>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Ayutthaya Camp. Todos los derechos reservados.</p>
            <p>Este es un correo automático, por favor no respondas a este mensaje.</p>
          </div>
        </div>
      </body>
    </html>
    `;

    // Enviar email con Resend
    await resend.emails.send({
      from: RESEND_FROM_EMAIL,
      to: email,
      subject: "Recuperación de Contraseña - ACMApp",
      html: htmlContent,
    });

    logger.info(`✅ Email de recuperación enviado a: ${email}`);
    return {
      success: true,
      message: "Email de recuperación enviado exitosamente",
    };
  } catch (error) {
    logger.error("❌ Error enviando email de recuperación:", error);
    throw new Error(`Error al enviar email: ${error.message}`);
  }
});
