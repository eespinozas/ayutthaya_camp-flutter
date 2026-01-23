# Cloud Functions - Ayutthaya Camp

Este directorio contiene las Cloud Functions para:
- Sistema de notificaciones push (FCM)
- Emails transaccionales profesionales (SendGrid)

## 📁 Estructura del Proyecto

```
functions/
├── src/                            # TypeScript source (emails)
│   ├── email/
│   │   ├── emailService.ts
│   │   ├── sendgridConfig.ts
│   │   ├── emailBase.ts
│   │   └── templates/
│   │       ├── verifyEmail.ts
│   │       └── resetPassword.ts
│   ├── functions/
│   │   ├── sendVerificationEmail.ts
│   │   └── sendPasswordResetEmail.ts
│   └── index.ts
├── lib/                            # Compiled JavaScript
├── index.js                        # JavaScript functions (notificaciones)
├── .env.example                    # Variables de entorno
├── package.json
├── tsconfig.json
└── README.md
```

## 📋 Funciones Implementadas

### 📧 EMAILS TRANSACCIONALES (TypeScript + SendGrid)

#### `sendVerificationEmail`
**Tipo:** HTTPS Callable
**Autenticación:** Requerida

**Descripción:**
- Envía email de verificación con link oficial de Firebase Auth
- Template HTML profesional y responsive
- Envío vía SendGrid API
- **Uso:** Verificación de email al registrarse

**Request:**
```typescript
{ email: string }
```

**Response:**
```typescript
{ success: boolean, message: string }
```

#### `sendPasswordResetEmail`
**Tipo:** HTTPS Callable
**Autenticación:** No requerida (público)

**Descripción:**
- Envía email de recuperación de contraseña
- Link oficial de Firebase Auth
- Template HTML profesional
- Previene enumeración de usuarios
- **Uso:** Recuperar contraseña olvidada

**Request:**
```typescript
{ email: string }
```

**Response:**
```typescript
{ success: boolean, message: string }
```

---

### 📱 NOTIFICACIONES PUSH (JavaScript + FCM)

### 1. `sendImmediateNotification`
**Tipo:** Trigger de Firestore (onCreate)
**Colección:** `notifications`

**Descripción:**
- Se dispara automáticamente cuando se crea un nuevo documento en la colección `notifications`
- Envía la notificación inmediatamente usando FCM
- Marca el documento como `sent: true` después de enviarlo
- **Uso:** Notificaciones a admins cuando se aprueba un pago

### 2. `processScheduledNotifications`
**Tipo:** Función programada (scheduled)
**Frecuencia:** Cada minuto

**Descripción:**
- Revisa la colección `scheduled_notifications` cada minuto
- Busca recordatorios cuya hora de envío ya pasó
- Envía hasta 50 notificaciones por ejecución
- Marca los recordatorios como enviados
- **Uso:** Recordatorios de clases (30 y 15 minutos antes)

### 3. `cleanupOldNotifications`
**Tipo:** Función programada (scheduled)
**Frecuencia:** Diaria (2:00 AM)

**Descripción:**
- Elimina notificaciones enviadas hace más de 30 días
- Mantiene la base de datos limpia
- Procesa hasta 500 documentos por ejecución

## 🚀 Instalación y Deployment

### Paso 1: Instalar dependencias
```bash
cd functions
npm install
```

### Paso 1.5: Configurar variables de entorno (para emails)

**Local (emulators):**
```bash
# Copia el ejemplo
cp .env.example .env

# Edita .env con tus credenciales de SendGrid
```

**Producción:**
```bash
firebase functions:config:set \
  sendgrid.api_key="SG.tu-api-key" \
  sendgrid.from_email="noreply@tuapp.com" \
  sendgrid.from_name="Ayutthaya Camp" \
  app.name="Ayutthaya Camp" \
  app.logo_url="https://tuapp.com/logo.png" \
  app.support_email="soporte@tuapp.com" \
  app.company_address="Tu Dirección, Ciudad" \
  app.firebase_action_domain="tuapp.firebaseapp.com"
```

### Paso 2: Configurar Firebase CLI
```bash
# Instalar Firebase CLI (si no lo tienes)
npm install -g firebase-tools

# Login en Firebase
firebase login

# Inicializar el proyecto (si no está inicializado)
firebase init
```

### Paso 3: Compilar TypeScript (para funciones de email)
```bash
npm run build
```

