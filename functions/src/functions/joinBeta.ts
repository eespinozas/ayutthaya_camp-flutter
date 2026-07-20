/**
 * Join Beta Cloud Function
 * Registra un correo como interesado en la beta de Android (closed testing
 * de Google Play). El correo queda en Firestore (beta_signups); el admin lo
 * agrega a la lista de testers en Play Console (scripts/export_beta_signups.py)
 * y el tester se une con el link público de opt-in que devuelve esta función.
 */

import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {isValidEmail} from "../email/resendService";

interface JoinBetaRequest {
  email: string;
}

interface JoinBetaResponse {
  success: boolean;
  message: string;
  alreadyRegistered: boolean;
  /** Paso 1: unirse al Google Group (autoservicio, habilita el acceso) */
  groupUrl: string;
  /** Paso 2: link de opt-in de la beta en Play */
  inviteUrl: string;
}

/**
 * Cloud Function: joinBeta
 *
 * Pública (no requiere autenticación): el formulario de inscripción a la beta
 * se usa antes de tener cuenta.
 *
 * @param {JoinBetaRequest} data - { email: string }
 * @returns {Promise<JoinBetaResponse>}
 */
export const joinBeta = onCall<JoinBetaRequest, Promise<JoinBetaResponse>>(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    const email = (request.data?.email || "").trim().toLowerCase();

    // 1. VALIDACIÓN DE EMAIL
    if (!email || !isValidEmail(email)) {
      throw new HttpsError(
        "invalid-argument",
        "Email inválido o no proporcionado"
      );
    }

    logger.info("🧪 Solicitud de inscripción a la beta", {email});

    const signupRef = admin.firestore().collection("beta_signups").doc(email);

    try {
      // 2. IDEMPOTENCIA: si ya se inscribió, no repetir la invitación
      const inviteUrl =
        process.env.BETA_INVITE_URL ||
        "https://play.google.com/apps/testing/com.ayutthaya.ayutthaya_camp";
      const groupUrl = process.env.BETA_GROUP_URL || "";

      const existing = await signupRef.get();
      if (existing.exists) {
        return {
          success: true,
          alreadyRegistered: true,
          groupUrl,
          inviteUrl,
          message: "Este correo ya está inscrito en la beta.",
        };
      }

      // 3. REGISTRAR LA INSCRIPCIÓN EN FIRESTORE
      // El admin agrega estos correos a la lista de testers de Play Console
      // (Testing > Closed testing) con scripts/export_beta_signups.py.
      await signupRef.set({
        email,
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("✅ Inscripción a la beta registrada", {email});

      return {
        success: true,
        alreadyRegistered: false,
        groupUrl,
        inviteUrl,
        message: "¡Inscripción exitosa!",
      };
    } catch (error: any) {
      if (error instanceof HttpsError) {
        throw error;
      }

      logger.error("❌ Error inscribiendo tester a la beta", {
        email,
        error: error.message,
        stack: error.stack,
      });

      throw new HttpsError(
        "internal",
        "No se pudo completar la inscripción. Intenta nuevamente."
      );
    }
  }
);
