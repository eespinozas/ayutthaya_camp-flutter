# Guía de Pruebas - Notificaciones Push

## ✅ Estado Actual

**App corriendo en:** `http://localhost:8080`
**FCM Token obtenido:** `deBUfJNYb3Tl9Y4UAKs6TI:APA91bFDFRAf22X14u2OjVdRfoXcUAkEGMJUKcp0l4DMnfIygOcnyGm6MjW2An7swpz8L_xfJw7sFVT7IRswXEgPT5ffU0nph0HC8frWZP1v4wMAWkCHkaQ`
**Permisos:** ✅ Autorizados

---

## 📋 Test 1: Notificación de Prueba Directa

### Objetivo
Verificar que Firebase Cloud Messaging puede enviar notificaciones al navegador.

### Pasos

1. **Abrir Firebase Console**
   ```
   https://console.firebase.google.com/project/ayuthaya-camp/settings/cloudmessaging
   ```

2. **Ir a "Send test message"**
   - En la página de Cloud Messaging, busca el botón azul "Send test message"

3. **Pegar tu FCM Token**
   ```
   deBUfJNYb3Tl9Y4UAKs6TI:APA91bFDFRAf22X14u2OjVdRfoXcUAkEGMJUKcp0l4DMnfIygOcnyGm6MjW2An7swpz8L_xfJw7sFVT7IRswXEgPT5ffU0nph0HC8frWZP1v4wMAWkCHkaQ
   ```

4. **Enviar notificación**
   - Título: `Prueba de Notificación`
   - Cuerpo: `Esta es una prueba desde Firebase Console`
   - Clic en "Test"

### Resultado Esperado
- ✅ Notificación aparece en Chrome (esquina inferior derecha)
- ✅ En la consola del navegador (F12) aparece: `📨 Mensaje recibido (foreground):`

### Si NO funciona
- Verificar que Chrome tiene permisos de notificación (candado en barra de URL)
- Verificar que estás en `http://localhost:8080` (no HTTPS en localhost)
- Revisar consola del navegador (F12) para errores

---

## 📋 Test 2: Notificación de Registro de Usuario

### Objetivo
Verificar que cuando un nuevo usuario se registra, los admins reciben notificación.

### Pasos

1. **Abrir la app en Chrome** (ya corriendo en `http://localhost:8080`)

2. **Ir a página de registro**
   - Clic en "Registrarse" o navegar a `/register`

3. **Crear un nuevo usuario de prueba**
   - Nombre: `Test Usuario`
   - Email: `test.notificaciones@prueba.com`
   - Contraseña: `Test1234!`
   - RUT: `11111111-1`
   - Teléfono: `+56912345678`

4. **Completar registro**
   - El sistema debería:
     1. Crear usuario en Firebase Auth
     2. Enviar email de verificación
     3. **Enviar notificación a todos los admins**

5. **Verificar en Firebase Console**
   ```
   https://console.firebase.google.com/project/ayuthaya-camp/firestore/data/~2Fnotifications
   ```
   - Debería aparecer un nuevo documento con:
     ```json
     {
       "title": "Nuevo Usuario Registrado",
       "body": "Test Usuario se ha registrado y requiere aprobación.",
       "sent": false,
       "createdAt": [timestamp]
     }
     ```

### Resultado Esperado
- ✅ Usuario creado en Firebase Auth
- ✅ Documento creado en colección `notifications`
- ✅ Admin recibe notificación (si tiene FCM token guardado)

### Notas
- La notificación se envía mediante Cloud Function (onUserCreated trigger)
- Si el admin no tiene FCM token guardado, el documento se crea pero no se envía
- Para que el admin reciba la notificación, debe haber iniciado sesión al menos una vez

---

## 📋 Test 3: Notificación de Pago Aprobado

### Objetivo
Verificar que cuando un admin aprueba un pago, el usuario recibe notificación.

### Pasos

1. **Login como Admin**
   - Email: `[tu email admin]`
   - Password: `[tu password]`

2. **Ir a sección "Pagos"**
   - En el menú inferior, clic en "Pagos"

3. **Buscar un pago pendiente**
   - Estado: "pending"
   - Si no hay pagos pendientes, crear uno manualmente en Firestore

4. **Aprobar el pago**
   - Clic en "Aprobar"
   - El sistema debería:
     1. Actualizar estado del pago a "approved"
     2. Actualizar membresía del usuario
     3. **Enviar notificación al usuario**

5. **Verificar en Firestore**
   ```
   https://console.firebase.google.com/project/ayuthaya-camp/firestore/data/~2Fnotifications
   ```
   - Nuevo documento con:
     ```json
     {
       "userId": "[userId]",
       "title": "Pago Aprobado",
       "body": "Tu pago ha sido aprobado. Ya puedes agendar clases.",
       "sent": false,
       "createdAt": [timestamp]
     }
     ```

