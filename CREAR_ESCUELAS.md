# Crear Escuelas en Firestore

## Opción 1: Desde Firebase Console

1. Ve a Firebase Console: https://console.firebase.google.com
2. Selecciona tu proyecto
3. Ve a Firestore Database
4. Crea una nueva colección llamada `schools`
5. Agrega documentos con la siguiente estructura:

### Ejemplo de documento:

**ID del documento:** `ayutthaya-centro` (o genera uno automático)

**Campos:**
```
name: "Ayutthaya Camp Centro"
address: "Dirección de la escuela"
active: true
createdAt: [timestamp actual]
```

### Escuelas de ejemplo:

```
ID: ayutthaya-centro
name: Ayutthaya Camp Centro
active: true

ID: ayutthaya-norte
name: Ayutthaya Camp Norte
active: true

ID: ayutthaya-sur
name: Ayutthaya Camp Sur
active: true
```

## Opción 2: Desde el código (una sola vez)

Ejecuta esta función una vez en tu app (puedes agregarla temporalmente en initState):

```dart
Future<void> _createInitialSchools() async {
  final schools = [
    {'name': 'Ayutthaya Camp Centro', 'active': true},
    {'name': 'Ayutthaya Camp Norte', 'active': true},
    {'name': 'Ayutthaya Camp Sur', 'active': true},
  ];

  for (var school in schools) {
    await FirebaseFirestore.instance.collection('schools').add({
      ...school,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
```

## Verificar Reglas de Firestore

Asegúrate de que las reglas de Firestore permitan leer la colección `schools`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /schools/{schoolId} {
      allow read: if true;  // Permitir lectura pública
      allow write: if false; // Solo desde backend o console
    }
  }
}
```
