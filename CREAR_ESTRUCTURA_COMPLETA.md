# Crear Estructura Completa en Firestore

## PASO 1: Actualizar Reglas de Firestore

### 1.1 Abrir Firebase Console
- Ve a https://console.firebase.google.com
- Selecciona tu proyecto
- Ve a **Firestore Database** → **Reglas**

### 1.2 Copiar y Pegar las Reglas Actualizadas
Abre el archivo `firestore.rules` de este proyecto y copia **TODO** el contenido.

Pégalo en Firebase Console, reemplazando todo lo que haya, y haz clic en **Publicar**.

---

## PASO 2: Crear la Escuela Principal

### 2.1 En Firebase Console
1. Ve a **Firestore Database** → **Datos**
2. Clic en **+ Iniciar colección**
3. ID de colección: `schools`
4. ID del documento: `ayutthaya-camp` (exactamente así, sin cambios)
5. Agrega estos campos:

```
name: "Ayutthaya Camp"
active: true
registrationPrice: 30000
createdAt: [timestamp actual - usa el botón de timestamp]
```

6. Clic en **Guardar**

---

## PASO 3: Crear Planes en la Subcolección

### 3.1 Desde el Documento de Escuela
1. Haz clic en el documento `schools/ayutthaya-camp` que acabas de crear
2. Verás un botón **+ Iniciar colección** (dentro del documento)
3. ID de la colección: `planes`

### 3.2 Crear Plan Básico
ID del documento: `plan-basico` (o genera automático)

Campos:
```
name: "Plan Básico"
description: "8 clases al mes"
price: 30000
classes: 8
days: 30
active: true
displayOrder: 1
createdAt: [timestamp]
```

### 3.3 Crear Plan Estándar
ID del documento: `plan-estandar`

Campos:
```
name: "Plan Estándar"
description: "12 clases al mes"
price: 40000
classes: 12
days: 30
active: true
displayOrder: 2
createdAt: [timestamp]
```

### 3.4 Crear Plan Premium
ID del documento: `plan-premium`

Campos:
```
name: "Plan Premium"
description: "20 clases al mes"
price: 50000
classes: 20
days: 30
active: true
displayOrder: 3
createdAt: [timestamp]
```

### 3.5 Crear Plan Ilimitado
ID del documento: `plan-ilimitado`

Campos:
```
name: "Plan Ilimitado"
description: "Clases ilimitadas"
price: 60000
classes: 999
days: 30
active: true
displayOrder: 4
createdAt: [timestamp]
```

---

## PASO 4: Verificar Estructura

Tu estructura en Firestore debe verse así:

```
schools/
  └─ ayutthaya-camp/
      ├─ name: "Ayutthaya Camp"
      ├─ active: true
      ├─ registrationPrice: 30000
      └─ planes/ (subcolección)
          ├─ plan-basico/
          │   ├─ name: "Plan Básico"
          │   ├─ price: 30000
          │   └─ ...
          ├─ plan-estandar/
          ├─ plan-premium/
          └─ plan-ilimitado/
```

---

## PASO 5: Probar la App

1. **Hot Restart** de la app Flutter
2. Ve a la pantalla de **Pagos**
3. Deberías ver los 4 planes disponibles en el combo
4. Ya no debe aparecer el error de permisos

---

## Estructura de Datos para Referencia

### Documento School (schools/ayutthaya-camp)
```typescript
{
  name: string
  active: boolean
  registrationPrice: number
  createdAt: Timestamp
}
```

### Documento Plan (schools/ayutthaya-camp/planes/{planId})
```typescript
{
  name: string
  description: string
  price: number
  classes: number
  days: number
  active: boolean
  displayOrder: number
  createdAt: Timestamp
}
```

---

## Alternativa: Crear desde el Código (Una sola vez)

Si prefieres, puedes agregar temporalmente esta función en tu app y ejecutarla una vez:

```dart
Future<void> _createSchoolAndPlans() async {
  final firestore = FirebaseFirestore.instance;

  // 1. Crear escuela
  await firestore.collection('schools').doc('ayutthaya-camp').set({
    'name': 'Ayutthaya Camp',
    'active': true,
    'registrationPrice': 30000,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // 2. Crear planes
  final planes = [
    {'name': 'Plan Básico', 'description': '8 clases al mes', 'price': 30000, 'classes': 8, 'days': 30, 'displayOrder': 1},
    {'name': 'Plan Estándar', 'description': '12 clases al mes', 'price': 40000, 'classes': 12, 'days': 30, 'displayOrder': 2},
    {'name': 'Plan Premium', 'description': '20 clases al mes', 'price': 50000, 'classes': 20, 'days': 30, 'displayOrder': 3},
    {'name': 'Plan Ilimitado', 'description': 'Clases ilimitadas', 'price': 60000, 'classes': 999, 'days': 30, 'displayOrder': 4},
  ];

  for (var plan in planes) {
    await firestore.collection('schools').doc('ayutthaya-camp').collection('planes').add({
      ...plan,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
```
