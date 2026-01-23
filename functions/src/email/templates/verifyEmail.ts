/**
 * Email Verification Template
 * Template para correos de verificación de email
 */

import {generateEmailBase, EmailBaseParams} from "../emailBase";

export interface VerifyEmailParams {
  verificationLink: string;
  userEmail: string;
  logoUrl: string;
  appName: string;
  supportEmail: string;
  companyAddress: string;
}

export function generateVerifyEmailTemplate(params: VerifyEmailParams): string {
  const {
    verificationLink,
    userEmail,
    logoUrl,
    appName,
    supportEmail,
    companyAddress,
  } = params;

  const baseParams: EmailBaseParams = {
    title: `Verifica tu correo electrónico - ${appName}`,
    preheader: "¡Bienvenido a Ayutthaya Camp! Solo un paso más para comenzar tu transformación",
    logoUrl,
    appName,
    mainHeading: "¡Bienvenido a Ayutthaya Camp! 🇨🇱🇹🇭",
    bodyText: `Estamos emocionados de que te unas a nuestra comunidad. Para activar tu cuenta y comenzar tu entrenamiento, necesitamos verificar tu correo electrónico. Haz clic en el botón de abajo para confirmar tu cuenta.`,
    buttonText: "✓ Verificar mi cuenta",
    buttonUrl: verificationLink,
    footerText: `Verificación enviada a ${userEmail}`,
    supportEmail,
    companyAddress,
  };

  return generateEmailBase(baseParams);
}

/**
 * Versión alternativa con más contexto
 */
export function generateVerifyEmailTemplateDetailed(params: VerifyEmailParams): string {
  const {
    verificationLink,
    userEmail,
    logoUrl,
    appName,
    supportEmail,
    companyAddress,
  } = params;

  const baseParams: EmailBaseParams = {
    title: `Verifica tu correo electrónico - ${appName}`,
    preheader: "Solo falta un paso para completar tu registro",
    logoUrl,
    appName,
    mainHeading: "¡Bienvenido a Ayutthaya Camp! 🎉",
    bodyText: `Estamos emocionados de tenerte con nosotros. Para activar tu cuenta y acceder a todas las funcionalidades, haz clic en el botón de abajo para verificar tu correo electrónico. Este enlace expirará en 24 horas por seguridad.`,
    buttonText: "Verificar mi cuenta",
    buttonUrl: verificationLink,
    footerText: `Verificación solicitada para: ${userEmail}`,
    supportEmail,
    companyAddress,
  };

  return generateEmailBase(baseParams);
}
