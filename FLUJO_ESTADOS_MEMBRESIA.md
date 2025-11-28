# Flujo de Estados de Membresía

## Estados Posibles

| Estado | Descripción | Cuándo se asigna |
|--------|-------------|------------------|
| `none` | Sin membresía | Al registrarse, antes de pagar matrícula |
| `pending` | Esperando aprobación | Al enviar pago de matrícula (esperando aprobación del admin) |
| `active` | Membresía activa | Cuando el admin aprueba la matrícula o pago mensual |
| `inactive` | Membresía vencida | Cuando la fecha de expiración ya pasó |

---

## Flujo Completo

### 1. Registro de Usuario

```
Usuario se registra
  ↓
membershipStatus: "none"
expirationDate: null
```

**Firestore (users/{userId}):**
```json
{
  "email": "usuario@example.com",
  "name": "Juan Pérez",
  "role": "student",
  "membershipStatus": "none",
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

---

### 2. Usuario Envía Pago de Matrícula

```
Usuario paga matrícula
  ↓
Se crea documento en payments/ con status: "pending"
  ↓
membershipStatus: "pending" (esperando aprobación)
```

**Firestore (users/{userId}):**
```json
{
  "membershipStatus": "pending",
  "updatedAt": "2025-01-15T11:00:00Z"
}
```

**Firestore (payments/{paymentId}):**
```json
{
  "userId": "userId123",
  "userName": "Juan Pérez",
  "type": "enrollment",
  "amount": 30000,
  "plan": "Plan Básico",
  "status": "pending",
  "receiptUrl": "https://storage.googleapis.com/...",
  "createdAt": "2025-01-15T11:00:00Z"
}
```

**Código:**
- `payment_service.dart:67-75` - Se actualiza el usuario a "pending" al crear pago de matrícula

---

### 3. Admin Aprueba la Matrícula

```
Admin aprueba el pago
  ↓
Payment.status: "approved"
  ↓
membershipStatus: "active"
expirationDate: fecha actual + 30 días
enrollmentDate: fecha actual
```

**Firestore (users/{userId}):**
```json
{
  "membershipStatus": "active",
  "enrollmentDate": "2025-01-15T12:00:00Z",
  "lastPaymentDate": "2025-01-15T12:00:00Z",
  "expirationDate": "2025-02-14T12:00:00Z",
  "updatedAt": "2025-01-15T12:00:00Z"
}
```

**Firestore (payments/{paymentId}):**
```json
{
  "status": "approved",
  "reviewedBy": "adminId",
  "reviewedAt": "2025-01-15T12:00:00Z"
}
```

**Código:**
- `payment_service.dart:128-170` - Método `approvePayment()`
- `payment_service.dart:186-210` - Método `_updateUserAfterEnrollment()`

---

### 4. Admin Rechaza la Matrícula

```
Admin rechaza el pago
  ↓
Payment.status: "rejected"
  ↓
membershipStatus: se mantiene "pending"
(NO se actualiza el usuario)
```

**Firestore (payments/{paymentId}):**
```json
{
  "status": "rejected",
  "rejectionReason": "Comprobante ilegible",
  "reviewedBy": "adminId",
  "reviewedAt": "2025-01-15T12:00:00Z"
}
```

**Usuario puede:**
- Ver el motivo del rechazo
- Enviar un nuevo pago con un comprobante correcto
- Seguir como "pending" hasta que se apruebe un pago

**Código:**
- `payment_service.dart:173-184` - Método `rejectPayment()` (NO actualiza al usuario)

---

### 5. Usuario con Membresía Activa Paga Mensualidad

```
Usuario activo paga mensualidad
  ↓
Se crea documento en payments/ con status: "pending"
  ↓
membershipStatus: se mantiene "active"
(hasta que el admin apruebe o rechace)
```

**Admin aprueba:**
```
Payment.status: "approved"
  ↓
expirationDate: se extiende según el plan
lastPaymentDate: fecha actual
membershipStatus: "active" (se mantiene)
```

**Código:**
- `payment_service.dart:212-253` - Método `_updateUserAfterMonthlyPayment()`

---

### 6. Plan Vencido (Verificación Automática)

```
Usuario inicia sesión
  ↓
DashboardViewModel carga datos
  ↓
Verifica: ¿expirationDate < fecha actual?
  ↓
