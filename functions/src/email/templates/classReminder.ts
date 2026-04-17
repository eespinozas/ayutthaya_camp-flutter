/**
 * Class Reminder Template
 * Template para recordatorios de clases próximas
 */

import {generateEmailBase, EmailBaseParams} from "../emailBase";

export interface ClassReminderParams {
  userEmail: string;
  userName?: string;
  className: string;
  classDate: string;
  classTime: string;
  minutesBefore: number;
  logoUrl: string;
  appName: string;
  supportEmail: string;
  companyAddress: string;
}

export function generateClassReminderTemplate(params: ClassReminderParams): string {
  const {
    userName,
    className,
    classDate,
    classTime,
    minutesBefore,
    logoUrl,
    appName,
    supportEmail,
    companyAddress,
  } = params;

  const timeText = minutesBefore === 30 ? "30 minutos" : "15 minutos";

  const baseParams: EmailBaseParams = {
    title: `Recordatorio de Clase - ${appName}`,
    preheader: `Tu clase de ${className} es en ${timeText}`,
    logoUrl,
    appName,
    userName,
    mainHeading: `Tu clase es en ${timeText} ⏰`,
    bodyText: `Este es un recordatorio de que tienes una clase programada próximamente.<br><br><strong>Detalles de la clase:</strong><br>🥊 Clase: ${className}<br>📅 Fecha: ${classDate}<br>🕐 Hora: ${classTime}<br><br>¡Prepárate para entrenar duro! No olvides traer tu equipo y llegar con algunos minutos de anticipación.`,
    buttonText: "Ver mis clases",
    buttonUrl: `https://ayuthaya-camp.firebaseapp.com/mis-clases`,
    footerText: `Clase programada para ${classDate} a las ${classTime}`,
    supportEmail,
    companyAddress,
    darkModeSupport: true,
  };

  return generateEmailBase(baseParams);
}
