/**
 * Send Password Reset Email Cloud Function
 * Envía correo de recuperación de contraseña con link oficial de Firebase
 */

import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {sendEmail, isValidEmail, initializeResend} from "../email/resendService";
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
    try {
      let userRecord;
      try {
        userRecord = await admin.auth().getUserByEmail(requestEmail);
      } catch (error: any) {
        if (error.code === "auth/user-not-found") {
          logger.info("⚠️ Usuario no encontrado", {
            email: requestEmail,
          });
          throw new HttpsError(
            "not-found",
            "Este correo electrónico no está registrado"
          );
        } else {
          throw error;
        }
      }

      // 3. OBTENER NOMBRE DEL USUARIO DESDE FIRESTORE
      let userName: string | undefined;
      try {
        const userDoc = await admin.firestore().collection("users").doc(userRecord.uid).get();
        userName = userDoc.data()?.name;
      } catch (error) {
        logger.warn("⚠️ No se pudo obtener el nombre del usuario desde Firestore", {
          uid: userRecord.uid,
        });
        // Continuar sin el nombre
      }

      // 4. GENERAR LINK DE RESET OFICIAL DE FIREBASE
      const appConfig = getAppConfig();
      const actionCodeSettings = {
        url: `https://${appConfig.firebaseActionDomain}`, // URL de continuación
        handleCodeInApp: true,
      };

      const resetLink = await admin
        .auth()
        .generatePasswordResetLink(requestEmail, actionCodeSettings);

      logger.info("🔗 Link de reset generado", {email: requestEmail, userName});

      // 5. GENERAR HTML DEL EMAIL CON PERSONALIZACIÓN
      const htmlContent = generateResetPasswordTemplate({
        resetLink,
        userEmail: requestEmail,
        userName,
        logoUrl: appConfig.logoUrl,
        appName: appConfig.appName,
        supportEmail: appConfig.supportEmail,
        companyAddress: appConfig.companyAddress,
      });

      // 6. ENVIAR EMAIL VÍA RESEND
      initializeResend();
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
        message: "Email de recuperación enviado exitosamente",
      };
    } catch (error: any) {
      // Si ya es un HttpsError, re-lanzarlo sin modificar (ej: not-found, invalid-argument)
      if (error instanceof HttpsError) {
        throw error;
      }

      // Para otros errores inesperados, registrar y devolver mensaje genérico
      logger.error("❌ Error inesperado enviando email de reset:", {
        email: requestEmail,
        error: error.message,
        stack: error.stack,
      });

      throw new HttpsError(
        "internal",
        "Error al procesar la solicitud. Por favor, intenta nuevamente."
      );
    }
  }
);
