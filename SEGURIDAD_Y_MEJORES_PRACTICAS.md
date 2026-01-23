# Seguridad y Mejores Prácticas - Emails Transaccionales

Documento exhaustivo de seguridad, deliverability y mejores prácticas para el sistema de emails transaccionales.

---

## 🔒 Seguridad

### 1. Protección de API Keys

#### ❌ NUNCA HAGAS ESTO:
```typescript
// MAL - API Key hardcodeada
const apiKey = "SG.xxxxxxxxxxxxxx";
```

#### ✅ CORRECTO:
```typescript
// BIEN - Variable de entorno
const apiKey = process.env.SENDGRID_API_KEY;
```

**Checklist de seguridad para API Keys:**
- [ ] API Keys en variables de entorno
- [ ] Archivo `.env` en `.gitignore`
- [ ] Usar Firebase Functions Config en producción
- [ ] Rotar API Keys cada 3-6 meses
- [ ] Usar API Keys con permisos mínimos necesarios
- [ ] Monitorear uso de API Keys en SendGrid Dashboard

**Rotación de API Keys:**
```bash
# 1. Crea nueva API Key en SendGrid
# 2. Actualiza variables
firebase functions:config:set sendgrid.api_key="SG.nueva-key"
firebase deploy --only functions

# 3. Espera 24h para verificar
# 4. Elimina la API Key antigua en SendGrid
```

---

### 2. Validación y Sanitización

#### Validación de Email
```typescript
// ✅ CORRECTO - Validación robusta
function isValidEmail(email: string): boolean {
  // Formato básico
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) return false;

  // Longitud máxima (RFC 5321)
  if (email.length > 254) return false;

  // No permitir caracteres peligrosos
  const dangerousChars = /[<>'"()]/;
  if (dangerousChars.test(email)) return false;

  return true;
}
```

#### Sanitización de Inputs
```typescript
// ✅ CORRECTO - Sanitizar antes de usar
const email = request.data.email
  ?.trim()
  .toLowerCase()
  .substring(0, 254); // Limitar longitud

if (!email || !isValidEmail(email)) {
  throw new HttpsError('invalid-argument', 'Email inválido');
}
```

---

### 3. Prevención de Enumeración de Usuarios

#### ❌ PROBLEMA:
```typescript
// MAL - Revela si el usuario existe
const user = await admin.auth().getUserByEmail(email);
if (!user) {
  throw new Error('Usuario no encontrado'); // ❌ Ataque de enumeración
}
```

#### ✅ SOLUCIÓN:
```typescript
// BIEN - Siempre devolver mensaje genérico
try {
  await admin.auth().getUserByEmail(email);
  // Enviar email...
} catch (error) {
  if (error.code === 'auth/user-not-found') {
    // NO enviar email, pero devolver éxito de todos modos
    logger.info('Usuario no existe (no se revela)');
  }
}

// Siempre devolver el mismo mensaje
return {
  success: true,
  message: 'Si el email está registrado, recibirás un correo',
};
```

**¿Por qué es importante?**
- Previene que atacantes descubran qué emails están registrados
- Cumple con regulaciones de privacidad (GDPR, CCPA)
- Es una best practice de seguridad estándar

---

### 4. Rate Limiting

Implementación de límites de solicitudes para prevenir abuso:

```typescript
// functions/src/utils/rateLimiting.ts
import * as admin from 'firebase-admin';
import {HttpsError} from 'firebase-functions/v2/https';

interface RateLimitConfig {
  maxRequests: number;
  windowMinutes: number;
}

export async function checkRateLimit(
  userId: string,
  action: string,
  config: RateLimitConfig = {maxRequests: 3, windowMinutes: 60}
): Promise<void> {
  const now = Date.now();
  const windowStart = now - (config.windowMinutes * 60 * 1000);

  const docRef = admin.firestore()
    .collection('rate_limits')
    .doc(`${userId}_${action}`);

  const doc = await docRef.get();
  const data = doc.data();

  if (data) {
    // Filtrar requests dentro de la ventana de tiempo
    const recentRequests = (data.requests || [])
      .filter((timestamp: number) => timestamp > windowStart);

    if (recentRequests.length >= config.maxRequests) {
      const oldestRequest = Math.min(...recentRequests);
      const minutesUntilAllowed = Math.ceil(
        ((oldestRequest + (config.windowMinutes * 60 * 1000)) - now) / 60000
      );

      throw new HttpsError(
        'resource-exhausted',
        `Demasiadas solicitudes. Intenta en ${minutesUntilAllowed} minuto(s)`
      );
    }

    // Agregar nueva request
    recentRequests.push(now);
    await docRef.set({requests: recentRequests});
  } else {
    // Primera request
    await docRef.set({requests: [now]});
  }
}

// Usar en las Cloud Functions
export const sendVerificationEmail = onCall(async (request) => {
  await checkRateLimit(request.auth!.uid, 'email_verification', {
    maxRequests: 3,
    windowMinutes: 60,
  });

  // ... resto del código
});
```

