# Troubleshooting - Notificaciones Push

Guía para resolver problemas comunes con notificaciones push en iOS, Android y Web.

---

## 🔍 Diagnóstico General

### Verificar que FCM está correctamente configurado

**1. Firebase Console**
- Ve a: https://console.firebase.google.com/project/ayuthaya-camp
- Project Settings > Cloud Messaging
- Verifica que existan:
  - ✅ Server key (Android)
  - ✅ APNs certificate (iOS)
  - ✅ Web Push certificate (VAPID key)

**2. Verificar token FCM en la app**
```dart
// Agregar esto temporalmente en main.dart para debugging
final token = await FirebaseMessaging.instance.getToken();
debugPrint('🔑 FCM Token: $token');
```

**3. Verificar que el token se guarda en Firestore**
```dart
// En Firestore Console:
// users/{userId}/fcmToken debe existir
```

---

## 📱 iOS - Problemas y Soluciones

### Problema: "No llegan notificaciones en iOS"

**Causas posibles:**

#### 1. Certificado APNs no configurado o expirado

**Verificar:**
```bash
# En Firebase Console > Project Settings > Cloud Messaging > iOS
# Debe haber un certificado .p8 válido
```

**Solución:**
1. Ve a [Apple Developer](https://developer.apple.com/account/resources/authkeys/list)
2. Genera nueva APNs Auth Key (.p8)
3. Descarga el archivo
4. En Firebase Console: sube el .p8
5. Ingresa Key ID y Team ID
6. Guarda cambios

#### 2. Permisos no otorgados

**Verificar:**
```dart
final settings = await FirebaseMessaging.instance.requestPermission();
debugPrint('iOS Permission status: ${settings.authorizationStatus}');
```

**Solución:**
1. Desinstalar app
2. Reinstalar y aceptar permisos cuando se soliciten
3. Si ya rechazó: ir a Settings > [App Name] > Notifications > Activar

#### 3. Info.plist mal configurado

**Verificar:** `ios/Runner/Info.plist`
```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

**Solución:**
Si no existe, agregarlo antes de `</dict>`

#### 4. Entitlement de notificaciones faltante

**Verificar en Xcode:**
1. Abrir `ios/Runner.xcworkspace`
2. Target "Runner" > Signing & Capabilities
3. Debe existir: "Push Notifications" capability

**Solución:**
Click en "+ Capability" > Buscar "Push Notifications" > Agregar

---

## 🤖 Android - Problemas y Soluciones

### Problema: "No llegan notificaciones en Android"

**Causas posibles:**

#### 1. Permisos POST_NOTIFICATIONS no otorgados (Android 13+)

**Verificar:**
```dart
// En Android 13+, se requiere permiso explícito
if (Platform.isAndroid && Build.VERSION.SDK_INT >= 33) {
  // Solicitar permiso
}
```

**Solución:**
Verificar `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Si no existe, agregarlo después de `<uses-permission android:name="android.permission.INTERNET"/>`

#### 2. google-services.json desactualizado

**Verificar:**
```bash
# Archivo debe existir en:
android/app/google-services.json
```

**Solución:**
1. Ve a Firebase Console > Project Settings
2. Descarga `google-services.json` actualizado
3. Reemplaza el archivo existente
4. Rebuild:
```bash
flutter clean
flutter pub get
flutter build apk
```

#### 3. Servicio de mensajería no configurado

**Verificar:** `android/app/src/main/AndroidManifest.xml`
```xml
<service
    android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT"/>
    </intent-filter>
</service>
```

**Solución:**
Si no existe, agregarlo dentro de `<application>` antes de `</application>`

---

## 🌐 Web - Problemas y Soluciones

### Problema: "No llegan notificaciones en Web"

**Causas posibles:**

#### 1. VAPID key no configurada

**Verificar:** `lib/core/services/notification_service.dart`
```dart
vapidKey: kIsWeb
  ? 'TU_VAPID_KEY_AQUI' // ← Debe tener valor real
  : null,
```

**Solución:**
1. Firebase Console > Cloud Messaging > Web Push certificates
2. Generate key pair
3. Copiar la clave pública
4. Reemplazar en el código

#### 2. Service Worker no disponible

**Error típico:**
```
"failed-service-worker-registration"
```

**Causa:** La app no está corriendo en HTTPS o localhost

**Solución en desarrollo:**
```bash
# Correr en localhost explícitamente
flutter run -d chrome --web-hostname localhost --web-port 8080
```

**Solución en producción:**
- Asegurar que el hosting usa HTTPS
- Firebase Hosting ya incluye HTTPS automático

#### 3. Permisos bloqueados en navegador

**Verificar:**
```
Chrome: Configuración > Privacidad y seguridad > Configuración de sitios > Notificaciones
```

**Solución:**
1. Permitir notificaciones para tu sitio
2. Recargar página
3. Aceptar cuando se solicite permiso

---

## 🔥 Firebase Cloud Functions - Problemas

### Problema: "Cloud Function no envía notificaciones"

#### 1. Verificar logs de Cloud Functions

**Ver errores:**
```bash
firebase functions:log --only sendImmediateNotification
```

O en Firebase Console:
- Functions > Logs > Filtrar por función

#### 2. Función no deployada

**Verificar:**
```bash
firebase functions:list
```

**Solución:**
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

#### 3. Token FCM inválido o expirado

**Síntoma:** Error `messaging/invalid-registration-token`

**Solución:**
```dart
// Forzar refresh del token
await FirebaseMessaging.instance.deleteToken();
final newToken = await FirebaseMessaging.instance.getToken();
// Guardar en Firestore
```

---

## 🧪 Testing Manual

### Script de prueba rápida

**Crear:** `test_notification.dart`
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> testNotifications() async {
  final messaging = FirebaseMessaging.instance;

  // 1. Verificar permisos
  final settings = await messaging.requestPermission();
  print('Permission: ${settings.authorizationStatus}');

  // 2. Obtener token
  final token = await messaging.getToken();
  print('FCM Token: $token');

  // 3. Escuchar mensajes
  FirebaseMessaging.onMessage.listen((message) {
    print('📨 Mensaje recibido:');
    print('Título: ${message.notification?.title}');
    print('Cuerpo: ${message.notification?.body}');
  });

  print('✅ Listening for notifications...');
}
```

### Enviar notificación de prueba desde Firebase Console

1. Ve a: Firebase Console > Cloud Messaging
2. Click "Send your first message"
3. Notification title: "Test"
4. Notification text: "Probando notificaciones"
5. Click "Send test message"
6. Pega tu FCM token
7. Click "Test"

---

## 📊 Checklist de Diagnóstico

Usa esta lista para identificar el problema:

**General:**
- [ ] Firebase configurado correctamente
- [ ] google-services.json / GoogleService-Info.plist actualizados
- [ ] Token FCM se obtiene correctamente
- [ ] Token se guarda en Firestore

**iOS:**
- [ ] Certificado APNs válido en Firebase Console
- [ ] Push Notifications capability habilitada en Xcode
- [ ] Info.plist tiene UIBackgroundModes
- [ ] Permisos otorgados por usuario
- [ ] Testeado en dispositivo real (no simulador)

**Android:**
- [ ] POST_NOTIFICATIONS permission en AndroidManifest.xml
- [ ] google-services.json actualizado
- [ ] Servicio de mensajería configurado
- [ ] Permisos otorgados (Android 13+)

**Web:**
- [ ] VAPID key configurada
- [ ] Corriendo en HTTPS o localhost
- [ ] Service worker registrado
- [ ] Permisos otorgados en navegador

**Cloud Functions:**
- [ ] Funciones deployadas
- [ ] No hay errores en logs
- [ ] Tokens válidos en Firestore

---

## 🆘 Última Opción

Si nada funciona:

1. **Limpiar completamente:**
```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..
```

2. **Reinstalar app completamente:**
- Desinstalar de dispositivo
- Rebuild desde cero
- Instalar y probar

3. **Verificar Firebase Project ID:**
```bash
# Debe coincidir en todos lados:
# - Firebase Console
# - google-services.json (Android)
# - GoogleService-Info.plist (iOS)
# - .firebaserc
```

4. **Contactar soporte:**
- Firebase Support: https://firebase.google.com/support
- Stack Overflow con tag `firebase-cloud-messaging`

---

## 📞 Recursos Útiles

- **Firebase Docs**: https://firebase.google.com/docs/cloud-messaging
- **Flutter Firebase Messaging**: https://firebase.flutter.dev/docs/messaging/overview
- **Apple APNs**: https://developer.apple.com/documentation/usernotifications
- **Android Notifications**: https://developer.android.com/develop/ui/views/notifications

---

**Última actualización**: 2026-04-14
**Mantenido por**: Equipo Dev Ayutthaya Camp