SI → membershipStatus: "inactive"
NO → mantiene estado actual
```

**Firestore (users/{userId}):**
```json
{
  "membershipStatus": "inactive",
  "expirationDate": "2025-01-10T12:00:00Z",  // Ya pasó
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

**Código:**
- `dashboard_viewmodel.dart:121-143` - Verificación automática de vencimiento

---

## Diagrama de Flujo

```
┌─────────────┐
│  REGISTRO   │
│ (none)      │
└──────┬──────┘
       │
       │ Envía pago de matrícula
       ↓
┌─────────────┐
│  PENDING    │ ←──────────────┐
│ (esperando) │                │
└──────┬──────┘                │
       │                       │ Admin rechaza
       │ Admin aprueba         │
       ↓                       │
┌─────────────┐                │
│   ACTIVE    │                │
│ (activo)    │ ───────────────┘
└──────┬──────┘
       │
       │ Plan vence
       ↓
┌─────────────┐
│  INACTIVE   │
│ (vencido)   │
└──────┬──────┘
       │
       │ Paga mensualidad y admin aprueba
       ↓
┌─────────────┐
│   ACTIVE    │
└─────────────┘
```

---

## Validaciones Importantes

### Al Agendar Clase

```dart
// dashboard_viewmodel.dart:56-59
bool get estaActivo {
  return membershipStatus == 'active';
}
```

Solo usuarios con `membershipStatus == 'active'` pueden agendar clases.

### Al Ver Dashboard

```dart
// Usuarios "pending" ven:
- Mensaje: "Tu matrícula está pendiente de aprobación"
- No pueden agendar clases

// Usuarios "inactive" ven:
- Mensaje: "Tu membresía ha vencido"
- Botón para renovar/pagar mensualidad
- No pueden agendar clases

// Usuarios "active" ven:
- Dashboard completo con clases disponibles
- Pueden agendar clases
```

---

## Casos de Uso

### Caso 1: Usuario Nuevo

1. Se registra → `none`
2. Paga matrícula → `pending`
3. Admin aprueba → `active` (vence en 30 días)
4. Paga mensualidad antes de vencer → `active` (se extiende)

### Caso 2: Usuario con Plan Vencido

1. Usuario con `active` no paga a tiempo
2. Fecha de expiración pasa
3. Al iniciar sesión → se actualiza a `inactive`
4. Paga mensualidad → queda `inactive` hasta que admin apruebe
5. Admin aprueba → `active` (nueva fecha de expiración)

### Caso 3: Usuario con Pago Rechazado

1. Usuario paga matrícula → `pending`
2. Admin rechaza (comprobante malo) → sigue `pending`
3. Usuario ve mensaje de rechazo con motivo
4. Usuario paga nuevamente con comprobante correcto → sigue `pending`
5. Admin aprueba → `active`

---

## Archivos Modificados

| Archivo | Cambios | Líneas |
|---------|---------|--------|
| `payment_service.dart` | Al crear pago de matrícula → actualiza usuario a "pending" | 67-75 |
| `payment_service.dart` | Al aprobar matrícula → actualiza usuario a "active" | 186-210 |
| `payment_service.dart` | Al aprobar mensualidad → extiende expirationDate | 212-253 |
| `payment_service.dart` | Al rechazar pago → NO actualiza usuario | 173-184 |
| `dashboard_viewmodel.dart` | Verifica vencimiento al cargar → actualiza a "inactive" | 121-143 |
| `dashboard_viewmodel.dart` | Getter `estaActivo` → valida si puede agendar | 56-59 |

---

## Testing

### Probar Flujo Completo

1. **Crear usuario nuevo:**
   ```
   Registro → membershipStatus debe ser "none"
   ```

2. **Enviar pago de matrícula:**
   ```
   Pagar matrícula → membershipStatus debe cambiar a "pending"
   Firebase Console → users/{userId} → membershipStatus == "pending"
   ```

3. **Aprobar matrícula:**
   ```
   Admin aprueba → membershipStatus debe cambiar a "active"
   Firebase Console → users/{userId} → expirationDate debe ser +30 días
   ```

4. **Simular vencimiento:**
   ```
   Firebase Console → users/{userId} → cambiar expirationDate a fecha pasada
   Cerrar sesión y volver a iniciar
   membershipStatus debe cambiar a "inactive"
   ```

5. **Probar rechazo:**
   ```
   Usuario "pending" → Admin rechaza pago
   membershipStatus debe seguir siendo "pending"
   Usuario ve mensaje de rechazo
   ```

---

## Resumen

✅ **Flujo implementado correctamente:**
- Usuario empieza como "none"
- Al pagar matrícula → "pending"
- Admin aprueba → "active"
- Admin rechaza → mantiene estado anterior
- Plan vence → "inactive" (verificación automática)
- Renovación → vuelve a "active" cuando admin aprueba

✅ **Validaciones:**
- Solo usuarios "active" pueden agendar clases
- Verificación automática de vencimiento al cargar dashboard
- Estados claramente diferenciados en la UI
