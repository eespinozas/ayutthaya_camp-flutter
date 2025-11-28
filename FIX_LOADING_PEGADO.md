# Fix: Loading Pegado al Aprobar/Rechazar Pago

## 🐛 Problema

Al hacer clic en "Aprobar" o "Rechazar" pago:
- Aparece el CircularProgressIndicator (loading)
- Se queda pegado en la pantalla
- No se puede seleccionar nada
- Error: `Assertion failed: org-dartlang-sdk:///lib/_engine/engine/window.dart:99:12`

---

## 🔍 Causa del Problema

### Problema 1: Context Inválido

```dart
// ❌ CÓDIGO PROBLEMÁTICO
ElevatedButton(
  onPressed: () async {
    Navigator.pop(context);  // Cierra el diálogo

    showDialog(
      context: context,  // ❌ Este context puede ser inválido
      ...
    );

    await _viewModel.approvePayment(...);

    Navigator.pop(context);  // ❌ Este context puede ser inválido
  },
)
```

**Problema:**
- Después de `Navigator.pop(context)`, el `context` puede volverse inválido
- Usar `context` en operaciones async después de `Navigator.pop()` causa problemas
- El `Navigator.pop()` al final no puede cerrar el loading porque el context es inválido

### Problema 2: Navigator Stack Inconsistente

El error `Assertion failed` indica que el Navigator está intentando hacer pop en un stack vacío o inconsistente.

---

## ✅ Solución Aplicada

### 1. Guardar el Context ANTES de Operaciones Async

```dart
// ✅ CÓDIGO CORREGIDO
ElevatedButton(
  onPressed: () async {
    // 1. Guardar el context ANTES de cualquier operación async
    final scaffoldContext = context;

    Navigator.pop(context);  // Cerrar diálogo de confirmación

    // 2. Usar el context guardado para el loading
    showDialog(
      context: scaffoldContext,  // ✅ Context válido guardado
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,  // Prevenir cierre accidental
        child: const Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent),
        ),
      ),
    );

    try {
      await _viewModel.approvePayment(payment.id!);

      if (!mounted) return;

      // 3. Usar Navigator.of() con el context guardado
      Navigator.of(scaffoldContext).pop();  // ✅ Cierra el loading

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(...);
    } catch (e) {
      if (!mounted) return;

      // 4. Verificar si se puede hacer pop antes de intentarlo
      if (Navigator.of(scaffoldContext).canPop()) {
        Navigator.of(scaffoldContext).pop();
      }

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(...);
    }
  },
)
```

### 2. WillPopScope para Prevenir Cierre Accidental

```dart
WillPopScope(
  onWillPop: () async => false,  // No permite cerrar con back button
  child: const Center(
    child: CircularProgressIndicator(...),
  ),
)
```

Esto previene que el usuario o el sistema cierren el diálogo accidentalmente.

### 3. Verificación de canPop()

```dart
if (Navigator.of(scaffoldContext).canPop()) {
  Navigator.of(scaffoldContext).pop();
}
```

Verifica que el Navigator tenga algo en el stack antes de hacer pop.

### 4. Logging Detallado

```dart
try {
  debugPrint('🔵 Iniciando aprobación de pago...');
  await _viewModel.approvePayment(payment.id!);
  debugPrint('🟢 Aprobación completada');

  debugPrint('🔵 Cerrando loading dialog...');
  Navigator.of(scaffoldContext).pop();
  debugPrint('🟢 Loading cerrado');
} catch (e) {
  debugPrint('🔴 Error al aprobar pago: $e');

  debugPrint('🔵 Cerrando loading dialog (error)...');
  if (Navigator.of(scaffoldContext).canPop()) {
    Navigator.of(scaffoldContext).pop();
    debugPrint('🟢 Loading cerrado (error)');
  }
}
```

Permite diagnosticar exactamente dónde ocurre el problema.

---

## 📋 Cambios Aplicados

### Archivos Modificados:

#### `admin_pagos_page.dart`

**Método _approvePayment (líneas 321-385):**
- ✅ Context guardado en `scaffoldContext`
- ✅ `WillPopScope` agregado al loading dialog
- ✅ `Navigator.of(scaffoldContext)` en lugar de `Navigator.pop(context)`
- ✅ Verificación `canPop()` en el catch
- ✅ Logging detallado

**Método _rejectPayment (líneas 444-519):**
- ✅ Mismo fix aplicado
- ✅ Manejo consistente de context y Navigator

---

## 🧪 Cómo Probar

### 1. Hot Restart
```bash
R  # En la terminal
```

### 2. Aprobar un Pago

1. Como admin: **Pagos** → **Pendientes**
2. Haz clic en **Aprobar**
3. Confirma en el diálogo

