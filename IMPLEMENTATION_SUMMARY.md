# 📋 Resumen de Implementación - Ayutthaya Camp

## ✅ Lo que se ha implementado

### 1. **Sistema de Autenticación (Firebase Auth Directo)**

**Archivos Eliminados:**
- ❌ `lib/core/api_client.dart`
- ❌ `lib/features/auth/data/` (toda la carpeta)
- ❌ `lib/features/auth/domain/` (toda la carpeta)

**Archivos Creados/Modificados:**
- ✅ `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart` - **Simplificado**
  - Usa Firebase Auth directo (sin backend)
  - Crea documento del usuario en Firestore al registrarse
  - Lee rol del usuario desde Firestore
  - Manejo de errores mejorado

**Funcionalidades:**
- ✅ Registro con Firebase Auth + crear documento en Firestore
- ✅ Login con Firebase Auth + leer rol desde Firestore
- ✅ Verificación de email automática
- ✅ Logout
- ✅ AuthStateChanges listener automático
- ✅ Detección de rol (admin vs student)

---

### 2. **Sistema de Pagos (Firebase Directo)**

**Estructura creada:**
```
lib/features/payments/
├── models/
│   └── payment.dart
├── services/
│   └── payment_service.dart
└── viewmodels/
    └── payment_viewmodel.dart
```

**Archivos:**

#### `payment.dart` - Modelo de Payment
- Enums: `PaymentType` (enrollment, monthly)
- Enums: `PaymentStatus` (pending, approved, rejected)
- Conversión a/desde Firestore

#### `payment_service.dart` - Servicio de Pagos
**Funciones:**
- `createPayment()` - Sube comprobante a Storage + crea documento en Firestore
- `getUserPayments()` - Stream de pagos del usuario
- `getAllPayments()` - Stream de todos los pagos (admin)
- `getPaymentsByStatus()` - Stream filtrado por estado (admin)
- `approvePayment()` - Aprobar pago y actualizar usuario
- `rejectPayment()` - Rechazar pago
- `hasApprovedEnrollment()` - Verificar matrícula aprobada
- `_updateUserAfterEnrollment()` - Actualiza `membershipStatus` a `active`
- `_updateUserAfterMonthlyPayment()` - Extiende `expirationDate` según plan

#### `payment_viewmodel.dart` - ViewModel
- Maneja loading states
- Wrapper sobre PaymentService
- Notifica cambios a la UI

#### **`pagos_page.dart` - Actualizado**
- Conectado con `PaymentViewModel`
- Sube comprobante a Firebase Storage
- Crea pago en Firestore
- Muestra loading durante el proceso
- Manejo de errores completo

---

### 3. **Estructura de Firestore**

**Colección: `users`**
```javascript
{
  email: string,
  name: string,
  role: "student" | "admin",
  membershipStatus: "none" | "pending" | "active" | "expired" | "frozen",
  enrollmentDate: timestamp,
  lastPaymentDate: timestamp,
  expirationDate: timestamp,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

**Colección: `payments`**
```javascript
{
  userId: string,
  userName: string,
  userEmail: string,
  type: "enrollment" | "monthly",
  amount: number,
  plan: string,
  paymentDate: timestamp,
  receiptUrl: string,
  status: "pending" | "approved" | "rejected",
  rejectionReason: string?,
  reviewedBy: string?,
  reviewedAt: timestamp?,
  createdAt: timestamp
}
```

**Firebase Storage:**
```
receipts/
  └── {userId}/
      └── payment_{timestamp}.jpg
```

---

### 4. **App Providers Actualizados**

**`app.dart` - Simplificado**
```dart
providers: [
  // Auth ViewModel (Firebase Auth directo)
  ChangeNotifierProvider<AuthViewModel>(
    create: (_) => AuthViewModel()..checkSession(),
  ),

  // Dashboard ViewModel
  ChangeNotifierProvider<DashboardViewModel>(
    create: (_) => DashboardViewModel(),
  ),

  // Payment ViewModel (Firebase directo)
  ChangeNotifierProvider<PaymentViewModel>(
    create: (_) => PaymentViewModel(),
  ),
]
```

---

## 🔄 Flujo de Pagos Actual

### **Usuario registra pago:**

1. **Usuario** va a tab "Pagos"
2. Click en "Pagar Matrícula" o "Pagar Mensualidad"
3. Selecciona monto, fecha y comprobante (foto)
4. Click "Enviar Pago"

5. **Flutter App**:
   - Sube imagen a `Firebase Storage: receipts/{userId}/`
   - Crea documento en `Firestore: payments/`
   - Estado: `pending`

6. **Admin** aprueba/rechaza:
   - Ve pago en `AdminPagosPage` (TODO: conectar con Firebase)
   - Click "Aprobar" → llama `paymentService.approvePayment()`
   - Actualiza usuario: `membershipStatus = "active"`
   - Calcula `expirationDate` (+30 días para mensual)

---

## 📦 Dependencias Agregadas

```yaml
firebase_core: ^3.5.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
firebase_storage: ^12.3.2  # ← Nueva
```

---

### **5. Sistema de Configuración Dinámica (Planes y Horarios) ✅ COMPLETADO**

**Estructura creada:**
```
lib/features/plans/
├── models/plan.dart
├── services/plan_service.dart
└── viewmodels/plan_viewmodel.dart

