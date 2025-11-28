# Scripts de Firebase

Scripts Python para inicializar y configurar Firebase Firestore.

## Requisitos

```bash
pip install firebase-admin
```

## Service Account

Todos los scripts requieren un archivo de service account de Firebase.

### Obtener el Service Account

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto → **Project Settings** (⚙️)
3. Ve a la pestaña **Service Accounts**
4. Click en **Generate new private key**
5. Guarda el archivo JSON en una ubicación segura

⚠️ **IMPORTANTE:** Este archivo contiene credenciales sensibles. Nunca lo subas a git.

## Configuración del Service Account

Hay 3 formas de especificar la ruta al service account:

### 1. Variable de entorno (Recomendado)

**Linux/Mac:**
```bash
export FIREBASE_SERVICE_ACCOUNT=/ruta/al/service-account.json
```

**Windows PowerShell:**
```powershell
$env:FIREBASE_SERVICE_ACCOUNT="C:\ruta\al\service-account.json"
```

**Windows CMD:**
```cmd
set FIREBASE_SERVICE_ACCOUNT=C:\ruta\al\service-account.json
```

### 2. Argumento de línea de comandos

```bash
python scripts/seed_firebase.py /ruta/al/service-account.json
python scripts/seed_config.py /ruta/al/service-account.json
```

### 3. Ubicación por defecto

Si no especificas nada, los scripts buscarán en:
```
scripts/firebase-service-account.json
```

## Scripts Disponibles

### `seed_firebase.py` - Inicializar Planes y Horarios

Crea los planes de membresía y horarios de clases iniciales.

**Uso:**
```bash
# Con variable de entorno
python scripts/seed_firebase.py

# Con argumento
python scripts/seed_firebase.py /ruta/al/service-account.json
```

**Crea:**
- 5 planes en la colección `plans`
- 12 horarios en la colección `class_schedules`

### `seed_config.py` - Configuración de la App

Crea la configuración inicial de la aplicación en Firestore.

**Uso:**
```bash
# Con variable de entorno
python scripts/seed_config.py

# Con argumento
python scripts/seed_config.py /ruta/al/service-account.json
```

**Crea 4 documentos en la colección `config`:**

1. **`config/app_settings`**
   - Configuración general de la app
   - Modo mantenimiento
   - Versión mínima
   - Contactos de soporte

2. **`config/payment_settings`**
   - Precio de matrícula
   - Métodos de pago
   - Configuración de aprobación automática

3. **`config/feature_flags`**
   - Features habilitadas/deshabilitadas
   - Permite activar/desactivar funcionalidades sin actualizar la app

4. **`config/business_info`**
   - Información del gimnasio
   - Horarios, dirección
   - Redes sociales

## Ejemplos de Uso

### Desarrollo Local

```bash
# Guardar service account en scripts/
cp ~/Downloads/service-account.json scripts/firebase-service-account.json

# Ejecutar scripts (usa ubicación por defecto)
python scripts/seed_firebase.py
python scripts/seed_config.py
```

### CI/CD o Servidor

```bash
# Configurar variable de entorno
export FIREBASE_SERVICE_ACCOUNT=/secure/path/service-account.json

# Ejecutar scripts
python scripts/seed_firebase.py
python scripts/seed_config.py
```

### Multiples Proyectos

```bash
# Proyecto de desarrollo
python scripts/seed_config.py ~/credentials/dev-service-account.json

# Proyecto de producción
python scripts/seed_config.py ~/credentials/prod-service-account.json
```

## Seguridad

✅ **Hacer:**
- Usar variables de entorno en producción
- Guardar el service account fuera del repositorio
- Verificar que `.gitignore` incluye `*service-account.json`

❌ **No hacer:**
- Subir el service account a git
- Hardcodear la ruta en el código
- Compartir el archivo por medios inseguros

## Verificación

El archivo `.gitignore` ya incluye protección para service accounts:

```gitignore
# Firebase service account credentials
*service-account.json
firebase-service-account.json
scripts/firebase-service-account.json
```

Verifica que tu archivo no esté en git:
```bash
git status
# No debe aparecer service-account.json
```

## Troubleshooting

### Error: No se encontró el archivo

```
ERROR: No se encontro el archivo: scripts/firebase-service-account.json
```

**Solución:** Especifica la ruta correcta:
```bash
python scripts/seed_config.py /ruta/correcta/service-account.json
```

### Error: Permission denied

```
ERROR: [Errno 13] Permission denied: 'service-account.json'
```

**Solución:** Verifica los permisos del archivo:
```bash
chmod 600 /ruta/al/service-account.json
```

### Error: Invalid service account

```
ERROR al inicializar Firebase: ...
```

**Solución:** Verifica que:
1. El archivo JSON es válido
2. Es del proyecto correcto
3. No está vencido o revocado

## Referencias

- [Firebase Admin SDK Setup](https://firebase.google.com/docs/admin/setup)
- [Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Best Practices for Service Accounts](https://cloud.google.com/iam/docs/best-practices-service-accounts)
