# Implementación de Emails Transaccionales con SendGrid

Guía completa para implementar correos electrónicos profesionales de verificación y recuperación de contraseña en tu app Flutter con Firebase.

---

## 📋 Tabla de Contenidos

1. [Arquitectura](#-arquitectura)
2. [Prerequisitos](#-prerequisitos)
3. [Configuración de SendGrid](#-configuración-de-sendgrid)
4. [Instalación y Deploy](#-instalación-y-deploy)
5. [Uso desde Flutter](#-uso-desde-flutter)
6. [Testing](#-testing)
7. [Seguridad](#-seguridad)
8. [Troubleshooting](#-troubleshooting)

---

## 🏗️ Arquitectura

```
┌─────────────┐         ┌──────────────────┐         ┌──────────────┐
│             │         │                  │         │              │
│  Flutter    │────────▶│  Cloud Function  │────────▶│   SendGrid   │
│  App        │  HTTPS  │  (TypeScript)    │   API   │   Email API  │
│             │         │                  │         │              │
└─────────────┘         └──────────────────┘         └──────────────┘
       │                         │                           │
       │                         ▼                           ▼
       │                  ┌─────────────┐            ┌─────────────┐
       │                  │  Firebase   │            │   Usuario   │
       └─────────────────▶│  Auth       │            │   Inbox     │
          Auth Token      └─────────────┘            └─────────────┘
```

**Flujo:**
1. Usuario solicita verificación/reset desde Flutter
2. Flutter llama Cloud Function con Firebase Auth token
3. Cloud Function valida identidad
4. Genera link oficial de Firebase Auth
5. Renderiza template HTML profesional
6. Envía email vía SendGrid
7. Usuario recibe email y hace click
8. Firebase maneja el action code automáticamente

---

## 🔧 Prerequisitos

### 1. Cuenta de SendGrid

Crea una cuenta gratuita en [SendGrid](https://signup.sendgrid.com/):
- Plan gratuito: 100 emails/día
- Planes pagos desde $19.95/mes para 40,000 emails/mes

### 2. Verificación de dominio (Recomendado para producción)

**Opción A: Domain Authentication (Mejor deliverability)**
```
1. Ve a Settings > Sender Authentication > Authenticate Your Domain
2. Agrega registros DNS CNAME a tu dominio
3. Espera verificación (24-48 horas)
```

**Opción B: Single Sender Verification (Rápido para testing)**
```
1. Ve a Settings > Sender Authentication > Verify a Single Sender
2. Completa el formulario con tu email
3. Verifica tu email
```

### 3. API Key de SendGrid

```
1. Ve a Settings > API Keys > Create API Key
2. Nombre: "Firebase Cloud Functions"
3. Permisos: Full Access (o solo Mail Send)
4. Copia la API Key (solo se muestra una vez)
```

---

## ⚙️ Configuración de SendGrid

### 1. Configura variables de entorno

En Firebase, configura las variables de entorno:

```bash
cd functions

# Configura cada variable
firebase functions:config:set sendgrid.api_key="SG.tu-api-key-aqui"
firebase functions:config:set sendgrid.from_email="noreply@tuapp.com"
firebase functions:config:set sendgrid.from_name="Ayutthaya Camp"
firebase functions:config:set app.name="Ayutthaya Camp"
firebase functions:config:set app.logo_url="https://tuapp.com/logo.png"
firebase functions:config:set app.support_email="soporte@tuapp.com"
firebase functions:config:set app.company_address="Tu Dirección, Ciudad, País"
firebase functions:config:set app.firebase_action_domain="tuapp.firebaseapp.com"
```

### 2. Crea archivo .env local (para emulators)

Copia `.env.example` a `.env` y completa:

```bash
cd functions
cp .env.example .env
```

Edita `functions/.env`:

```env
SENDGRID_API_KEY=SG.tu-api-key-aqui
SENDGRID_FROM_EMAIL=noreply@tuapp.com
SENDGRID_FROM_NAME=Ayutthaya Camp
APP_NAME=Ayutthaya Camp
APP_LOGO_URL=https://tuapp.com/logo.png
SUPPORT_EMAIL=soporte@tuapp.com
COMPANY_ADDRESS=Tu Dirección, Ciudad, País
FIREBASE_ACTION_DOMAIN=tuapp.firebaseapp.com
NODE_ENV=development
```

**IMPORTANTE:** El archivo `.env` ya está en `.gitignore`. NUNCA lo subas a Git.

---

## 🚀 Instalación y Deploy

### 1. Instala dependencias

```bash
cd functions
npm install
```

Esto instalará:
- `@sendgrid/mail`: Cliente oficial de SendGrid
- `typescript`: Compilador TypeScript
- `@types/node`: Tipos de Node.js
- Otras dependencias de desarrollo

### 2. Compila TypeScript

```bash
npm run build
```

Esto compilará `src/` → `lib/`

### 3. Prueba localmente (opcional)

```bash
# Inicia emulators
npm run serve

# En otra terminal, prueba
curl -X POST http://localhost:5001/tu-proyecto/us-central1/sendVerificationEmail \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_DE_PRUEBA" \
  -d '{"data":{"email":"test@example.com"}}'
```

### 4. Deploy a producción

```bash
npm run deploy
```

O deploy selectivo:

```bash
firebase deploy --only functions:sendVerificationEmail
firebase deploy --only functions:sendPasswordResetEmail
```

### 5. Verifica el deploy

```bash
firebase functions:log --only sendVerificationEmail
```

---

## 📱 Uso desde Flutter

### 1. Agregar dependencia

En `pubspec.yaml`:

```yaml
dependencies:
  cloud_functions: ^5.1.0  # Ya la tienes si usas Firebase
```

### 2. Crear servicio de email

Crea `lib/core/services/auth_email_service.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthEmailService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Envía email de verificación personalizado
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    if (user.emailVerified) {
      throw Exception('El email ya está verificado');
    }

    try {
      final callable = _functions.httpsCallable('sendVerificationEmail');
      final result = await callable.call<Map<String, dynamic>>({
        'email': user.email,
      });

      final success = result.data['success'] as bool;
      final message = result.data['message'] as String;

      if (!success) {
        throw Exception(message);
      }

      print('✅ Email de verificación enviado: $message');
    } on FirebaseFunctionsException catch (e) {
      print('❌ Error: ${e.code} - ${e.message}');
      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      print('❌ Error inesperado: $e');
      throw Exception('Error al enviar email de verificación');
    }
  }

  /// Envía email de recuperación de contraseña personalizado
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
    } catch (e) {
      print('❌ Error inesperado: $e');
      throw Exception('Error al enviar email de recuperación');
    }
  }

  // Validación básica de email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Mensajes de error amigables
  String _getErrorMessage(String code) {
    switch (code) {
      case 'unauthenticated':
        return 'Debes iniciar sesión primero';
      case 'invalid-argument':
        return 'Email inválido';
      case 'permission-denied':
        return 'No tienes permiso para realizar esta acción';
      case 'internal':
        return 'Error del servidor. Intenta nuevamente';
      default:
        return 'Error desconocido. Intenta nuevamente';
    }
  }
}
```

### 3. Ejemplo de uso en UI

**Verificación de email:**

```dart
// En tu LoginPage o DashboardPage
class _LoginPageState extends State<LoginPage> {
  final _emailService = AuthEmailService();
  bool _isSendingEmail = false;

  Future<void> _sendVerificationEmail() async {
    setState(() => _isSendingEmail = true);

    try {
      await _emailService.sendVerificationEmail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de verificación enviado. Revisa tu bandeja de entrada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingEmail = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isSendingEmail
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _sendVerificationEmail,
                child: const Text('Enviar email de verificación'),
              ),
      ),
    );
  }
}
```

**Recuperación de contraseña:**

```dart
// En tu ForgotPasswordPage
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _emailService = AuthEmailService();
  bool _isSendingEmail = false;

  Future<void> _sendResetEmail() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu email')),
      );
      return;
    }

    setState(() => _isSendingEmail = true);

    try {
      await _emailService.sendPasswordResetEmail(_emailController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email enviado. Revisa tu bandeja de entrada.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingEmail = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _isSendingEmail
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _sendResetEmail,
                    child: const Text('Enviar email de recuperación'),
                  ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧪 Testing

### 1. Test local con emulators

```bash
cd functions
npm run serve
```

### 2. Test en producción (con usuarios de prueba)

Crea un usuario de prueba en Firebase Auth y prueba desde tu app Flutter.

### 3. Revisa logs

```bash
# Logs en tiempo real
firebase functions:log --only sendVerificationEmail

# Logs específicos
firebase functions:log --only sendPasswordResetEmail --lines 50
```

### 4. Test de deliverability

Usa [Mail Tester](https://www.mail-tester.com/) para verificar:
- SPF/DKIM records
- Spam score
- HTML rendering en diferentes clientes

---

## 🔒 Seguridad

### 1. Validación de autenticación

✅ **Implementado en el código:**
- `sendVerificationEmail` requiere autenticación
- Verifica que el email pertenezca al usuario autenticado

### 2. Prevención de enumeración de usuarios

✅ **Implementado en el código:**
- `sendPasswordResetEmail` NO revela si un email existe
- Siempre devuelve mensaje genérico de éxito

### 3. Rate limiting

⚠️ **Pendiente de implementar:**

Firebase tiene rate limiting básico, pero considera agregar:

```typescript
// En sendVerificationEmail.ts
const recentSends = await admin.firestore()
  .collection('email_rate_limit')
  .doc(userId)
  .get();

if (recentSends.exists) {
  const lastSent = recentSends.data()?.lastSent?.toDate();
  const now = new Date();
  const minutesSinceLastSend = (now.getTime() - lastSent.getTime()) / 60000;

  if (minutesSinceLastSend < 5) {
    throw new HttpsError(
      'resource-exhausted',
      'Por favor, espera 5 minutos antes de solicitar otro email'
    );
  }
}

// Guardar timestamp
await admin.firestore()
  .collection('email_rate_limit')
  .doc(userId)
  .set({ lastSent: admin.firestore.FieldValue.serverTimestamp() });
```

### 4. Protección de API Keys

✅ **Implementado:**
- `.env` en `.gitignore`
- Usar Firebase Functions Config en producción
- Nunca hardcodear API keys

### 5. Validación de inputs

✅ **Implementado:**
- Validación de formato de email
- Sanitización de inputs
- Type checking con TypeScript

---

## 🐛 Troubleshooting

### Problema: "SENDGRID_API_KEY no está configurada"

**Solución:**
```bash
# En producción
firebase functions:config:set sendgrid.api_key="SG.tu-key"
firebase deploy --only functions

# En local
# Crea .env en functions/ con SENDGRID_API_KEY=...
```

### Problema: "Sender email not verified"

**Solución:**
1. Ve a SendGrid > Settings > Sender Authentication
2. Verifica tu email o dominio
3. Espera confirmación por email

### Problema: Emails van a spam

**Soluciones:**
1. Configura Domain Authentication (SPF/DKIM)
2. No uses URLs acortadas
3. Mantén balance texto/HTML
4. Evita palabras spam ("free", "click here")
5. Usa tu propio dominio (no @gmail.com)

### Problema: "FirebaseFunctionsException: internal"

**Solución:**
```bash
# Revisa logs
firebase functions:log --only sendVerificationEmail

# Común: SendGrid API Key inválida o email no verificado
```

### Problema: Link de verificación no funciona

**Solución:**
- Verifica que `FIREBASE_ACTION_DOMAIN` esté correcta
- Debe ser: `tu-proyecto.firebaseapp.com` o tu dominio custom
- Revisa Firebase Console > Authentication > Templates

### Problema: "Cannot read property 'email' of undefined"

**Solución:**
- Usuario no autenticado
- Token expirado
- Verifica que estés llamando con usuario logueado

---

## 📊 Monitoreo y Métricas

### 1. SendGrid Dashboard

Ve a [SendGrid Stats](https://app.sendgrid.com/statistics) para ver:
- Emails enviados/entregados
- Bounces y rechazos
- Opens y clicks (si está habilitado)

### 2. Firebase Console

Ve a Firebase Console > Functions para ver:
- Invocaciones
- Errores
- Tiempo de ejecución
- Costos

### 3. Alertas

Configura alertas en Firebase:
```bash
firebase functions:config:set monitoring.alert_email="admin@tuapp.com"
```

---

## 💰 Costos Estimados

### SendGrid
- **Gratis:** 100 emails/día (3,000/mes)
- **Essentials:** $19.95/mes → 40,000 emails
- **Pro:** $89.95/mes → 100,000 emails

### Firebase Cloud Functions
- **Gratis (Spark Plan):**
  - 2M invocaciones/mes
  - 400,000 GB-seg/mes
  - 200,000 CPU-seg/mes
- **Pagado (Blaze Plan):**
  - $0.40 por millón de invocaciones
  - $0.0000025 por GB-seg
  - $0.0000100 por GHz-seg

**Ejemplo:** 10,000 emails/mes ≈ $0 - $1 en Firebase + $0 - $19.95 en SendGrid

---

## 🚀 Próximos Pasos

### Mejoras recomendadas

1. **Templates dinámicos:**
   ```typescript
   // Agregar idiomas, nombres personalizados, etc.
   interface TemplateData {
     userName?: string;
     language: 'es' | 'en';
   }
   ```

2. **Logging en Firestore:**
   ```typescript
   await admin.firestore().collection('email_logs').add({
     to: email,
     type: 'verification',
     sentAt: admin.firestore.FieldValue.serverTimestamp(),
     success: true,
   });
   ```

3. **Retry logic:**
   ```typescript
   const MAX_RETRIES = 3;
   for (let i = 0; i < MAX_RETRIES; i++) {
     try {
       await sendEmail(...);
       break;
     } catch (error) {
       if (i === MAX_RETRIES - 1) throw error;
       await sleep(1000 * (i + 1));
     }
   }
   ```

4. **Tests unitarios:**
   ```typescript
   import * as functionsTest from 'firebase-functions-test';
   // Agregar tests en functions/src/__tests__/
   ```

---

## 📚 Referencias

- [SendGrid API Docs](https://docs.sendgrid.com/)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Firebase Auth Admin SDK](https://firebase.google.com/docs/auth/admin)
- [Email Deliverability Best Practices](https://sendgrid.com/blog/10-tips-to-improve-email-deliverability/)

---

## 🙋 Soporte

Si tienes problemas:
1. Revisa los logs: `firebase functions:log`
2. Verifica SendGrid Activity Feed
3. Consulta esta documentación
4. Abre un issue en el repo

---

**¡Listo!** Ahora tienes un sistema profesional de emails transaccionales. 🎉