### Paso 4: Desplegar funciones
```bash
# Desplegar todas las funciones
npm run deploy

# O usar el comando directo
firebase deploy --only functions

# Deploy selectivo
firebase deploy --only functions:sendVerificationEmail
firebase deploy --only functions:sendPasswordResetEmail
```

### Paso 5: Verificar deployment
```bash
# Ver logs en tiempo real
firebase functions:log

# Logs de funciones específicas
firebase functions:log --only sendVerificationEmail
```

## 📊 Estructura de Datos

### Colección `notifications`
```javascript
{
  userId: "user_id",
  fcmToken: "token_dispositivo",
  title: "Nuevo Pago Aprobado",
  body: "Se ha aprobado el pago de Juan Pérez",
  data: {
    type: "payment_approved",
    paymentId: "payment123"
  },
  createdAt: Timestamp,
  sent: false,
  sentAt: Timestamp, // Después de enviar
  response: "message_id" // ID del mensaje FCM
}
```

### Colección `scheduled_notifications`
```javascript
{
  bookingId: "booking_id",
  userId: "user_id",
  title: "Recordatorio de Clase",
  body: "Tu clase de Muay Thai es en 30 minutos...",
  data: {
    type: "class_reminder",
    bookingId: "booking123",
    minutesBefore: 30
  },
  scheduledFor: Timestamp, // Cuándo debe enviarse
  sent: false,
  createdAt: Timestamp,
  sentAt: Timestamp, // Después de enviar
  response: "message_id"
}
```

## 🔧 Desarrollo Local

### Ejecutar emuladores
```bash
npm run serve
```

Esto inicia los emuladores de Firebase Functions localmente para testing.

### Scripts disponibles
```bash
npm run build          # Compila TypeScript
npm run build:watch    # Compila en watch mode
npm run serve          # Emulators locales
npm run deploy         # Deploy a producción
npm run logs           # Ver logs
npm run lint           # Linter
npm run lint:fix       # Auto-fix linter
```

## 📝 Logs y Monitoreo

### Ver logs en consola
```bash
# Logs en tiempo real
firebase functions:log

# Logs de una función específica
firebase functions:log --only sendImmediateNotification
```

### Ver logs en Firebase Console
1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Seleccionar el proyecto
3. Ir a Functions → Logs

## ⚙️ Configuración Adicional

### Zona Horaria
Las funciones están configuradas para usar la zona horaria de Chile (`America/Santiago`).

Para cambiarla, edita el parámetro `timeZone` en las funciones programadas.

### Límites de Procesamiento
- **Notificaciones inmediatas:** Sin límite
- **Recordatorios programados:** 50 por minuto
- **Limpieza:** 500 documentos por día

Estos límites se pueden ajustar editando el parámetro `limit()` en las queries.

## 🔐 Seguridad

Las Cloud Functions se ejecutan con privilegios de administrador y tienen acceso completo a Firestore y FCM.

**Importante:**
- No expongas las funciones como HTTPS callable sin autenticación
- Los triggers de Firestore son seguros (no son públicos)
- Las funciones programadas son automáticas y seguras

## ❗ Troubleshooting

### Error: "Permission denied"
- Verifica que el proyecto tenga habilitado Cloud Functions
- Verifica que tengas permisos de Editor o Owner en el proyecto

### Error: "FCM token is not valid"
- El token FCM del usuario puede haber expirado
- Pide al usuario que vuelva a iniciar sesión en la app

### Recordatorios no se envían
- Verifica que la función `processScheduledNotifications` esté desplegada
- Revisa los logs: `firebase functions:log --only processScheduledNotifications`
- Verifica que los documentos tengan el campo `scheduledFor` correcto

## 📚 Documentación Adicional

### Emails Transaccionales
- **Guía completa:** `../IMPLEMENTACION_EMAILS_TRANSACCIONALES.md`
- **Seguridad:** `../SEGURIDAD_Y_MEJORES_PRACTICAS.md`
- **SendGrid API:** https://docs.sendgrid.com/

### Firebase
- [Documentación de Cloud Functions](https://firebase.google.com/docs/functions)
- [Documentación de FCM](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Auth Admin SDK](https://firebase.google.com/docs/auth/admin)

## 📞 Soporte

Para problemas o preguntas:
1. Revisa la documentación en este directorio
2. Revisa los logs: `firebase functions:log`
3. Consulta los archivos `.md` en la raíz del proyecto
