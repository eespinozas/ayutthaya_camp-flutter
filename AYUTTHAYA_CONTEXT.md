# Ayutthaya Camp App - Contexto del Proyecto

## 1. Propósito Principal

**Ayutthaya Camp** es un centro de entrenamiento de Muay Thai que busca profesionalizar la gestión de clases, pagos y asistencias mediante una aplicación móvil Flutter.

### Problema que Resuelve
- **Antes**: La asistencia se marcaba por WhatsApp, sin control real de planes contratados ni historial
- **Ahora**: Sistema centralizado para agendar clases, gestionar pagos, marcar asistencias y llevar registro completo
- **Visión**: Posicionar a Ayutthaya Camp como un gimnasio de alto nivel con tecnología de vanguardia

---

## 2. Usuarios y Roles

### 2.1 Administradores (3 usuarios)
- **2 entrenadores** con rol admin
- **1 community manager** con acceso admin
- **Permisos**: Acceso completo a gestión de alumnos, pagos, clases y reportes

### 2.2 Alumnos
- **Estados**:
  - `none`: Registrado pero sin plan
  - `pending`: Matriculación enviada, esperando aprobación
  - `active`: Membresía activa
  - `expired`: Membresía vencida
  - `frozen`: Congelada (no implementado aún)

---

## 3. Flujos Principales

### 3.1 Flujo de Alumno (Usuario Regular)

#### Registro y Matriculación
```
1. Alumno se registra → email + contraseña
2. Recibe email de verificación
3. Accede a la app (estado: none)
4. Ve banner "Activa tu Membresía"
5. Navega a Pagos → Selecciona plan
6. Sube comprobante de pago (matrícula + mensualidad)
7. Estado cambia a "pending"
8. Admin recibe notificación push
9. Admin aprueba pago → Estado "active"
10. Alumno puede agendar clases
```

#### Agendar Clase
```
1. Navega a "Agendar"
2. Selecciona fecha en calendario
3. Ve horarios disponibles
4. Agenda clase (si tiene cupos en su plan)
5. Clase aparece en "Mis Clases"
6. Puede cancelar hasta cierto tiempo antes
```

#### Confirmar Asistencia
```
1. 30 min antes de la clase: puede confirmar asistencia
2. Durante la clase: puede confirmar asistencia
3. 30 min después: ventana de confirmación cierra
4. Admin también puede marcar asistencia escaneando QR
```

### 3.2 Flujo de Admin

#### Aprobar Pagos
```
1. Accede a pestaña "Pagos"
2. Ve lista de pagos pendientes
3. Revisa comprobante
4. Aprueba o rechaza
5. Si aprueba matrícula:
   - Usuario pasa a estado "active"
   - Se calcula fecha de expiración según plan
   - Usuario recibe notificación
```

#### Gestionar Alumnos
```
1. Accede a pestaña "Alumnos"
2. Ve lista paginada de usuarios
3. Puede buscar por nombre/email
4. Puede dar de baja (cambiar estado a "expired")
5. Ve detalles: plan, clases restantes, historial
```

#### Dashboard
```
1. Ve KPIs del día:
   - Asistencias totales
   - Clases completadas
   - Nuevos alumnos
   - Ingresos del día
2. Ve alertas:
   - Pagos pendientes
   - Usuarios pendientes de aprobación
   - Membresías por vencer (3 días)
3. Ve ocupación por clase
```

---

## 4. Pantallas Existentes

### 4.1 App de Alumnos
- **Menú inferior**:
  - Inicio (Dashboard)
  - Agendar
  - **QR Central** (botón circular para abrir cámara y marcar asistencia)
  - Mis Clases
  - Pagos
  - Perfil

### 4.2 App de Admin
- **Menú inferior**:
  - Dashboard
  - Alumnos
  - Pagos
  - Clases
  - Reportes
  - Perfil

---

## 5. Integraciones Técnicas

### 5.1 Firebase
- **Authentication**: Email/password
- **Firestore**: Base de datos principal
  - Colecciones: users, payments, bookings, schedules, plans, notifications, scheduled_notifications
- **Storage**: Almacenamiento de comprobantes de pago
- **Cloud Functions**:
  - Envío de emails (verificación, reset password)
  - Procesamiento de notificaciones push
  - Limpieza de datos antiguos

