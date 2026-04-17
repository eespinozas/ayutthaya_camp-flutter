# ✅ Fixes Críticos Implementados - FASE 1

**Fecha:** 10 de Abril, 2026
**Tiempo de implementación:** ~2 horas
**Estado:** ✅ COMPLETADO

---

## 📋 Resumen

Se implementaron **4 fixes críticos** para prevenir pérdida de ingresos y mejorar la experiencia del usuario:

| # | Fix | Estado | Impacto |
|---|-----|--------|---------|
| 1 | Validar membershipStatus en QR | ✅ | Previene entrenamientos gratis |
| 2 | Validar límite de clases/mes | ✅ | Respeta límites del plan |
| 3 | Notificar rechazo al usuario | ✅ | Usuario sabe si pago rechazado |
| 4 | Validar matrícula (1 año) | ✅ | Solo renueva después de 1 año |

---

## 📂 Archivos Modificados (3)

### 1. ✅ `lib/core/config/app_constants.dart` (NUEVO)
**Líneas:** 58 líneas nuevas
**Propósito:** Centralizar constantes configurables

```dart
class BookingConstants {
  static const int checkInWindowMinutes = 20;
  static const int minHoursToCancelBooking = 24;
  // ... más constantes
}

class MembershipConstants {
  static const bool requireActiveMembershipForQR = true;
  static const bool enforcePlanLimits = true;
  static const int minDaysForRenewEnrollment = 365; // 1 año
  // ... más constantes
}

class AppMessages {
  static const String membershipNone = '...';
  static const String membershipPending = '...';
  static const String membershipInactive = '...';
}
```

**Beneficio:**
- ✅ Fácil ajustar configuraciones sin tocar código
- ✅ Mensajes consistentes en toda la app
- ✅ Un solo lugar para cambiar comportamiento

---

### 2. ✅ `lib/features/bookings/services/booking_service.dart`
**Cambios:** ~90 líneas agregadas
**Métodos modificados:**
- `processQRCheckIn()` - Agregadas validaciones
- `_getMembershipBlockMessage()` - NUEVO método helper
- `_getAttendedClassesThisMonth()` - NUEVO método helper

#### Fix #1 y #2: Validaciones en QR Check-in

**Código agregado al inicio de `processQRCheckIn()`:**

```dart
// ✅ FIX #1: Validar membresía activa
if (MembershipConstants.requireActiveMembershipForQR) {
  final userDoc = await _firestore.collection('users').doc(userId).get();

  if (!userDoc.exists) {
    return {'success': false, 'message': 'Usuario no encontrado'};
  }

  final userData = userDoc.data()!;
  final membershipStatus = userData['membershipStatus'] ?? 'none';

  // Bloquear si NO es 'active'
  if (membershipStatus != 'active') {
    return {
      'success': false,
      'message': _getMembershipBlockMessage(membershipStatus),
      'action': 'membership_required',
      'membershipStatus': membershipStatus,
    };
  }

  // ✅ FIX #2: Validar límite de clases del plan
  if (MembershipConstants.enforcePlanLimits) {
    final plan = userData['plan'];
    if (plan != null && plan['classesPerMonth'] != null) {
      final classesThisMonth = await _getAttendedClassesThisMonth(userId);
      final limit = plan['classesPerMonth'] as int;

      if (classesThisMonth >= limit) {
        return {
          'success': false,
          'message': 'Has alcanzado tu límite de $limit clases este mes.\n\n'
              'Actualiza tu plan para continuar entrenando.',
          'action': 'limit_reached',
          'classesUsed': classesThisMonth,
          'classesLimit': limit,
        };
      }
    }
  }
}

// Continuar con lógica original de detectar clase activa...
```

**Mensajes personalizados según estado:**

```dart
String _getMembershipBlockMessage(String status) {
  switch (status) {
    case 'none':
      return 'Debes matricularte primero para acceder a las clases.\n\n'
             'Ve a la sección "Pagos" para subir tu comprobante de matrícula.';

    case 'pending':
      return 'Tu pago de matrícula está en revisión.\n\n'
             'Por favor espera la aprobación del administrador.';

    case 'inactive':
      return 'Tu membresía ha vencido.\n\n'
             'Por favor renueva tu plan en la sección "Pagos".';

    default:
      return 'No tienes una membresía activa.';
  }
}
```

