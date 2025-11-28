# Cómo Aplicar las Reglas de Firestore

## Método 1: Copiar y Pegar en Firebase Console (Recomendado)

### Paso 1: Abrir Firebase Console
1. Ve a https://console.firebase.google.com
2. Selecciona tu proyecto
3. En el menú lateral, haz clic en **Firestore Database**
4. Haz clic en la pestaña **Reglas**

### Paso 2: Copiar las Reglas
1. Abre el archivo `firestore.rules` en este proyecto
2. Copia **TODO** el contenido del archivo

### Paso 3: Pegar y Publicar
1. En Firebase Console, **borra todo** el contenido actual en el editor de reglas
2. **Pega** el contenido que copiaste del archivo `firestore.rules`
3. Haz clic en **Publicar**
4. Espera unos segundos hasta que veas el mensaje "Reglas publicadas correctamente"

### Paso 4: Probar
1. Recarga tu app Flutter (Hot Restart)
2. Ve a la pantalla de registro
3. Intenta registrarte e iniciar sesión
4. Ya no deberías ver errores de permisos

---

## Método 2: Usar Firebase CLI (Avanzado)

Si tienes Firebase CLI instalado:

```bash
# Desde la raíz del proyecto
firebase deploy --only firestore:rules
```

---

## ¿Qué incluyen estas reglas?

✅ **schools** - Lectura pública (para formulario de registro)
✅ **users** - Los usuarios leen/actualizan sus propios datos
✅ **plans** - Lectura pública (para ver planes disponibles)
✅ **class_schedules** - Lectura pública (para ver horarios)
✅ **bookings** - Los usuarios gestionan sus propias reservas
✅ **payments** - Los usuarios ven sus propios pagos, admin aprueba

---

## Errores Resueltos

Estas reglas corrigen los siguientes errores:

❌ `[cloud_firestore/permission-denied] Missing or insufficient permissions` en:
- Carga de escuelas (schools)
- Lectura de usuario (users)
- Planes activos (plans)
- Horarios de clases (class_schedules)
- Reservas (bookings)
- Pagos (payments)

---

## Verificar que las Reglas están Aplicadas

Después de publicar las reglas, puedes verificarlas en Firebase Console:

1. Ve a **Firestore Database** → **Reglas**
2. Deberías ver las reglas que acabas de pegar
3. La fecha de publicación debe ser la actual