### 5.2 Emails (Resend)
- **Servicio**: Resend (migrado desde SendGrid)
- **Emails automáticos**:
  - Verificación de email (registro)
  - Recuperación de contraseña
- **Configuración**: Variables de entorno en Firebase Functions
  - `RESEND_API_KEY`
  - `RESEND_FROM_EMAIL`

### 5.3 Notificaciones Push (Firebase Cloud Messaging)
- **Estado**: Implementadas pero **NO TESTEADAS**
- **Eventos**:
  - Nuevo usuario registrado → Notifica a admins
  - Pago aprobado → Notifica al usuario
  - Recordatorio de clase (30/15 min antes) → Programado pero no validado
- **Problema conocido**: Falta configurar VAPID key para web

### 5.4 Pagos
- **Método actual**: Manual (subida de comprobantes)
- **Roadmap futuro**: Pasarela de pagos automática (Stripe, MercadoPago, etc.)

---

## 6. Arquitectura Técnica

### 6.1 Stack Tecnológico
```yaml
Framework: Flutter 3.9+
Lenguaje: Dart 3.9.2
Versión actual: 1.0.1+10
Estado Management: Provider 6.1.5
Backend: Firebase (Firestore, Auth, Storage, Functions)
Cloud Functions: Node.js + TypeScript
```

### 6.2 Estructura de Carpetas
```
lib/
├── app/                    # Configuración de la app
├── core/
│   ├── config/            # Constantes y configuración
│   ├── services/          # Servicios compartidos
│   │   ├── auth_email_service.dart
│   │   ├── notification_service.dart
│   │   ├── firebase_service.dart
│   │   └── pagination_service.dart
│   └── widgets/           # Widgets reutilizables
├── features/
│   ├── admin/             # Funcionalidades admin
│   │   └── presentation/
│   │       ├── pages/     # 7 páginas admin
│   │       └── viewmodels/
│   ├── auth/              # Autenticación
│   │   └── presentation/
│   ├── bookings/          # Agendamiento de clases
│   │   ├── models/
│   │   ├── services/
│   │   └── viewmodels/
│   ├── dashboard/         # Dashboard alumno
│   ├── payments/          # Pagos
│   ├── plans/             # Planes y membresías
│   └── schedules/         # Horarios de clases
├── theme/                 # Sistema de diseño
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   └── app_spacing.dart
└── utils/
```

### 6.3 Patrones de Arquitectura Detectados
- **MVVM**: ViewModels con ChangeNotifier + Provider
- **Feature-based structure**: Organización por funcionalidad
- **Partial Clean Architecture**: Separación models/services/viewmodels
- **Inconsistencias**:
  - Algunos features tienen domain/data/presentation (dashboard)
  - Otros solo models/services/viewmodels (bookings, payments)
  - No hay capa de repository consistente

---

## 7. Modelos de Datos Principales

