# 🔥 Cómo ejecutar el script de seed por CLI

## Paso 1: Descargar credenciales de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Click en el ícono de engranaje ⚙️ → **Project Settings**
4. Ve a la pestaña **Service Accounts**
5. Click en **Generate new private key**
6. Se descargará un archivo JSON
7. **Renombra** ese archivo a: `firebase-service-account.json`
8. **Mueve** el archivo a la raíz del proyecto (al lado de `pubspec.yaml`)

**IMPORTANTE:** Este archivo contiene credenciales secretas. NO lo subas a Git.

---

## Paso 2: Instalar Python (si no lo tienes)

### Windows:
- Descarga desde [python.org](https://www.python.org/downloads/)
- Durante la instalación, marca ✅ "Add Python to PATH"

### Verificar instalación:
```bash
python --version
```

---

## Paso 3: Instalar dependencias

Abre la terminal en la carpeta del proyecto y ejecuta:

```bash
pip install -r scripts/requirements.txt
```

Esto instalará `firebase-admin`.

---

## Paso 4: Ejecutar el script

```bash
python scripts/seed_firebase.py
```

**Resultado esperado:**
```
🔥 Iniciando seed de Firebase...

✅ Firebase inicializado correctamente

📦 Agregando planes...

✅ Plan agregado: Plan Novato - $10000
✅ Plan agregado: Plan Iniciado - $35000
✅ Plan agregado: Plan Guerrero - $45000
✅ Plan agregado: Plan Nak Muay - $55000
✅ Plan agregado: Plan Peleador - $65000

🎉 5/5 planes agregados

📅 Agregando horarios de clases...

✅ Horario agregado: Muay Thai a las 07:00 (Lun, Mar, Mié, Jue, Vie)
✅ Horario agregado: Boxing a las 08:00 (Lun, Mar, Mié, Jue, Vie)
✅ Horario agregado: Muay Thai a las 09:30 (Mar, Jue, Sáb)
✅ Horario agregado: Muay Thai a las 18:00 (Lun, Mar, Mié, Jue, Vie)
✅ Horario agregado: Boxing a las 19:30 (Lun, Mié, Vie)

🎉 5/5 horarios agregados

==================================================
✅ SEED COMPLETADO EXITOSAMENTE
==================================================
📦 Planes agregados: 5
📅 Horarios agregados: 5
```

---

## Verificar en Firebase

Ve a [Firebase Console](https://console.firebase.google.com/) → Firestore Database

Deberías ver:
- Colección `plans` con 5 documentos
- Colección `class_schedules` con 5 documentos

---

## Troubleshooting

### Error: "No module named 'firebase_admin'"
```bash
pip install firebase-admin
```

### Error: "firebase-service-account.json not found"
Asegúrate de que el archivo esté en la raíz del proyecto, al mismo nivel que `pubspec.yaml`.

### Error: "Permission denied"
Verifica que el service account tenga permisos de Firestore en Firebase Console.

---

## Nota importante

⚠️ **NO ejecutes el script más de una vez** o tendrás datos duplicados.

Si quieres limpiar y volver a ejecutar, elimina manualmente los documentos en Firebase Console primero.
