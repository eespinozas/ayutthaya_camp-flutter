# Configurar Reglas de Firestore para Schools

El error "no se pudieron cargar las escuelas" probablemente se debe a que las reglas de Firestore no permiten leer la colección `schools`.

## Verificar y Actualizar Reglas

1. Ve a Firebase Console: https://console.firebase.google.com
2. Selecciona tu proyecto
3. Ve a **Firestore Database** → **Reglas**
4. Agrega las reglas para la colección `schools`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Reglas para schools
    match /schools/{schoolId} {
      allow read: if true;  // Permitir lectura pública
      allow create: if request.auth != null;  // Solo usuarios autenticados pueden crear
      allow update, delete: if false;  // Solo desde console
    }

    // Reglas para users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if false;
    }

    // Reglas para class_schedules
    match /class_schedules/{scheduleId} {
      allow read: if true;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Reglas para bookings
    match /bookings/{bookingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && (
        request.auth.uid == resource.data.userId ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
      );
    }

    // Reglas para payments
    match /payments/{paymentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow delete: if false;
    }
  }
}
```

## Reglas Temporales (Solo para Desarrollo)

Si estás en desarrollo y quieres permitir todo temporalmente:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **ADVERTENCIA:** Las reglas temporales permiten acceso completo. Solo úsalas durante desarrollo y cámbialas antes de producción.

## Verificar en la Consola

Después de ejecutar la app, revisa la consola de debug para ver el error específico:
- `❌ Error cargando escuelas: [mensaje de error]`

El mensaje te dirá exactamente qué está fallando (permisos, colección no existe, etc.)
