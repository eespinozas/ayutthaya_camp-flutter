# 🔥 Desplegar Índices de Firestore

## El error que estás viendo

Si ves un error como:
```
FAILED_PRECONDITION: The query requires an index
```

Significa que necesitas crear índices compuestos en Firestore.

## Solución Rápida

### Opción 1: Desplegar los índices definidos (RECOMENDADO)

Ya tenemos los índices definidos en `firestore.indexes.json`. Solo necesitas desplegarlos:

```bash
firebase deploy --only firestore:indexes
```

Esto creará automáticamente todos los índices necesarios.

### Opción 2: Usar el enlace del error

Cuando veas el error en la consola de Flutter, normalmente incluye un enlace directo como:

```
https://console.firebase.google.com/v1/r/project/YOUR-PROJECT/firestore/indexes?create_composite=...
```

Solo haz clic en ese enlace y se creará el índice automáticamente.

### Opción 3: Crear manualmente en Firebase Console

1. Ve a: https://console.firebase.google.com
2. Selecciona tu proyecto
3. Ve a **Firestore Database** → **Indexes**
4. Click en **Create Index**
5. Configura:
   - **Collection ID**: `payments`
   - **Fields to index**:
     - Campo: `status`, Order: **Ascending**
     - Campo: `createdAt`, Order: **Descending**
   - **Query scope**: Collection

## Índices Actuales Definidos

El archivo `firestore.indexes.json` incluye estos índices:

### Para Payments (Pagos del Admin)
```json
{
  "collection": "payments",
  "fields": [
    { "field": "status", "order": "ASCENDING" },
    { "field": "createdAt", "order": "DESCENDING" }
  ]
}
```

Este índice es necesario para:
- `getPendingPayments()` - Filtrar por status='pending' y ordenar por fecha
- `getApprovedPayments()` - Filtrar por status='approved' y ordenar por fecha
- `getRejectedPayments()` - Filtrar por status='rejected' y ordenar por fecha

### Para Bookings (Usuario)
```json
{
  "collection": "bookings",
  "fields": [
    { "field": "userId", "order": "ASCENDING" },
    { "field": "createdAt", "order": "DESCENDING" }
  ]
}
```

### Para Bookings (Admin - Clases)
```json
{
  "collection": "bookings",
  "fields": [
    { "field": "scheduleId", "order": "ASCENDING" },
    { "field": "classDate", "order": "ASCENDING" },
    { "field": "userName", "order": "ASCENDING" }
  ]
}
```

Este índice es necesario para:
- `getClassBookings()` - Obtener bookings de una clase específica en una fecha

### Para Class Schedules (Admin - Clases)
```json
{
  "collection": "class_schedules",
  "fields": [
    { "field": "daysOfWeek", "arrayConfig": "CONTAINS" },
    { "field": "time", "order": "ASCENDING" }
  ]
}
```

Este índice es necesario para:
- `getSchedules()` - Filtrar schedules donde `daysOfWeek` contiene el día seleccionado y ordenar por hora
- **Nota**: `daysOfWeek` es un array con números del 1-7 (1=Lunes, 2=Martes, etc.)

## Verificar que los índices están creados

Después de desplegarlos:

1. Ve a Firebase Console → Firestore → Indexes
2. Deberías ver todos los índices con estado **Enabled** (verde)
3. Si están en **Building**, espera unos minutos

## Troubleshooting

### "Command not found: firebase"

Instala Firebase CLI:
```bash
npm install -g firebase-tools
```

Luego inicia sesión:
```bash
firebase login
```

### "No project active"

Inicializa Firebase en el proyecto:
```bash
firebase init firestore
```

Selecciona tu proyecto cuando te lo pida.

### Los índices ya existen

Si el comando dice que los índices ya existen, entonces el problema podría ser otro. Revisa la consola de Flutter para ver el error exacto.