**Configuración recomendada:**
- Email verification: 3 requests/hora
- Password reset: 5 requests/hora
- Limpiar datos antiguos con Cloud Scheduler

---

### 5. Autenticación y Autorización

#### Email Verification
```typescript
// ✅ CORRECTO - Verificar que el usuario sea el dueño
if (!request.auth) {
  throw new HttpsError('unauthenticated', 'Autenticación requerida');
}

const userRecord = await admin.auth().getUser(request.auth.uid);

if (userRecord.email !== request.data.email) {
  throw new HttpsError(
    'permission-denied',
    'No puedes verificar un email que no es tuyo'
  );
}
```

#### Password Reset
```typescript
// ✅ CORRECTO - Puede ser público, pero con rate limiting
// No requiere autenticación (el usuario olvidó su contraseña)
// Pero SIEMPRE aplicar rate limiting por IP/email

await checkRateLimitByEmail(request.data.email, 'password_reset');
```

---

### 6. Logging y Monitoreo

#### ✅ CORRECTO - Logging seguro
```typescript
// BIEN - No loggear información sensible
logger.info('Email de verificación enviado', {
  userId: request.auth!.uid,
  // ❌ NO loggear: email completo, tokens, links
});

// BIEN - Loggear errores sin exponer detalles al cliente
logger.error('Error enviando email', {
  userId: request.auth!.uid,
  errorCode: error.code, // OK
  // ❌ NO loggear: error.response (puede contener API keys)
});
```

#### ❌ EVITAR:
```typescript
// MAL - Exponer información sensible
logger.info('Email enviado', {
  email: user.email,        // ❌ PII
  verificationLink: link,   // ❌ Token sensible
  apiKey: config.apiKey,    // ❌ CRÍTICO - Nunca loggear
});
```

**Checklist de logging:**
- [ ] No loggear PII (emails, nombres, teléfonos)
- [ ] No loggear tokens o API keys
- [ ] No loggear contraseñas (obvio, pero pasa)
- [ ] Usar niveles apropiados (info, warn, error)
- [ ] Monitorear logs con alertas automáticas

---

## 📧 Deliverability (Entregabilidad)

### 1. Domain Authentication

**SPF, DKIM, DMARC - Los tres pilares de autenticación:**

#### SPF (Sender Policy Framework)
Especifica qué servidores pueden enviar emails por tu dominio.

```dns
# Registro TXT en tu DNS
v=spf1 include:sendgrid.net ~all
```

#### DKIM (DomainKeys Identified Mail)
Firma criptográfica que verifica que el email no fue alterado.

```bash
# SendGrid genera los registros CNAME automáticamente
# Settings > Sender Authentication > Authenticate Your Domain
```

#### DMARC (Domain-based Message Authentication)
Policy que indica qué hacer con emails que fallan SPF/DKIM.

```dns
# Registro TXT en tu DNS
_dmarc.tudominio.com TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@tudominio.com"
```

**Configuración en SendGrid:**
1. Ve a Settings > Sender Authentication
2. Click "Authenticate Your Domain"
3. Sigue el wizard
4. Agrega registros DNS proporcionados
5. Verifica (puede tardar 24-48h)

---

### 2. Sender Reputation

#### Factores que afectan tu reputación:

**✅ BUENAS PRÁCTICAS:**
- Enviar solo a usuarios que solicitaron el email
- Mantener bounce rate bajo (<5%)
- Mantener complaint rate bajo (<0.1%)
- Volumen consistente (no picos enormes)
- Engagement alto (opens, clicks)

**❌ EVITAR:**
- Comprar listas de emails
- Enviar sin consentimiento
- No manejar bounces
- Ignorar unsubscribes
- Enviar a traps de spam

#### Calentamiento de IP (IP Warmup)

Si usas IP dedicada:
```
Día 1-2:    100 emails/día
Día 3-5:    500 emails/día
Día 6-10:   1,000 emails/día
Día 11-15:  5,000 emails/día
Día 16-20:  10,000 emails/día
Día 21+:    Volumen completo
```

---

### 3. Contenido del Email

#### HTML Best Practices

**✅ BUENO:**
- Ratio texto/imagen: 60/40 o 70/30
- HTML inline CSS (soportado universalmente)
- Responsive design (mobile-first)
- Alt text en imágenes
- Plain text version (fallback)

