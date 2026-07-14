/**
 * Request Account Deletion Cloud Function
 * Genera un token de un solo uso y envía un correo de confirmación.
 * La cuenta NO se elimina aquí: solo cuando el usuario confirma desde
 * el enlace del correo (ver confirmAccountDeletion).
 */

import * as admin from "firebase-admin";
import * as crypto from "crypto";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {sendEmail, initializeResend} from "../email/resendService";
import {generateDeleteAccountTemplate} from "../email/templates/deleteAccount";
import {getAppConfig} from "../email/sendgridConfig";

interface RequestAccountDeletionResponse {
  success: boolean;
  message: string;
}

/** Vigencia del enlace de confirmación (24 horas). */
const TOKEN_TTL_MS = 24 * 60 * 60 * 1000;

/** Colección donde se guardan las solicitudes pendientes (solo Admin SDK). */
export const DELETION_REQUESTS_COLLECTION = "account_deletion_requests";

export const requestAccountDeletion = onCall<
  void,
  Promise<RequestAccountDeletionResponse>
>(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes estar autenticado para solicitar la eliminación de tu cuenta"
      );
    }

    const userId = request.auth.uid;

    try {
      const userRecord = await admin.auth().getUser(userId);
      const email = userRecord.email;
      if (!email) {
        throw new HttpsError("failed-precondition", "La cuenta no tiene un email asociado");
      }

      // Nombre para personalizar el correo (opcional)
      let userName: string | undefined;
      try {
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        userName = userDoc.data()?.name;
      } catch {
        // Continuar sin el nombre
      }

      // Token de un solo uso. Se guarda solo el hash: si alguien leyera la
      // colección, no podría reconstruir el enlace de confirmación.
      const token = crypto.randomBytes(32).toString("hex");
      const tokenHash = crypto.createHash("sha256").update(token).digest("hex");
      const now = Date.now();

      await admin.firestore()
        .collection(DELETION_REQUESTS_COLLECTION)
        .doc(tokenHash)
        .set({
          uid: userId,
          email,
          createdAt: admin.firestore.Timestamp.fromMillis(now),
          expiresAt: admin.firestore.Timestamp.fromMillis(now + TOKEN_TTL_MS),
          used: false,
        });

      const projectId = process.env.GCLOUD_PROJECT;
      const confirmationLink =
        `https://us-central1-${projectId}.cloudfunctions.net/confirmAccountDeletion?token=${token}`;

      const appConfig = getAppConfig();
      const htmlContent = generateDeleteAccountTemplate({
        confirmationLink,
        userEmail: email,
        userName,
        logoUrl: appConfig.logoUrl,
        appName: appConfig.appName,
        supportEmail: appConfig.supportEmail,
        companyAddress: appConfig.companyAddress,
      });

      initializeResend();
      await sendEmail({
        to: email,
        subject: `Confirma la eliminación de tu cuenta - ${appConfig.appName}`,
        htmlContent,
      });

      logger.info("✅ Correo de confirmación de eliminación enviado", {userId, email});

      return {
        success: true,
        message: "Te enviamos un correo para confirmar la eliminación de tu cuenta",
      };
    } catch (error: unknown) {
      if (error instanceof HttpsError) throw error;
      const message = error instanceof Error ? error.message : String(error);
      logger.error("❌ Error solicitando eliminación de cuenta:", {userId, error: message});
      throw new HttpsError(
        "internal",
        "No se pudo procesar la solicitud. Por favor, intenta nuevamente."
      );
    }
  }
);