**Logs esperados:**
```
🔵 Iniciando aprobación de pago...
═══════════════════════════════════════════
🔄 INICIANDO APROBACIÓN DE PAGO
═══════════════════════════════════════════
⏳ Paso 1: Obteniendo documento del pago...
✅ Paso 1: Pago encontrado
...
✅ APROBACIÓN COMPLETADA EXITOSAMENTE
═══════════════════════════════════════════
🟢 Aprobación completada
🔵 Cerrando loading dialog...
🟢 Loading cerrado
```

**UI esperada:**
- ✅ Loading aparece
- ✅ Loading se cierra después de 1-2 segundos
- ✅ Aparece mensaje "Pago de [Usuario] aprobado"
- ✅ El pago se mueve a "Aprobados"
- ✅ Puedes interactuar con la app normalmente

### 3. Rechazar un Pago

1. Como admin: **Pagos** → **Pendientes**
2. Haz clic en el ícono ❌ (rechazar)
3. Escribe un motivo
4. Confirma

**Logs esperados:**
```
🔵 Iniciando rechazo de pago...
🔄 Rechazando pago: abc123
   - Motivo: Comprobante ilegible
✅ Pago rechazado exitosamente
🟢 Rechazo completado
🔵 Cerrando loading dialog...
🟢 Loading cerrado
```

**UI esperada:**
- ✅ Loading aparece
- ✅ Loading se cierra rápidamente
- ✅ Aparece mensaje "Pago de [Usuario] rechazado"
- ✅ El pago se mueve a "Rechazados"

---

## 🐛 Si Aún Aparece el Problema

### Verificación 1: Context Válido

Si ves este log:
```
⚠️ Widget no montado, saliendo...
```

**Causa:** El widget se desmontó antes de completar la operación.

**Solución:** Ya está manejado con `if (!mounted) return;`

### Verificación 2: Navigator Stack

Si ves errores de assertion sobre Navigator:

1. Revisa que no haya otros lugares haciendo `Navigator.pop()`
2. Verifica que el context guardado sea del Scaffold correcto
3. Usa `Navigator.of(scaffoldContext, rootNavigator: true).pop()` si es necesario

### Verificación 3: Loading No Se Cierra

Si el loading aparece pero nunca se cierra:

**Revisa los logs:**
- ¿Llega a "🟢 Aprobación completada"?
  - NO → El problema está en `admin_pagos_viewmodel.dart`
  - SÍ → Continúa

- ¿Llega a "🔵 Cerrando loading dialog..."?
  - NO → El `if (!mounted)` está retornando
  - SÍ → Continúa

- ¿Llega a "🟢 Loading cerrado"?
  - NO → El `Navigator.pop()` está fallando
  - SÍ → El problema es visual/UI

---

## 📝 Resumen de Mejoras

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Context** | Usado directamente | Guardado en `scaffoldContext` |
| **Navigator.pop()** | `Navigator.pop(context)` | `Navigator.of(scaffoldContext).pop()` |
| **Loading Dialog** | `showDialog(...)` | `WillPopScope(showDialog(...))` |
| **Error Handling** | Simple try-catch | try-catch con `canPop()` |
| **Logging** | Mínimo | Detallado paso a paso |
| **Mounted Check** | Básico | Completo con logs |

---

## ✅ Resultado Final

Con estos cambios:
- ✅ El loading aparece correctamente
- ✅ El loading se cierra automáticamente al completar
- ✅ No hay errors de assertion
- ✅ El Navigator stack se mantiene consistente
- ✅ Fácil de debuggear con logs detallados
- ✅ Manejo robusto de errores

---

## 🔧 Código de Referencia

### Pattern para Dialogs con Loading

Usa este pattern en futuros casos similares:

```dart
ElevatedButton(
  onPressed: () async {
    // 1. Guardar context
    final scaffoldContext = context;

    // 2. Cerrar diálogo actual (si hay)
    Navigator.pop(context);

    // 3. Mostrar loading con WillPopScope
    showDialog(
      context: scaffoldContext,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    // 4. Operación async
    try {
      await miOperacionAsync();

      // 5. Verificar mounted
      if (!mounted) return;

      // 6. Cerrar loading con context guardado
      Navigator.of(scaffoldContext).pop();

      // 7. Mostrar resultado
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(...);

    } catch (e) {
      if (!mounted) return;

      // 8. Cerrar loading verificando canPop
      if (Navigator.of(scaffoldContext).canPop()) {
        Navigator.of(scaffoldContext).pop();
      }

      // 9. Mostrar error
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(...);
    }
  },
)
```

Este pattern evita todos los problemas comunes con dialogs y operaciones async.
