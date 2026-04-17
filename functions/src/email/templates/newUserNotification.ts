/**
 * New User Notification Template
 * Template para notificar a admins sobre nuevo usuario registrado
 */

import {generateEmailBase, EmailBaseParams} from "../emailBase";

export interface NewUserNotificationParams {
  newUserName: string;
  newUserEmail: string;
  newUserPhone?: string;
  registrationDate: string;
  logoUrl: string;
  appName: string;
  supportEmail: string;
  companyAddress: string;
}

export function generateNewUserNotificationTemplate(params: NewUserNotificationParams): string {
  const {
    newUserName,
    newUserEmail,
    newUserPhone,
    registrationDate,
    logoUrl,
    appName,
    supportEmail,
    companyAddress,
  } = params;

  const phoneInfo = newUserPhone ? `<br>📱 Teléfono: ${newUserPhone}` : '';

  const baseParams: EmailBaseParams = {
    title: `Nuevo Usuario Registrado - ${appName}`,
    preheader: `${newUserName} se ha registrado y requiere aprobación`,
    logoUrl,
    appName,
    mainHeading: "Nuevo Usuario Registrado 🎉",
    bodyText: `Un nuevo usuario se ha registrado en la plataforma y está esperando la aprobación de su pago para comenzar a entrenar.<br><br><strong>Detalles del usuario:</strong><br>👤 Nombre: ${newUserName}<br>📧 Email: ${newUserEmail}${phoneInfo}<br>📅 Fecha de registro: ${registrationDate}`,
    buttonText: "Ver usuarios pendientes",
    buttonUrl: `https://ayuthaya-camp.firebaseapp.com/admin/alumnos`,
    footerText: `Este es un correo automático para administradores`,
    supportEmail,
    companyAddress,
    darkModeSupport: true,
  };

  return generateEmailBase(baseParams);
}
