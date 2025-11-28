# Configuración de Cuenta de Administrador

## 🔐 Cómo crear la cuenta de Admin

Para probar la interfaz de administrador, solo necesitas crear una cuenta con el email especial de admin.

### ✅ Opción Rápida: Desde la App (Recomendado)

1. Abre la app
2. Click en **"¿No tienes cuenta? Crear una"**
3. Registra con:
   - Email: `admin@ayutthaya.com`
   - Password: `admin123` (o la que prefieras)
4. **¡Listo!** No necesitas verificar el email para el admin
5. Haz login y entrarás directo al panel de administración

### Opción 2: Desde Firebase Console

1. Ve a **Firebase Console** → **Authentication** → **Users**
2. Click en **"Add user"**
3. Email: `admin@ayutthaya.com`
4. Password: `admin123`
5. Click **"Add user"**
6. **¡Listo!** Ya puedes hacer login

**Nota:** El admin no requiere verificación de email, entra directamente al panel.

## 🎯 Cómo funciona el sistema de roles

### Detección de Admin

El sistema detecta automáticamente si un usuario es admin basándose en el email:

```dart
// En AuthViewModel.dart línea 111
if (email.toLowerCase() == 'admin@ayutthaya.com') {
  _userRole = 'admin';
} else {
  _userRole = 'student';
}
```

### Rutas según Rol

**Admin** → `AdminMainNavBar` con 5 tabs:
- 🏠 Dashboard (resumen del día, asistencias, alertas)
- 👥 Alumnos (gestión de alumnos y aprobaciones)
- 💰 Pagos (aprobar comprobantes)
- 📅 Clases (marcar asistencia)
- 📊 Reportes (analytics)

**Student** → `MainNavBar` con 5 tabs:
- 🏠 Inicio (dashboard personal)
- 📅 Agendar (reservar clases)
- 🥊 Mis Clases (clases reservadas)
- 💳 Pagos (pagar mensualidad)
- 👤 Mi Perfil

## 🚀 Prueba el Admin

1. Crea la cuenta según las instrucciones arriba
2. Cierra la app y vuelve a abrirla
3. Haz login con:
   - Email: `admin@ayutthaya.com`
   - Password: `admin123`
4. Deberías ver "¡Bienvenido Admin!" y entrar al panel de administración

## 📝 Notas

- Por ahora, el rol se detecta por email (hardcoded)
- En producción, esto debe venir desde Firestore/base de datos
- El dashboard de admin muestra datos de ejemplo (mock data)
- Las funcionalidades de aprobar alumnos/pagos están por implementar

## 🔧 Para Producción

En producción, deberás:

1. Crear un campo `role` en Firestore para cada usuario:
   ```firestore
   users/
     └── {userId}/
         ├── email: "admin@ayutthaya.com"
         ├── role: "admin"  ← Agregar este campo
         └── ...
   ```

2. Modificar `AuthViewModel.login()` para leer el rol desde Firestore:
   ```dart
   // En lugar de verificar el email, leer de Firestore
   final userDoc = await FirebaseFirestore.instance
       .collection('users')
       .doc(_user!.uid)
       .get();

   _userRole = userDoc.data()?['role'] ?? 'student';
   ```

3. Proteger rutas en el backend para que solo admins puedan acceder a ciertas APIs
