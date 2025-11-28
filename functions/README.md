# Cloud Functions - Ayutthaya Camp

Este directorio contiene las Cloud Functions para el sistema de notificaciones push de Ayutthaya Camp.

## 📋 Funciones Implementadas

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

### Paso 2: Configurar Firebase CLI
```bash
# Instalar Firebase CLI (si no lo tienes)
npm install -g firebase-tools

# Login en Firebase
firebase login

# Inicializar el proyecto (si no está inicializado)
firebase init
```

### Paso 3: Desplegar funciones
```bash
# Desplegar todas las funciones
npm run deploy

# O usar el comando directo
firebase deploy --only functions
```

### Paso 4: Verificar deployment
```bash
# Ver logs en tiempo real
firebase functions:log
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

## 📞 Soporte

Para problemas o preguntas, revisa:
- [Documentación de Cloud Functions](https://firebase.google.com/docs/functions)
- [Documentación de FCM](https://firebase.google.com/docs/cloud-messaging)
