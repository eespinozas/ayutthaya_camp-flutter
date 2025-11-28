# 🔌 Backend API - Ayutthaya Camp

Este documento define los endpoints que tu backend en Node.js debe exponer para que la app Flutter pueda funcionar correctamente.

---

## 🏗️ Base URL

```
http://localhost:3000/api
```

o en producción:
```
https://tu-backend.com/api
```

---

## 🔐 Autenticación

Todos los endpoints (excepto auth) requieren el token de Firebase Auth en el header:

```
Authorization: Bearer {firebaseToken}
```

El backend debe verificar el token con Firebase Admin SDK.

---

## 📋 Endpoints Necesarios

### **1. Pagos (Payments)**

#### **POST /payments**
Crear un nuevo pago (matrícula o mensualidad).

**Request:**
```json
{
  "type": "enrollment" | "monthly",
  "amount": 50000,
  "plan": "Mensual" | "Trimestral" | "Semestral" | "Anual",
  "paymentDate": "2024-11-20T10:00:00Z",
  "receiptBase64": "data:image/jpeg;base64,/9j/4AAQ..."
}
```

**Response (201):**
```json
{
  "success": true,
  "paymentId": "abc123",
  "message": "Pago creado exitosamente"
}
```

**Lo que hace el backend:**
1. Verificar token de autenticación
2. Subir imagen a Firebase Storage (`receipts/{userId}/{paymentId}.jpg`)
3. Crear documento en Firestore `payments/` con:
   - userId (del token)
   - userName
   - userEmail
   - type, amount, plan, paymentDate
   - receiptUrl (URL de Storage)
   - status: "pending"
   - createdAt: timestamp

---

#### **GET /payments/user**
Obtener historial de pagos del usuario actual.

**Response (200):**
```json
{
  "success": true,
  "payments": [
    {
      "id": "abc123",
      "type": "enrollment",
      "amount": 50000,
      "plan": "Matrícula",
      "paymentDate": "2024-11-20T10:00:00Z",
      "receiptUrl": "https://...",
      "status": "approved",
      "createdAt": "2024-11-20T10:05:00Z",
      "reviewedAt": "2024-11-20T11:00:00Z"
    }
  ]
}
```

---

#### **GET /payments/admin** (Admin only)
Obtener todos los pagos (para admin).

**Query params:**
- `status` (opcional): "pending" | "approved" | "rejected"

**Response (200):**
```json
{
  "success": true,
  "payments": [
    {
      "id": "abc123",
      "userId": "user123",
      "userName": "Juan Pérez",
      "userEmail": "juan@gmail.com",
      "type": "enrollment",
      "amount": 50000,
      "plan": "Matrícula",
      "paymentDate": "2024-11-20T10:00:00Z",
      "receiptUrl": "https://...",
      "status": "pending",
      "createdAt": "2024-11-20T10:05:00Z"
    }
  ]
}
```

---

#### **PUT /payments/:paymentId/approve** (Admin only)
Aprobar un pago.

**Response (200):**
```json
{
  "success": true,
  "message": "Pago aprobado exitosamente"
}
```

**Lo que hace el backend:**
1. Verificar que el usuario es admin
2. Actualizar documento en Firestore:
   - status: "approved"
   - reviewedBy: adminId
   - reviewedAt: timestamp
3. Si es matrícula (`enrollment`):
   - Actualizar usuario: `membershipStatus = "active"`
   - Calcular `expirationDate = now + 30 days`
4. Si es mensualidad (`monthly`):
   - Actualizar `expirationDate` según el plan

---

#### **PUT /payments/:paymentId/reject** (Admin only)
Rechazar un pago.

**Request:**
```json
{
  "reason": "Comprobante ilegible"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Pago rechazado"
}
```

**Lo que hace el backend:**
1. Verificar que el usuario es admin
2. Actualizar documento:
   - status: "rejected"
   - rejectionReason: reason
   - reviewedBy: adminId
   - reviewedAt: timestamp

---

### **2. Usuario (User)**

#### **GET /user/me**
Obtener datos del usuario actual.

