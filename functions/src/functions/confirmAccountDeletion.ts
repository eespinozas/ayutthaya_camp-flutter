/**
 * Confirm Account Deletion Cloud Function (HTTP)
 * Destino del enlace enviado por correo. Valida el token de un solo uso
 * y elimina la cuenta: Auth, perfil en Firestore, bookings y foto de perfil.
 *
 * Los pagos se CONSERVAN por registro contable (quedan asociados a un uid
 * ya inexistente); si algún día se requiere borrarlos, agregar aquí la
 * limpieza de `payments` y `receipts/{uid}` en Storage.
 */

import * as admin from "firebase-admin";
import * as crypto from "crypto";
import {onRequest} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {DELETION_REQUESTS_COLLECTION} from "./requestAccountDeletion";

/** Página HTML simple (dark, consistente con la app) para la respuesta. */
function htmlPage(heading: string, body: string, ok: boolean): string {
  const accent = ok ? "#10B981" : "#EF4444";
  return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${heading} - Ayutthaya Camp</title>
<style>
  body{margin:0;background:#0F0F0F;color:#EDE7DC;font-family:system-ui,sans-serif;
    display:flex;align-items:center;justify-content:center;min-height:100vh;padding:24px;box-sizing:border-box;}
  .card{max-width:440px;text-align:center;background:#1A1A1A;border:1px solid #2a251d;
    border-radius:18px;padding:40px 32px;}
  .icon{font-size:48px;margin-bottom:16px;}
  h1{font-size:22px;margin:0 0 12px;color:${accent};}
  p{color:#a89e8f;font-size:15px;line-height:1.6;margin:0;}
</style>
</head>
<body><div class="card"><div class="icon">${ok ? "✅" : "⚠️"}</div><h1>${heading}</h1><p>${body}</p></div></body>
</html>`;
}

export const confirmAccountDeletion = onRequest(
  {region: "us-central1"},
  async (req, res) => {
    const token = String(req.query.token || "");

    if (!token || !/^[a-f0-9]{64}$/.test(token)) {
      res.status(400).send(htmlPage(
        "Enlace inválido",
        "El enlace de confirmación no es válido. Solicita la eliminación nuevamente desde la app.",
        false
      ));
      return;
    }

    const tokenHash = crypto.createHash("sha256").update(token).digest("hex");
    const requestRef = admin.firestore()
      .collection(DELETION_REQUESTS_COLLECTION)
      .doc(tokenHash);

    try {
      // Validar y marcar como usado atómicamente (evita doble ejecución).
      const {uid, email} = await admin.firestore().runTransaction(async (tx) => {
        const snap = await tx.get(requestRef);
        if (!snap.exists) {
          throw new Error("NOT_FOUND");
        }
        const data = snap.data() as {
          uid: string; email: string; used: boolean;
          expiresAt: admin.firestore.Timestamp;
        };
        if (data.used) throw new Error("ALREADY_USED");
        if (data.expiresAt.toMillis() < Date.now()) throw new Error("EXPIRED");
        tx.update(requestRef, {used: true, confirmedAt: admin.firestore.FieldValue.serverTimestamp()});
        return {uid: data.uid, email: data.email};
      });

      logger.info("🗑️ Confirmada eliminación de cuenta, borrando datos...", {uid, email});
      const db = admin.firestore();

      // 1. Bookings del usuario (en lotes)
      const bookings = await db.collection("bookings").where("userId", "==", uid).get();
      let batch = db.batch();
      let count = 0;
      for (const doc of bookings.docs) {
        batch.delete(doc.ref);
        if (++count % 400 === 0) {
          await batch.commit();
          batch = db.batch();
        }
      }
      await batch.commit();
      logger.info(`🗑️ ${bookings.size} bookings eliminados`, {uid});

      // 2. Documento de perfil
      await db.collection("users").doc(uid).delete();

      // 3. Foto de perfil en Storage (si existe)
      try {
        await admin.storage().bucket().file(`profile_photos/${uid}.jpg`).delete();
      } catch {
        // Sin foto: continuar
      }

      // 4. Usuario de Firebase Auth (invalida la sesión en todos los dispositivos)
      await admin.auth().deleteUser(uid);

      logger.info("✅ Cuenta eliminada por completo", {uid, email});

      res.status(200).send(htmlPage(
        "Cuenta eliminada",
        "Tu cuenta y tus datos fueron eliminados permanentemente. " +
        "Gracias por haber sido parte de Ayutthaya Camp. Si algún día quieres volver, " +
        "siempre puedes crear una cuenta nueva.",
        true
      ));
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);

      if (message === "NOT_FOUND" || message === "ALREADY_USED") {
        res.status(410).send(htmlPage(
          "Enlace ya utilizado",
          "Este enlace no es válido o ya fue utilizado. Si tu cuenta aún existe y deseas " +
          "eliminarla, solicita la eliminación nuevamente desde la app.",
          false
        ));
        return;
      }
      if (message === "EXPIRED") {
        res.status(410).send(htmlPage(
          "Enlace expirado",
          "Este enlace expiró (dura 24 horas). Tu cuenta sigue activa: si aún deseas " +
          "eliminarla, solicita la eliminación nuevamente desde la app.",
          false
        ));
        return;
      }

      logger.error("❌ Error eliminando cuenta:", {error: message});
      res.status(500).send(htmlPage(
        "Algo salió mal",
        "No pudimos completar la eliminación. Por favor intenta de nuevo más tarde o " +
        "escríbenos a soporte.",
        false
      ));
    }
  }
);
