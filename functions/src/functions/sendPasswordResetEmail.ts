/**
 * Send Password Reset Email Cloud Function
 * Envía correo de recuperación de contraseña con link oficial de Firebase
 */

import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {sendEmail, isValidEmail, initializeSendGrid} from "../email/emailService";
import {generateResetPasswordTemplate} from "../email/templates/resetPassword";
import {getAppConfig} from "../email/sendgridConfig";

interface SendPasswordResetEmailRequest {
  email: string;
}

interface SendPasswordResetEmailResponse {
  success: boolean;
  message: string;
}

/**
 * Cloud Function: sendPasswordResetEmail
 *
 * Genera un link de reset de contraseña oficial de Firebase y envía un correo HTML profesional
 *
 * @param {SendPasswordResetEmailRequest} data - { email: string }
 * @param {CallableContext} context - Contexto (puede ser público)
 * @returns {Promise<SendPasswordResetEmailResponse>}
 */
export const sendPasswordResetEmail = onCall<
  SendPasswordResetEmailRequest,
  Promise<SendPasswordResetEmailResponse>
>(
  {
    region: "us-central1", // Cambia según tu región preferida
    cors: true,
  },
  async (request) => {
    const requestEmail = request.data.email;

    logger.info(`🔐 Solicitud de reset de contraseña`, {
      email: requestEmail,
      authenticated: !!request.auth,
    });

    // 1. VALIDACIÓN DE EMAIL
    if (!requestEmail || !isValidEmail(requestEmail)) {
      throw new HttpsError(
        "invalid-argument",
        "Email inválido o no proporcionado"
      );
    }

    // 2. VERIFICAR QUE EL USUARIO EXISTE
    // IMPORTANTE: Por seguridad, NO revelamos si el email existe o no
    // Siempre devolvemos éxito para evitar enumeración de usuarios
    try {
      let userExists = true;
      try {
        await admin.auth().getUserByEmail(requestEmail);
      } catch (error: any) {
        if (error.code === "auth/user-not-found") {
          userExists = false;
          logger.info("⚠️ Usuario no encontrado (no se revela al cliente)", {
            email: requestEmail,
          });
        } else {
          throw error;
        }
      }

      // Si el usuario no existe, devolvemos éxito sin enviar email
      // Esto previene ataques de enumeración de usuarios
      if (!userExists) {
        logger.info("✅ Respuesta exitosa (usuario no existe, email no enviado)");
        return {
          success: true,
          message: "Si el email está registrado, recibirás un correo de recuperación",
        };
      }

      // 3. GENERAR LINK DE RESET OFICIAL DE FIREBASE
      const appConfig = getAppConfig();
      const actionCodeSettings = {
        url: `https://${appConfig.firebaseActionDomain}`, // URL de continuación
        handleCodeInApp: true,
      };

      const resetLink = await admin
        .auth()
        .generatePasswordResetLink(requestEmail, actionCodeSettings);

      logger.info("🔗 Link de reset generado", {email: requestEmail});

      // 4. GENERAR HTML DEL EMAIL
      const htmlContent = generateResetPasswordTemplate({
        resetLink,
        userEmail: requestEmail,
        logoUrl: appConfig.logoUrl,
        appName: appConfig.appName,
        supportEmail: appConfig.supportEmail,
        companyAddress: appConfig.companyAddress,
      });

      // 5. ENVIAR EMAIL VÍA SENDGRID
      initializeSendGrid();
      await sendEmail({
        to: requestEmail,
        subject: `Restablece tu contraseña - ${appConfig.appName}`,
        htmlContent,
      });

      logger.info("✅ Email de reset enviado exitosamente", {
        email: requestEmail,
      });

      return {
        success: true,
        message: "Si el email está registrado, recibirás un correo de recuperación",
      };
    } catch (error: any) {
      logger.error("❌ Error enviando email de reset:", {
        email: requestEmail,
        error: error.message,
        stack: error.stack,
      });

      // No exponer detalles técnicos al cliente
      // Siempre devolver un mensaje genérico
      throw new HttpsError(
        "internal",
        "Error al procesar la solicitud. Por favor, intenta nuevamente."
      );
    }
  }
);
