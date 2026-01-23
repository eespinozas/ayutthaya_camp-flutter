# Configurar Notificaciones Push para Web

## Problema resuelto
El error `[firebase_messaging/failed-service-worker-registration]` ha sido solucionado con los siguientes cambios:

1. ✅ Se creó el archivo `web/firebase-messaging-sw.js` (Service Worker)
2. ✅ Se actualizó `notification_service.dart` para manejar errores en web
3. ⚠️ Falta configurar la clave VAPID (opcional, solo si quieres notificaciones en web)

## Configuración de la clave VAPID (Opcional)

Las notificaciones push en web requieren una clave VAPID. Sigue estos pasos:

### 1. Obtener la clave VAPID de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **ayutthaya-camp**
3. Ve a **Project Settings** (⚙️ > Project settings)
4. Selecciona la pestaña **Cloud Messaging**
5. En la sección **Web Push certificates**, busca **Key pair** o **Generate key pair**
6. Copia la clave que aparece (es una cadena larga como: `BNx...abc123...xyz`)

### 2. Actualizar el código con tu clave VAPID

Reemplaza `'YOUR_VAPID_KEY_HERE'` en los siguientes archivos:

#### En `lib/core/services/notification_service.dart`:

```dart
String? token = await _messaging.getToken(
  vapidKey: kIsWeb
    ? 'TU_CLAVE_VAPID_AQUI' // <- Pega tu clave aquí
    : null,
);
```

Busca esta línea en dos lugares:
- En el método `initialize()` (línea ~43)
- En el método `saveUserToken()` (línea ~111)

### 3. Verificar que el Service Worker esté registrado

El archivo `web/firebase-messaging-sw.js` ya está creado con la configuración correcta de Firebase.

## Importante: HTTPS requerido

Las notificaciones push en web **solo funcionan** en:
- ✅ HTTPS (producción)
- ✅ localhost (desarrollo)
- ❌ HTTP en dominios públicos (no funciona)

## Pruebas

### En desarrollo local:
```bash
flutter run -d chrome
```
Las notificaciones deberían funcionar en `localhost`.

### En producción:
Despliega tu app en Firebase Hosting o cualquier servicio con HTTPS:
```bash
flutter build web
firebase deploy --only hosting
```

## Solución alternativa (si no necesitas notificaciones en web)

Si solo necesitas notificaciones en móvil, el error es inofensivo. El código ya está actualizado para:
- ✅ Registrar el error sin bloquear la app
- ✅ Continuar funcionando normalmente
- ✅ Soportar notificaciones en iOS/Android sin problemas

## Estado actual

- ✅ El error ya no bloquea la aplicación
- ✅ Las notificaciones funcionan en móvil
- ⚠️ Las notificaciones en web requieren:
  1. Configurar la clave VAPID (ver arriba)
  2. Usar HTTPS o localhost
  3. Navegador compatible (Chrome, Firefox, Edge)

## Verificar que funciona

Después de configurar la clave VAPID, verifica en la consola:
- ✅ `🔑 FCM Token: ...` (token obtenido correctamente)
- ❌ `⚠️ Service Worker no registrado` (falta clave VAPID o no estás en HTTPS)
