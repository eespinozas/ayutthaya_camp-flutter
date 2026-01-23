# Configurar Dominio Personalizado para Firebase Authentication

## ✅ Cambios realizados

1. **Actualizado `ACTION_DOMAIN` en `functions/.env`:**
   - Antes: `ayuthaya-camp.firebaseapp.com`
   - Ahora: `ayutthayamuaythai.com`

2. **Cloud Functions redesplegadas** con la nueva configuración

## 🔧 Pasos adicionales requeridos en Firebase Console

Para que los correos de verificación redirijan a `https://ayutthayamuaythai.com/`, necesitas autorizar el dominio en Firebase Authentication:

### Paso 1: Ir a Firebase Console

1. Ve a: https://console.firebase.google.com/project/ayuthaya-camp/authentication/settings
2. O navega a: **Authentication** → **Settings** → **Authorized domains**

### Paso 2: Agregar dominio personalizado

1. Haz clic en **"Add domain"**
2. Ingresa: `ayutthayamuaythai.com`
3. Haz clic en **"Add"**

### Paso 3: Configurar DNS (si aún no lo has hecho)

Si tu dominio `ayutthayamuaythai.com` no está configurado en Firebase Hosting:

#### Opción A: Usar Firebase Hosting con dominio personalizado

```bash
# Agregar dominio personalizado
firebase hosting:channel:deploy production --only hosting
```

Luego en Firebase Console:
1. Ve a **Hosting** → **Add custom domain**
2. Ingresa `ayutthayamuaythai.com`
3. Sigue las instrucciones para configurar los registros DNS

#### Opción B: Si usas hosting externo

Asegúrate de que tu aplicación web Flutter esté desplegada en `https://ayutthayamuaythai.com/`

### Paso 4: Configurar la página de action handler

Firebase necesita que tu dominio tenga una página que maneje las acciones de autenticación (verificación de email, reset de contraseña).

Debes configurar una ruta en tu app que maneje estos action codes:
- URL de ejemplo: `https://ayutthayamuaythai.com/__/auth/action`

## 📋 Verificación

Después de configurar el dominio autorizado:

1. **Registra un nuevo usuario**
2. **Verifica el correo electrónico**
3. El link en el correo ahora debería apuntar a:
   ```
   https://ayutthayamuaythai.com/__/auth/action?mode=verifyEmail&...
   ```
   en lugar de:
   ```
   https://ayuthaya-camp.firebaseapp.com/__/auth/action?mode=verifyEmail&...
   ```

## ⚠️ Notas importantes

- **Los dominios autorizados existentes seguirán funcionando** (como `ayuthaya-camp.firebaseapp.com`)
- Si el dominio `ayutthayamuaythai.com` no está autorizado, los usuarios recibirán un error al hacer clic en el link de verificación
- Asegúrate de que tu app Flutter esté desplegada en el dominio personalizado para manejar las redirecciones

## 🔍 Troubleshooting

Si después de agregar el dominio sigue redirigiendo al dominio de Firebase:

1. Verifica que las Cloud Functions estén usando el `.env` correcto
2. Revisa los logs de las funciones:
   ```bash
   firebase functions:log
   ```
3. Prueba con un nuevo usuario (los links anteriores seguirán usando el dominio viejo)
