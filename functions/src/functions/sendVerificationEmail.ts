/**
 * Send Verification Email Cloud Function
 * Envía correo de verificación de email con link oficial de Firebase
 */

import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {sendEmail, isValidEmail, initializeSendGrid} from "../email/emailService";
import {generateVerifyEmailTemplate} from "../email/templates/verifyEmail";
import {getAppConfig} from "../email/sendgridConfig";

interface SendVerificationEmailRequest {
  email: string;
}

interface SendVerificationEmailResponse {
  success: boolean;
  message: string;
}

/**
 * Cloud Function: sendVerificationEmail
 *
 * Genera un link de verificación oficial de Firebase y envía un correo HTML profesional
 *
 * @param {SendVerificationEmailRequest} data - { email: string }
 * @param {CallableContext} context - Contexto de autenticación de Firebase
 * @returns {Promise<SendVerificationEmailResponse>}
 */
export const sendVerificationEmail = onCall<
  SendVerificationEmailRequest,
  Promise<SendVerificationEmailResponse>
>(
  {
    region: "us-central1", // Cambia según tu región preferida
    cors: true,
  },
  async (request) => {
    // 1. VALIDACIÓN DE AUTENTICACIÓN
    if (!request.auth) {
      logger.warn("⚠️ Intento de envío sin autenticación");
      throw new HttpsError(
        "unauthenticated",
        "Debes estar autenticado para solicitar verificación de email"
      );
    }

    const userId = request.auth.uid;
    const requestEmail = request.data.email;

    logger.info(`📨 Solicitud de verificación de email`, {
      userId,
      email: requestEmail,
    });

    // 2. VALIDACIÓN DE EMAIL
    if (!requestEmail || !isValidEmail(requestEmail)) {
      throw new HttpsError(
        "invalid-argument",
        "Email inválido o no proporcionado"
      );
    }

    // 3. VERIFICAR QUE EL EMAIL PERTENECE AL USUARIO AUTENTICADO
    try {
      const userRecord = await admin.auth().getUser(userId);

      if (userRecord.email !== requestEmail) {
        logger.warn("⚠️ Intento de verificar email que no pertenece al usuario", {
          userId,
          userEmail: userRecord.email,
          requestedEmail: requestEmail,
        });
        throw new HttpsError(
          "permission-denied",
          "No puedes solicitar verificación para un email que no es tuyo"
        );
      }

      // Verificar si ya está verificado
      if (userRecord.emailVerified) {
        logger.info("ℹ️ Email ya verificado", {userId, email: requestEmail});
        return {
          success: true,
          message: "Tu email ya está verificado",
        };
      }

      // 4. GENERAR LINK DE VERIFICACIÓN OFICIAL DE FIREBASE
      const appConfig = getAppConfig();
      const actionCodeSettings = {
        url: `https://${appConfig.firebaseActionDomain}/verify-email.html`, // URL de auto-verificación
        handleCodeInApp: false,
      };

      const firebaseLink = await admin
        .auth()
        .generateEmailVerificationLink(requestEmail, actionCodeSettings);

      // 5. EXTRAER EL oobCode DEL LINK DE FIREBASE
      // El link de Firebase tiene formato: https://.../__/auth/action?mode=verifyEmail&oobCode=XXX&...
      const url = new URL(firebaseLink);
      const oobCode = url.searchParams.get("oobCode");

      if (!oobCode) {
        throw new HttpsError("internal", "No se pudo extraer el código de verificación");
      }

      // 6. CREAR LINK DIRECTO A NUESTRA PÁGINA (BYPASS FIREBASE UI)
      const verificationLink = `https://${appConfig.firebaseActionDomain}/verify-email.html?mode=verifyEmail&oobCode=${oobCode}`;

      logger.info("🔗 Link de verificación directo generado", {
        userId,
        email: requestEmail,
        hasOobCode: !!oobCode,
      });

      // 7. GENERAR HTML DEL EMAIL
      const htmlContent = generateVerifyEmailTemplate({
        verificationLink,
        userEmail: requestEmail,
        logoUrl: appConfig.logoUrl,
        appName: appConfig.appName,
        supportEmail: appConfig.supportEmail,
        companyAddress: appConfig.companyAddress,
      });

      // 8. ENVIAR EMAIL VÍA SENDGRID
      initializeSendGrid();
      await sendEmail({
        to: requestEmail,
        subject: `Verifica tu correo electrónico - ${appConfig.appName}`,
        htmlContent,
      });

      logger.info("✅ Email de verificación enviado exitosamente", {
        userId,
        email: requestEmail,
      });

      return {
        success: true,
        message: "Email de verificación enviado exitosamente",
      };
    } catch (error: any) {
      logger.error("❌ Error enviando email de verificación:", {
        userId,
        email: requestEmail,
        error: error.message,
        stack: error.stack,
      });

      // No exponer detalles técnicos al cliente
      throw new HttpsError(
        "internal",
        "Error al enviar el email de verificación. Por favor, intenta nuevamente."
      );
    }
  }
);
