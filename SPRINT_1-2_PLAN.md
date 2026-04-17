# Sprint 1-2: Crítico - Notificaciones + Emails + Errores

**Duración**: 2 semanas (10 días hábiles)
**Objetivo**: Estabilizar funcionalidades críticas antes de cualquier migración arquitectural

---

## Día 1-2: Eliminar Emails Redundantes

### Problema Detectado

**Flujo actual (DUPLICADO):**
```
Usuario se registra
  ├─> Firebase Auth envía email verificación automático ✅
  └─> Cloud Function sendVerificationEmail() TAMBIÉN envía email ❌ REDUNDANTE
```

**Resultado**: Usuario recibe 2 emails idénticos de verificación

### Solución

**Opción A - Recomendada (usar Firebase Auth nativo):**
- ✅ Eliminar dependencia de Cloud Function para verificación
- ✅ Usar `sendEmailVerification()` de Firebase Auth directamente
- ✅ Mantener Cloud Function SOLO para reset password (más personalizable)

**Opción B - Alternativa (usar solo Cloud Functions):**
- Desactivar emails automáticos de Firebase Auth
- Usar Cloud Functions para TODO
- ❌ Más complejo, menos confiable

**Decisión**: Implementar Opción A

### Archivos a Modificar

#### 1. `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`

**ANTES (línea 172):**
```dart
// 3. Enviar email de verificación
await cred.user?.sendEmailVerification();
```

**DESPUÉS:**
```dart
// 3. Enviar email de verificación (Firebase Auth nativo)
await cred.user?.sendEmailVerification();
// ✅ Ya NO llamamos a AuthEmailService aquí (era redundante)
```

#### 2. `lib/core/services/auth_email_service.dart`

**ACCIÓN**: Eliminar método `sendVerificationEmail()` completamente

**MANTENER SOLO**:
- `sendPasswordResetEmail()` (para templates personalizados)

**NUEVO CONTENIDO**:
```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para emails transaccionales PERSONALIZADOS mediante Cloud Functions
///
/// NOTA: Para verificación de email, usa Firebase Auth nativo:
/// `await user.sendEmailVerification()`
class AuthEmailService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Envía email de recuperación de contraseña personalizado con template HTML
  ///
  /// [email] - Email del usuario que solicita recuperación
  ///
  /// Por seguridad, siempre devuelve éxito aunque el email no exista
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty || !_isValidEmail(email)) {
      throw Exception('Email inválido');
    }

    try {
      final callable = _functions.httpsCallable('sendPasswordResetEmail');
      final result = await callable.call<Map<String, dynamic>>({
        'email': email,
      });

      final success = result.data['success'] as bool;
      final message = result.data['message'] as String;

      if (!success) {
        throw Exception(message);
      }

      print('✅ Email de recuperación enviado: $message');
    } on FirebaseFunctionsException catch (e) {
      print('❌ Error: ${e.code} - ${e.message}');
      throw Exception(_getErrorMessage(e.code));
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _getErrorMessage(String code) {
    // ... (mantener igual)
  }
}
```

#### 3. `lib/features/auth/presentation/pages/email_verification_page.dart`

**ANTES (línea 24):**
```dart
await _emailService.sendVerificationEmail();
```

**DESPUÉS:**
```dart
await _auth.currentUser?.sendEmailVerification(); // Firebase Auth nativo
```

**ELIMINAR**:
```dart
final _emailService = AuthEmailService(); // Ya no necesario
```

### Testing

**Casos de prueba:**
1. ✅ Registro nuevo usuario → recibe 1 solo email
2. ✅ Reenviar email desde EmailVerificationPage → funciona
3. ✅ Reset password → recibe email personalizado
4. ✅ No hay errores en consola

---

## Día 3-5: Implementar Manejo de Errores Centralizado

### Objetivo
Tener un sistema robusto para capturar, registrar y mostrar errores de forma consistente.

### Archivos a Crear

#### 1. `lib/core/error/failures.dart`

