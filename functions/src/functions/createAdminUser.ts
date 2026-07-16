/**
 * Create Admin User Cloud Function
 * Crea una cuenta de administrador con contraseña temporal generada.
 * Solo puede invocarla un usuario con rol admin. El nuevo admin queda con
 * mustChangePassword: true y la app lo obliga a cambiarla al primer login.
 *
 * Se usa Cloud Function (Admin SDK) y no createUserWithEmailAndPassword en
 * el cliente porque este último cerraría la sesión del admin que crea.
 */

import * as admin from "firebase-admin";
import * as crypto from "crypto";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";
import {isValidEmail} from "../email/resendService";

interface CreateAdminUserRequest {
  nombre: string;
  apellido: string;
  email: string;
  schoolId: string;
}

interface CreateAdminUserResponse {
  success: boolean;
  message: string;
  uid: string;
  tempPassword: string;
}

/**
 * Genera una contraseña temporal que cumple las reglas de la app
 * (mínimo 10 caracteres, al menos una mayúscula, letras y números).
 * Formato legible para dictarla o copiarla: p.ej. "Kx7Tq2Mn9Rp4".
 */
function generateTempPassword(): string {
  const upper = "ABCDEFGHJKLMNPQRSTUVWXYZ"; // sin I/O (ambiguas)
  const lower = "abcdefghjkmnpqrstuvwxyz"; // sin l (ambigua)
  const digits = "23456789"; // sin 0/1 (ambiguos)
  const all = upper + lower + digits;

  const pick = (chars: string) => chars[crypto.randomInt(chars.length)];

  // Garantizar al menos una mayúscula, una minúscula y un dígito
  const chars = [pick(upper), pick(lower), pick(digits)];
  while (chars.length < 12) {
    chars.push(pick(all));
  }
  // Mezclar (Fisher-Yates con randomInt criptográfico)
  for (let i = chars.length - 1; i > 0; i--) {
    const j = crypto.randomInt(i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join("");
}

export const createAdminUser = onCall<
  CreateAdminUserRequest,
  Promise<CreateAdminUserResponse>
>(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Debes estar autenticado para crear administradores"
      );
    }

    // Solo un admin puede crear otros admins
    const callerId = request.auth.uid;
    const callerDoc = await admin.firestore().collection("users").doc(callerId).get();
    if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
      logger.warn("⚠️ Intento de crear admin sin rol admin", {callerId});
      throw new HttpsError(
        "permission-denied",
        "Solo un administrador puede crear otros administradores"
      );
    }

    const nombre = (request.data.nombre || "").trim();
    const apellido = (request.data.apellido || "").trim();
    const email = (request.data.email || "").trim().toLowerCase();
    const schoolId = (request.data.schoolId || "").trim();

    if (nombre.length < 2 || apellido.length < 2) {
      throw new HttpsError("invalid-argument", "Nombre y apellido son requeridos (mínimo 2 caracteres)");
    }
    if (!isValidEmail(email)) {
      throw new HttpsError("invalid-argument", "El correo no es válido");
    }
    if (!schoolId) {
      throw new HttpsError("invalid-argument", "Debes seleccionar una escuela");
    }

    try {
      const tempPassword = generateTempPassword();

      // Crear en Firebase Auth. emailVerified: true — es una cuenta interna
      // creada por el dueño, no necesita el flujo de verificación.
      const userRecord = await admin.auth().createUser({
        email,
        password: tempPassword,
        displayName: `${nombre} ${apellido}`,
        emailVerified: true,
      });

      // Documento de perfil con rol admin y cambio de contraseña obligatorio
      await admin.firestore().collection("users").doc(userRecord.uid).set({
        email,
        searchKey: email,
        name: `${nombre} ${apellido}`,
        nombre,
        apellido,
        role: "admin",
        schoolId,
        membershipStatus: "active",
        mustChangePassword: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: callerId,
      });

      logger.info("✅ Administrador creado", {
        uid: userRecord.uid,
        email,
        createdBy: callerId,
      });

      return {
        success: true,
        message: "Administrador creado exitosamente",
        uid: userRecord.uid,
        tempPassword,
      };
    } catch (error: unknown) {
      if (error instanceof HttpsError) throw error;

      const code = (error as {code?: string}).code;
      if (code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "Ya existe una cuenta con ese correo");
      }

      const message = error instanceof Error ? error.message : String(error);
      logger.error("❌ Error creando administrador:", {email, error: message});
      throw new HttpsError("internal", "No se pudo crear el administrador. Intenta nuevamente.");
    }
  }
);
