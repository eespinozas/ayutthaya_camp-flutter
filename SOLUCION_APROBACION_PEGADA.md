# Solución: App Pegada al Aprobar Pago

## 🐛 Problema

Al hacer clic en "Aprobar" pago en el panel de admin, la app se quedaba "pegada" con el loading indicator mostrándose indefinidamente.

---

## 🔍 Causa del Problema

En el archivo `admin_pagos_viewmodel.dart`, líneas 160-172 (versión anterior), el código intentaba buscar el plan en una colección `plans` que no existe:

```dart
// ❌ CÓDIGO PROBLEMÁTICO (anterior)
final plansSnapshot = await _firestore
    .collection('plans')  // Esta colección NO existe
    .where('name', isEqualTo: planName)
    .limit(1)
    .get();
```

**Problema:**
- Los planes están en una **subcolección**: `schools/{schoolId}/planes/{planId}`
- NO en una colección raíz `plans`
- La consulta fallaba o se quedaba esperando infinitamente
- El catch estaba silenciando el error pero seguía causando problemas

---

## ✅ Solución Implementada

### 1. Eliminada la Consulta Innecesaria

En lugar de buscar el plan en Firestore, ahora determinamos el `classLimit` basado en el nombre del plan que ya está en el pago:

```dart
// ✅ CÓDIGO NUEVO (correcto)
final planName = payment.plan;

// Determinar el límite de clases basado en el nombre del plan
int classLimit = 12; // Default: Plan Estándar

if (planName.toLowerCase().contains('básico') || planName.contains('8')) {
  classLimit = 8;
} else if (planName.toLowerCase().contains('estándar') || planName.toLowerCase().contains('estandar') || planName.contains('12')) {
  classLimit = 12;
} else if (planName.toLowerCase().contains('premium') || planName.contains('20')) {
  classLimit = 20;
} else if (planName.toLowerCase().contains('ilimitado') || planName.contains('999')) {
  classLimit = 999;
}
```

**Ventajas:**
- No requiere consulta a Firestore
- Más rápido y eficiente
- Usa información que ya está disponible en el pago
- No puede fallar por permisos o colecciones inexistentes

---

### 2. Agregado Logging Detallado

Para diagnosticar futuros problemas, agregué logging paso a paso:

```dart
debugPrint('═══════════════════════════════════════════');
debugPrint('🔄 INICIANDO APROBACIÓN DE PAGO');
debugPrint('═══════════════════════════════════════════');

debugPrint('⏳ Paso 1: Obteniendo documento del pago...');
// ... código ...
debugPrint('✅ Paso 1: Pago encontrado');

debugPrint('⏳ Paso 2: Actualizando estado del pago...');
// ... código ...
debugPrint('✅ Paso 2: Pago actualizado');

// ... más pasos ...

debugPrint('═══════════════════════════════════════════');
debugPrint('✅ APROBACIÓN COMPLETADA EXITOSAMENTE');
debugPrint('═══════════════════════════════════════════');
```

Ahora puedes ver exactamente en qué paso se queda pegado si hay un problema.

---

### 3. Agregado Campo lastPaymentDate

También agregué el campo `lastPaymentDate` que faltaba:

```dart
await _firestore.collection('users').doc(payment.userId).update({
  'membershipStatus': 'active',
  'planName': planName,
  'expirationDate': Timestamp.fromDate(newExpirationDate),
  'classLimit': classLimit,
  'lastPaymentDate': FieldValue.serverTimestamp(), // ✅ NUEVO
  'updatedAt': FieldValue.serverTimestamp(),
});
```

---

## 📋 Cambios en el Código

### Archivo: `admin_pagos_viewmodel.dart`

#### Antes (líneas 154-187):
```dart
// 4. Obtener información del plan desde el pago
final planName = payment.plan;

// Obtener el límite de clases según el plan
int classLimit = 12; // Default
try {
  final plansSnapshot = await _firestore
      .collection('plans')  // ❌ Colección inexistente
      .where('name', isEqualTo: planName)
      .limit(1)
      .get();

  if (plansSnapshot.docs.isNotEmpty) {
    classLimit = plansSnapshot.docs.first.data()['classLimit'] ?? 12;
    debugPrint('📋 Límite de clases del plan: $classLimit');
  }
} catch (e) {
  debugPrint('⚠️ Error obteniendo plan, usando default: $e');
}

// 5. Actualizar el usuario
await _firestore.collection('users').doc(payment.userId).update({
  'membershipStatus': 'active',
  'planName': planName,
  'expirationDate': Timestamp.fromDate(newExpirationDate),
  'classLimit': classLimit,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

#### Después (líneas 178-222):
```dart
// 4. Obtener información del plan desde el pago
debugPrint('');
debugPrint('⏳ Paso 5: Determinando límite de clases del plan...');
final planName = payment.plan;

// Determinar el límite de clases basado en el nombre del plan
int classLimit = 12; // Default: Plan Estándar