### 7.1 User (Firestore: `users`)
```dart
{
  email: String
  searchKey: String (lowercase para búsquedas)
  name: String
  role: 'student' | 'admin'
  membershipStatus: 'none' | 'pending' | 'active' | 'expired' | 'frozen'
  expirationDate: Timestamp?
  fcmToken: String? (para notificaciones)
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

### 7.2 Payment
```dart
{
  userId: String
  userName: String
  userEmail: String
  type: 'enrollment' | 'monthly'
  amount: double
  plan: String
  paymentDate: Timestamp
  receiptUrl: String (Storage URL)
  status: 'pending' | 'approved' | 'rejected' | 'failed'
  rejectionReason: String?
  reviewedBy: String?
  reviewedAt: Timestamp?
  createdAt: Timestamp
}
```

### 7.3 Booking
```dart
{
  userId: String
  userName: String
  userEmail: String
  scheduleId: String
  scheduleTime: String (ej: "07:00")
  scheduleType: String (ej: "Muay Thai")
  instructor: String
  classDate: Timestamp
  status: 'confirmed' | 'attended' | 'cancelled' | 'noShow'
  userConfirmedAttendance: bool
  attendanceConfirmedAt: Timestamp?
  attendedAt: Timestamp?
  attendedBy: String? (admin que marcó)
  createdAt: Timestamp
}
```

### 7.4 Plan
```dart
{
  name: String
  priceCLP: double
  durationDays: int
  description: String
  classesPerMonth: int? (null = ilimitado)
  active: bool
  displayOrder: int
  createdAt: Timestamp
}
```

---

## 8. Funcionalidades que Funcionan

- Autenticación (email/password)
- Registro de usuarios
- Flujo de aprobación de pagos
- Agenda de clases
- Escaneo QR para marcar asistencia
- Dashboards (alumno y admin)
- Gestión de alumnos (paginada)
- Sistema de planes
- Emails de verificación y reset password

---

## 9. Problemas Conocidos

### 9.1 Notificaciones Push
- **Estado**: Código implementado pero **NO TESTEADAS**
- **Issue**: Falta configurar VAPID key para web
- **Impacto**: No hay confirmación de que las notificaciones lleguen

### 9.2 Emails Redundantes
- Algunos flujos envían múltiples emails innecesarios
- Falta identificar específicamente cuáles

### 9.3 Problemas de Diseño
- Inconsistencias visuales entre pantallas
- No hay sistema de diseño centralizado (aunque existe carpeta `theme/`)
- Algunos widgets duplican código

### 9.4 Arquitectura Inconsistente
- No todos los features siguen la misma estructura
- Falta capa de repository en muchos lugares
- Services acceden directamente a Firestore
- No hay inyección de dependencias formal

---

## 10. Roadmap Futuro

### 10.1 Corto Plazo (Próximas iteraciones)
1. **Validar notificaciones push** (testeo completo)
2. **Eliminar emails redundantes**
3. **Unificar sistema de diseño** (usar carpeta theme/)
4. **Refactorizar arquitectura** hacia Clean Architecture consistente

### 10.2 Mediano Plazo
1. **Pasarela de pagos automática** (Stripe, MercadoPago, Flow)
2. **Sistema de planes robusto** (renovaciones automáticas, recordatorios)
3. **Reportes avanzados** (analytics, gráficos)
4. **Gestión de horarios por admins** (CRUD de schedules desde app)

### 10.3 Largo Plazo
1. **Rol de instructor separado** (no solo admin)
2. **Sistema de gamificación/recompensas**:
   - Metas mensuales (ej: 12 clases → premio físico)
   - Programa de referidos
   - Badges/logros
3. **Integración con redes sociales**
4. **App para instructores** (móvil nativa o versión especializada)
5. **API pública** para integraciones externas

---

## 11. Decisiones de Diseño Detectadas

### 11.1 Por Qué Provider y No Bloc/Riverpod
- **Simplicidad**: Provider es más directo para un MVP
- **Curva de aprendizaje**: Menor para equipos pequeños
- **Suficiente**: Para el alcance actual, Provider cumple

### 11.2 Por Qué Feature-Based Structure
- **Escalabilidad**: Fácil encontrar código relacionado
- **Mantenibilidad**: Cambios aislados por funcionalidad
- **Colaboración**: Múltiples devs pueden trabajar en features separados

### 11.3 Por Qué Firebase
- **Tiempo de desarrollo**: Backend as a Service reduce tiempo
- **Costo inicial**: Plan gratuito generoso
- **Escalabilidad**: Crece con el negocio
- **Realtime**: Firestore permite updates en tiempo real

---

## 12. Métricas y KPIs

### 12.1 KPIs del Negocio (según dashboard admin)
- Asistencias del día
- Clases completadas
- Nuevos alumnos
- Ingresos del día
- Ocupación por clase
- Pagos pendientes
- Membresías por vencer

### 12.2 Métricas Técnicas Recomendadas (futuro)
- Tiempo de carga de pantallas
- Tasa de conversión (registro → matrícula)
- Tasa de retención mensual
- Tasa de asistencia promedio
- Tiempo promedio de aprobación de pagos

---

## 13. Consideraciones de Seguridad

### 13.1 Implementadas
- Firebase Auth para autenticación
- Firestore Security Rules (archivo: `firestore.rules`)
- Storage Rules para comprobantes
- Validación de roles en frontend

### 13.2 Por Mejorar
- Implementar Security Rules más granulares
- Validación de roles en Cloud Functions (backend)
- Rate limiting en operaciones críticas
- Sanitización de inputs en formularios
- Auditoría de accesos (logs)

---

## 14. Testing

### 14.1 Estado Actual
- **Dev dependencies**:
  - `flutter_test`
  - `mockito: 5.4.4`
  - `build_runner: 2.4.13`
  - `fake_cloud_firestore: 3.0.3`
  - `firebase_auth_mocks: 0.14.1`
- **Tests existentes**: Por confirmar (carpeta `test/` en git status)

### 14.2 Recomendaciones
- Unit tests para ViewModels
- Widget tests para pantallas críticas
- Integration tests para flujos completos
- Mocks de Firebase para tests deterministas

---

## 15. CI/CD y Deployment

### 15.1 Archivos Detectados
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`
- `fastlane/Fastfile`
- `scripts/versioning.sh`

