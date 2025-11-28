# Fix: Error de Navigator en Loop Infinito

## 🐛 Problema Original

Al aprobar o rechazar un pago, se producía un error en loop infinito:
```
org-dartlang-sdk:///lib/_engine/engine/window.dart:99:12
Another exception was thrown: Assertion failed:
```

Este error ocurre cuando:
- Se intenta hacer `Navigator.pop()` en un stack vacío
- El context usado para Navigator se vuelve inválido
- Hay múltiples intentos de cerrar el mismo dialog

## ❌ Código Problemático (Anterior)

```dart
ElevatedButton(
  onPressed: () async {
    final scaffoldContext = context;  // Context del AlertDialog

    Navigator.pop(context);  // Cerrar dialog de confirmación

    showDialog(  // Mostrar loading dialog
      context: scaffoldContext,  // ❌ Este context puede ser inválido
      builder: (context) => CircularProgressIndicator(),
    );

    await _viewModel.approvePayment(...);

    Navigator.of(scaffoldContext).pop();  // ❌ Puede fallar si context es inválido
  },
)
```

**Problemas:**
1. El `scaffoldContext` se captura dentro del AlertDialog
2. Después de cerrar el dialog con `Navigator.pop(context)`, el context puede invalidarse
3. El loading dialog se abre con un context potencialmente inválido
4. Intentar cerrar el loading causa assertion errors
5. Si falla, el error se repite en loop infinito

## ✅ Solución Implementada

### 1. Agregado Estado de Loading

```dart
class _AdminPagosPageState extends State<AdminPagosPage> {
  bool _isProcessingPayment = false;  // ✅ Estado de loading
  // ...
}
```

### 2. Eliminados Dialogs de Loading

En lugar de usar `showDialog()` para el loading, ahora usamos un **overlay con Stack**:

```dart
return Stack(
  children: [
    Scaffold(
      // ... contenido normal
    ),
    // Overlay de loading
    if (_isProcessingPayment)
      Container(
        color: Colors.black.withOpacity(0.7),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Colors.orangeAccent),
              SizedBox(height: 16),
              Text('Procesando...'),
            ],
          ),
        ),
      ),
  ],
);
```

### 3. Actualizado Método de Aprobación

```dart
ElevatedButton(
  onPressed: _isProcessingPayment ? null : () async {
    // 1. Cerrar dialog de confirmación
    Navigator.pop(context);

    // 2. Activar loading con setState
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      await _viewModel.approvePayment(payment.id!);

      if (!mounted) return;

      // 3. Desactivar loading
      setState(() {
        _isProcessingPayment = false;
      });

      // 4. Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pago aprobado')),
      );
    } catch (e) {
      if (!mounted) return;

      // 5. Desactivar loading en caso de error
      setState(() {
        _isProcessingPayment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
)
```

### 4. Mismo Fix para Rechazo

El método `_rejectPayment` usa el mismo enfoque.

## 🎯 Ventajas de la Nueva Solución

| Aspecto | Antes (Dialog) | Ahora (Overlay) |
|---------|----------------|-----------------|
| **Navigator Stack** | Múltiples pops requeridos | Un solo pop (dialog de confirmación) |
| **Context** | Se invalida después de pop | Siempre válido (del State) |
| **Errors** | Assertion errors en loop | No hay errors de Navigator |
| **UX** | Puede bloquearse | Siempre funciona correctamente |
| **Código** | Complejo con context guardado | Simple con setState |

## 🔧 Cómo Funciona

### Flujo Anterior (❌ Con Bugs)
```
1. Usuario click "Aprobar"
2. Se abre AlertDialog de confirmación
3. Usuario confirma
4. Se captura scaffoldContext = context (del AlertDialog)
5. Se cierra AlertDialog con Navigator.pop(context)
6. Se intenta abrir loading dialog con scaffoldContext ← ⚠️ Context puede ser inválido
7. Se ejecuta approvePayment()
8. Se intenta cerrar loading con Navigator.of(scaffoldContext).pop() ← ❌ Falla
9. Error de assertion en loop infinito
```

### Flujo Nuevo (✅ Funciona)
```
1. Usuario click "Aprobar"
2. Se abre AlertDialog de confirmación
3. Usuario confirma
4. Se cierra AlertDialog con Navigator.pop(context)
5. Se activa _isProcessingPayment = true
6. UI se reconstruye mostrando overlay de loading
7. Se ejecuta approvePayment()
8. Se desactiva _isProcessingPayment = false
9. UI se reconstruye sin overlay
10. ✅ Muestra mensaje de éxito
```

## 🧪 Cómo Probar

### 1. Hot Restart

En la terminal donde corre la app:
```
R  (mayúscula)
```

O detén y reinicia:
```
flutter run
```

### 2. Probar Aprobación

1. Como admin: **Pagos** → **Pendientes**
2. Haz clic en **Aprobar**
3. Confirma en el diálogo

**Resultado esperado:**
- ✅ Se cierra el dialog de confirmación
- ✅ Aparece overlay oscuro con "Procesando..."
- ✅ El overlay desaparece después de 1-2 segundos
- ✅ Aparece mensaje "Pago de [Usuario] aprobado"
- ✅ El pago se mueve a "Aprobados"
- ✅ **NO hay errores de Navigator**
- ✅ **NO se queda pegado**

### 3. Probar Rechazo

1. Como admin: **Pagos** → **Pendientes**
2. Haz clic en el ícono ❌ (rechazar)
3. Escribe un motivo
4. Confirma

**Resultado esperado:**
- ✅ Se cierra el dialog de rechazo
- ✅ Aparece overlay de loading
- ✅ El overlay desaparece rápidamente
- ✅ Aparece mensaje "Pago de [Usuario] rechazado"
- ✅ El pago se mueve a "Rechazados"

## 📝 Cambios en el Código

### Archivo: `admin_pagos_page.dart`

#### Línea 19: Estado agregado
```dart
bool _isProcessingPayment = false;
```

#### Líneas 323-375: Método _approvePayment actualizado
- Eliminado uso de `scaffoldContext`
- Eliminado `showDialog()` para loading
- Agregado `setState()` para controlar `_isProcessingPayment`
- Simplificado manejo de Navigator

#### Líneas 435-497: Método _rejectPayment actualizado
- Mismo enfoque que approve

#### Líneas 538-640: Widget build() actualizado
- Envuelto Scaffold en Stack
- Agregado overlay condicional `if (_isProcessingPayment)`

## ✅ Resultado Final

Con esta solución:
- ✅ **NO más errors de Navigator**
- ✅ **NO más loops infinitos**
- ✅ **NO más pantalla bloqueada**
- ✅ Loading funciona correctamente
- ✅ Código más simple y mantenible
- ✅ Mejor UX con overlay semitransparente

## 🔑 Lección Aprendida

**Evita usar Dialogs para Loading en operaciones async complejas.**

En su lugar:
- Usa estado booleano (`isLoading`)
- Muestra overlay con Stack
- Usa setState() para controlar la visibilidad

Esto evita completamente los problemas con Navigator y context invalidation.
