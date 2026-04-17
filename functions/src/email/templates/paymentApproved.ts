/**
 * Payment Approved Template
 * Template para notificar a usuarios que su pago fue aprobado
 */

import {generateEmailBase, EmailBaseParams} from "../emailBase";

export interface PaymentApprovedParams {
  userEmail: string;
  userName?: string;
  planName: string;
  amount: string;
  approvedDate: string;
  logoUrl: string;
  appName: string;
  supportEmail: string;
  companyAddress: string;
}

export function generatePaymentApprovedTemplate(params: PaymentApprovedParams): string {
  const {
    userName,
    planName,
    amount,
    approvedDate,
    logoUrl,
    appName,
    supportEmail,
    companyAddress,
  } = params;

  const baseParams: EmailBaseParams = {
    title: `Pago Aprobado - ${appName}`,
    preheader: "¡Tu pago ha sido aprobado! Ya puedes agendar tus clases",
    logoUrl,
    appName,
    userName,
    mainHeading: "¡Tu pago ha sido aprobado! ✅",
    bodyText: `Nos complace informarte que tu pago de ${amount} para el plan "${planName}" ha sido aprobado exitosamente. Ahora puedes comenzar a agendar tus clases y disfrutar de todos los beneficios de tu membresía.`,
    buttonText: "Agendar mi primera clase",
    buttonUrl: `https://ayuthaya-camp.firebaseapp.com/agendar`,
    footerText: `Pago aprobado el ${approvedDate} • Plan: ${planName}`,
    supportEmail,
    companyAddress,
    darkModeSupport: true,
  };

  return generateEmailBase(baseParams);
}
