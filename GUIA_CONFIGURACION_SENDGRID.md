# Guía Paso a Paso - Configuración de SendGrid

Configuración completa de SendGrid desde cero para enviar emails transaccionales profesionales.

---

## 📋 Prerequisitos

- ✅ Cuenta de SendGrid creada (gratis en https://signup.sendgrid.com/)
- ⏱️ Tiempo estimado: 15-20 minutos
- 📧 Un email válido para verificar (puede ser Gmail, Outlook, etc.)

---

## 🎯 Opción Recomendada para Empezar: Single Sender Verification

Esta es la forma **MÁS RÁPIDA** de empezar (5 minutos). Ideal para desarrollo y testing.

### PASO 1: Inicia sesión en SendGrid

```
https://app.sendgrid.com/
```

Deberías ver el dashboard principal.

---

### PASO 2: Navega a Sender Authentication

En el menú lateral izquierdo:

```
Settings (Configuración) → Sender Authentication
```

O ve directamente a:
```
https://app.sendgrid.com/settings/sender_auth
```

---

### PASO 3: Verificar un Single Sender

En la página de Sender Authentication, verás dos opciones:

```
┌─────────────────────────────────────────────────────────┐
│  Authenticate Your Domain                               │
│  (Recomendado para producción - toma más tiempo)        │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Verify a Single Sender                                 │
│  (RÁPIDO - ideal para empezar)                    ← ESTE│
└─────────────────────────────────────────────────────────┘
```

Haz clic en **"Create New Sender"** o **"Verify a Single Sender"**

---

### PASO 4: Completa el formulario

Llena el formulario con tu información:

```
┌─────────────────────────────────────────────────────────┐
│  From Name: *                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Ayutthaya Camp                                    │  │
│  └───────────────────────────────────────────────────┘  │
│  (Nombre que verán los usuarios)                        │
│                                                          │
│  From Email Address: *                                  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ noreply@tudominio.com                             │  │
│  └───────────────────────────────────────────────────┘  │
│  (Email desde el que se enviarán los correos)           │
│                                                          │
│  Reply To: *                                            │
│  ┌───────────────────────────────────────────────────┐  │
│  │ soporte@tudominio.com                             │  │
│  └───────────────────────────────────────────────────┘  │
│  (Email para respuestas)                                │
│                                                          │
│  Company Address: *                                     │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Calle Principal 123                               │  │
│  └───────────────────────────────────────────────────┘  │
│                                                          │
│  City: *                                                │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Santiago                                          │  │
│  └───────────────────────────────────────────────────┘  │
│                                                          │
│  Country: *                                             │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Chile                                             │  │
│  └───────────────────────────────────────────────────┘  │
│                                                          │
│  Nickname: (opcional)                                   │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Ayutthaya Production                              │  │
│  └───────────────────────────────────────────────────┘  │
│                                                          │
│                            [ Create ]                    │
└─────────────────────────────────────────────────────────┘
```

**IMPORTANTE:**
- **From Email:** Puede ser cualquier email (Gmail, Outlook, etc.) PERO debe ser uno que controles
- **Si usas Gmail:** `tunombre@gmail.com` está bien para empezar
- **Si tienes dominio propio:** Mejor usa `noreply@tudominio.com`

Haz clic en **"Create"**

---

### PASO 5: Verifica tu email

SendGrid te enviará un correo de verificación al "From Email" que pusiste.

```
┌─────────────────────────────────────────────────────────┐
│  📧 Revisa tu bandeja de entrada                        │
│                                                          │
│  De: SendGrid <noreply@sendgrid.com>                    │
│  Asunto: Please Verify Your Single Sender              │
│                                                          │
│  "Please click the link below to verify your            │
│   sender identity."                                     │
│                                                          │
│   [Verify Single Sender]  ← HAZ CLIC AQUÍ              │
└─────────────────────────────────────────────────────────┘
```

**Pasos:**
1. Abre tu email
2. Busca el correo de SendGrid (revisa spam si no lo ves)
3. Haz clic en el link de verificación
4. Serás redirigido a SendGrid confirmando la verificación

---

### PASO 6: Confirma la verificación

Regresa a SendGrid Dashboard → Settings → Sender Authentication

Deberías ver tu sender con un check verde:

```
Verified Single Senders
┌─────────────────────────────────────────────────────────┐
│  ✅ Ayutthaya Camp                                      │
│     noreply@tudominio.com                               │
│     Created: Jan 20, 2026                               │
│     Status: Verified                                    │
│                                                          │
│     [ Edit ]  [ Delete ]                                │
└─────────────────────────────────────────────────────────┘
```

**¡Listo!** Ya puedes enviar emails desde ese email.

---

## 🔑 PASO 7: Crear API Key

Ahora necesitas una API Key para que las Cloud Functions puedan enviar emails.

### 7.1. Navega a API Keys

En el menú lateral:

```
Settings → API Keys
```

O ve directamente a:
```
https://app.sendgrid.com/settings/api_keys
```

---

### 7.2. Crear nueva API Key

Haz clic en **"Create API Key"** (botón azul arriba a la derecha)

```
┌─────────────────────────────────────────────────────────┐
│  Create API Key                                         │
│                                                          │
│  API Key Name: *                                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Firebase Cloud Functions - Ayutthaya              │  │
│  └───────────────────────────────────────────────────┘  │
│  (Un nombre descriptivo para identificarla)             │
│                                                          │
│  API Key Permissions:                                   │
│  ○ Full Access                                          │
│  ● Restricted Access  ← SELECCIONA ESTE                │
│                                                          │
│  [ Expand All ]                                         │
│                                                          │
│  ▼ Mail Send                                            │
│     ☑ Mail Send     ← MARCA SOLO ESTO                  │
│                                                          │
│  ▶ Alerts                                               │
│  ▶ API Keys                                             │
│  ▶ Billing                                              │
│  ...                                                    │
│                                                          │
│                    [ Create & View ]                    │
└─────────────────────────────────────────────────────────┘
```

**Configuración recomendada:**
- **API Key Name:** "Firebase Cloud Functions - Ayutthaya"
- **Permissions:** Restricted Access
- **Marca solo:** Mail Send → Mail Send (checkbox)

Haz clic en **"Create & View"**

---

### 7.3. COPIAR LA API KEY (¡IMPORTANTE!)

SendGrid te mostrará la API Key **UNA SOLA VEZ**:

```
┌─────────────────────────────────────────────────────────┐
│  ⚠️  Your API Key - Please copy now!                    │
│                                                          │
│  This is the only time you will see this key.           │
│  Please store it somewhere safe.                        │
│                                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │ SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       │  │
│  │ xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  │  │
│  └───────────────────────────────────────────────────┘  │
│                                                          │
│           [ Copy ]           [ Done ]                   │
└─────────────────────────────────────────────────────────┘
```

**PASOS CRÍTICOS:**
1. Haz clic en **"Copy"** para copiar la API Key
2. Pégala en un lugar seguro (Notepad, archivo temporal)
3. **NO CIERRES** la ventana hasta que la hayas guardado
4. La API Key empieza con `SG.`

**⚠️ SI LA PIERDES:** Tendrás que crear una nueva y eliminar la antigua.

---

## 📝 PASO 8: Guardar las Variables de Entorno

Ahora tienes toda la información necesaria. Vamos a configurarla.

### 8.1. Variables que necesitas

```
SENDGRID_API_KEY=SG.xxxxxxxxxx... (la que acabas de copiar)
SENDGRID_FROM_EMAIL=noreply@tudominio.com (el email que verificaste)
SENDGRID_FROM_NAME=Ayutthaya Camp (el nombre que pusiste)
```

### 8.2. Configurar localmente (para emulators)

Abre el archivo:
```
functions/.env
```

Si no existe, créalo:
```bash
cd functions
cp .env.example .env
```

Edita `functions/.env` y pega tus valores:

```env
# SENDGRID CONFIGURATION
SENDGRID_API_KEY=SG.tu-api-key-completa-aqui
SENDGRID_FROM_EMAIL=noreply@tudominio.com
SENDGRID_FROM_NAME=Ayutthaya Camp

# APP CONFIGURATION
APP_NAME=Ayutthaya Camp
APP_LOGO_URL=https://tudominio.com/logo.png
SUPPORT_EMAIL=soporte@tudominio.com
COMPANY_ADDRESS=Calle Principal 123, Santiago, Chile
FIREBASE_ACTION_DOMAIN=ayutthaya-camp.firebaseapp.com

# ENVIRONMENT
NODE_ENV=development
```

**Ajusta:**
- `APP_LOGO_URL`: URL pública de tu logo (o usa placeholder)
- `SUPPORT_EMAIL`: Tu email de soporte
- `COMPANY_ADDRESS`: Tu dirección (aparece en el footer del email)
- `FIREBASE_ACTION_DOMAIN`: Tu dominio de Firebase (sin https://)

**¿Cómo obtener FIREBASE_ACTION_DOMAIN?**

Ve a Firebase Console → Authentication → Settings → Authorized domains

Usa el primer dominio listado, por ejemplo:
```
ayutthaya-camp.firebaseapp.com
```

---

### 8.3. Configurar en producción

Desde tu terminal:

```bash
firebase functions:config:set \
  sendgrid.api_key="SG.tu-api-key-completa-aqui" \
  sendgrid.from_email="noreply@tudominio.com" \
  sendgrid.from_name="Ayutthaya Camp" \
  app.name="Ayutthaya Camp" \
  app.logo_url="https://tudominio.com/logo.png" \
  app.support_email="soporte@tudominio.com" \
  app.company_address="Calle Principal 123, Santiago, Chile" \
  app.firebase_action_domain="ayutthaya-camp.firebaseapp.com"
```

**Importante:** Reemplaza todos los valores con los tuyos.

Para verificar que se guardaron:
```bash
firebase functions:config:get
```

---

## ✅ PASO 9: Verificar que todo funciona

### Verificación rápida en SendGrid

Ve a SendGrid Dashboard → Activity

```
https://app.sendgrid.com/email_activity
```

Aquí verás todos los emails que envíes (cuando empieces a probar).

---

### Test desde Firebase Emulators (opcional pero recomendado)

```bash
cd functions
npm install        # Si no lo has hecho
npm run build      # Compilar TypeScript
npm run serve      # Iniciar emulators
```

En otra terminal, prueba:
```bash
# Reemplaza 'your-project-id' con tu ID de proyecto
curl -X POST http://localhost:5001/your-project-id/us-central1/sendPasswordResetEmail \
  -H "Content-Type: application/json" \
  -d '{"data":{"email":"tu-email-de-prueba@gmail.com"}}'
```

Si todo está bien, deberías recibir un email de prueba.

---

## 🎉 ¡CONFIGURACIÓN COMPLETA!

Ya tienes todo listo. Resumen de lo que configuraste:

### ✅ Checklist
- [x] Cuenta de SendGrid creada
- [x] Single Sender verificado
- [x] API Key creada y copiada
- [x] Variables de entorno configuradas (local)
- [x] Variables de entorno configuradas (producción)

### 📊 Información que guardaste

```
┌──────────────────────────────────────────────────────┐
│ SENDGRID_API_KEY                                     │
│ SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx        │
│                                                      │
│ SENDGRID_FROM_EMAIL                                  │
│ noreply@tudominio.com                                │
│                                                      │
│ SENDGRID_FROM_NAME                                   │
│ Ayutthaya Camp                                       │
└──────────────────────────────────────────────────────┘
```

---

## 🚀 Próximos Pasos

1. **Compilar y desplegar:**
```bash
cd functions
npm run build
npm run deploy
```

2. **Probar desde Flutter:**
```dart
final emailService = AuthEmailService();
await emailService.sendVerificationEmail();
```

3. **Monitorear:**
   - Logs de Firebase: `firebase functions:log`
   - Activity en SendGrid: https://app.sendgrid.com/email_activity

---

## 💡 MEJORA FUTURA (Opcional): Domain Authentication

Para mejor deliverability en producción, configura Domain Authentication:

### ¿Cuándo hacerlo?
- ✅ Tienes un dominio propio
- ✅ Tienes acceso a configurar DNS
- ✅ Vas a enviar volumen importante de emails

### Beneficios:
- Mejor deliverability (menos spam)
- Emails más confiables
- Usar emails como `noreply@tudominio.com`

### Cómo hacerlo:

**PASO 1:** Ve a Settings → Sender Authentication → Authenticate Your Domain

**PASO 2:** Selecciona tu DNS provider (GoDaddy, Cloudflare, etc.)

**PASO 3:** SendGrid te dará registros DNS para agregar:

```
Registros CNAME a agregar en tu DNS:
┌──────────────────────────────────────────────────────┐
│ s1._domainkey.tudominio.com → s1.domainkey.u123...  │
│ s2._domainkey.tudominio.com → s2.domainkey.u123...  │
│ em123.tudominio.com → u123.wl.sendgrid.net          │
└──────────────────────────────────────────────────────┘
```

**PASO 4:** Agrega esos registros en tu panel de DNS

**PASO 5:** Espera 24-48 horas para verificación

**PASO 6:** SendGrid verificará y te confirmará

---

## 🆘 Troubleshooting

### No recibí el email de verificación
**Solución:**
1. Revisa la carpeta de spam
2. Espera 5-10 minutos
3. Ve a Sender Authentication y haz clic en "Resend Verification Email"

### Perdí la API Key
**Solución:**
1. Ve a Settings → API Keys
2. Elimina la API Key antigua
3. Crea una nueva
4. Actualiza las variables de entorno

### "Sender email not verified" al enviar
**Solución:**
1. Verifica que el email en `SENDGRID_FROM_EMAIL` sea EXACTAMENTE el mismo que verificaste
2. Revisa en Settings → Sender Authentication que tenga el check verde

### Emails van a spam
**Solución inmediata:**
1. Configura Domain Authentication (ver arriba)
2. No uses palabras como "Free", "Click here" en el subject
3. Mantén balance entre texto e imágenes

**Solución a largo plazo:**
1. Warm up: Empieza enviando pocos emails y aumenta gradualmente
2. Mantén bajo el bounce rate (<5%)
3. Monitorea tu sender reputation

---

## 📞 Soporte SendGrid

Si tienes problemas con SendGrid:

- **Docs:** https://docs.sendgrid.com/
- **Support:** https://support.sendgrid.com/
- **Status:** https://status.sendgrid.com/

---

## 🎓 Recursos Adicionales

- **Email Deliverability Guide:** https://sendgrid.com/resource/email-deliverability-guide/
- **Email Testing:** https://sendgrid.com/solutions/email-testing/
- **Best Practices:** https://sendgrid.com/blog/best-practices/

---

**¡Todo listo!** Ahora puedes enviar emails transaccionales profesionales. 🚀