**Contar clases del mes:**

```dart
Future<int> _getAttendedClassesThisMonth(String userId) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final snapshot = await _firestore
      .collection('bookings')
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: BookingStatus.attended.name)
      .where('classDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .where('classDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
      .get();

  return snapshot.docs.length;
}
```

---

### 3. ✅ `lib/features/payments/services/payment_service.dart`
**Cambios:** ~120 líneas modificadas
**Métodos modificados:**
- `rejectPayment()` - Agregada notificación al usuario
- `_checkDuplicatePayment()` - Refactorizado completamente

#### Fix #3: Notificar Rechazo al Usuario

**Código agregado en `rejectPayment()`:**

```dart
Future<void> rejectPayment(String paymentId, String adminId, String reason) async {
  try {
    // Obtener datos del pago antes de actualizar
    final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
    final paymentData = paymentDoc.data();

    if (paymentData == null) {
      throw Exception('Pago no encontrado');
    }

    // Actualizar estado del pago
    await _firestore.collection('payments').doc(paymentId).update({
      'status': PaymentStatus.rejected.name,
      'rejectionReason': reason,
      'reviewedBy': adminId,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    // ✅ FIX #3: Notificar al usuario del rechazo
    if (MembershipConstants.notifyUserOnPaymentRejection) {
      final userId = paymentData['userId'] as String;
      final paymentType = paymentData['type'] as String;
      final paymentTypeText = paymentType == 'enrollment' ? 'matrícula' : 'mensualidad';

      await NotificationService().sendNotificationToUser(
        userId: userId,
        title: '❌ Pago Rechazado',
        body: 'Tu comprobante de $paymentTypeText ha sido rechazado.\n\n'
            'Motivo: $reason\n\n'
            'Por favor sube un nuevo comprobante válido.',
        data: {
          'type': 'payment_rejected',
          'paymentId': paymentId,
          'reason': reason,
          'paymentType': paymentType,
        },
      );

      debugPrint('✅ Usuario notificado del rechazo: $userId');
    }
  } catch (e) {
    debugPrint('❌ Error al rechazar pago: $e');
    throw Exception('Error al rechazar pago: $e');
  }
}
```

**Beneficio:**
- ✅ Usuario recibe notificación push inmediata
- ✅ Sabe exactamente por qué fue rechazado
- ✅ Puede subir nuevo comprobante sin esperar

---

#### Fix #4: Validar Matrícula (1 año)

**Código refactorizado en `_checkDuplicatePayment()`:**

```dart
Future<Map<String, dynamic>> _checkDuplicatePayment(String userId, PaymentType type) async {
  try {
    final now = DateTime.now();

    // ✅ FIX #4: Para MATRÍCULA, validar membresía activa y fecha
    if (type == PaymentType.enrollment) {
      debugPrint('🔍 Verificando condiciones para nueva matrícula...');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final membershipStatus = userData['membershipStatus'] ?? 'none';

        // 1. Si tiene membresía activa, bloquear
        if (membershipStatus == 'active') {
          return {
            'allowed': false,
            'message': 'Ya tienes una membresía activa.\n\n'
                'Para extender tu plan, realiza un pago de mensualidad.',
          };
        }

        // 2. Si tiene pago pendiente, bloquear
        if (membershipStatus == 'pending') {
          return {
            'allowed': false,
            'message': 'Ya tienes un pago de matrícula pendiente.\n\n'
                'Espera la revisión del administrador.',
          };
        }

        // 3. Verificar fecha de última matrícula (365 días)
        final enrollmentDate = userData['enrollmentDate'] as Timestamp?;
        if (enrollmentDate != null) {
          final lastEnrollment = enrollmentDate.toDate();
          final daysSinceEnrollment = now.difference(lastEnrollment).inDays;

          if (daysSinceEnrollment < MembershipConstants.minDaysForRenewEnrollment) {
            final daysRemaining = MembershipConstants.minDaysForRenewEnrollment - daysSinceEnrollment;
            return {
              'allowed': false,
              'message': 'Solo puedes renovar tu matrícula después de 1 año.\n\n'
                  'Tu última matrícula fue el ${lastEnrollment.day}/${lastEnrollment.month}/${lastEnrollment.year}.\n'
                  'Podrás renovar en $daysRemaining días.',
            };
          }
        }
      }

      return {'allowed': true};
    }

    // Para MENSUALIDAD: lógica original (1 por mes)
    // ... código existente
  }
}
```

