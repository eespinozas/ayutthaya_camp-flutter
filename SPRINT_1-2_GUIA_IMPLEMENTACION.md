# Sprint 1-2: Guía de Implementación Rápida

Esta guía te ayuda a implementar los cambios del Sprint 1-2 paso a paso.

---

## ✅ Cambios Completados

### 1. Email Redundante Eliminado

**Archivos modificados:**
- ✅ `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`
- ✅ `lib/core/services/auth_email_service.dart`
- ✅ `lib/features/auth/presentation/pages/email_verification_page.dart`

**Qué cambió:**
- ANTES: Usuario recibía 2 emails de verificación (Firebase Auth + Cloud Function)
- AHORA: Usuario recibe 1 solo email (Firebase Auth nativo)

**Verificar:**
```bash
# Testear registro de nuevo usuario
flutter run
# 1. Registrar nuevo usuario
# 2. Verificar que llega 1 solo email
# 3. Verificar que el email funciona correctamente
```

---

### 2. Sistema de Manejo de Errores Centralizado

**Archivos creados:**
```
lib/core/error/
├── failures.dart           ✅ Creado
├── exceptions.dart         ✅ Creado
└── error_handler.dart      ✅ Creado

lib/core/widgets/atoms/
└── app_error_message.dart  ✅ Creado
```

**Cómo usarlo en tus ViewModels:**

#### ANTES (sin manejo centralizado):
```dart
Future<void> login(String email, String password) async {
  try {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _user = cred.user;
  } catch (e) {
    _error = e.toString(); // ❌ Mensaje críptico
  }
}
```

#### DESPUÉS (con ErrorHandler):
```dart
import '../../../core/error/error_handler.dart'; // ← Importar

Future<void> login(String email, String password) async {
  try {
    _loading = true;
    _error = null;
    notifyListeners();

    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    _user = cred.user;
  } catch (e, stackTrace) {
    // Logging para debugging
    ErrorHandler.logError(e, stackTrace, context: 'AuthViewModel.login');

    // Mensaje amigable para usuario
    _error = ErrorHandler.getUserMessage(e); // ✅ "Contraseña incorrecta"
  } finally {
    _loading = false;
    notifyListeners();
  }
}
```

**Cómo usarlo en las páginas:**

#### Opción 1: Widget de error completo
```dart
if (viewModel.error != null) {
  return AppErrorMessage(
    message: viewModel.error!,
    onRetry: () => viewModel.reload(),
  );
}
```

#### Opción 2: SnackBar
```dart
if (viewModel.error != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    AppErrorSnackBar(message: viewModel.error!),
  );
}
```

#### Opción 3: Dialog
```dart
if (viewModel.error != null) {
  await AppErrorDialog.show(
    context,
    message: viewModel.error!,
    onRetry: () => viewModel.retry(),
  );
}
```

---

## 🔧 Tareas Pendientes (Completar manualmente)

### 3. Configurar VAPID Key para Notificaciones Web

**Paso 1: Obtener VAPID Key de Firebase**
1. Ve a [Firebase Console](https://console.firebase.google.com/project/ayuthaya-camp)
2. Project Settings > Cloud Messaging
3. En "Web Push certificates", click "Generate key pair"
4. Copia la clave pública generada

**Paso 2: Actualizar el código**

Editar: `lib/core/services/notification_service.dart`

**Buscar línea 43 y 130:**
```dart
vapidKey: kIsWeb
  ? 'YOUR_VAPID_KEY_HERE' // ← Reemplazar
  : null,
```

**Reemplazar con:**
```dart
vapidKey: kIsWeb
  ? 'TU_CLAVE_VAPID_REAL_AQUI' // ← Pegar la key de Firebase Console
  : null,
```

**Paso 3: Testear**
```bash
# En web (requiere HTTPS o localhost)
flutter run -d chrome --web-hostname localhost --web-port 8080

# Verificar en consola del navegador:
# - No debe haber errores de "VAPID key"
# - Token FCM debe generarse correctamente
```

---

### 4. Testear Notificaciones en Dispositivos Reales

**iOS (Requiere certificado APNs):**
1. Ve a [Firebase Console](https://console.firebase.google.com/project/ayuthaya-camp)
2. Project Settings > Cloud Messaging > iOS
3. Sube tu certificado `.p8` de Apple Developer
4. Ingresa Key ID y Team ID
5. Testear en dispositivo iOS real

**Android (Debería funcionar sin cambios):**
```bash
# Build y deploy en dispositivo Android
flutter build apk --release
# Instalar y testear notificaciones
```

**Script de prueba:**
```bash
# Usar el script de Python (requiere firebase-admin)
python scripts/test_notifications.py
```

O desde Firebase Console:
1. Cloud Messaging > Send test message
2. Ingresar FCM token del dispositivo
3. Enviar notificación

---

## 📝 Checklist de Validación

### Emails
- [ ] Usuario nuevo recibe 1 solo email de verificación
- [ ] Email de reset password funciona correctamente
- [ ] No hay emails duplicados en ningún flujo

### Manejo de Errores
- [ ] Errores de login muestran mensajes amigables
- [ ] Errores de registro muestran mensajes amigables
- [ ] Errores de Firestore se manejan correctamente
- [ ] Logs de error aparecen en consola (modo debug)

### Notificaciones
- [ ] VAPID key configurada (web)
- [ ] Certificado APNs subido (iOS)
- [ ] Notificación de nuevo usuario → Admin funciona
- [ ] Notificación de pago aprobado → Usuario funciona
- [ ] Recordatorio de clase funciona (si aplica)

---

## 🚀 Próximos Pasos

Una vez completado el Sprint 1-2:

1. **Deploy a staging** para testing con usuarios reales
2. **Monitorear errores** en Firebase Crashlytics
3. **Medir métricas**:
   - Tasa de emails duplicados (debería ser 0%)
   - Tasa de entrega de notificaciones (objetivo: >95%)
   - Errores reportados por usuarios (debería bajar)

4. **Preparar Sprint 3-4**: Sistema de diseño + Clean Architecture

---

## 🆘 Problemas Comunes

### "No llegan notificaciones en iOS"
→ Ver: `NOTIFICACIONES_TROUBLESHOOTING.md`

### "Usuario no recibe email de verificación"
→ Verificar:
1. Spam folder
2. Firebase Auth está habilitado en Console
3. Template de email está configurado

### "Errores siguen mostrando mensajes feos"
→ Asegurar que usas `ErrorHandler.getUserMessage(e)` en TODOS los catch blocks

---

**Última actualización**: 2026-04-14
**Sprint**: 1-2
**Status**: ✅ Implementación base completa, pendiente testing
