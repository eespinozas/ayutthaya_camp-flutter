# 🚀 Guía de Setup de Cloud Functions

Esta guía te ayudará a desplegar las Cloud Functions para el sistema de notificaciones push.

## ✅ Pre-requisitos

Antes de comenzar, asegúrate de tener:

1. **Node.js instalado** (versión 18 o superior)
   ```bash
   node --version
   ```

2. **Firebase CLI instalado**
   ```bash
   npm install -g firebase-tools
   ```

3. **Firebase Cloud Messaging (FCM) habilitado** en tu proyecto
   - Ya lo tienes habilitado ✅

## 📋 Pasos de Instalación

### 1. Navegar al directorio de functions
```bash
cd functions
```

### 2. Instalar dependencias
```bash
npm install
```

Esto instalará:
- `firebase-admin`: SDK de Firebase para administración
- `firebase-functions`: Framework para Cloud Functions

### 3. Login en Firebase
```bash
firebase login
```

Esto abrirá tu navegador para autenticarte con tu cuenta de Google.

### 4. Verificar el proyecto
```bash
firebase use
```

Esto mostrará el proyecto actual. Si no está configurado:
```bash
firebase use --add
```

## 🚀 Deployment

### Opción 1: Desplegar todas las funciones (Recomendado)
```bash
cd functions
npm run deploy
```

### Opción 2: Desplegar una función específica
```bash
firebase deploy --only functions:sendImmediateNotification
firebase deploy --only functions:processScheduledNotifications
firebase deploy --only functions:cleanupOldNotifications
```

## ✅ Verificación

### 1. Verificar que las funciones se desplegaron
Ve a [Firebase Console](https://console.firebase.google.com) → Tu Proyecto → Functions

Deberías ver:
- ✅ `sendImmediateNotification`
- ✅ `processScheduledNotifications`
- ✅ `cleanupOldNotifications`

### 2. Probar notificación inmediata

En la consola de Firebase, ve a Firestore y crea un documento de prueba:

**Colección:** `notifications`
**Documento nuevo (ID automático)**
```json
{
  "userId": "tu_user_id_de_prueba",
  "fcmToken": "tu_fcm_token",
  "title": "Prueba de Notificación",
  "body": "Esta es una notificación de prueba",
  "data": {
    "type": "test"
  },
  "sent": false,
  "createdAt": [Timestamp actual]
}
```

**Resultado esperado:**
- La función se dispara automáticamente
- El campo `sent` cambia a `true`
- Aparece el campo `sentAt` con timestamp
- Recibes la notificación en tu dispositivo

### 3. Ver logs
```bash
firebase functions:log
```

O en Firebase Console → Functions → Logs

## 🔧 Troubleshooting

### Error: "Permission denied"
**Solución:**
1. Ve a [Google Cloud Console](https://console.cloud.google.com)
2. Selecciona tu proyecto
3. Ve a IAM & Admin
4. Asegúrate de que Cloud Functions API esté habilitada

### Error: "Billing account required"
**Solución:**
Cloud Functions requiere que el proyecto tenga una cuenta de facturación configurada (plan Blaze).

1. Ve a Firebase Console → Upgrade
2. Selecciona el plan "Blaze" (pay as you go)
3. Configura tu método de pago

**Nota:** El plan Blaze tiene una cuota gratuita generosa:
- 2 millones de invocaciones al mes gratis
- Para uso normal de la app, es probable que no pagues nada

### Las notificaciones no llegan
**Checklist:**
1. ✅ Verifica que FCM esté habilitado en Firebase Console
2. ✅ Verifica que el usuario tenga un `fcmToken` válido en Firestore
3. ✅ Verifica los logs de la función: `firebase functions:log`
4. ✅ Asegúrate de que la app tenga permisos de notificaciones

### Los recordatorios no se envían a tiempo
**Checklist:**
1. ✅ Verifica que `processScheduledNotifications` esté desplegada
2. ✅ Verifica que los documentos en `scheduled_notifications` tengan el campo `scheduledFor` correcto
3. ✅ Revisa los logs: `firebase functions:log --only processScheduledNotifications`

## 📊 Monitoreo

### Ver estadísticas de uso
Firebase Console → Functions → Dashboard

Aquí puedes ver:
- Número de invocaciones
- Tiempo de ejecución
- Errores
- Costos (si aplica)

### Alertas
Puedes configurar alertas en Firebase Console → Functions → Health para recibir notificaciones si:
- Las funciones fallan frecuentemente
- El tiempo de ejecución es muy alto
- Hay errores críticos

## 💰 Costos

Con el **plan Blaze**, tienes una cuota gratuita de:
- **Invocaciones:** 2,000,000 al mes
- **GB-segundos:** 400,000 al mes
- **CPU-segundos:** 200,000 al mes
- **Salidas de red:** 5 GB al mes

Para una app con ~100 usuarios activos y ~300 clases al mes:
- Notificaciones inmediatas: ~100/mes (admins)
- Recordatorios: ~600/mes (2 por clase)
- Limpieza: ~30/mes
- **Total:** ~730 invocaciones/mes (muy por debajo del límite)

**Conclusión:** Es probable que nunca pagues nada por las Cloud Functions 💚

## 🎉 ¡Listo!

Una vez desplegadas las funciones, el sistema de notificaciones funciona automáticamente:

1. ✅ Cuando un admin aprueba un pago → Notificación a todos los admins
2. ✅ Cuando un alumno agenda una clase → Se programan 2 recordatorios (30 y 15 min antes)
3. ✅ Cada minuto se revisan y envían los recordatorios pendientes
4. ✅ Cada día se limpian las notificaciones antiguas

## 📞 Siguiente Paso

Después de desplegar, prueba el flujo completo:
1. Aprueba un pago como admin
2. Agenda una clase como alumno
3. Verifica que las notificaciones lleguen

¡Todo debería funcionar! 🚀
