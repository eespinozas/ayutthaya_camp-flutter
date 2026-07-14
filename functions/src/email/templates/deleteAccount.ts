/**
 * Account Deletion Confirmation Template
 * Template para el correo de confirmación de eliminación de cuenta
 */

import {generateEmailBase, EmailBaseParams} from "../emailBase";

export interface DeleteAccountParams {
  confirmationLink: string;
  userEmail: string;
  userName?: string;
  logoUrl: string;
  appName: string;
  supportEmail: string;
  companyAddress: string;
}

export function generateDeleteAccountTemplate(params: DeleteAccountParams): string {
  const {
    confirmationLink,
    userEmail,
    userName,
    logoUrl,
    appName,
    supportEmail,
    companyAddress,
  } = params;

  const baseParams: EmailBaseParams = {
    title: `Confirma la eliminación de tu cuenta - ${appName}`,
    preheader: "Recibimos una solicitud para eliminar tu cuenta. Confírmala solo si fuiste tú.",
    logoUrl,
    appName,
    userName,
    mainHeading: "Solicitud de eliminación de cuenta",
    bodyText: `Recibimos una solicitud para eliminar permanentemente tu cuenta de ${appName} (${userEmail}). ` +
      `Si confirmas, se borrarán tu perfil, tus clases agendadas, tu progreso y tu foto de perfil. ` +
      `Esta acción NO se puede deshacer.\n\n` +
      `Si no solicitaste esto, ignora este correo: tu cuenta seguirá activa y el enlace expirará en 24 horas.`,
    buttonText: "Eliminar mi cuenta definitivamente",
    buttonUrl: confirmationLink,
    footerText: `Solicitud de eliminación para: ${userEmail}. Si no fuiste tú, contáctanos en ${supportEmail}.`,
    supportEmail,
    companyAddress,
  };

  return generateEmailBase(baseParams);
}
