/**
 * Resend Email Service
 * Servicio de email usando Resend (reemplazo de SendGrid)
 */

import {Resend} from "resend";
import {logger} from "firebase-functions";

export interface EmailOptions {
  to: string;
  subject: string;
  htmlContent: string;
  textContent?: string;
}

let resendClient: Resend | null = null;

/**
 * Inicializa Resend con la API Key
 */
export function initializeResend(): void {
  const apiKey = process.env.RESEND_API_KEY;

  if (!apiKey) {
    throw new Error("RESEND_API_KEY no está configurada en las variables de entorno");
  }

  resendClient = new Resend(apiKey);
  logger.info("✅ Resend inicializado correctamente");
}

/**
 * Obtiene la configuración de Resend
 */
function getResendConfig() {
  const fromEmail = process.env.RESEND_FROM_EMAIL || "Ayutthaya Camp <no-responder@ayutthayacamp.cl>";

  if (!process.env.RESEND_API_KEY) {
    throw new Error("RESEND_API_KEY no está configurada");
  }

  return {
    fromEmail,
  };
}

/**
 * Envía un correo electrónico vía Resend
 */
export async function sendEmail(options: EmailOptions): Promise<boolean> {
  try {
    // Inicializar si no está inicializado
    if (!resendClient) {
      initializeResend();
    }

    const config = getResendConfig();

    logger.info(`📧 Enviando email via Resend a: ${options.to}`);
    logger.info(`📝 Asunto: ${options.subject}`);

    const response = await resendClient!.emails.send({
      from: config.fromEmail,
      to: options.to,
      subject: options.subject,
      html: options.htmlContent,
    });

    logger.info("✅ Email enviado exitosamente via Resend", {
      to: options.to,
      messageId: response.data?.id,
    });

    return true;
  } catch (error: any) {
    logger.error("❌ Error enviando email via Resend:", {
      to: options.to,
      error: error.message,
      name: error.name,
      statusCode: error.statusCode,
    });

    // Re-throw para manejo en la Cloud Function
    throw new Error(`Error enviando email: ${error.message}`);
  }
}

/**
 * Valida formato de email
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}
