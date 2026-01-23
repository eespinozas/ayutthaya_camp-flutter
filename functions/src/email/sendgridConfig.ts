/**
 * SendGrid Configuration
 * Configuración y validación de SendGrid
 */

export interface SendGridConfig {
  apiKey: string;
  fromEmail: string;
  fromName: string;
}

/**
 * Obtiene y valida la configuración de SendGrid desde variables de entorno
 */
export function getSendGridConfig(): SendGridConfig {
  const apiKey = process.env.SENDGRID_API_KEY;
  const fromEmail = process.env.SENDGRID_FROM_EMAIL;
  const fromName = process.env.SENDGRID_FROM_NAME || "Ayutthaya Camp";

  if (!apiKey) {
    throw new Error("SENDGRID_API_KEY no está configurada en las variables de entorno");
  }

  if (!fromEmail) {
    throw new Error("SENDGRID_FROM_EMAIL no está configurada en las variables de entorno");
  }

  // Validación básica del formato de email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(fromEmail)) {
    throw new Error(`SENDGRID_FROM_EMAIL tiene un formato inválido: ${fromEmail}`);
  }

  // Validación básica de la API Key de SendGrid
  if (!apiKey.startsWith("SG.")) {
    throw new Error("SENDGRID_API_KEY parece no ser válida (debe comenzar con 'SG.')");
  }

  return {
    apiKey,
    fromEmail,
    fromName,
  };
}

/**
 * Obtiene configuración general de la app
 */
export function getAppConfig() {
  return {
    appName: process.env.APP_NAME || "Ayutthaya Camp",
    logoUrl: process.env.APP_LOGO_URL || "https://via.placeholder.com/120x120?text=Logo",
    supportEmail: process.env.SUPPORT_EMAIL || "soporte@ayutthaya.com",
    companyAddress: process.env.COMPANY_ADDRESS || "Tu Dirección, Ciudad, País",
    firebaseActionDomain: process.env.ACTION_DOMAIN || "ayutthaya-camp.firebaseapp.com",
  };
}
