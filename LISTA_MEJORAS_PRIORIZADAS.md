# Lista Priorizada de Mejoras - Ayutthaya Camp App

## Matriz de Priorización

Cada mejora está clasificada según:
- **Impacto**: Alto (🔴), Medio (🟡), Bajo (🟢)
- **Urgencia**: Crítica (⚠️), Alta (🔥), Media (⏱️), Baja (📅)
- **Esfuerzo**: Bajo (1-2 días), Medio (3-5 días), Alto (1-2 semanas), Muy Alto (>2 semanas)
- **Prioridad**: P0 (crítica), P1 (alta), P2 (media), P3 (baja)

---

## P0 - CRÍTICO (Hacer AHORA)

### 1. Validar Notificaciones Push End-to-End
**Impacto**: 🔴 Alto | **Urgencia**: ⚠️ Crítica | **Esfuerzo**: Medio (3-5 días)

**Problema actual:**
- Código de notificaciones implementado pero **NO TESTEADO**
- No hay confirmación de que las notificaciones lleguen a los dispositivos
- Falta VAPID key configurada para web
- Posibles issues en producción que no se detectarán hasta que usuarios se quejen

**Solución:**
```yaml
1. Configurar VAPID key en Firebase Console
2. Testear en iOS (APNs)
3. Testear en Android (FCM)
4. Testear en Web (con HTTPS)
5. Verificar notificaciones de:
   - Nuevo usuario registrado → Admin
   - Pago aprobado → Usuario
   - Recordatorio de clase → Usuario
6. Documentar troubleshooting
```

**Archivos a revisar:**
- `lib/core/services/notification_service.dart`
- `functions/index.js` (Cloud Functions)

**Resultado esperado:**
- ✅ Notificaciones funcionando en iOS, Android y Web
- ✅ Documentación de troubleshooting
- ✅ Monitoreo de errores de notificaciones

---

### 2. Auditar y Eliminar Emails Redundantes
**Impacto**: 🟡 Medio | **Urgencia**: 🔥 Alta | **Esfuerzo**: Bajo (1-2 días)

**Problema actual:**
- Se mencionó que "hay emails redundantes"
- No está claro cuáles son exactamente
- Posible spam a usuarios

**Solución:**
```yaml
1. Mapear todos los eventos que disparan emails:
   - Registro → email de verificación
   - Reset password → email de recuperación
   - ¿Otros?
2. Identificar duplicados o innecesarios
3. Configurar preferencias de notificación por usuario
4. Implementar debouncing para evitar spam
```

**Archivos a revisar:**
- `functions/index.js` (sendVerificationEmail, sendPasswordResetEmail)
- `lib/core/services/auth_email_service.dart`
- `lib/features/auth/presentation/viewmodels/auth_viewmodel.dart`

**Resultado esperado:**
- ✅ Documento con flujo de emails actual
- ✅ Lista de emails a eliminar/consolidar
- ✅ Implementación de preferencias de usuario

---

### 3. Implementar Manejo de Errores Centralizado
**Impacto**: 🔴 Alto | **Urgencia**: 🔥 Alta | **Esfuerzo**: Bajo (1-2 días)

**Problema actual:**
- Errores manejados inconsistentemente
- Mensajes de error poco claros para usuarios
- Difícil debuggear problemas en producción

**Solución:**
```dart
// lib/core/error/error_handler.dart
class ErrorHandler {
  static void handle(dynamic error, StackTrace? stackTrace) {
    // Log error
    AppLogger.error('Error occurred', error, stackTrace);

    // Report to Crashlytics
    FirebaseCrashlytics.instance.recordError(error, stackTrace);

    // Show user-friendly message
    return _getUserMessage(error);
  }

  static String _getUserMessage(dynamic error) {
    if (error is FirebaseException) {
      return _getFirebaseErrorMessage(error.code);
    }
    if (error is SocketException) {
      return 'Sin conexión a internet';
    }
    return 'Error inesperado. Contacta soporte.';
  }
}
```

**Resultado esperado:**
- ✅ Manejo de errores consistente en toda la app
- ✅ Mensajes claros para usuarios
- ✅ Logging para debuggear

---

## P1 - ALTA PRIORIDAD (Próximos 2 sprints)

### 4. Unificar Sistema de Diseño
**Impacto**: 🔴 Alto | **Urgencia**: ⏱️ Media | **Esfuerzo**: Medio (3-5 días)

