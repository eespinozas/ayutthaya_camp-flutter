# Cómo Testear Notificaciones Push

✅ **VAPID Key configurada correctamente**

Ahora puedes testear las notificaciones en todas las plataformas.

---

## 🌐 Testear en Web (Más Fácil)

### Paso 1: Correr la app en web
```bash
flutter run -d chrome --web-hostname localhost --web-port 8080
```

### Paso 2: Verificar que el token se genere
Abre la consola del navegador (F12) y busca:
```
🔑 FCM Token: [un token largo aquí]
```

**Si ves el token = ✅ Configuración correcta**

### Paso 3: Enviar notificación de prueba

#### Opción A: Desde Firebase Console (más fácil)
1. Ve a: Firebase Console > Cloud Messaging
2. Click "Send test message"
3. Pega el token FCM que copiaste de la consola
4. Agrega título y cuerpo
5. Click "Test"

**Deberías ver la notificación aparecer** 🔔

#### Opción B: Desde tu app (más real)
1. Registra un nuevo usuario
2. El admin debería recibir notificación automática
3. O aprueba un pago y el usuario recibirá notificación

---

## 🤖 Testear en Android

### Paso 1: Build y deploy
```bash
flutter run -d [tu-dispositivo-android]
```

### Paso 2: Dar permisos
Cuando la app solicite permisos de notificaciones, acepta.

### Paso 3: Obtener token
Mira los logs de Flutter:
```bash
flutter logs
```

Busca:
```
🔑 FCM Token: [token]
```

### Paso 4: Enviar notificación de prueba
Igual que en web: Firebase Console > Send test message

---

## 📱 Testear en iOS

⚠️ **Requiere configuración adicional:**

### Antes de testear:
1. Necesitas certificado APNs (.p8) de Apple Developer
2. Subirlo a Firebase Console > Project Settings > Cloud Messaging
3. Solo funciona en **dispositivo real** (no simulador)

### Pasos:
1. Conecta iPhone/iPad
2. `flutter run -d [tu-dispositivo-ios]`
3. Acepta permisos cuando aparezca el diálogo
4. Obtén token de los logs
5. Envía test desde Firebase Console

---

## ✅ Checklist de Validación

### Web
- [ ] Token FCM se genera correctamente
- [ ] No hay errores de VAPID key
- [ ] Notificación de prueba llega
- [ ] Al hacer click en notificación, abre la app

### Android
- [ ] Permisos de notificación otorgados
- [ ] Token FCM se genera
- [ ] Notificación llega con app cerrada
- [ ] Notificación llega con app en background
- [ ] Al tocar notificación, navega correctamente

### iOS
- [ ] Certificado APNs subido a Firebase
- [ ] Permisos otorgados
- [ ] Token FCM se genera
- [ ] Notificación llega (dispositivo real)
- [ ] Navegación funciona

---

## 🎬 Testear Flujos Completos

### 1. Registro de Nuevo Usuario → Notificación a Admin
```
1. Registra nuevo usuario en la app
2. Verifica que el admin reciba notificación
3. Toca la notificación → debe ir a lista de alumnos
```

### 2. Pago Aprobado → Notificación a Usuario
```
1. Usuario sube comprobante
2. Admin aprueba pago
3. Usuario recibe notificación
4. Toca notificación → debe ir al dashboard
```

### 3. Recordatorio de Clase
```
1. Agenda una clase
2. Espera a que falten 30 minutos (o modifica el tiempo en código)
3. Deberías recibir recordatorio
```

---

## 🐛 Problemas Comunes

### "Service Worker no disponible" (Web)
**Solución:** Usa `localhost` con el comando exacto:
```bash
flutter run -d chrome --web-hostname localhost --web-port 8080
```

### "Token is null" (Cualquier plataforma)
**Solución:**
1. Verifica que los permisos estén otorgados
2. Revisa que Firebase esté inicializado en `main.dart`
3. Mira los logs para errores específicos

### "Notificación no llega" (iOS)
**Solución:**
1. Verifica que el certificado APNs esté subido
2. Solo funciona en dispositivo real (no simulador)
3. Revisa que los permisos estén activos en Settings

---

## 🎯 Siguiente Paso

Una vez que las notificaciones funcionen:

1. **Documenta cualquier problema** que encontraste
2. **Testea con usuarios reales** (beta testers)
3. **Monitorea logs** en Firebase Console para ver tasa de entrega
4. **Prepara Sprint 3-4**: Sistema de diseño unificado

---

**Última actualización**: 2026-04-14
**VAPID Key**: ✅ Configurada
**Status**: Listo para testear
