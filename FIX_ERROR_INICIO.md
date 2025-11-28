# Fix: Error de Navigator al Iniciar la App

## 🐛 Problema

Cuando la app inicia, aparece el error en loop infinito:
```
Another exception was thrown: Assertion failed:
org-dartlang-sdk:///lib/_engine/engine/window.dart:99:12
```

Este error aparece **antes incluso de navegar** a cualquier página, apenas inicia la app.

## ✅ Solución Implementada

He agregado protecciones en múltiples lugares para evitar que cualquier error cause este loop:

### 1. `main.dart` - Carga Segura de Configuración

```dart
// Cargar configuración de Firebase (no bloquear si falla)
try {
  final configService = ConfigService();
  await configService.loadConfig();

  if (configService.isMaintenanceMode) {
    runApp(const MaintenanceApp());
    return;
  }
} catch (e) {
  debugPrint('⚠️ Error cargando configuración al inicio: $e');
  debugPrint('   La app continuará con valores por defecto');
}
```

**Antes:** Si ConfigService fallaba, la app podía quedar en estado inválido
**Ahora:** Si falla, se logea el error y la app continúa con valores por defecto

### 2. `main.dart` - MaintenanceApp Protegido

```dart
String supportEmail = 'soporte@ayutthayacamp.com';
try {
  supportEmail = ConfigService().supportEmail;
} catch (e) {
  debugPrint('⚠️ No se pudo obtener supportEmail de ConfigService: $e');
}
```

**Antes:** Acceso directo a ConfigService que podía fallar
**Ahora:** Try-catch con valor por defecto

### 3. `admin_pagos_viewmodel.dart` - Streams Protegidos

Todos los métodos de streams ahora tienen try-catch:

```dart
Stream<List<Payment>> getPendingPayments() {
  try {
    return _firestore
        .collection('payments')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => ...)
  } catch (e) {
    debugPrint('❌ Error crítico en getPendingPayments: $e');
    return Stream.value([]);  // Devuelve stream vacío en lugar de fallar
  }
}
```

**Antes:** Si el stream fallaba al iniciar, podía causar errores en cascada
**Ahora:** Devuelve stream vacío y logea el error

### 4. `admin_pagos_page.dart` - StreamBuilder Protegido

```dart
Widget _buildPaymentListStream(Stream<List<Payment>> stream, String status) {
  return StreamBuilder<List<Payment>>(
    stream: stream,
    builder: (context, snapshot) {
      // Protección contra widget desmontado
      if (!mounted) {
        return const SizedBox.shrink();
      }

      // ... resto del código
    },
  );
}
```

**Antes:** No verificaba si el widget estaba montado
**Ahora:** Retorna widget vacío si está desmontado

## 🔧 Pasos para Resolver

### Paso 1: Detener la App Completamente

**NO uses Hot Restart (R)**, debes hacer un **full stop + restart**.

**Opción A: Desde VS Code / Android Studio**
1. Click en el botón rojo de "Stop" ⏹️
2. Espera a que termine completamente
3. Presiona F5 o click en "Run"

**Opción B: Desde Terminal**
1. Presiona `q` en la terminal donde corre la app
2. Espera a que cierre
3. Ejecuta de nuevo:
```bash
flutter run
```

**Opción C: Si nada funciona (método drástico)**
```bash
# Detener Flutter
flutter clean

# Obtener dependencias de nuevo
flutter pub get

# Ejecutar
flutter run
```

### Paso 2: Ver los Logs desde el Inicio

En una terminal separada, ejecuta:

**Windows:**
```bash
flutter logs -d windows --clear
```

**Chrome:**
```bash
flutter logs -d chrome --clear
```

Busca cualquiera de estos mensajes:

```
⚠️ Error cargando configuración al inicio: ...
❌ Error crítico en getPendingPayments: ...
❌ Error crítico en getApprovedPayments: ...
❌ Error crítico en getRejectedPayments: ...
```

### Paso 3: Verificar Configuración de Firebase

