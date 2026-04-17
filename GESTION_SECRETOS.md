# Gestión de Secretos - Ayutthaya Camp

## 🔐 ¿Por qué usar variables de entorno?

**Problema:**
```dart
// ❌ MAL: Secretos hardcodeados en código
const vapidKey = 'BCbeUPbnsqfFQlAiVnpOSWW69CIjSHbGfvKbIg55HMKaDgDj7xorrntamqpfugKAB2Cc0TQdwPW_AEGSeCkeLJw';
const stripeKey = 'pk_live_51xxx';
```

**Riesgos:**
- ❌ Se sube a Git → público en GitHub
- ❌ Difícil cambiar (requiere redeploy)
- ❌ Mismo valor en dev, staging y producción
- ❌ Fácil de robar si alguien descompila la app

**Solución:**
```dart
// ✅ BIEN: Secretos en .env
final vapidKey = dotenv.env['VAPID_KEY'];
final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
```

---

## 📁 Estructura de Archivos

```
proyecto/
├── .env                    ← Valores REALES (NO se sube a Git)
├── .env.example           ← Plantilla (SÍ se sube a Git)
├── .gitignore             ← Asegura que .env NO se suba
└── lib/
    └── core/
        └── config/
            └── env_config.dart  ← Acceso centralizado a .env
```

---

## ⚙️ Configuración Actual

### 1. `.env` (valores reales)
```bash
# Este archivo NO se sube a Git (está en .gitignore)
VAPID_KEY=BCbeUPbnsqfFQlAiVnpOSWW69CIjSHbGfvKbIg55HMKaDgDj7xorrntamqpfugKAB2Cc0TQdwPW_AEGSeCkeLJw
API_BASE_URL=http://localhost:3000
```

### 2. `.env.example` (plantilla)
```bash
# Este archivo SÍ se sube a Git como referencia
VAPID_KEY=TU_VAPID_KEY_AQUI
API_BASE_URL=http://localhost:3000
```

### 3. `.gitignore`
```bash
# ✅ Asegura que .env NO se suba
.env
.env.local
.env.production
```

---

## 🚀 Cómo Usar

### En el código:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Leer variable
final vapidKey = dotenv.env['VAPID_KEY'];
final apiUrl = dotenv.env['API_BASE_URL'];

// Con valor por defecto (si no existe)
final timeout = dotenv.env['TIMEOUT'] ?? '30';
```

### En main.dart (ya está configurado):
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar .env
  await dotenv.load(fileName: ".env");

  runApp(const App());
}
```

---

## 🔄 Para Nuevos Desarrolladores

Cuando alguien clone el proyecto:

```bash
# 1. Clonar repo
git clone https://github.com/tu-usuario/ayutthaya_camp.git

# 2. Copiar plantilla
cp .env.example .env

# 3. Llenar valores reales en .env
# Obtener VAPID_KEY de Firebase Console
# Obtener otras keys según GESTION_SECRETOS.md

# 4. Instalar dependencias
flutter pub get

# 5. Correr app
flutter run
```

---

## 🌍 Diferentes Entornos

### Desarrollo Local
```bash
.env
```

### Staging
```bash
.env.staging
API_BASE_URL=https://staging-api.ayutthayacamp.cl
VAPID_KEY=TU_VAPID_KEY_STAGING
```

### Producción
```bash
.env.production
API_BASE_URL=https://api.ayutthayacamp.cl
VAPID_KEY=TU_VAPID_KEY_PRODUCCION
```

**Cargar según entorno:**
```dart
// main.dart
await dotenv.load(
  fileName: kReleaseMode ? '.env.production' : '.env'
);
```

---

## 🔒 Secretos por Plataforma

### Flutter (App Móvil/Web)
✅ **Usar:** `.env` + `flutter_dotenv`
```dart
final key = dotenv.env['VAPID_KEY'];
```

### Firebase Cloud Functions (Backend)
✅ **Usar:** Firebase Environment Config
```bash
# Configurar secreto
firebase functions:secrets:set RESEND_API_KEY

# Acceder en código
const resendKey = process.env.RESEND_API_KEY;
```

**Ya configurado en `functions/index.js`:**
```javascript
const RESEND_API_KEY = process.env.RESEND_API_KEY || "";
```

---

## 📋 Checklist de Secretos

### Secretos Actuales
- [x] VAPID_KEY (web push) → ✅ En .env
- [x] RESEND_API_KEY (emails) → ✅ En Firebase Functions secrets
- [ ] STRIPE_PUBLISHABLE_KEY (pagos) → Pendiente (futuro)
- [ ] STRIPE_SECRET_KEY (pagos backend) → Pendiente (futuro)

### Firebase Secrets (NO en código)
- [x] google-services.json (Android) → ✅ En .gitignore
- [x] GoogleService-Info.plist (iOS) → ✅ En .gitignore
- [x] serviceAccountKey.json → ✅ En .gitignore

### CI/CD Secrets
- [ ] ANDROID_KEYSTORE_PASSWORD
- [ ] IOS_CERTIFICATE_PASSWORD
- [ ] FIREBASE_TOKEN

---

## ⚠️ Qué NUNCA Hacer

❌ **NUNCA hardcodear secretos:**
```dart
const apiKey = 'sk_live_51xxx'; // ❌ MAL
```

❌ **NUNCA subir .env a Git:**
```bash
git add .env  # ❌ MAL
```

❌ **NUNCA compartir secretos por Slack/Email:**
```
"Hola, la API key es: sk_live_51xxx" # ❌ MAL
```

✅ **SÍ usar gestor de contraseñas:**
- 1Password (para equipos)
- LastPass
- Bitwarden
- Firebase Secrets Manager

---

## 🆘 Si un Secreto se Filtró

### 1. Revocarlo INMEDIATAMENTE
```bash
# Firebase Console > Regenerar VAPID key
# Stripe > Revocar API key
# Resend > Eliminar API key
```

### 2. Generar nuevo secreto
```bash
# Crear nueva key en el servicio
# Actualizar .env local
# Actualizar en producción
```

### 3. Verificar el daño
```bash
# Revisar logs de uso
# Firebase Console > Usage
# Stripe Dashboard > Events
```

### 4. Notificar al equipo
```
"⚠️ VAPID key comprometida. Nueva key: [compartir de forma segura]"
```

---

## 📞 Recursos

- **flutter_dotenv docs**: https://pub.dev/packages/flutter_dotenv
- **Firebase Secrets**: https://firebase.google.com/docs/functions/config-env
- **12-factor app**: https://12factor.net/config

---

**Última actualización**: 2026-04-14
**Mantenido por**: Equipo Dev Ayutthaya Camp