lib/features/schedules/
├── models/class_schedule.dart
├── services/class_schedule_service.dart
└── viewmodels/class_schedule_viewmodel.dart
```

#### **Plan Model y Service:**
- Campos: `name`, `price`, `durationDays`, `description`, `active`, `displayOrder`
- Métodos: `getActivePlans()`, `getAllPlans()`, `createPlan()`, `updatePlan()`, `deletePlan()`
- Integrado con `PagosPage` - dropdown de planes al pagar mensualidad
- Precio se auto-completa al seleccionar plan

#### **ClassSchedule Model y Service:**
- Campos: `time`, `instructor`, `type`, `capacity`, `daysOfWeek`, `active`, `displayOrder`
- Métodos: `getActiveSchedules()`, `getSchedulesForDay(dayOfWeek)`, `createSchedule()`, `updateSchedule()`, `deleteSchedule()`
- Helpers: `isOnDay(int dayOfWeek)`, `getTimeAsDateTime(DateTime date)`
- Integrado con `AgendarPage` - clases dinámicas desde Firebase
- Filtrado por día de la semana automático

#### **Actualización de Providers (`app.dart`):**
```dart
ChangeNotifierProvider<PlanViewModel>(
  create: (_) => PlanViewModel(),
),
ChangeNotifierProvider<ClassScheduleViewModel>(
  create: (_) => ClassScheduleViewModel(),
),
```

#### **PagosPage actualizado:**
- StreamBuilder lee planes activos desde Firebase
- Dropdown de selección de plan (solo en mensualidad)
- Auto-completa monto al seleccionar plan
- Validación de plan obligatorio

#### **AgendarPage actualizado:**
- StreamBuilder lee horarios desde Firebase
- Filtrado automático por día seleccionado
- Muestra clases dinámicas según `daysOfWeek`
- Formateo de hora 12h/24h
- Error handling completo

**Colecciones Firestore agregadas:**
```javascript
// Collection: plans
{
  name: string,           // "Mensual", "Trimestral"
  price: number,          // 60000, 150000
  durationDays: number,   // 30, 90, 180, 365
  description: string,
  active: boolean,
  displayOrder: number,
  createdAt: timestamp,
  updatedAt: timestamp
}

// Collection: class_schedules
{
  time: string,           // "07:00", "18:00"
  instructor: string,     // "Francisco Poveda"
  type: string,           // "Muay Thai", "Boxing"
  capacity: number,       // 15
  daysOfWeek: array,      // [1,2,3,4,5] = Lun-Vie
  active: boolean,
  displayOrder: number,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

---

## 🚧 Pendientes

### **1. Conectar AdminPagosPage con Firebase**
Actualmente usa mock data. Necesita:
- Leer pagos con `paymentVM.getPaymentsByStatus()`
- Botones de aprobar/rechazar conectados
- Stream builder para actualización en tiempo real

### **2. Sistema de Reservas (Bookings)**
Crear:
- `lib/features/bookings/` (models, services, viewmodels)
- Colección `bookings` en Firestore
- Conectar con `AgendarPage` y `MisClasesPage`
- AdminClasesPage para marcar asistencia real

### **3. Crear Admin UI para Gestionar Planes y Horarios**
Páginas de administración para:
- Crear/editar/eliminar planes
- Crear/editar/eliminar horarios de clases
- Configurar instructores
- Ajustar capacidad de clases

### **4. Leer Datos Reales en PagosPage (Historial)**
Actualmente muestra mock data en el historial. Necesita:
- Stream de `paymentVM.getUserPayments(userId)`
- StreamBuilder para mostrar pagos reales
- Leer `membershipStatus` desde Firestore

### **5. Security Rules de Firebase**
Configurar en Firebase Console:
- Firestore Rules (users, payments, bookings, plans, class_schedules)
- Storage Rules (receipts)
- Permisos de admin vs student

### **6. Dashboard Admin con Datos Reales**
Conectar estadísticas con Firestore:
- Contar asistencias reales desde bookings
- Pagos del día/mes desde payments
- Alumnos nuevos desde users
- Clases más populares

---

## 🎯 Siguiente Paso Recomendado

**Crear sistema de Bookings (Reservas)** para:
- Permitir que usuarios reserven clases desde `AgendarPage`
- Admin marque asistencia en `AdminClasesPage`
- Ver clases reservadas en "Mis Clases"
- Validar capacidad de clases
- Verificar que el usuario tenga membresía activa

¿Continuamos con Bookings?
