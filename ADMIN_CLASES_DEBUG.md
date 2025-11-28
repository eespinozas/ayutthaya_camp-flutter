# 🔍 Diagnóstico: Admin Clases - Schedules Duplicados

## Cambios Realizados

### 1. **Filtro por Día de la Semana usando `daysOfWeek`**
Ahora el sistema filtra los `class_schedules` por el día de la semana de la fecha seleccionada usando el array `daysOfWeek`:

```dart
// Si seleccionas "Lunes 24 Nov", weekday = 1
// Busca schedules donde daysOfWeek contiene 1
.where('daysOfWeek', arrayContains: 1)
.orderBy('time', descending: false)
```

**Mapeo de días:**
- 1 = Lunes
- 2 = Martes
- 3 = Miércoles
- 4 = Jueves
- 5 = Viernes
- 6 = Sábado
- 7 = Domingo

### 2. **Logging Detallado**
Se agregó logging extensivo que te mostrará:
- ✅ Fecha seleccionada y día de la semana
- ✅ Todos los schedules recibidos de Firestore con su información completa
- ✅ Cuáles schedules se filtran y por qué
- ✅ Bookings para cada schedule con nombre de alumnos

## Cómo Diagnosticar el Problema

### Paso 1: Desplegar los Índices
Primero, despliega los nuevos índices de Firestore:

```bash
firebase deploy --only firestore:indexes
```

Índices agregados:
- **bookings**: `scheduleId` + `classDate` + `userName`
- **class_schedules**: `day` + `time`

### Paso 2: Ejecutar la App y Revisar la Consola

1. Abre el tab de **Clases** en el admin
2. Revisa la consola/terminal donde ejecutaste `flutter run`
3. Verás un log como este:

```
═══════════════════════════════════════════════════════
📊 SCHEDULES RECIBIDOS DE FIRESTORE
═══════════════════════════════════════════════════════
Total de documentos: X
Filtrando por día: Lunes (posición: 1)

Schedule ID: abc123
  - time: 07:00
  - daysOfWeek: [1, 3, 5]  (Lunes, Miércoles, Viernes)
  - capacity: 15
  - instructor: Juan Pérez

Schedule ID: def456
  - time: 08:00
  - daysOfWeek: [2, 4]  (Martes, Jueves)
  - capacity: 15
  - instructor: María García

  ⚠️ SKIP: Schedule no incluye el día 1 (Lunes)

Schedules parseados exitosamente: 1
═══════════════════════════════════════════════════════
```

### Paso 3: Copia el Log Completo
Copia TODO el log desde la consola, especialmente la sección con los marcos `═══════...═══════`

### Paso 4: Compartir el Log
Pega el log completo para que pueda diagnosticar:
- ¿Cuántos schedules hay en la base de datos?
- ¿Están duplicados?
- ¿Tienen el campo `day` correctamente?
- ¿Corresponden los horarios a lo que esperas?

## Posibles Problemas y Soluciones

### Problema 1: Schedules sin campo `daysOfWeek`
**Síntoma**: Ves schedules con `daysOfWeek: null` en el log

**Solución**: Todos los schedules deben tener un campo `daysOfWeek` que es un array con los números de los días:
- `[1]` = Solo Lunes
- `[1, 3, 5]` = Lunes, Miércoles, Viernes
- `[2, 4]` = Martes, Jueves
- `[1, 2, 3, 4, 5]` = Lunes a Viernes

### Problema 2: Múltiples Schedules con Mismo Horario
**Síntoma**: Ves múltiples schedules con `time: 07:00` para el mismo día

**Solución**:
- Si los schedules tienen diferentes `daysOfWeek`, está bien (por ejemplo, una clase a las 07:00 los Lunes y otra a las 07:00 los Martes)
- Si son para los mismos días, verifica si son diferentes instructores o tipos de clase
- Si son duplicados exactos, eliminar los duplicados en Firestore

### Problema 3: Error de Índice
**Síntoma**: Ves un error que dice "requires an index"

**Solución**:
1. El código tiene un FALLBACK que obtendrá todos los schedules y filtrará en cliente
2. Despliega los índices: `firebase deploy --only firestore:indexes`
3. O usa el enlace del error para crear el índice automáticamente

### Problema 4: Schedules de Todos los Días
**Síntoma**: Ves schedules de varios días cuando solo debería mostrar los del día seleccionado

**Solución**:
- Verifica que el filtro `array-contains` esté funcionando
- Mira el log para ver qué schedules se están filtrando con "⚠️ SKIP"
- Verifica que el array `daysOfWeek` contenga números del 1 al 7 (no 0-6)

## Estructura Esperada en Firestore

### Collection: `class_schedules`
```json
{
  "id": "schedule_135_07",
  "daysOfWeek": [1, 3, 5],  // Lunes, Miércoles, Viernes
  "time": "07:00",
  "capacity": 15,
  "instructor": "Juan Pérez",
  "createdAt": "timestamp"
}
```

**Otro ejemplo:**
```json
{
  "id": "schedule_24_19",
  "daysOfWeek": [2, 4],  // Martes y Jueves
  "time": "19:00",
  "capacity": 12,
  "instructor": "María García",
  "createdAt": "timestamp"
}
```

### Collection: `bookings`
```json
{
  "id": "booking_001",
  "scheduleId": "schedule_lun_07",
  "userId": "user_001",
  "userName": "María García",
  "classDate": "2025-11-24T00:00:00Z",
  "scheduleTime": "07:00",
  "status": "confirmed",
  "createdAt": "timestamp"
}
```

## Siguiente Paso

Ejecuta la app, copia el log completo de la consola y compártelo para diagnosticar exactamente qué está pasando con los schedules! 📋