```dart
/// Clase base para todos los failures del dominio
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure: $message (code: ${code ?? 'unknown'})';
}

/// Failures específicos por categoría
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}
```

#### 2. `lib/core/error/exceptions.dart`

```dart
/// Excepciones para la capa de datos
class ServerException implements Exception {
  final String message;
  final String? code;

  const ServerException(this.message, {this.code});

  @override
  String toString() => 'ServerException: $message (code: ${code ?? 'unknown'})';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class ValidationException implements Exception {
  final String message;

  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
```

#### 3. `lib/core/error/error_handler.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'failures.dart';

/// Manejo centralizado de errores
class ErrorHandler {
  /// Convierte excepciones en mensajes amigables para el usuario
  static String getUserMessage(dynamic error) {
    if (error is Failure) {
      return error.message;
    }

    if (error is FirebaseAuthException) {
      return _getFirebaseAuthMessage(error.code);
    }

    if (error is FirebaseException) {
      return _getFirestoreMessage(error.code);
    }

    if (error.toString().contains('SocketException')) {
      return 'Sin conexión a internet. Verifica tu red.';
    }

    if (error.toString().contains('TimeoutException')) {
      return 'La operación tardó demasiado. Intenta nuevamente.';
    }

    // Error genérico
    return 'Error inesperado. Si persiste, contacta soporte.';
  }

  /// Log de errores para debugging
  static void logError(dynamic error, StackTrace? stackTrace, {String? context}) {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('❌ ERROR ${context != null ? "en $context" : ""}');
      debugPrint('───────────────────────────────────────────────────');
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace:\n$stackTrace');
      }
      debugPrint('═══════════════════════════════════════════════════');
    }

    // TODO: Enviar a Firebase Crashlytics en producción
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Mensajes específicos de Firebase Auth
  static String _getFirebaseAuthMessage(String code) {
    switch (code) {
      // Auth errors
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Intenta nuevamente.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Inicia sesión.';
      case 'weak-password':
        return 'Contraseña muy débil. Usa al menos 6 caracteres.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tus datos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta en unos minutos.';
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexión.';

      // Default
      default:
        return 'Error de autenticación ($code).';
    }
  }

  /// Mensajes específicos de Firestore
  static String _getFirestoreMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'No tienes permisos para realizar esta acción.';
      case 'not-found':
        return 'Documento no encontrado.';
      case 'already-exists':
        return 'Este documento ya existe.';
      case 'resource-exhausted':
        return 'Límite de operaciones excedido. Intenta más tarde.';
      case 'failed-precondition':
        return 'Operación no permitida en el estado actual.';
      case 'aborted':
        return 'Operación abortada. Intenta nuevamente.';
      case 'out-of-range':
        return 'Fuera de rango válido.';
      case 'unimplemented':
        return 'Funcionalidad no implementada.';
      case 'internal':
        return 'Error interno del servidor.';
      case 'unavailable':
        return 'Servicio no disponible. Intenta más tarde.';
      case 'data-loss':
        return 'Pérdida de datos. Contacta soporte.';
      case 'unauthenticated':
        return 'Debes iniciar sesión para continuar.';

      default:
        return 'Error de base de datos ($code).';
    }
  }
}
```

#### 4. `lib/core/widgets/atoms/app_error_message.dart`

```dart
import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar errores
class AppErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### Ejemplo de Uso en ViewModels

```dart
// ANTES
Future<void> login(String email, String password) async {
  try {
    _loading = true;
    notifyListeners();

    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    _user = cred.user;
  } catch (e) {
    _error = e.toString(); // ❌ Mensaje feo para usuario
  } finally {
    _loading = false;
    notifyListeners();
  }
}

// DESPUÉS
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
    ErrorHandler.logError(e, stackTrace, context: 'AuthViewModel.login');
    _error = ErrorHandler.getUserMessage(e); // ✅ Mensaje amigable
  } finally {
    _loading = false;
    notifyListeners();
  }
}
```

---

## Día 6-8: Configurar y Validar Notificaciones Push

### Objetivo
Asegurar que las notificaciones push funcionen en iOS, Android y Web.

