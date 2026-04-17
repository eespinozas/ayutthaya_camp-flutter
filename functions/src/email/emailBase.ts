/**
 * Base Email Template
 * Template HTML base reutilizable con diseño moderno y responsive
 */

export interface EmailBaseParams {
  title: string;
  preheader: string;
  logoUrl: string;
  appName: string;
  mainHeading: string;
  bodyText: string;
  buttonText?: string;
  buttonUrl?: string;
  footerText: string;
  supportEmail: string;
  companyAddress: string;
  userName?: string; // Nombre del usuario para personalización
  darkModeSupport?: boolean; // Soporte para dark mode (default: true)
}

export function generateEmailBase(params: EmailBaseParams): string {
  const {
    title,
    preheader,
    logoUrl,
    appName,
    mainHeading,
    bodyText,
    buttonText,
    buttonUrl,
    footerText,
    supportEmail,
    companyAddress,
    userName,
    darkModeSupport = true,
  } = params;

  // Personalizar heading si hay userName
  const personalizedHeading = userName
    ? `¡Hola ${userName}! ${mainHeading}`
    : mainHeading;

  return `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>${title}</title>
  <!--[if mso]>
  <style type="text/css">
    body, table, td {font-family: Arial, Helvetica, sans-serif !important;}
  </style>
  <![endif]-->
  <style>
    /* Reset styles */
    body {
      margin: 0;
      padding: 0;
      width: 100% !important;
      -webkit-text-size-adjust: 100%;
      -ms-text-size-adjust: 100%;
    }
    img {
      border: 0;
      outline: none;
      text-decoration: none;
      -ms-interpolation-mode: bicubic;
    }
    a img {
      border: none;
    }
    table {
      border-collapse: collapse;
      mso-table-lspace: 0pt;
      mso-table-rspace: 0pt;
    }
    td {
      border-collapse: collapse;
    }

    /* Gmail/iOS fix */
    .ExternalClass {width: 100%;}
    .ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {
      line-height: 100%;
    }

    /* Dark Mode Support */
    ${darkModeSupport ? `
    @media (prefers-color-scheme: dark) {
      .dark-mode-bg {
        background: linear-gradient(180deg, #1a1a1a 0%, #0f0f0f 100%) !important;
      }
      .dark-mode-card {
        background: linear-gradient(135deg, rgba(30, 30, 30, 0.98) 0%, rgba(20, 20, 20, 1) 100%) !important;
        border-color: rgba(255, 107, 0, 0.3) !important;
      }
      .dark-mode-text {
        color: #ffffff !important;
      }
      .dark-mode-text-secondary {
        color: #e2e8f0 !important;
      }
    }
    ` : ''}

    /* Responsive styles */
    @media only screen and (max-width: 600px) {
      .email-container {
        width: 100% !important;
        margin: auto !important;
      }
      .fluid {
        width: 100% !important;
        max-width: 100% !important;
        height: auto !important;
        margin-left: auto !important;
        margin-right: auto !important;
      }
      .stack-column {
        display: block !important;
        width: 100% !important;
        max-width: 100% !important;
        direction: ltr !important;
      }
      .mobile-padding {
        padding: 24px !important;
      }
      .hero-text {
        font-size: 30px !important;
        line-height: 38px !important;
      }
      .logo-container {
        width: 100px !important;
        height: 100px !important;
      }
      .logo-img {
        width: 100px !important;
        height: 100px !important;
      }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background: linear-gradient(180deg, #f8fafc 0%, #e2e8f0 100%); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">

  <!-- Preheader (hidden text for email preview) -->
  <div style="display: none; max-height: 0; overflow: hidden; mso-hide: all;">
    ${preheader}
  </div>

  <!-- Email Container -->
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background: linear-gradient(180deg, #f8fafc 0%, #e2e8f0 100%); min-height: 100vh;">
    <tr>
      <td style="padding: 40px 10px;">

        <!-- Main Card -->
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" class="email-container dark-mode-card" style="margin: auto; background: #ffffff; border-radius: 20px; box-shadow: 0 10px 40px rgba(0, 0, 0, 0.08), 0 2px 8px rgba(0, 0, 0, 0.04); border: 1px solid #e2e8f0;">

          <!-- Decorative Top Bar with Gradient -->
          <tr>
            <td style="background: linear-gradient(135deg, #FF8C00 0%, #FF6B00 50%, #FF4500 100%); height: 6px; border-radius: 20px 20px 0 0;"></td>
          </tr>

          <!-- Logo Section with Clean Design -->
          <tr>
            <td style="padding: 48px 40px 32px 40px; text-align: center; background: linear-gradient(180deg, #ffffff 0%, #fafafa 100%);">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin: 0 auto;">
                <tr>
                  <td align="center">
                    <div class="logo-container" style="background: linear-gradient(135deg, #FF8C00 0%, #FF6B00 100%); width: 120px; height: 120px; border-radius: 24px; margin: 0 auto; box-shadow: 0 8px 24px rgba(255, 107, 0, 0.25), 0 0 0 4px rgba(255, 107, 0, 0.1); overflow: hidden; position: relative;">
                      <img src="${logoUrl}" alt="${appName}" width="120" height="120" class="logo-img" style="width: 120px; height: 120px; object-fit: cover; object-position: center; display: block;">
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Main Content -->
          <tr>
            <td class="mobile-padding" style="padding: 8px 48px 48px 48px;">

              <!-- Heading -->
              <h1 class="hero-text dark-mode-text" style="margin: 0 0 20px 0; font-size: 32px; line-height: 40px; color: #0f172a; font-weight: 800; text-align: center; letter-spacing: -0.5px;">
                ${personalizedHeading}
              </h1>

              <!-- Body Text -->
              <p class="dark-mode-text-secondary" style="margin: 0 0 36px 0; font-size: 16px; line-height: 26px; color: #475569; text-align: center; font-weight: 400;">
                ${bodyText}
              </p>

              ${buttonText && buttonUrl ? `
              <!-- CTA Button -->
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <tr>
                  <td style="padding: 0 0 32px 0; text-align: center;">
                    <!--[if mso]>
                    <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="${buttonUrl}" style="height:56px;v-text-anchor:middle;width:280px;" arcsize="14%" strokecolor="#FF8C00" fillcolor="#FF8C00">
                      <w:anchorlock/>
                      <center style="color:#ffffff;font-family:sans-serif;font-size:16px;font-weight:700;">
                        ${buttonText}
                      </center>
                    </v:roundrect>
                    <![endif]-->
                    <!--[if !mso]><!-->
                    <a href="${buttonUrl}" style="background: linear-gradient(135deg, #FF8C00 0%, #FF6B00 100%); border: none; color: #ffffff; padding: 16px 40px; text-align: center; text-decoration: none; display: inline-block; font-size: 16px; font-weight: 700; border-radius: 14px; min-width: 240px; box-shadow: 0 4px 16px rgba(255, 107, 0, 0.3); letter-spacing: 0.3px;">
                      ${buttonText}
                    </a>
                    <!--<![endif]-->
                  </td>
                </tr>
              </table>

              <!-- Alternative Link -->
              <p style="margin: 0 0 16px 0; font-size: 13px; line-height: 20px; color: #94a3b8; text-align: center;">
                Si el botón no funciona, copia y pega este enlace:
              </p>
              <div style="background: #f1f5f9; padding: 16px; border-radius: 12px; border: 1px solid #e2e8f0;">
                <p style="margin: 0; font-size: 12px; line-height: 18px; color: #FF6B00; word-break: break-all; text-align: center; font-family: 'Courier New', monospace;">
                  <a href="${buttonUrl}" style="color: #FF6B00; text-decoration: none;">${buttonUrl}</a>
                </p>
              </div>
              ` : ''}

            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding: 0 48px 32px 48px;">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <tr>
                  <td style="border-top: 1px solid #e2e8f0;"></td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td class="mobile-padding" style="padding: 0px 48px 40px 48px; text-align: center;">
              <p style="margin: 0 0 16px 0; font-size: 14px; line-height: 22px; color: #64748b; font-weight: 500;">
                ${footerText}
              </p>
              <p style="margin: 0 0 20px 0; font-size: 13px; line-height: 20px; color: #94a3b8;">
                Si no solicitaste esta acción, puedes ignorar este correo de forma segura.
              </p>

              <!-- Important Notice Box -->
              <div style="background: linear-gradient(135deg, #fff7ed 0%, #ffedd5 100%); border: 1px solid #fed7aa; border-radius: 12px; padding: 16px; margin: 0 0 24px 0;">
                <p style="margin: 0; font-size: 13px; line-height: 20px; color: #9a3412; text-align: center;">
                  <strong style="color: #c2410c;">💡 Consejo:</strong> Si es tu primer correo de nosotros, revisa tu carpeta de spam.
                </p>
              </div>

              <p style="margin: 0 0 16px 0; font-size: 13px; line-height: 20px; color: #64748b;">
                ¿Necesitas ayuda?
                <a href="mailto:${supportEmail}" style="color: #FF6B00; text-decoration: none; font-weight: 600;">${supportEmail}</a>
              </p>
              <p style="margin: 0; font-size: 12px; line-height: 18px; color: #94a3b8;">
                ${companyAddress}
              </p>
            </td>
          </tr>

          <!-- Decorative Bottom Bar -->
          <tr>
            <td style="background: linear-gradient(135deg, #FF8C00 0%, #FF6B00 50%, #FF4500 100%); height: 6px; border-radius: 0 0 20px 20px;"></td>
          </tr>

        </table>
        <!-- End Main Card -->

        <!-- Extra Footer (outside card) -->
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" class="email-container" style="margin: auto;">
          <tr>
            <td style="padding: 32px 10px 20px 10px; text-align: center;">
              <p style="margin: 0 0 8px 0; font-size: 12px; line-height: 18px; color: #94a3b8;">
                © ${new Date().getFullYear()} ${appName}. Todos los derechos reservados.
              </p>
              <p style="margin: 0; font-size: 11px; line-height: 16px; color: #cbd5e1;">
                Este es un correo automático, por favor no respondas a esta dirección.
              </p>
            </td>
          </tr>
        </table>

      </td>
    </tr>
  </table>

</body>
</html>
  `.trim();
}