**Problema actual:**
- Carpeta `theme/` existe pero no se usa consistentemente
- Widgets duplicados con estilos hardcodeados
- Inconsistencias visuales entre pantallas

**Solución:**
```yaml
1. Consolidar `lib/theme/` en `lib/core/theme/`
2. Crear widgets atómicos reutilizables:
   - AppButton (con variantes primary, secondary, outline, danger)
   - AppTextField
   - AppCard
   - AppLoadingIndicator
   - AppErrorMessage
3. Aplicar en todas las pantallas existentes
4. Documentar en Storybook o similar
```

**Archivos a crear:**
```
lib/core/theme/
├── app_theme.dart (ThemeData consolidado)
├── app_colors.dart (ya existe, revisar)
├── app_text_styles.dart (ya existe, revisar)
├── app_spacing.dart (ya existe, revisar)
└── app_animations.dart (ya existe, revisar)

lib/core/widgets/atoms/
├── app_button.dart
├── app_text_field.dart
├── app_card.dart
├── app_loading_indicator.dart
└── app_error_message.dart
```

**Resultado esperado:**
- ✅ Sistema de diseño centralizado y documentado
- ✅ Widgets reutilizables en producción
- ✅ Reducción de código duplicado en 30%+

---

### 5. Refactorizar Auth hacia Clean Architecture
**Impacto**: 🔴 Alto | **Urgencia**: ⏱️ Media | **Esfuerzo**: Alto (1-2 semanas)

**Problema actual:**
- `AuthViewModel` tiene lógica de negocio mezclada con UI logic
- Acceso directo a Firebase desde ViewModel
- Difícil de testear

**Solución:**
Seguir estructura de Clean Architecture (ver PROPUESTA_ARQUITECTURAL.md):
```yaml
1. Crear entities (UserEntity)
2. Crear repository interface (AuthRepository)
3. Crear use cases (LoginUser, RegisterUser, LogoutUser)
4. Crear data sources (AuthRemoteDataSource, AuthLocalDataSource)
5. Crear models (UserModel extends UserEntity)
6. Implementar repository (AuthRepositoryImpl)
7. Refactorizar ViewModel (usar use cases)
8. Setup DI con GetIt
9. Escribir tests unitarios
```

**Resultado esperado:**
- ✅ Auth con Clean Architecture completa
- ✅ Tests unitarios > 80% coverage
- ✅ Patrón replicable para otros features

---

### 6. Implementar Caché Local con Hive
**Impacto**: 🟡 Medio | **Urgencia**: ⏱️ Media | **Esfuerzo**: Medio (3-5 días)

**Problema actual:**
- Cada vez que se abre la app, se carga todo desde Firestore
- Experiencia lenta en conexiones malas
- Gasto innecesario de reads de Firestore

**Solución:**
```yaml
1. Agregar Hive como dependencia
2. Crear LocalDataSources para:
   - User (última sesión)
   - Bookings (clases agendadas)
   - Payments (últimos pagos)
   - Plans (lista de planes)
3. Implementar estrategia cache-first con fallback a network
4. Sync en background cuando hay cambios
```

**Resultado esperado:**
- ✅ App funciona offline (modo lectura)
- ✅ Startup time < 1 segundo
- ✅ Reducción de 50% en Firestore reads

---

### 7. Optimizar Queries de Firestore
**Impacto**: 🟡 Medio | **Urgencia**: ⏱️ Media | **Esfuerzo**: Bajo (1-2 días)

**Problema actual:**
- Algunos queries cargan más datos de los necesarios
- Falta paginación en algunas listas
- No hay índices compuestos optimizados

**Solución:**
```yaml
1. Auditar todos los queries de Firestore:
   - Admin dashboard: agregar .limit(100)
   - Bookings: filtrar por fecha antes de cargar
   - Payments: paginar de 20 en 20
2. Crear índices compuestos en firestore.indexes.json
3. Usar .select() para traer solo campos necesarios
4. Implementar infinite scroll en listas largas
```

**Archivos a revisar:**
- `firestore.indexes.json`
- `lib/features/*/services/*.dart`

**Resultado esperado:**
- ✅ Queries 50% más rápidos
- ✅ Reducción de reads de Firestore en 30%
- ✅ Listas paginadas en todos lados

---

## P2 - MEDIA PRIORIDAD (Mes 2-3)

### 8. Migrar Bookings y Payments a Clean Architecture
**Impacto**: 🔴 Alto | **Urgencia**: 📅 Baja | **Esfuerzo**: Muy Alto (>2 semanas)

