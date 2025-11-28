# Cambios en Gestión de Alumnos

## 🎯 Problemas Resueltos

### 1. ❌ Problema: Botón "Activar" mostraba modal de planes
**Antes:**
- Al hacer clic en "Activar" en un usuario pendiente, se mostraba un modal para seleccionar planes
- El alumno ya había seleccionado y pagado por un plan
- Esto causaba confusión y duplicación de datos

**✅ Solución:**
- El botón ahora se llama **"Ver Pago"** y redirige al tab de **Pagos**
- Muestra un diálogo explicando al admin que debe ir a Pagos para aprobar
- Al hacer clic en "Ir a Pagos", navega automáticamente al tab de Pagos (índice 2)

---

### 2. ❌ Problema: Faltaba sección "Inactivos"
**Antes:**
- Solo había dos categorías: "Pendientes" y "Activos"
- Los usuarios con plan vencido (`membershipStatus: "inactive"`) no aparecían en ninguna sección

**✅ Solución:**
- Agregado tercer tab: **"Inactivos"**
- Muestra usuarios con `membershipStatus: "inactive"` (plan vencido, no han renovado)
- Tarjeta especial con borde rojo y badge "INACTIVO"
- Muestra la fecha de vencimiento

---

## 📋 Cambios Implementados

### Archivos Modificados:

#### 1. `admin_main_nav_bar.dart`
**Líneas 20-43:**
```dart
// Agregado callback onNavigateToPagos
Widget _buildPage(int index) {
  switch (index) {
    case 1:
      return AdminAlumnosPage(
        onNavigateToPagos: () {
          setState(() {
            _selectedIndex = 2; // Navegar a Pagos
          });
        },
      );
    // ...
  }
}
```

**Qué hace:** Permite que AdminAlumnosPage navegue al tab de Pagos

---

#### 2. `admin_alumnos_page.dart`

##### A. Constructor actualizado (Líneas 4-13)
```dart
class AdminAlumnosPage extends StatefulWidget {
  final VoidCallback onNavigateToPagos;

  const AdminAlumnosPage({
    super.key,
    required this.onNavigateToPagos,
  });
}
```

**Qué hace:** Recibe el callback para navegar a Pagos

---

##### B. Filtro de usuarios inactivos (Líneas 76-82)
```dart
final inactiveUsers = studentUsers
    .where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['membershipStatus'] ?? 'none';
      return status == 'inactive';
    })
    .toList();
```

**Qué hace:** Filtra usuarios con estado "inactive"

---

##### C. Card de estadísticas actualizado (Líneas 89-119)
```dart
Row(
  children: [
    Expanded(child: _buildStatCard('Pendientes', ...)),
    Expanded(child: _buildStatCard('Activos', ...)),
    Expanded(child: _buildStatCard('Inactivos', ...)), // NUEVO
  ],
)
```

**Qué hace:** Muestra contador de usuarios inactivos

---

##### D. Método _goToPagosToActivate (Líneas 246-333)
```dart
void _goToPagosToActivate(Map<String, dynamic> userData) {
  final userName = userData['name'] ?? 'Usuario';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ir a Pagos'),
      content: Column(
        children: [
          Text('El usuario $userName ya ha enviado un pago.'),
          // Instrucciones paso a paso
          Text('1. Ve a la pestaña "Pagos"\n'
               '2. Encuentra el pago de $userName\n'
               '3. Revisa el comprobante\n'
               '4. Aprueba o rechaza el pago'),
        ],
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onNavigateToPagos(); // Navegar a Pagos
          },
          icon: Icon(Icons.payment),
          label: Text('Ir a Pagos'),
        ),
      ],
    ),
  );
}
```

**Qué hace:**
1. Muestra diálogo explicando al admin qué hacer
2. Al hacer clic en "Ir a Pagos", cierra el diálogo y navega al tab de Pagos
3. Ya no selecciona planes ni aprueba directamente

---

##### E. Widget _UserCardWithName actualizado (Líneas 337-673)

**Cambio de parámetro:**
```dart
// ANTES:
final bool isPending;

// DESPUÉS:
final String status; // 'pending', 'active', 'inactive'
```

**Switch para manejar estados:**
```dart
switch (status) {
  case 'pending':
    return _buildPendingCard(name);
  case 'active':
    return _buildActiveCard(name);
  case 'inactive':
    return _buildInactiveCard(name); // NUEVO
}
```

**Botón actualizado:**
```dart
// ANTES:
ElevatedButton(
  child: Text('Activar'),
)

// DESPUÉS:
ElevatedButton.icon(
  icon: Icon(Icons.payment),
  label: Text('Ver Pago'),
)
```

---

##### F. Método _buildInactiveCard (Líneas 589-672)
```dart
Widget _buildInactiveCard(String name) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.red.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.cancel_outlined, color: Colors.red),
        Column(
          children: [
            Text(name),
            Text(email),
            Container(
              child: Text('INACTIVO'), // Badge rojo
            ),
            Text('Venció: $expirationText'),
          ],
        ),
      ],
    ),
  );
}
```

**Qué hace:** Muestra tarjeta especial para usuarios inactivos con:
- Ícono rojo de cancelación
- Badge "INACTIVO" en rojo
- Fecha de vencimiento
- Borde rojo

---