### Resultado Esperado
- ✅ Pago actualizado a "approved"
- ✅ Membresía del usuario actualizada
- ✅ Documento creado en `notifications`
- ✅ Usuario recibe notificación (si tiene FCM token)

---

## 📋 Test 4: Recordatorio de Clase (30 min antes)

### Objetivo
Verificar que se programan recordatorios automáticos cuando un usuario agenda una clase.

### Pasos

1. **Login como usuario con membresía activa**
   - Email: `[email usuario activo]`
   - Password: `[password]`

2. **Ir a "Agendar Clase"**
   - En el menú inferior, clic en "Agendar"

3. **Reservar una clase**
   - Seleccionar fecha (hoy o mañana)
   - Seleccionar horario
   - Clic en "Confirmar Reserva"

4. **Verificar en Firestore**
   ```
   https://console.firebase.google.com/project/ayuthaya-camp/firestore/data/~2Fscheduled_notifications
   ```
   - Deberían aparecer 2 documentos (30 min y 15 min antes):
     ```json
     {
       "bookingId": "[bookingId]",
       "userId": "[userId]",
       "title": "Recordatorio de Clase",
       "body": "Tu clase de [nombre] es en 30 minutos...",
       "scheduledFor": [timestamp 30 min antes],
       "sent": false
     }
     ```

5. **Esperar 30 minutos antes de la clase** (o modificar manualmente el timestamp para prueba rápida)

### Resultado Esperado
- ✅ 2 documentos creados en `scheduled_notifications`
- ✅ Cloud Function enviará notificación automáticamente cuando llegue el momento
- ✅ Usuario recibe notificación 30 y 15 min antes

### Prueba Rápida (sin esperar)
Para testear sin esperar 30 minutos:
1. Crear booking normalmente
2. En Firestore, editar `scheduledFor` del documento recién creado
3. Cambiar a una fecha/hora en los próximos 2 minutos
4. Esperar y verificar que llega la notificación

---

## 🔍 Debugging

### Ver logs en tiempo real
Abre la consola del navegador (F12) y busca:
- `📱 Permisos de notificación: ...`
- `✅ Notificaciones autorizadas`
- `🔑 FCM Token: ...`
- `📨 Mensaje recibido (foreground): ...`

### Ver FCM Token de otros usuarios
1. Ir a Firestore Console
2. Colección `users`
3. Abrir documento del usuario
4. Buscar campo `fcmToken`

### Verificar permisos del navegador
1. Clic en el candado en la barra de URL
2. Verificar que "Notificaciones" está en "Permitir"
3. Si está bloqueado, cambiar a "Permitir" y recargar

### Firebase Console - Ver mensajes enviados
1. Firebase Console > Cloud Messaging
2. Pestaña "Notification Analytics"
3. Ver estadísticas de mensajes enviados/recibidos/abiertos

---

## ✅ Checklist de Pruebas

- [ ] Test 1: Notificación directa desde Firebase Console
- [ ] Test 2: Notificación de nuevo usuario registrado (admin recibe)
- [ ] Test 3: Notificación de pago aprobado (usuario recibe)
- [ ] Test 4: Recordatorios de clase programados (30 y 15 min antes)
- [ ] Verificar que notificaciones aparecen en Chrome
- [ ] Verificar que logs aparecen en consola del navegador
- [ ] Verificar que documentos se crean en Firestore
- [ ] Verificar que FCM tokens se guardan correctamente

---

## 🚨 Problemas Comunes

### "Service Worker registration failed"
- **Causa:** Intentando usar HTTPS en localhost sin certificado
- **Solución:** Usar `http://localhost:8080` (NO https)

### No llega notificación
1. Verificar permisos del navegador (candado en URL)
2. Verificar que FCM token existe en Firestore (campo `fcmToken` del usuario)
3. Verificar que el documento en `notifications` tiene `sent: false`
4. Verificar logs de Cloud Functions en Firebase Console

### Notificación llega pero no se ve
- **Causa:** App en foreground, notificación solo aparece en logs
- **Solución:** Minimizar Chrome o usar otra pestaña para que aparezca la notificación visual

### FCM Token es null
1. Verificar que `.env` tiene `VAPID_KEY` correcto
2. Verificar que `flutter_dotenv` está cargado en `main.dart`
3. Recargar la app completamente (Ctrl+Shift+R)

---

## 📞 Siguiente Paso

Una vez completados todos los tests:
1. Documentar resultados (qué funcionó, qué no)
2. Capturar screenshots de notificaciones
3. Verificar que todos los flows están funcionando
4. Preparar para deployment a staging

---

**Fecha de creación:** 2026-04-14
**Sprint:** 1-2 (Notificaciones + Emails + Errores)
**Estado:** ✅ App corriendo, listo para testear
