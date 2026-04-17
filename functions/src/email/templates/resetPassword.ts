/**
 * Password Reset Template
 * Template para correos de recuperación de contraseña
 */

import {generateEmailBase, EmailBaseParams} from "../emailBase";

export interface ResetPasswordParams {
  resetLink: string;
  userEmail: string;
  userName?: string; // Nombre del usuario para personalización
  logoUrl: string;
  appName: string;
  supportEmail: string;
  companyAddress: string;
}

export function generateResetPasswordTemplate(params: ResetPasswordParams): string {
  const {
    resetLink,
    userEmail,
    userName,
    logoUrl,
    appName,
    supportEmail,
    companyAddress,
  } = params;

  const baseParams: EmailBaseParams = {
    title: `Restablece tu contraseña - ${appName}`,
    preheader: "Recupera el acceso a tu cuenta de forma segura",
    logoUrl,
    appName,
    userName,
    mainHeading: "Restablece tu contraseña 🔐",
    bodyText: `Recibimos una solicitud para restablecer la contraseña de tu cuenta en ${appName}. Haz clic en el botón de abajo para crear una nueva contraseña segura. Este enlace expirará en 1 hora por tu seguridad.`,
    buttonText: "Restablecer contraseña",
    buttonUrl: resetLink,
    footerText: `Solicitud de restablecimiento para: ${userEmail}`,
    supportEmail,
    companyAddress,
    darkModeSupport: true,
  };

  return generateEmailBase(baseParams);
}

/**
 * Versión con más advertencias de seguridad
 */
export function generateResetPasswordTemplateSecure(params: ResetPasswordParams): string {
  const {
    resetLink,
    userEmail,
    logoUrl,
    appName,
    supportEmail,
    companyAddress,
  } = params;

  const baseParams: EmailBaseParams = {
    title: `Solicitud de restablecimiento de contraseña - ${appName}`,
    preheader: "Recibimos tu solicitud para restablecer tu contraseña",
    logoUrl,
    appName,
    mainHeading: "🔐 Restablece tu contraseña",
    bodyText: `Hemos recibido una solicitud para restablecer la contraseña de tu cuenta. Si fuiste tú quien la solicitó, haz clic en el botón de abajo para crear una nueva contraseña segura. Por tu seguridad, este enlace solo será válido durante 1 hora. Si NO solicitaste este cambio, ignora este correo y tu contraseña permanecerá sin cambios.`,
    buttonText: "Crear nueva contraseña",
    buttonUrl: resetLink,
    footerText: `Cuenta asociada: ${userEmail}`,
    supportEmail,
    companyAddress,
  };

  return generateEmailBase(baseParams);
}