**Problema actual:**
- Mismos problemas que Auth (ver mejora #5)
- Features críticos del negocio

**Solución:**
Replicar estructura de Auth (ver PROPUESTA_ARQUITECTURAL.md FASE 3)

**Resultado esperado:**
- ✅ Bookings con Clean Architecture
- ✅ Payments con Clean Architecture
- ✅ Tests > 80% coverage en ambos

---

### 9. Implementar Analytics y Tracking
**Impacto**: 🟡 Medio | **Urgencia**: 📅 Baja | **Esfuerzo**: Medio (3-5 días)

**Problema actual:**
- No hay tracking de eventos
- No sabemos cómo usan la app los usuarios
- No hay datos para tomar decisiones

**Solución:**
```yaml
1. Configurar Firebase Analytics
2. Implementar eventos clave:
   - user_register
   - user_login
   - class_booked
   - payment_submitted
   - payment_approved
   - class_attended
3. Dashboards en Firebase Console
4. Alertas para eventos críticos
```

**Resultado esperado:**
- ✅ Tracking de eventos en producción
- ✅ Dashboard de analytics
- ✅ Decisiones basadas en datos

---

### 10. Crear Automated Tests (E2E)
**Impacto**: 🔴 Alto | **Urgencia**: 📅 Baja | **Esfuerzo**: Alto (1-2 semanas)

**Problema actual:**
- Solo tests unitarios (cuando los hay)
- No hay tests de integración
- Regresiones frecuentes

**Solución:**
```yaml
1. Setup Patrol o Integration Test framework
2. Tests críticos:
   - Flujo de registro completo
   - Flujo de matrícula
   - Flujo de agendamiento de clase
   - Flujo de aprobación de pago (admin)
3. Integrar en CI/CD
```

**Resultado esperado:**
- ✅ 10+ tests E2E críticos
- ✅ CI/CD ejecuta tests antes de deploy
- ✅ Reducción de bugs en producción

---

### 11. Implementar Feature Flags
**Impacto**: 🟡 Medio | **Urgencia**: 📅 Baja | **Esfuerzo**: Bajo (1-2 días)

**Problema actual:**
- No podemos desplegar features parcialmente
- Difícil rollback si algo sale mal
- Testing en producción riesgoso

**Solución:**
```yaml
1. Usar Firebase Remote Config
2. Flags críticos:
   - enable_notifications
   - enable_payments_integration
   - enable_new_dashboard
   - maintenance_mode
3. Dashboard para toggles
```

**Resultado esperado:**
- ✅ Despliegue gradual de features
- ✅ Rollback instantáneo sin redeploy
- ✅ A/B testing capabilities

---

## P3 - BAJA PRIORIDAD (Mes 4+)

### 12. Migrar a Pasarela de Pagos Automática
**Impacto**: 🔴 Alto | **Urgencia**: 📅 Baja | **Esfuerzo**: Muy Alto (>2 semanas)

**Problema actual:**
- Pagos manuales (subir comprobante)
- Admin debe aprobar manualmente
- Fricción en proceso de matrícula

**Solución:**
```yaml
1. Investigar pasarelas para Chile:
   - Flow (recomendado para Chile)
   - Mercado Pago
   - Stripe
2. Implementar integración
3. Mantener opción manual como fallback
4. Notificaciones automáticas de pago exitoso
```

**Resultado esperado:**
- ✅ Pagos automáticos en producción
- ✅ Reducción de tiempo de aprobación de 24h → 1 minuto
- ✅ Tasa de conversión +20%

---

### 13. Sistema de Gamificación/Recompensas
**Impacto**: 🟡 Medio | **Urgencia**: 📅 Baja | **Esfuerzo**: Alto (1-2 semanas)

**Problema actual:**
- No hay incentivos para asistencia regular
- Falta engagement de usuarios

**Solución:**
```yaml
1. Definir sistema de puntos:
   - 10 puntos por asistencia confirmada
   - 50 puntos por referido exitoso
   - Bonus por racha (ej: 5 días seguidos)
2. Recompensas físicas:
   - 100 puntos → Vendas gratis
   - 500 puntos → Clase privada
   - 1000 puntos → Mes gratis
3. UI: Pantalla de recompensas + progreso
4. Notificaciones de logros
```

**Resultado esperado:**
- ✅ Sistema de puntos en producción
- ✅ Aumento de asistencia promedio +15%
- ✅ Tasa de retención +10%

---

### 14. Rol de Instructor Separado
**Impacto**: 🟡 Medio | **Urgencia**: 📅 Baja | **Esfuerzo**: Medio (3-5 días)

**Problema actual:**
- Solo existen roles 'admin' y 'student'
- Instructores no tienen vista específica

**Solución:**
```yaml
1. Crear rol 'instructor' en Firestore
2. Vista de instructor:
   - Sus clases del día
   - Lista de alumnos inscritos
   - Marcar asistencias rápido
3. Permisos granulares (solo sus clases)
```

**Resultado esperado:**
- ✅ Rol instructor en producción
- ✅ App específica para instructores
- ✅ Reducción de carga en admins

---

### 15. Dashboard de Reportes Avanzados
**Impacto**: 🟡 Medio | **Urgencia**: 📅 Baja | **Esfuerzo**: Alto (1-2 semanas)

**Problema actual:**
- Dashboard actual es básico
- No hay gráficos ni tendencias
- Difícil tomar decisiones estratégicas

**Solución:**
```yaml
1. Agregar gráficos:
   - Asistencia por semana (línea)
   - Ingresos por mes (barras)
   - Tasa de retención (porcentaje)
   - Clases más populares (pie chart)
2. Filtros por fecha, instructor, tipo de clase
3. Export a PDF/Excel
4. Envío automático por email (semanal)
```

**Resultado esperado:**
- ✅ Dashboard con gráficos interactivos
- ✅ Reportes exportables
- ✅ Decisiones basadas en datos

---

## Resumen por Prioridad

| Prioridad | # Mejoras | Esfuerzo Total | Impacto Esperado |
|-----------|-----------|----------------|------------------|
| **P0** | 3 | ~2 semanas | Crítico - Estabilidad y UX |
| **P1** | 4 | ~4-5 semanas | Alto - Arquitectura y Performance |
| **P2** | 4 | ~6-7 semanas | Medio - Testing y Analytics |
| **P3** | 5 | ~8-10 semanas | Baja - Features avanzados |

**Total**: 16 mejoras | ~20-24 semanas de trabajo

---

## Roadmap Visual

```
Sprint 1-2:  [P0] Notificaciones + Emails + Errores
             ▓▓▓▓▓▓▓▓▓▓ (Crítico)

Sprint 3-4:  [P1] Sistema Diseño + Auth Clean Arch
             ▓▓▓▓▓▓▓▓▓▓ (Alta)

Sprint 5-6:  [P1] Caché Local + Optimización Queries
             ▓▓▓▓▓▓▓▓▓▓ (Alta)

Sprint 7-8:  [P2] Bookings/Payments Clean Arch
             ░░░░░░░░░░ (Media)

Sprint 9-10: [P2] Analytics + E2E Tests
             ░░░░░░░░░░ (Media)

Sprint 11+:  [P3] Pasarela Pagos + Gamificación
             ░░░░░░░░░░ (Baja)
```

---

## Criterios de Éxito Generales

### Técnicos
- ✅ Code coverage > 80%
- ✅ Flutter analyze 0 warnings
- ✅ Build time < 3 minutos
- ✅ App size < 50MB
- ✅ Crash rate < 0.5%

### Negocio
- ✅ Tiempo aprobación pagos < 1 hora (desde 24h)
- ✅ Tasa conversión registro→matrícula > 60%
- ✅ Tasa asistencia promedio > 70%
- ✅ NPS > 50
- ✅ MAU (Monthly Active Users) +25%

### UX
- ✅ Startup time < 2 segundos
- ✅ Tiempo agendar clase < 30 segundos
- ✅ Confirmación pago < 5 minutos
- ✅ 0 quejas de emails spam
- ✅ 0 quejas de notificaciones no recibidas

---

## Notas Finales

### Flexibilidad
Este roadmap es **flexible** y debe ajustarse según:
- Feedback de usuarios
- Nuevas prioridades de negocio
- Recursos disponibles
- Métricas de uso real

### Incremental
**No intentar hacer todo a la vez**. Cada mejora debe:
1. Ser deployable independientemente
2. Incluir tests
3. Tener rollback plan
4. Medirse con métricas

### Comunicación
Mantener a todos los stakeholders informados:
- **Entrenadores**: Qué mejoras les afectan
- **Community Manager**: Cómo comunicar a usuarios
- **Equipo dev**: Cambios arquitecturales

---

**Última actualización**: 2026-04-14
**Versión**: 1.0
**Próxima revisión**: Al terminar Sprint 2 (reevaluar prioridades)