**Validaciones implementadas:**

| Condición | Acción |
|-----------|--------|
| `membershipStatus == 'active'` | ❌ Bloquear - "Paga mensualidad, no matrícula" |
| `membershipStatus == 'pending'` | ❌ Bloquear - "Ya tienes pago pendiente" |
| Última matrícula < 365 días | ❌ Bloquear - "Espera X días" |
| Última matrícula ≥ 365 días | ✅ Permitir renovar |
| Nunca se matriculó | ✅ Permitir primera matrícula |

---

## 🧪 Casos de Prueba

### Test 1: QR sin Membresía

**Escenario:**
```
Usuario con membershipStatus: 'none'
Escanea QR del gym
```

**Resultado esperado:**
```json
{
  "success": false,
  "message": "Debes matricularte primero para acceder a las clases.\n\nVe a la sección \"Pagos\" para subir tu comprobante de matrícula.",
  "action": "membership_required",
  "membershipStatus": "none"
}
```

**Cómo probar:**
1. Crea usuario nuevo (automáticamente tiene `membershipStatus: 'none'`)
2. NO pagues matrícula
3. Escanea QR en `AgendasPage`
4. ✅ Debe bloquear con mensaje claro

---

### Test 2: Límite de Clases

**Escenario:**
```
Usuario con plan: "8 clases/mes"
Ya asistió a 8 clases este mes
Intenta escanear QR para clase 9
```

**Resultado esperado:**
```json
{
  "success": false,
  "message": "Has alcanzado tu límite de 8 clases este mes.\n\nActualiza tu plan para continuar entrenando.",
  "action": "limit_reached",
  "classesUsed": 8,
  "classesLimit": 8
}
```

**Cómo probar:**
1. En Firestore, asigna plan al usuario:
   ```json
   {
     "plan": {
       "name": "8 Clases",
       "classesPerMonth": 8
     }
   }
   ```
2. Crea 8 bookings con `status: 'attended'` para este mes
3. Escanea QR
4. ✅ Debe bloquear con mensaje de límite

---

### Test 3: Notificación de Rechazo

**Escenario:**
```
Usuario sube comprobante de pago
Admin rechaza con motivo: "Comprobante ilegible"
```

**Resultado esperado:**
- ✅ Pago actualizado a `status: 'rejected'`
- ✅ Usuario recibe notificación push
- ✅ Título: "❌ Pago Rechazado"
- ✅ Cuerpo incluye motivo: "Comprobante ilegible"

**Cómo probar:**
1. Usuario sube pago (PagosPage)
2. Admin va a AdminPagosPage
3. Click "Rechazar" con motivo
4. ✅ Verificar en Firebase Console que se creó documento en `notifications/`
5. ✅ Usuario recibe notificación (si Cloud Functions desplegadas)

---

### Test 4: Doble Matrícula (Bloqueada)

**Escenario A:** Usuario con membresía activa
```
Usuario tiene membershipStatus: 'active'
Intenta pagar matrícula nuevamente
```

**Resultado esperado:**
```
Error: "Ya tienes una membresía activa.
Para extender tu plan, realiza un pago de mensualidad."
```

**Escenario B:** Renovar antes de 1 año
```
Usuario se matriculó el 15/01/2026
Hoy es 15/06/2026 (6 meses después)
Intenta pagar matrícula
```

**Resultado esperado:**
```
Error: "Solo puedes renovar tu matrícula después de 1 año.
Tu última matrícula fue el 15/1/2026.
Podrás renovar en 184 días."
```

**Escenario C:** Renovar después de 1 año ✅
```
Usuario se matriculó el 15/01/2025
Hoy es 20/01/2026 (370 días después)
Intenta pagar matrícula
```