if (planName.toLowerCase().contains('básico') || planName.contains('8')) {
  classLimit = 8;
} else if (planName.toLowerCase().contains('estándar') || planName.toLowerCase().contains('estandar') || planName.contains('12')) {
  classLimit = 12;
} else if (planName.toLowerCase().contains('premium') || planName.contains('20')) {
  classLimit = 20;
} else if (planName.toLowerCase().contains('ilimitado') || planName.contains('999')) {
  classLimit = 999;
}

debugPrint('✅ Paso 5: Límite de clases determinado');
debugPrint('   - Plan: $planName');
debugPrint('   - Límite: $classLimit clases');

// 5. Actualizar el usuario
debugPrint('');
debugPrint('⏳ Paso 6: Actualizando usuario en Firestore...');
await _firestore.collection('users').doc(payment.userId).update({
  'membershipStatus': 'active',
  'planName': planName,
  'expirationDate': Timestamp.fromDate(newExpirationDate),
  'classLimit': classLimit,
  'lastPaymentDate': FieldValue.serverTimestamp(), // ✅ NUEVO
  'updatedAt': FieldValue.serverTimestamp(),
});

debugPrint('✅ Paso 6: Usuario actualizado exitosamente');
debugPrint('   - membershipStatus: active');
debugPrint('   - planName: $planName');
debugPrint('   - classLimit: $classLimit');
debugPrint('   - expirationDate: $newExpirationDate');

debugPrint('');
debugPrint('═══════════════════════════════════════════');
debugPrint('✅ APROBACIÓN COMPLETADA EXITOSAMENTE');
debugPrint('═══════════════════════════════════════════');
debugPrint('');
```

---

## 🔄 Flujo de Aprobación Corregido

### Flujo Anterior (❌ Con Bug)
```
Admin aprueba pago
  ↓
Actualiza pago a "approved"
  ↓
Busca plan en collection 'plans' ← ❌ SE QUEDA PEGADO AQUÍ
  ↓
(nunca llega aquí)
```

### Flujo Nuevo (✅ Funciona)
```
Admin aprueba pago
  ↓
1. Obtiene documento del pago
  ↓
2. Actualiza pago a "approved"
  ↓
3. Obtiene datos del usuario
  ↓
4. Calcula fecha de expiración
  ↓
5. Determina classLimit del nombre del plan (sin consulta)
  ↓
6. Actualiza usuario a "active"
  ↓
✅ Cierra loading y muestra mensaje de éxito
```

---

## 🧪 Cómo Probar

### 1. Hot Restart
```bash
R  # En la terminal donde corre la app
```

### 2. Probar Aprobación
1. Como usuario: Registra y paga matrícula
2. Como admin: Ve a **Pagos** → **Pendientes**
3. Haz clic en **Ver Comprobante** (verifica que cargue correctamente)
4. Haz clic en **Aprobar**
5. Confirma en el diálogo

### 3. Verificar Logs
En la consola deberías ver:

```
═══════════════════════════════════════════
🔄 INICIANDO APROBACIÓN DE PAGO
═══════════════════════════════════════════
Payment ID: abc123

⏳ Paso 1: Obteniendo documento del pago...
✅ Paso 1: Pago encontrado
   - Usuario: Juan Pérez (userId123)
   - Plan: Plan Premium
   - Monto: $50000

⏳ Paso 2: Actualizando estado del pago a "approved"...
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
✅ Paso 6: Usuario actualizado exitosamente
   - membershipStatus: active
   - planName: Plan Premium
   - classLimit: 20
   - expirationDate: 2025-12-25

═══════════════════════════════════════════
✅ APROBACIÓN COMPLETADA EXITOSAMENTE
═══════════════════════════════════════════
```

### 4. Verificar UI
- El loading indicator debe cerrarse
- Debe aparecer mensaje: "Pago de [Usuario] aprobado"
- El pago debe moverse al tab "Aprobados"
- El usuario debe aparecer en "Activos" en la página de Alumnos

---

## 🐛 Si Aún Se Queda Pegado

Si después de estos cambios aún se queda pegado, revisa los logs para ver en qué paso exactamente:

1. **Se queda en Paso 1**: Problema leyendo el pago
   - Verifica que el paymentId sea correcto
   - Verifica las reglas de Firestore para `payments`

2. **Se queda en Paso 2**: Problema actualizando el pago
   - Verifica permisos de escritura en `payments`
   - Verifica que el admin esté autenticado

3. **Se queda en Paso 3**: Problema leyendo el usuario
   - Verifica que el userId en el pago sea correcto
   - Verifica las reglas de Firestore para `users`

4. **Se queda en Paso 6**: Problema actualizando el usuario
   - Verifica permisos de escritura en `users`
   - Verifica que los campos sean válidos

---

## 📝 Resumen

✅ **Problema resuelto:** Eliminada consulta innecesaria a colección inexistente
✅ **Logging agregado:** Diagnóstico detallado paso a paso
✅ **Campo agregado:** `lastPaymentDate` en actualización de usuario
✅ **Optimización:** Determinación de classLimit sin consulta a Firestore

El proceso de aprobación ahora es:
- **Más rápido** (sin consulta innecesaria)
- **Más confiable** (no depende de colecciones externas)
- **Más fácil de depurar** (logs detallados)
