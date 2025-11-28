# Crear Índices de Firestore - Paso a Paso

## 🎯 Instrucciones para crear índices manualmente

### Paso 1: Abrir Firebase Console
1. Ve a: https://console.firebase.google.com/
2. Selecciona tu proyecto de Ayutthaya Camp
3. En el menú lateral izquierdo, busca **"Firestore Database"**
4. Haz clic en **"Firestore Database"**

### Paso 2: Ir a la pestaña de Índices
1. En la parte superior verás varias pestañas: Data, Rules, Indexes, Usage
2. Haz clic en la pestaña **"Indexes"**
3. Verás dos sub-pestañas: "Composite" y "Single field"
4. Asegúrate de estar en **"Composite"**

---

## 📋 ÍNDICE 1: Historial de pagos del usuario

**Haz clic en el botón "Create Index"** y completa:

```
Collection ID:          payments
Query scope:            Collection

Fields to index:
  Field path      Index type      Array config
  ─────────────────────────────────────────────
  userId          Ascending       (vacío)
  createdAt       Descending      (vacío)
```

**Valores exactos:**
- Collection ID: `payments`
- Campo 1: `userId` → Ascending
- Campo 2: `createdAt` → Descending

Haz clic en **"Create"**. Verás un mensaje "Index is being built..."

---

## 📋 ÍNDICE 2: Filtrar pagos por estado (admin)

**Haz clic en "Create Index" nuevamente** y completa:

```
Collection ID:          payments
Query scope:            Collection

Fields to index:
  Field path      Index type      Array config
  ─────────────────────────────────────────────
  status          Ascending       (vacío)
  createdAt       Descending      (vacío)
```

**Valores exactos:**
- Collection ID: `payments`
- Campo 1: `status` → Ascending
- Campo 2: `createdAt` → Descending

Haz clic en **"Create"**

---

## 📋 ÍNDICE 3: Verificar matrícula aprobada

**Haz clic en "Create Index" nuevamente** y completa:

```
Collection ID:          payments
Query scope:            Collection

Fields to index:
  Field path      Index type      Array config
  ─────────────────────────────────────────────
  userId          Ascending       (vacío)
  type            Ascending       (vacío)
  status          Ascending       (vacío)
```

**Valores exactos:**
- Collection ID: `payments`
- Campo 1: `userId` → Ascending
- Campo 2: `type` → Ascending
- Campo 3: `status` → Ascending

Haz clic en **"Create"**

---

## 📋 ÍNDICE 4: Mis clases (bookings)

**Haz clic en "Create Index" nuevamente** y completa:

```
Collection ID:          bookings
Query scope:            Collection

Fields to index:
  Field path      Index type      Array config
  ─────────────────────────────────────────────
  userId          Ascending       (vacío)
  createdAt       Descending      (vacío)
```

**Valores exactos:**
- Collection ID: `bookings`
- Campo 1: `userId` → Ascending
- Campo 2: `createdAt` → Descending

Haz clic en **"Create"**

---

## ⏱️ Espera a que se construyan

Después de crear los 4 índices, verás una tabla con todos ellos. Cada uno tendrá un estado:

- 🔵 **Building** - Se está construyendo (espera)
- ✅ **Enabled** - Listo para usar

**IMPORTANTE:** Los índices pueden tardar entre 2-10 minutos en construirse, especialmente si ya tienes datos en la base de datos.

**NO cierres la pestaña de Firebase Console** hasta que todos los índices muestren "Enabled".

---

## 🧪 Verificar que funciona

Una vez que todos los índices estén en estado **"Enabled"**:

1. Vuelve a tu app Flutter
2. Recarga la página (F5 en Chrome)
3. Navega a la sección "Pagos"
4. El error debería desaparecer y verás tus pagos

---

## ❓ Troubleshooting

**Si sigues viendo errores:**
- Asegúrate de que todos los índices estén en estado "Enabled"
- Verifica que escribiste correctamente los nombres de los campos (respetan mayúsculas/minúsculas)
- Recarga completamente la app (Ctrl+Shift+R en Chrome)

**Si un índice falla al construirse:**
- Elimínalo haciendo clic en los 3 puntos (...) → Delete
- Créalo nuevamente verificando los nombres de los campos
