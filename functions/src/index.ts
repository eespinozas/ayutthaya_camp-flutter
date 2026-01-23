/**
 * Cloud Functions Entry Point
 * Punto de entrada para todas las Cloud Functions
 */

import * as dotenv from "dotenv";
import * as admin from "firebase-admin";
import * as path from "path";

// Cargar variables de entorno desde .env
// En desarrollo carga desde src/.env, en producción desde .env en la raíz de functions
const envPath = process.env.NODE_ENV === "production"
  ? path.resolve(__dirname, "../.env")
  : path.resolve(__dirname, ".env");

dotenv.config({path: envPath});

// Inicializar Firebase Admin SDK (solo una vez)
admin.initializeApp();

// ============================================================================
// FUNCIONES DE EMAIL TRANSACCIONAL
// ============================================================================
export {sendVerificationEmail} from "./functions/sendVerificationEmail";
export {sendPasswordResetEmail} from "./functions/sendPasswordResetEmail";

// ============================================================================
// FUNCIONES EXISTENTES (del index.js original)
// ============================================================================
// Si deseas mantener las funciones existentes, re-impórtalas aquí
// O migra su código a TypeScript siguiendo la misma estructura
