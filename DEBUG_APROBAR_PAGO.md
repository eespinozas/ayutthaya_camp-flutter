# Debug: Problema al Aprobar Pago

## Cambios Realizados

He mejorado el logging y manejo de errores para diagnosticar por qué el loading se queda pegado al aprobar un pago:

### 1. ConfigService (`lib/core/services/config_service.dart`)
- Agregado timeout de 10 segundos al cargar configuración
- Mejor logging de errores con stacktrace
- Advierte si faltan documentos de configuración

### 2. AdminPagosViewModel (`lib/features/admin/presentation/viewmodels/admin_pagos_viewmodel.dart`)
- Agregado timeout de 10 segundos a operaciones de Firestore
- Logging más detallado en cada paso
- Mensajes claros de timeout si una operación se queda pegada

## Cómo Probar

### 1. Hot Restart

En la terminal donde corre la app, presiona:
```
R  (mayúscula)
```

O detén y vuelve a iniciar:
```
flutter run
```

### 2. Ver los Logs

**Windows:**
```powershell
flutter logs -d windows
```

**Chrome:**
```powershell
flutter logs -d chrome
```

### 3. Aprobar un Pago

1. Como admin: Ve a **Pagos** → **Pendientes**
2. Haz clic en **Aprobar**
3. Confirma en el diálogo

### 4. Observar los Logs

Deberías ver logs como estos:

```
🔵 Iniciando aprobación de pago...
═══════════════════════════════════════════
🔄 INICIANDO APROBACIÓN DE PAGO
═══════════════════════════════════════════
Payment ID: abc123

⏳ Paso 1: Obteniendo documento del pago...
✅ Paso 1: Pago encontrado
   - Usuario: Juan Pérez (userId123)
   - Plan: Plan Premium
   - Monto: $50000
   - Admin ID: admin123

⏳ Paso 2: Actualizando estado del pago a "approved"...
   Ejecutando: payments.doc(abc123).update()...
✅ Paso 2: Pago actualizado a "approved"

⏳ Paso 3: Obteniendo datos del usuario...
✅ Paso 3: Usuario encontrado
   - Status actual: pending
   - Plan actual: null

⏳ Paso 4: Calculando fecha de expiración...
   - Nueva membresía desde hoy
✅ Paso 4: Nueva fecha de expiración: 2025-12-25

⏳ Paso 5: Determinando límite de clases del plan...
✅ Paso 5: Límite de clases determinado
   - Plan: Plan Premium
   - Límite: 20 clases

⏳ Paso 6: Actualizando usuario en Firestore...
   Ejecutando: users.doc(userId123).update()...
✅ Paso 6: Usuario actualizado exitosamente
   - membershipStatus: active
   - planName: Plan Premium
   - classLimit: 20
   - expirationDate: 2025-12-25

═══════════════════════════════════════════
✅ APROBACIÓN COMPLETADA EXITOSAMENTE
═══════════════════════════════════════════

🟢 Aprobación completada
🔵 Cerrando loading dialog...
🟢 Loading cerrado
```

## Posibles Problemas y Soluciones

### Problema 1: Se queda en "Paso 2" o "Paso 6"

**Síntomas:**
```
⏳ Paso 2: Actualizando estado del pago a "approved"...
   Ejecutando: payments.doc(abc123).update()...
⚠️ TIMEOUT al actualizar pago
```

**Causa:** Permisos de Firestore incorrectos

**Solución:**
1. Verifica las reglas en Firebase Console → Firestore → Reglas
2. Las reglas deben permitir que admins actualicen `payments` y `users`
3. Si es necesario, vuelve a desplegar las reglas:
```bash
firebase deploy --only firestore:rules
```

### Problema 2: Error de conexión

**Síntomas:**
```
🔴 Error al aprobar pago: [firebase_firestore/unavailable] The service is currently unavailable
```

**Solución:**
- Verifica tu conexión a internet
- Verifica el estado de Firebase: https://status.firebase.google.com/

### Problema 3: ConfigService no puede cargar

**Síntomas:**
```
⚠️ Timeout al cargar configuración, usando valores por defecto
⚠️ Algunos documentos de configuración no existen
   Ejecuta: python scripts/seed_config.py
```

**Solución:**
```bash
python scripts/seed_config.py
```

Esto no debería bloquear la aprobación de pagos, pero es mejor tener la configuración correcta.

### Problema 4: El loading sigue sin cerrarse

**Síntomas:**
- Los logs muestran "✅ APROBACIÓN COMPLETADA EXITOSAMENTE"
- Pero el loading no se cierra

**Causa:** Problema con el context o Navigator

**Solución temporal:**
1. Cierra la app completamente
2. Vuelve a abrirla
3. Intenta de nuevo

Si el problema persiste, el issue está en el manejo del Navigator en `admin_pagos_page.dart`

## Información de Diagnóstico

### Verificar Reglas de Firestore

```bash
firebase firestore:rules
```

### Ver Logs en Tiempo Real

**Windows:**
```bash
flutter logs -d windows --clear
```

**Chrome (con DevTools abierto):**
```bash
flutter logs -d chrome --clear
```

### Ver Estado de la App

En la consola de Flutter, después del hot restart, busca:
```
🔧 Cargando configuración de Firebase...
✅ Configuración cargada:
   - App settings: true
   - Payment settings: true
   - Feature flags: true
   - Business info: true
```

Si ves `false` en alguno, ejecuta `python scripts/seed_config.py`

## Reporte de Bugs

Si el problema persiste después de estos pasos, proporciona:

1. **Los logs completos** desde "🔵 Iniciando aprobación de pago..." hasta el final
2. **El paso donde se queda pegado** (ej: "Paso 2", "Paso 6")
3. **Plataforma** (Windows, Chrome, etc.)
4. **Si aparece algún timeout o error**

Con esta información podré identificar exactamente dónde está el problema.