### 15.2 Estado
- Configuración CI/CD básica en GitHub Actions
- Fastlane para automatización de builds
- Scripts de versionado
- Por confirmar: deployment automático a stores

---

## 16. Configuración de Entorno

### 16.1 Archivos de Configuración
```
.env                          # Variables de entorno
firebase_options.dart         # Configuración Firebase auto-generada
firestore.rules              # Reglas de seguridad Firestore
firestore.indexes.json       # Índices de Firestore
.secrets.baseline            # Baseline para detección de secretos
```

### 16.2 Variables de Entorno Requeridas
- Firebase config (auto en `firebase_options.dart`)
- Resend API Key (en Firebase Functions)
- VAPID Key (para notificaciones web - pendiente)

---

## 17. Dependencias Clave

### 17.1 Core
- `firebase_core: 3.5.0`
- `firebase_auth: 5.3.1`
- `cloud_firestore: 5.4.4`
- `firebase_storage: 12.3.2`
- `firebase_messaging: 15.1.3`

### 17.2 State Management & Navigation
- `provider: 6.1.5`

### 17.3 UI/UX
- `table_calendar: 3.1.2` (para agendar)
- `qr_flutter: 4.1.0` (generación QR)
- `mobile_scanner: 6.0.2` (escaneo QR)
- `image_picker: 1.1.2` (subir comprobantes)

### 17.4 Utilities
- `intl: 0.20.2` (internacionalización, fechas)
- `http: 1.5.0` (llamadas HTTP)
- `flutter_dotenv: 5.1.0` (variables de entorno)

---

## 18. Próximos Pasos Recomendados

### 18.1 Inmediato (Sprint 1)
1. Testear notificaciones push end-to-end
2. Documentar flujos de emails actuales
3. Identificar y eliminar emails redundantes
4. Crear guía de estilo visual unificada

### 18.2 Corto Plazo (Sprint 2-3)
1. Refactorizar hacia Clean Architecture consistente
2. Implementar repository pattern en todos los features
3. Centralizar manejo de errores
4. Añadir logging estructurado

### 18.3 Mediano Plazo (Mes 2-3)
1. Integrar pasarela de pagos
2. Sistema de renovación automática
3. Dashboard de analytics
4. Sistema de gamificación v1

---

## 19. Contactos y Recursos

### 19.1 Equipo
- **2 Entrenadores**: Acceso admin
- **1 Community Manager**: Acceso admin
- **Developer**: (tú)

### 19.2 Recursos Externos
- Firebase Console: `console.firebase.google.com/project/ayuthaya-camp`
- Resend Dashboard: (configurar)
- GitHub Repo: (por confirmar URL)

---

## 20. Glosario

- **Matrícula**: Pago inicial para activar membresía (enrollment)
- **Mensualidad**: Pago recurrente del plan (monthly)
- **Clase agendada**: Booking confirmado
- **Asistencia confirmada**: Usuario marcó que asistirá/asistió
- **Clase completada**: Admin marcó asistencia o clase terminó
- **Plan ilimitado**: `classesPerMonth = null`
- **VAPID**: Voluntary Application Server Identification (para web push)

---

**Última actualización**: 2026-04-14
**Versión de la app**: 1.0.1+10
**Estado**: Pre-producción (no hay nada en producción aún)