##### G. Sección de usuarios inactivos en el build (Líneas 173-195)
```dart
// Usuarios inactivos
if (inactiveUsers.isNotEmpty) ...[
  const Text('Usuarios Inactivos'),
  ...inactiveUsers.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final email = data['email'] as String?;

    return _UserCardWithName(
      userId: doc.id,
      email: email ?? 'Sin email',
      status: 'inactive',
      expirationDate: data['expirationDate'],
    );
  }).toList(),
],
```

**Qué hace:** Renderiza la lista de usuarios inactivos

---

## 🔄 Flujo Completo Actualizado

### Flujo Anterior (❌ Incorrecto)
```
Usuario pendiente
  ↓
Admin hace clic en "Activar"
  ↓
Modal de selección de planes
  ↓
Admin selecciona plan
  ↓
Usuario activado directamente
```

**Problemas:**
- El usuario ya había pagado por un plan específico
- El admin podía seleccionar un plan diferente
- No se revisaba el comprobante de pago

---

### Flujo Nuevo (✅ Correcto)
```
Usuario pendiente (ya pagó y seleccionó plan)
  ↓
Admin hace clic en "Ver Pago"
  ↓
Diálogo: "Este usuario ya pagó, ve a Pagos"
  ↓
Admin hace clic en "Ir a Pagos"
  ↓
Navega al tab de Pagos
  ↓
Admin encuentra el pago pendiente
  ↓
Admin revisa el comprobante
  ↓
Admin aprueba o rechaza
  ↓
Usuario se activa con el plan que pagó
```

**Ventajas:**
- El admin DEBE revisar el comprobante
- Se respeta el plan que el usuario pagó
- Flujo más claro y correcto

---

## 📊 Estados de Usuario

| Estado | Descripción | Dónde aparece |
|--------|-------------|---------------|
| `none` | Sin membresía | Pendientes |
| `pending` | Esperando aprobación de pago | Pendientes |
| `active` | Membresía activa, puede agendar | Activos |
| `inactive` | Plan vencido, no ha renovado | Inactivos |

---

## 🎨 Cambios Visuales

### Card de Usuario Pendiente
- **Antes:** Botón verde "Activar"
- **Después:** Botón naranja "Ver Pago" con ícono 💳

### Card de Usuario Inactivo (NUEVO)
- Borde rojo
- Ícono rojo de cancelación
- Badge "INACTIVO" en rojo
- Muestra fecha de vencimiento

### Estadísticas
- **Antes:** 2 cards (Pendientes, Activos)
- **Después:** 3 cards (Pendientes, Activos, Inactivos)

---

## 🔍 Cómo Probar

### 1. Probar Usuario Pendiente
1. Registra un nuevo usuario
2. Como ese usuario, paga la matrícula con un plan específico (ej: Plan Premium)
3. Ve al Panel Admin → Alumnos
4. Deberías ver al usuario en "Pendientes" con botón "Ver Pago"
5. Haz clic en "Ver Pago"
6. Verifica que aparezca el diálogo explicativo
7. Haz clic en "Ir a Pagos"
8. Verifica que navegue al tab de Pagos
9. Aprueba el pago
10. Verifica que el usuario ahora aparezca en "Activos" con el plan que pagó

### 2. Probar Usuario Inactivo
1. En Firebase Console → Firestore → users/{userId}
2. Cambia `expirationDate` a una fecha pasada (ej: hace 5 días)
3. Cambia `membershipStatus` a `"inactive"`
4. Recarga el Panel Admin → Alumnos
5. Deberías ver al usuario en "Usuarios Inactivos"
6. Verifica que muestre badge "INACTIVO" y fecha de vencimiento

### 3. Verificar Contador
1. Verifica que los contadores en la parte superior sean correctos:
   - Pendientes: usuarios con status "pending" o "none"
   - Activos: usuarios con status "active"
   - Inactivos: usuarios con status "inactive"

---

## 📝 Notas Importantes

### ⚠️ El método _activateUser fue ELIMINADO
El método completo que permitía activar usuarios directamente fue reemplazado por `_goToPagosToActivate`.

**No se puede:**
- Activar usuarios directamente desde la página de Alumnos
- Seleccionar un plan diferente al que el usuario pagó
- Aprobar sin revisar el comprobante

**Se debe:**
- Ir a la pestaña de Pagos
- Revisar el comprobante
- Aprobar o rechazar el pago desde allí

### ✅ Usuarios Inactivos
Los usuarios inactivos son aquellos que:
- Tuvieron un plan activo anteriormente
- Su fecha de expiración ya pasó
- No han renovado su mensualidad

**Qué hacer con ellos:**
- Deben pagar una nueva mensualidad
- El pago aparecerá en Pagos → Pendientes
- Al aprobar el pago, volverán a estar Activos

---

## 🚀 Resumen de Mejoras

✅ **Flujo correcto:** Admin debe revisar comprobante antes de aprobar
✅ **Se respeta el plan pagado:** No se puede cambiar arbitrariamente
✅ **Navegación automática:** Botón "Ir a Pagos" navega directamente
✅ **Visibilidad de inactivos:** Nueva sección para usuarios con plan vencido
✅ **Mejor UX:** Diálogo explicativo guía al admin
✅ **Código más limpio:** Eliminado método complejo _activateUser