**❌ EVITAR:**
- Solo imágenes (sin texto)
- JavaScript (no funciona en emails)
- Embedded videos (usar thumbnails con links)
- Formularios (no son seguros en email)
- CSS externos (no cargan)

#### Palabras que disparan spam filters

**❌ EVITAR:**
- "Free", "Gratis"
- "Click here", "Haz click aquí"
- TEXTO EN MAYÚSCULAS
- !!!!! Múltiples signos de exclamación
- "Urgente", "Actúa ahora"
- "Garantizado", "Sin riesgo"
- "$$$", símbolos de dinero

**✅ USAR:**
- Lenguaje profesional y claro
- Personalización (nombre del usuario)
- Calls-to-action específicos
- Información relevante

---

### 4. Technical Configuration

#### Disable Click/Open Tracking para emails de auth

```typescript
// ✅ CORRECTO - Configuración en emailService.ts
const msg = {
  // ...
  trackingSettings: {
    clickTracking: {
      enable: false, // ❌ No tracking en links de auth
      enableText: false,
    },
    openTracking: {
      enable: false, // ❌ No tracking por privacidad
    },
  },
};
```

**¿Por qué?**
- Los proxies de email (Apple Mail Privacy) pueden activar los links
- Mejor UX (links directos, no redirects)
- Cumplimiento de privacidad

#### Categories y Tags

```typescript
// ✅ CORRECTO - Usar categorías para análisis
const msg = {
  // ...
  categories: ['auth', 'transactional'], // Para filtrar en SendGrid
  customArgs: {
    user_id: userId,
    action: 'email_verification',
  },
};
```

---

## 🎯 Mejores Prácticas de Código

### 1. Manejo de Errores

```typescript
// ✅ CORRECTO - Manejo robusto de errores
try {
  await sendEmail(options);
  logger.info('Email enviado exitosamente');
} catch (error: any) {
  // Loggear error completo internamente
  logger.error('Error enviando email', {
    errorCode: error.code,
    errorMessage: error.message,
    // NO loggear: error.response (puede tener API keys)
  });

  // Devolver error genérico al cliente
  throw new HttpsError(
    'internal',
    'Error al enviar el email. Por favor, intenta nuevamente.'
  );
}
```

### 2. Retry Logic con Exponential Backoff

```typescript
async function sendEmailWithRetry(
  options: EmailOptions,
  maxRetries: number = 3
): Promise<boolean> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await sendEmail(options);
      return true;
    } catch (error: any) {
      // Solo reintentar en errores transitorios
      const retryableErrors = [
        'ECONNRESET',
        'ETIMEDOUT',
        'SERVICE_UNAVAILABLE',
      ];

      const isRetryable = retryableErrors.some(
        (code) => error.code?.includes(code)
      );

      if (!isRetryable || attempt === maxRetries) {
        throw error;
      }

      // Exponential backoff: 1s, 2s, 4s
      const delay = Math.pow(2, attempt - 1) * 1000;
      logger.warn(`Reintento ${attempt}/${maxRetries} en ${delay}ms`);
      await sleep(delay);
    }
  }

  throw new Error('Max retries exceeded');
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
```

### 3. Idempotencia

Prevenir envío duplicado de emails:

```typescript
// Generar ID único para cada operación
const operationId = `verify_${userId}_${Date.now()}`;

// Verificar si ya se procesó
const existingOp = await admin.firestore()
  .collection('email_operations')
  .doc(operationId)
  .get();

if (existingOp.exists) {
  logger.info('Operación ya procesada', {operationId});
  return {success: true, message: 'Email ya enviado'};
}

// Marcar como procesando
await admin.firestore()
  .collection('email_operations')
  .doc(operationId)
  .set({
    status: 'processing',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

try {
  await sendEmail(options);

  // Marcar como completado
  await admin.firestore()
    .collection('email_operations')
    .doc(operationId)
    .update({status: 'completed'});
} catch (error) {
  // Marcar como fallido
  await admin.firestore()
    .collection('email_operations')
    .doc(operationId)
    .update({status: 'failed', error: error.message});

  throw error;
}
```

---

## 🧪 Testing

### 1. Testing Local

```bash
# 1. Usar email de prueba
SENDGRID_FROM_EMAIL=test@example.com npm run serve

# 2. O usar Sink de SendGrid
# Settings > Inbound Parse > Add Host & URL
```

### 2. Testing en Staging

```typescript
// Detectar ambiente
const isProduction = process.env.NODE_ENV === 'production';

if (!isProduction) {
  // En staging, agregar prefijo al subject
  msg.subject = `[STAGING] ${msg.subject}`;

  // O enviar solo a email de prueba
  msg.to = process.env.TEST_EMAIL || msg.to;
}
```

### 3. Test de Deliverability

