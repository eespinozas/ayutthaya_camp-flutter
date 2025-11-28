# Índices de Firestore Requeridos

Firebase Firestore requiere índices compuestos para queries que combinan múltiples campos con `where()` y `orderBy()`.

## Opción 1: Usar el enlace del error (RECOMENDADO)

Cuando veas el error "The query requires an index", Firebase te dará un enlace directo que se ve así:

```
https://console.firebase.google.com/v1/r/project/YOUR_PROJECT_ID/firestore/indexes?create_composite=...
```

**Simplemente haz clic en ese enlace** y Firebase creará el índice automáticamente.

---

## Opción 2: Crear índices manualmente

Si prefieres crear los índices manualmente, ve a:
**Firebase Console → Firestore Database → Indexes**

### Índices necesarios para la colección `payments`:

#### 1. getUserPayments (para historial de pagos del usuario)
- **Colección**: `payments`
- **Campos**:
  - `userId` - Ascending
  - `createdAt` - Descending
- **Query scope**: Collection

#### 2. getPaymentsByStatus (para admin ver pagos por estado)
- **Colección**: `payments`
- **Campos**:
  - `status` - Ascending
  - `createdAt` - Descending
- **Query scope**: Collection

#### 3. hasApprovedEnrollment (para verificar matrícula aprobada)
- **Colección**: `payments`
- **Campos**:
  - `userId` - Ascending
  - `type` - Ascending
  - `status` - Ascending
- **Query scope**: Collection

---

## Índices necesarios para la colección `bookings`:

#### 4. getUserBookings (para "Mis Clases")
- **Colección**: `bookings`
- **Campos**:
  - `userId` - Ascending
  - `createdAt` - Descending
- **Query scope**: Collection

---

## ¿Por qué se necesitan estos índices?

Firestore requiere índices compuestos cuando:
- Usas múltiples `where()` con diferentes campos
- Combinas `where()` con `orderBy()` en campos diferentes
- Usas `orderBy()` en múltiples campos

Estos índices mejoran el rendimiento de las queries y son obligatorios para que funcionen.

---

## Tiempo de creación

Los índices pueden tardar varios minutos en construirse la primera vez. Verás el estado en la consola de Firebase:
- 🔄 **Building** - El índice se está creando
- ✅ **Enabled** - El índice está listo para usar

No podrás ejecutar las queries hasta que los índices estén en estado "Enabled".