### Paso 1: Configurar VAPID Key (Web)

#### Firebase Console
1. Ve a: `Project Settings > Cloud Messaging > Web Push certificates`
2. Genera un nuevo par de claves VAPID
3. Copia la **Public key**

#### Actualizar `lib/core/services/notification_service.dart`

**LÍNEA 43 y 130:**
```dart
// ANTES
vapidKey: kIsWeb
  ? 'YOUR_VAPID_KEY_HERE' // ❌ Placeholder
  : null,

// DESPUÉS
vapidKey: kIsWeb
  ? 'TU_VAPID_KEY_REAL_AQUI' // ✅ Reemplazar con key de Firebase Console
  : null,
```

### Paso 2: Configurar iOS (APNs)

#### `ios/Runner/Info.plist`
Verificar que exista:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

#### Subir APNs Certificate a Firebase
1. Ve a: `Project Settings > Cloud Messaging > iOS app configuration`
2. Sube tu certificado `.p8` de Apple Developer
3. Ingresa Key ID y Team ID

### Paso 3: Configurar Android (FCM)

Ya debería estar funcionando, pero verificar:

#### `android/app/src/main/AndroidManifest.xml`
```xml
<manifest>
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

  <application>
    <!-- Firebase Messaging Service -->
    <service
      android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
      android:exported="false">
      <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT"/>
      </intent-filter>
    </service>
  </application>
</manifest>
```

### Paso 4: Testing Manual

#### Script de Testing: `scripts/test_notifications.py`

```python
#!/usr/bin/env python3
"""
Script para testear notificaciones push manualmente
Requiere: pip install firebase-admin
"""

import firebase_admin
from firebase_admin import credentials, messaging

# Inicializar Firebase Admin SDK
cred = credentials.Certificate('path/to/serviceAccountKey.json')
firebase_admin.initialize_app(cred)

def send_test_notification(fcm_token):
    """Envía notificación de prueba a un token específico"""

    message = messaging.Message(
        notification=messaging.Notification(
            title='🧪 Test de Notificación',
            body='Si ves esto, las notificaciones funcionan correctamente!',
        ),
        data={
            'type': 'test',
            'timestamp': str(int(time.time())),
        },
        token=fcm_token,
    )

    try:
        response = messaging.send(message)
        print(f'✅ Notificación enviada exitosamente: {response}')
        return True
    except Exception as e:
        print(f'❌ Error enviando notificación: {e}')
        return False

if __name__ == '__main__':
    # Reemplazar con un FCM token real de un dispositivo
    test_token = input('Ingresa el FCM token del dispositivo: ')
    send_test_notification(test_token)
```

### Paso 5: Checklist de Validación

**iOS:**
- [ ] Notificación llega con app cerrada
- [ ] Notificación llega con app en background
- [ ] Notificación llega con app en foreground
- [ ] Al tocar notificación, navega correctamente
- [ ] Sonido funciona
- [ ] Badge count funciona

**Android:**
- [ ] Notificación llega con app cerrada
- [ ] Notificación llega con app en background
- [ ] Notificación llega con app en foreground
- [ ] Al tocar notificación, navega correctamente
- [ ] Sonido funciona
- [ ] Icono se muestra correctamente

**Web:**
- [ ] Permisos se solicitan correctamente
- [ ] Notificación llega en Chrome/Edge
- [ ] Notificación llega en Firefox
- [ ] Al hacer click, abre la app

### Paso 6: Documentar Troubleshooting

Crear archivo: `NOTIFICACIONES_TROUBLESHOOTING.md`