**Response (200):**
```json
{
  "success": true,
  "user": {
    "id": "user123",
    "email": "juan@gmail.com",
    "name": "Juan Pérez",
    "role": "student" | "admin",
    "membershipStatus": "none" | "pending" | "active" | "expired",
    "enrollmentDate": "2024-11-20T11:00:00Z",
    "expirationDate": "2024-12-20T11:00:00Z",
    "lastPaymentDate": "2024-11-20T11:00:00Z"
  }
}
```

---

#### **PUT /user/me**
Actualizar datos del perfil.

**Request:**
```json
{
  "name": "Juan Pérez Updated",
  "phone": "+57 300 123 4567"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Perfil actualizado"
}
```

---

### **3. Reservas (Bookings)**

#### **POST /bookings**
Crear una reserva de clase.

**Request:**
```json
{
  "classDate": "2024-11-25T07:00:00Z",
  "classTime": "07:00",
  "instructor": "Francisco Poveda",
  "type": "Muay Thai"
}
```

**Response (201):**
```json
{
  "success": true,
  "bookingId": "booking123",
  "message": "Clase reservada exitosamente"
}
```

**Validaciones del backend:**
1. Usuario debe tener `membershipStatus = "active"`
2. Verificar que no haya superado la capacidad (15 personas)
3. Usuario no puede reservar la misma clase dos veces

---

#### **GET /bookings/user**
Obtener reservas del usuario.

**Query params:**
- `status` (opcional): "reserved" | "attended" | "missed" | "cancelled"

**Response (200):**
```json
{
  "success": true,
  "bookings": [
    {
      "id": "booking123",
      "classDate": "2024-11-25T07:00:00Z",
      "classTime": "07:00",
      "instructor": "Francisco Poveda",
      "type": "Muay Thai",
      "status": "reserved",
      "createdAt": "2024-11-20T10:00:00Z"
    }
  ]
}
```

---

#### **PUT /bookings/:bookingId/cancel**
Cancelar una reserva.

**Request:**
```json
{
  "reason": "No puedo asistir"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Reserva cancelada"
}
```

---

#### **GET /bookings/admin** (Admin only)
Obtener todas las reservas.

**Query params:**
- `date` (opcional): "2024-11-25"
- `classTime` (opcional): "07:00"

**Response (200):**
```json
{
  "success": true,
  "bookings": [...]
}
```

---

#### **PUT /bookings/:bookingId/attendance** (Admin only)
Marcar asistencia.

**Request:**
```json
{
  "attended": true
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Asistencia actualizada"
}
```

---

### **4. Dashboard / Stats**

#### **GET /stats/admin/daily** (Admin only)
Obtener estadísticas del día.

**Query params:**
- `date` (opcional): "2024-11-20"

**Response (200):**
```json
{
  "success": true,
  "stats": {
    "totalAsistencias": 45,
    "clasesCompletadas": 5,
    "clasesTotales": 5,
    "alumnosNuevos": 3,
    "pagosRecibidos": 180000,
    "clases": [
      {
        "hora": "07:00",
        "inscritos": 14,
        "asistieron": 14,
        "capacidad": 15
      }
    ]
  }
}
```

---

#### **GET /stats/admin/weekly** (Admin only)
Estadísticas de la semana.

**Query params:**
- `weekStart` (opcional): "2024-11-18"

---

#### **GET /stats/admin/monthly** (Admin only)
Estadísticas del mes.

**Query params:**
- `month` (opcional): "2024-11"

---

## 🔒 Middleware de Autenticación

Tu backend en Node.js debe tener un middleware que:

```javascript
const admin = require('firebase-admin');

async function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.split('Bearer ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No autorizado' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.userId = decodedToken.uid;
    req.userEmail = decodedToken.email;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Token inválido' });
  }
}
```

---

## 🧪 Testing con Postman/Thunder Client

Ejemplo de request con autenticación:

```
POST http://localhost:3000/api/payments
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "type": "enrollment",
  "amount": 50000,
  "plan": "Matrícula",
  "paymentDate": "2024-11-20T10:00:00Z",
  "receiptBase64": "data:image/jpeg;base64,/9j/4AAQ..."
}
```

---

## 📦 Próximos Pasos

1. **Implementar endpoints en Node.js**
2. **Crear API client en Flutter** para llamar estos endpoints
3. **Actualizar PagosPage** para usar el API
4. **Actualizar AdminPagosPage** para usar el API
5. **Implementar sistema de bookings**