**Resultado esperado:**
```
✅ Permite crear pago de matrícula
```

**Cómo probar:**
1. En Firebase Console, modificar `enrollmentDate` del usuario
2. Intentar crear pago de matrícula en app
3. Verificar mensaje correcto según escenario

---

## 📊 Impacto de los Fixes

### Antes de los Fixes ❌

```
Escenario 1: Usuario sin pagar
├─ Se registra → membershipStatus: 'none'
├─ Va al gym
├─ Escanea QR
└─ ✅ Entra y entrena GRATIS 💸 PÉRDIDA DE INGRESOS

Escenario 2: Usuario con plan "8 clases"
├─ Ya asistió 8 veces este mes
├─ Escanea QR clase 9, 10, 11...
└─ ✅ Permite sin límite 📈 EXCEDE PLAN

Escenario 3: Pago rechazado
├─ Admin rechaza comprobante
└─ ❌ Usuario NO se entera 😕 MALA UX

Escenario 4: Doble matrícula
├─ Usuario paga matrícula
├─ Admin aprueba → active
├─ Usuario paga matrícula otra vez
└─ ✅ Permite crear pago 🔄 CONFUSIÓN
```

### Después de los Fixes ✅

```
Escenario 1: Usuario sin pagar
├─ Se registra → membershipStatus: 'none'
├─ Va al gym
├─ Escanea QR
└─ ❌ Bloqueado: "Debes matricularte" ✅ PREVIENE PÉRDIDA

Escenario 2: Usuario con plan "8 clases"
├─ Ya asistió 8 veces este mes
├─ Escanea QR clase 9
└─ ❌ Bloqueado: "Límite alcanzado" ✅ RESPETA PLAN

Escenario 3: Pago rechazado
├─ Admin rechaza comprobante
└─ ✅ Notificación: "Rechazado - Motivo: X" ✅ BUENA UX

Escenario 4: Doble matrícula
├─ Usuario paga matrícula
├─ Admin aprueba → active
├─ Usuario intenta pagar matrícula
└─ ❌ Bloqueado: "Ya tienes membresía" ✅ PREVIENE CONFUSIÓN
```

---

## 🎯 Próximos Pasos Recomendados

### 1. Testing Inmediato (Hoy)
```bash
✅ Probar los 4 escenarios de prueba arriba
✅ Verificar que las notificaciones se crean en Firestore
✅ Probar con diferentes estados de membresía
```

### 2. Desplegar Cloud Functions (Para que notificaciones funcionen)
```bash
cd functions
firebase deploy --only functions
```

### 3. FASE 2 - Nuevas Funcionalidades (Cuando quieras)
```
⏳ Cancelar booking (hasta 24h antes)
⏳ Botón "Confirmar de inmediato" al reservar
⏳ Auto no-show (Cloud Function)
⏳ Estado 'pending' para bookings
```

---

## 📞 Soporte

Si encuentras algún problema con los fixes:

1. **Revisa Firebase Console:**
   - Collection `users` → Verifica `membershipStatus`
   - Collection `bookings` → Verifica clases del mes
   - Collection `notifications` → Verifica notificaciones creadas

2. **Revisa logs de Flutter:**
   ```bash
   flutter run
   # Busca líneas con:
   # "✅ Clases usadas este mes: X/Y"
   # "❌ Usuario notificado del rechazo"
   # "🔍 Verificando condiciones para nueva matrícula"
   ```

3. **Ajusta configuración:**
   - Edita `lib/core/config/app_constants.dart`
   - Cambia constantes según necesites

---

## ✅ Checklist de Implementación

- [x] Crear `lib/core/config/app_constants.dart`
- [x] Agregar validación de membershipStatus en QR
- [x] Agregar validación de límite de clases
- [x] Agregar notificación de rechazo
- [x] Refactorizar validación de matrícula (1 año)
- [x] Agregar métodos helper necesarios
- [x] Documentar cambios
- [ ] Testing manual de los 4 escenarios
- [ ] Desplegar Cloud Functions (para notificaciones)

---

**Implementado por:** Flutter Architect Agent
**Fecha:** 10 de Abril, 2026
**Versión:** 1.0 - FASE 1 Completada ✅
