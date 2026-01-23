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
  } = params;

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
        padding: 20px !important;
      }
      .hero-text {
        font-size: 32px !important;
        line-height: 38px !important;
      }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background: linear-gradient(180deg, #FF8C00 0%, #FF6B00 30%, #CC5500 60%, #1a1a1a 100%); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;">

  <!-- Preheader (hidden text for email preview) -->
  <div style="display: none; max-height: 0; overflow: hidden; mso-hide: all;">
    ${preheader}
  </div>

  <!-- Email Container -->
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background: linear-gradient(180deg, #FF8C00 0%, #FF6B00 30%, #CC5500 60%, #1a1a1a 100%); min-height: 100vh;">
    <tr>
      <td style="padding: 60px 10px;">

        <!-- Main Card -->
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" class="email-container" style="margin: auto; background: linear-gradient(135deg, rgba(26, 26, 26, 0.95) 0%, rgba(0, 0, 0, 0.98) 100%); border-radius: 16px; box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 140, 0, 0.2); backdrop-filter: blur(10px);">

          <!-- Decorative Top Bar -->
          <tr>
            <td style="background: linear-gradient(90deg, #FF8C00 0%, #FF6B00 50%, #FF8C00 100%); height: 4px; border-radius: 16px 16px 0 0;"></td>
          </tr>

          <!-- Logo Section -->
          <tr>
            <td style="padding: 50px 40px 30px 40px; text-align: center;">
              <div style="background: linear-gradient(135deg, #FF8C00 0%, #FF6B00 100%); width: 120px; height: 120px; border-radius: 50%; margin: 0 auto; display: flex; align-items: center; justify-content: center; box-shadow: 0 8px 24px rgba(255, 107, 0, 0.4); overflow: hidden; position: relative;">
                <img src="${logoUrl}" alt="${appName}" width="120" height="120" style="width: 120px; height: 120px; object-fit: cover; object-position: center;">
              </div>
            </td>
          </tr>

          <!-- Main Content -->
          <tr>
            <td class="mobile-padding" style="padding: 0px 40px 40px 40px;">

              <!-- Heading -->
              <h1 class="hero-text" style="margin: 0 0 24px 0; font-size: 36px; line-height: 44px; color: #ffffff; font-weight: 700; text-align: center; letter-spacing: -0.5px; text-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);">
                ${mainHeading}
              </h1>

              <!-- Body Text -->
              <p style="margin: 0 0 32px 0; font-size: 17px; line-height: 28px; color: #e2e8f0; text-align: center; font-weight: 400;">
                ${bodyText}
              </p>

              ${buttonText && buttonUrl ? `
              <!-- CTA Button -->
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <tr>
                  <td style="padding: 10px 0 30px 0; text-align: center;">
                    <!--[if mso]>
                    <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="${buttonUrl}" style="height:56px;v-text-anchor:middle;width:300px;" arcsize="15%" strokecolor="#FF8C00" fillcolor="#FF8C00">
                      <w:anchorlock/>
                      <center style="color:#000000;font-family:sans-serif;font-size:18px;font-weight:700;">
                        ${buttonText}
                      </center>
                    </v:roundrect>
                    <![endif]-->
                    <a href="${buttonUrl}" style="background: linear-gradient(135deg, #FF8C00 0%, #FF6B00 100%); border: none; color: #000000; padding: 18px 48px; text-align: center; text-decoration: none; display: inline-block; font-size: 18px; font-weight: 700; border-radius: 12px; min-width: 250px; box-shadow: 0 8px 24px rgba(255, 107, 0, 0.4), 0 2px 8px rgba(0, 0, 0, 0.2); transition: all 0.3s ease; text-transform: uppercase; letter-spacing: 0.5px;">
                      ${buttonText}
                    </a>
                  </td>
                </tr>
              </table>

              <!-- Alternative Link -->
              <p style="margin: 0 0 20px 0; font-size: 14px; line-height: 22px; color: #94a3b8; text-align: center;">
                Si el botón no funciona, copia y pega este enlace en tu navegador:
              </p>
              <p style="margin: 0; font-size: 12px; line-height: 20px; color: #FF8C00; word-break: break-all; text-align: center; background: rgba(255, 140, 0, 0.1); padding: 12px; border-radius: 8px; border: 1px solid rgba(255, 140, 0, 0.2);">
                <a href="${buttonUrl}" style="color: #FF8C00; text-decoration: none;">${buttonUrl}</a>
              </p>
              ` : ''}

            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding: 0 40px;">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <tr>
                  <td style="border-top: 1px solid rgba(255, 140, 0, 0.2);"></td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td class="mobile-padding" style="padding: 40px 40px 50px 40px; text-align: center;">
              <p style="margin: 0 0 16px 0; font-size: 15px; line-height: 24px; color: #cbd5e1; font-weight: 500;">
                ${footerText}
              </p>
              <p style="margin: 0 0 12px 0; font-size: 13px; line-height: 20px; color: #94a3b8;">
                Si no solicitaste esta acción, puedes ignorar este correo de forma segura.
              </p>
              <p style="margin: 0 0 20px 0; font-size: 13px; line-height: 20px; color: #94a3b8;">
                ¿Necesitas ayuda? Escríbenos a
                <a href="mailto:${supportEmail}" style="color: #FF8C00; text-decoration: none; font-weight: 600;">${supportEmail}</a>
              </p>
              <p style="margin: 0; font-size: 12px; line-height: 18px; color: #64748b;">
                ${companyAddress}
              </p>
            </td>
          </tr>

          <!-- Decorative Bottom Bar -->
          <tr>
            <td style="background: linear-gradient(90deg, #FF8C00 0%, #FF6B00 50%, #FF8C00 100%); height: 4px; border-radius: 0 0 16px 16px;"></td>
          </tr>

        </table>
        <!-- End Main Card -->

        <!-- Extra Footer (outside card) -->
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" class="email-container" style="margin: auto;">
          <tr>
            <td style="padding: 30px 10px; text-align: center;">
              <p style="margin: 0; font-size: 12px; line-height: 18px; color: rgba(255, 255, 255, 0.6); text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);">
                © ${new Date().getFullYear()} ${appName}. Todos los derechos reservados.
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