```markdown
# Troubleshooting - Notificaciones Push

## Problema: "Service Worker no disponible en web"

**Causa**: La app no está corriendo en HTTPS o localhost

**Solución**:
1. En desarrollo: usar `flutter run -d chrome --web-hostname localhost --web-port 8080`
2. En producción: asegurar que el hosting usa HTTPS

## Problema: "No llegan notificaciones en iOS"

**Causa**: Certificado APNs no configurado o expirado

**Solución**:
1. Verificar en Firebase Console > Cloud Messaging > iOS
2. Renovar certificado .p8 en Apple Developer
3. Volver a subir a Firebase

## Problema: "Token null en getToken()"

**Causa**: Permisos no otorgados

**Solución**:
1. Verificar que se solicitan permisos: `await _messaging.requestPermission()`
2. En iOS: verificar que el usuario dio permiso en Settings
3. En Android: verificar `POST_NOTIFICATIONS` permission

## Problema: "Notificación se envía pero no se recibe"

**Diagnóstico**:
1. Verificar que el token esté actualizado en Firestore
2. Revisar logs de Firebase Console > Cloud Messaging
3. Verificar que el token no esté revocado

**Solución**:
1. Forzar refresh del token: borrar app y reinstalar
2. Verificar Firestore Rules permite escribir fcmToken
```

---

## Día 9-10: Testing End-to-End + Documentación

### Tests Manuales Críticos

#### 1. Flujo de Registro Completo
```
1. Usuario nuevo se registra
   ✅ Recibe 1 solo email de verificación
   ✅ Email tiene formato correcto

2. Usuario verifica email
   ✅ Puede hacer login después de verificar
   ✅ Es redirigido al dashboard correcto

3. Admin recibe notificación
   ✅ Notificación push llega
   ✅ Muestra nombre del nuevo usuario
```

#### 2. Flujo de Matrícula
```
1. Alumno sube comprobante
   ✅ Upload a Firebase Storage funciona
   ✅ Payment se crea con status "pending"
   ✅ Admin recibe notificación push

2. Admin aprueba pago
   ✅ User status cambia a "active"
   ✅ Alumno recibe notificación push
   ✅ expirationDate se calcula correctamente
```

#### 3. Flujo de Reset Password
```
1. Usuario solicita reset
   ✅ Recibe email personalizado (Cloud Function)
   ✅ Email tiene template HTML bonito

2. Usuario hace reset
   ✅ Puede hacer login con nueva password
```

### Documentación Final

Crear: `SPRINT_1-2_RESULTADOS.md`

```markdown
# Resultados Sprint 1-2

## ✅ Completado

### 1. Emails Redundantes Eliminados
- ❌ ANTES: 2 emails de verificación
- ✅ AHORA: 1 email de verificación (Firebase Auth nativo)
- Mantenido: Email personalizado para reset password

### 2. Manejo de Errores Centralizado
- Archivos creados:
  - `core/error/failures.dart`
  - `core/error/exceptions.dart`
  - `core/error/error_handler.dart`
  - `core/widgets/atoms/app_error_message.dart`
- Mensajes de error 100% amigables para usuarios

### 3. Notificaciones Push Validadas
- ✅ iOS: Funcionando
- ✅ Android: Funcionando
- ✅ Web: Funcionando (HTTPS requerido)
- Documentación: `NOTIFICACIONES_TROUBLESHOOTING.md`

## 📊 Métricas

- **Emails reducidos**: 50% (de 2 a 1)
- **Errores capturados**: 100% (con ErrorHandler)
- **Notificaciones testeadas**: 18 casos (6 por plataforma)
- **Tests manuales pasados**: 3/3 flujos críticos

## 🐛 Issues Encontrados y Resueltos

1. **VAPID key faltante en web**
   - Solución: Configurado en notification_service.dart

2. **Error messages crípticos**
   - Solución: ErrorHandler traduce todos los códigos

## 🚀 Próximos Pasos (Sprint 3-4)

1. Sistema de diseño unificado
2. Refactorización Auth hacia Clean Architecture
3. Implementación de caché local
```

---

## Checklist de Entrega

- [ ] Código refactorizado y testeado
- [ ] PRs creados y aprobados
- [ ] Documentación actualizada
- [ ] Tests manuales pasados
- [ ] Deploy a staging completado
- [ ] Stakeholders notificados
- [ ] SPRINT_1-2_RESULTADOS.md creado

---

**Última actualización**: 2026-04-14
**Sprint Owner**: (Tu nombre)
**Status**: 🟢 En progreso