El problema puede ser que los documentos de configuración no existen en Firestore.

Ejecuta:
```bash
python scripts/seed_config.py
```

Deberías ver:
```
Creando configuracion inicial en Firestore...
[1/4] Creando app_settings...
   OK app_settings creado
...
OK Configuracion creada exitosamente
```

### Paso 4: Verificar Índices de Firestore

Si ves este error:
```
🔴 ¡FALTA ÍNDICE DE FIRESTORE!
```

Ejecuta:
```bash
firebase deploy --only firestore:indexes
```

## 🐛 Diagnóstico por Logs

### Si ves: "Error cargando configuración al inicio"

**Problema:** ConfigService no puede conectar con Firestore

**Solución:**
1. Verifica tu conexión a internet
2. Verifica que Firebase esté configurado correctamente
3. Ejecuta `python scripts/seed_config.py`

### Si ves: "Error crítico en getPendingPayments"

**Problema:** Faltan índices de Firestore o problema de permisos

**Solución:**
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### Si ves: "Assertion failed" en loop

**Problema:** Estado corrupto de la app que hot restart no limpia

**Solución:**
1. Detén la app completamente (`q`)
2. Ejecuta `flutter clean`
3. Ejecuta `flutter pub get`
4. Ejecuta `flutter run`

## ⚠️ Causas Comunes

1. **Hot Restart en lugar de Full Restart**
   - Hot restart (R) mantiene el estado
   - Si el estado está corrupto, el error persiste
   - Solución: Full stop + restart

2. **Documentos de config faltantes en Firestore**
   - ConfigService intenta cargar documentos que no existen
   - Causa timeout y puede dejar la app en estado inválido
   - Solución: `python scripts/seed_config.py`

3. **Índices de Firestore faltantes**
   - Los streams de pagos requieren índices
   - Sin índices, las queries fallan
   - Solución: `firebase deploy --only firestore:indexes`

4. **Reglas de Firestore incorrectas**
   - Si las reglas no permiten leer config o payments
   - Los streams fallan y causan errores
   - Solución: `firebase deploy --only firestore:rules`

## 🎯 Verificación Final

Después de hacer full restart, la app debería:

1. ✅ Iniciar sin errores de Navigator
2. ✅ Mostrar logs de carga de config:
```
🔧 Cargando configuración de Firebase...
✅ Configuración cargada:
   - App settings: true
   - Payment settings: true
   - Feature flags: true
   - Business info: true
```

3. ✅ Si eres admin, mostrar logs de streams:
```
📡 Iniciando stream de pagos pendientes...
✅ Pagos pendientes recibidos: 0
```

4. ✅ **NO mostrar ningún error de Assertion**

## 📝 Si el Problema Persiste

Si después de todos estos pasos el error continúa, necesito:

1. **Los logs completos desde que inicia la app**
   - Desde el primer log hasta el error
   - Incluye todo lo que aparece

2. **Plataforma que estás usando**
   - Windows, Chrome, etc.

3. **Qué estabas haciendo cuando empezó**
   - ¿Estabas en la página de pagos?
   - ¿Hiciste hot restart?
   - ¿Cambiaste algo en el código?

Con esa información podré identificar qué está causando el loop.

## 🔍 Para Desarrolladores

Si estás desarrollando y quieres prevenir este error:

1. **Nunca uses dialogs para loading en operaciones async**
   - Usa overlays con Stack y setState
   - Ejemplo: ver `admin_pagos_page.dart` líneas 617-638

2. **Siempre protege los streams con try-catch**
   - Devuelve stream vacío en caso de error
   - Ejemplo: ver `admin_pagos_viewmodel.dart`

3. **Verifica `mounted` antes de usar context**
   - Especialmente después de operaciones async
   - Ejemplo: ver `admin_pagos_page.dart` líneas 337-340

4. **Captura el context al inicio del callback**
   - No uses context después de Navigator.pop()
   - O mejor aún, usa setState en lugar de dialogs

Con estas prácticas, evitarás errores de Navigator en el futuro.
