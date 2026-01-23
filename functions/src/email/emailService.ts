/**
 * Email Service
 * Servicio principal para envío de correos vía SendGrid
 */

import sgMail from "@sendgrid/mail";
import {getSendGridConfig} from "./sendgridConfig";
import {logger} from "firebase-functions";

export interface EmailOptions {
  to: string;
  subject: string;
  htmlContent: string;
  textContent?: string;
}

/**
 * Inicializa SendGrid con la API Key
 */
export function initializeSendGrid(): void {
  const config = getSendGridConfig();
  sgMail.setApiKey(config.apiKey);
  logger.info("✅ SendGrid inicializado correctamente");
}

/**
 * Envía un correo electrónico vía SendGrid
 */
export async function sendEmail(options: EmailOptions): Promise<boolean> {
  try {
    const config = getSendGridConfig();

    const msg = {
      to: options.to,
      from: {
        email: config.fromEmail,
        name: config.fromName,
      },
      subject: options.subject,
      html: options.htmlContent,
      text: options.textContent || extractTextFromHtml(options.htmlContent),
      // Configuraciones adicionales para mejor deliverability
      trackingSettings: {
        clickTracking: {
          enable: false, // Deshabilitado para links de autenticación
          enableText: false,
        },
        openTracking: {
          enable: false, // Deshabilitado para privacidad
        },
      },
      // Categorías para análisis en SendGrid
      categories: ["auth", "transactional"],
    };

    logger.info(`📧 Enviando email a: ${options.to}`);
    logger.info(`📝 Asunto: ${options.subject}`);

    const response = await sgMail.send(msg);

    logger.info("✅ Email enviado exitosamente", {
      to: options.to,
      statusCode: response[0].statusCode,
      messageId: response[0].headers["x-message-id"],
    });

    return true;
  } catch (error: any) {
    logger.error("❌ Error enviando email:", {
      to: options.to,
      error: error.message,
      code: error.code,
      response: error.response?.body,
    });

    // Re-throw para manejo en la Cloud Function
    throw new Error(`Error enviando email: ${error.message}`);
  }
}

/**
 * Extrae texto plano del HTML (fallback básico)
 */
function extractTextFromHtml(html: string): string {
  // Remover tags HTML y decodificar entidades básicas
  return html
    .replace(/<style[^>]*>.*?<\/style>/gi, "")
    .replace(/<script[^>]*>.*?<\/script>/gi, "")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Valida formato de email
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}