Herramientas para verificar:
- [Mail Tester](https://www.mail-tester.com/) - Spam score
- [MXToolbox](https://mxtoolbox.com/) - DNS records
- [SendGrid Email Testing](https://sendgrid.com/solutions/email-testing/)
- [Litmus](https://litmus.com/) - Rendering en diferentes clientes

---

## 📊 Monitoreo y Alertas

### 1. Métricas Clave

**SendGrid Dashboard:**
- Delivered Rate (>95%)
- Bounce Rate (<5%)
- Complaint Rate (<0.1%)
- Block Rate (<1%)

**Firebase Console:**
- Function invocations
- Function errors
- Execution time
- Memory usage

### 2. Alertas Automáticas

Configurar alertas para:
```typescript
// Cloud Function para verificar métricas diariamente
export const checkEmailHealth = onSchedule('0 9 * * *', async () => {
  const stats = await getEmailStats(); // Implementar con SendGrid API

  if (stats.bounceRate > 0.05) {
    await sendAlertToAdmin('Alto bounce rate detectado');
  }

  if (stats.complaintRate > 0.001) {
    await sendAlertToAdmin('Alto complaint rate detectado');
  }
});
```

---

## 🌍 Cumplimiento Legal

### 1. GDPR (Europa)

**Requisitos:**
- Consentimiento explícito para emails marketing
- Emails transaccionales permitidos sin consentimiento
- Derecho al olvido (eliminar datos)
- Portabilidad de datos

**Implementación:**
```typescript
// Loggear consentimiento
await admin.firestore().collection('user_consents').doc(userId).set({
  email: userEmail,
  consentedAt: admin.firestore.FieldValue.serverTimestamp(),
  consentType: 'transactional_emails',
  ipAddress: request.ip, // Opcional
});
```

### 2. CAN-SPAM (USA)

**Requisitos:**
- No usar "From" falso
- Subject line preciso
- Identificarte como remitente
- Incluir dirección física
- Opción de unsubscribe clara

**Implementación:**
✅ Ya incluido en los templates en el footer

### 3. CASL (Canadá)

Similar a CAN-SPAM pero más estricto:
- Consentimiento explícito
- Identificación clara del remitente
- Unsubscribe funcional

---

## 🚀 Optimización de Performance

### 1. Caching de Templates

```typescript
// Cache de templates compilados
const templateCache = new Map<string, string>();

function getTemplate(type: string, data: any): string {
  const cacheKey = `${type}_${JSON.stringify(data)}`;

  if (templateCache.has(cacheKey)) {
    return templateCache.get(cacheKey)!;
  }

  const html = generateTemplate(type, data);
  templateCache.set(cacheKey, html);
  return html;
}
```

### 2. Batch Processing

Si envías múltiples emails:
```typescript
// ✅ CORRECTO - Batch de hasta 1000
await sgMail.send([
  {to: 'user1@example.com', ...},
  {to: 'user2@example.com', ...},
  // ... hasta 1000
]);

// ❌ EVITAR - Loops de envíos individuales
for (const user of users) {
  await sgMail.send({to: user.email, ...}); // Lento
}
```

### 3. Timeouts Apropiados

```typescript
export const sendVerificationEmail = onCall({
  timeoutSeconds: 60, // 1 minuto (suficiente para SendGrid)
  memory: '256MB',    // Memoria mínima necesaria
}, async (request) => {
  // ...
});
```

---

## ✅ Checklist Final de Producción

Antes de lanzar a producción:

### Configuración
- [ ] Variables de entorno configuradas
- [ ] Domain authentication completada (SPF/DKIM/DMARC)
- [ ] Sender email verificado
- [ ] Logo y assets públicamente accesibles
- [ ] Firebase action domain configurado

### Seguridad
- [ ] API Keys no hardcodeadas
- [ ] `.env` en `.gitignore`
- [ ] Rate limiting implementado
- [ ] Validación de inputs robusta
- [ ] Logging sin información sensible

### Código
- [ ] TypeScript compilado sin errores
- [ ] Tests unitarios pasando
- [ ] Manejo de errores robusto
- [ ] Retry logic implementado

### Testing
- [ ] Emails de prueba enviados y recibidos
- [ ] Links de verificación funcionando
- [ ] Diseño responsive probado
- [ ] Spam score verificado (<5)

### Monitoreo
- [ ] Logs configurados
- [ ] Alertas configuradas
- [ ] Dashboards de métricas listos

### Legal
- [ ] Footer con dirección incluido
- [ ] Política de privacidad actualizada
- [ ] Términos de servicio actualizados

---

**¡Listo para producción!** 🚀

Este documento debe actualizarse regularmente con nuevos aprendizajes y mejoras.
