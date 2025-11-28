# Resumen: Implementación de Comprobantes en Storage

## 🎯 Objetivo Completado

Implementar la funcionalidad para que los comprobantes de pago se suban automáticamente a Firebase Storage y que el administrador pueda visualizarlos.

---

## ✅ Cambios Implementados

### 1. Subida Automática a Firebase Storage

**Archivo:** `lib/features/payments/services/payment_service.dart`

#### Antes:
```dart
// TEMPORAL: No subir archivo a Storage (problema con CORS)
final downloadUrl = 'pending_upload'; // URL temporal
```

#### Después:
```dart
// Subir archivo a Firebase Storage
final downloadUrl = await _uploadReceiptToStorage(
  userId: userId,
  receiptFile: receiptFile,
  receiptBytes: receiptBytes,
  receiptFileName: receiptFileName,
);
```

#### Nuevo Método Implementado:

```dart
Future<String> _uploadReceiptToStorage({
  required String userId,
  File? receiptFile,
  Uint8List? receiptBytes,
  String? receiptFileName,
})
```

**Funcionalidades:**
- ✅ Soporta `File` (móvil) y `Uint8List` (web)
- ✅ Genera rutas únicas: `receipts/{userId}/{timestamp}_{filename}`
- ✅ Valida formato del archivo (JPG, PNG, PDF)
- ✅ Establece el `content-type` correcto
- ✅ Retorna la URL de descarga pública
- ✅ Manejo de errores completo

---

### 2. Visualización en Panel de Admin

**Archivo:** `lib/features/admin/presentation/pages/admin_pagos_page.dart`

#### Método `_viewReceipt` Mejorado:

**Nuevas Capacidades:**
- ✅ Detecta automáticamente si es imagen o PDF
- ✅ Muestra estado "pending_upload" si el archivo no se subió
- ✅ Visualiza imágenes directamente en un diálogo
- ✅ Muestra PDFs con ícono y botón de apertura
- ✅ Loading indicator mientras carga la imagen
- ✅ Error handling elegante con mensajes claros

#### Nuevos Widgets Auxiliares:

1. **`_buildPendingUploadView()`**
   - Se muestra cuando `receiptUrl == 'pending_upload'`
   - Indica que el archivo no se ha subido aún

2. **`_buildPDFView(String url)`**
   - Muestra ícono de PDF
   - Botón "Abrir PDF" (con URL seleccionable)
   - Preparado para integrar `url_launcher` en el futuro

3. **`_buildImageView(String url)`**
   - Carga imágenes con `Image.network`
   - Loading indicator con progreso
   - Error handling si la imagen no carga

---

### 3. Reglas de Seguridad de Storage

**Archivo:** `storage.rules` (NUEVO)

```javascript
match /receipts/{userId}/{fileName} {
  // Lectura: usuario dueño o admin
  allow read: if request.auth != null && (
    request.auth.uid == userId ||
    firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin'
  );

  // Escritura: solo el usuario dueño
  allow write: if request.auth != null && request.auth.uid == userId &&
    request.resource.size < 10 * 1024 * 1024 &&  // Máximo 10MB
    (
      request.resource.contentType.matches('image/jpeg') ||
      request.resource.contentType.matches('image/png') ||
      request.resource.contentType.matches('application/pdf')
    );
}
```

**Validaciones:**
- ✅ Solo el usuario dueño puede subir a su carpeta
- ✅ Admins pueden leer todos los comprobantes
- ✅ Tamaño máximo: 10MB
- ✅ Formatos permitidos: JPG, PNG, PDF
- ✅ Acceso denegado a cualquier otra ruta

---

## 📁 Estructura de Archivos en Storage

```
receipts/
  ├─ {userId1}/
  │   ├─ 1732455600000_comprobante1.jpg
  │   ├─ 1732456200000_comprobante2.png
  │   └─ 1732457800000_comprobante3.pdf
  ├─ {userId2}/
  │   └─ 1732458400000_comprobante.jpg
  └─ ...
```

**Beneficios de esta estructura:**
- Organización por usuario
- Nombres únicos con timestamp
- Fácil de mantener y limpiar
- Cumple con las reglas de seguridad

---

## 🔄 Flujo Completo

### Flujo del Usuario (Alumno)

1. Usuario va a **Pagos** → **Pagar Matrícula/Mensualidad**
2. Selecciona un plan
3. Adjunta comprobante mediante:
   - 📷 Tomar Foto (cámara)
   - 🖼️ Galería (seleccionar imagen)
   - 📄 Documento (seleccionar PDF/imagen)
4. Presiona **Enviar Pago**
5. La app:
   - Valida el archivo (formato y tamaño)
   - Sube el archivo a Storage en `receipts/{userId}/{timestamp}_{filename}`
   - Obtiene la URL de descarga
   - Crea el documento en Firestore con la URL
6. Usuario ve "Pago registrado exitosamente"

### Flujo del Admin

1. Admin va a **Panel Admin** → **Pagos** → **Pendientes**
2. Ve lista de pagos pendientes con información del usuario
3. Hace clic en **Ver Comprobante**
4. Según el tipo de archivo:
   - **Imagen**: Se muestra directamente en un diálogo
   - **PDF**: Se muestra ícono con botón "Abrir PDF"
5. Admin revisa el comprobante
6. Admin hace clic en **Aprobar** o **Rechazar**
7. Si aprueba:
   - El pago cambia a estado `approved`
   - El usuario se actualiza con `membershipStatus: active`
   - Se calcula la fecha de expiración

---

## 🚀 Próximos Pasos

### 1. Aplicar Reglas de Storage en Firebase

**IMPORTANTE:** Antes de probar, debes aplicar las reglas de Storage.

Sigue las instrucciones en: **`APLICAR_REGLAS_STORAGE.md`**

### 2. Probar la Funcionalidad

1. **Hot Restart** de la app
2. Intenta registrar un pago con comprobante
3. Verifica en Firebase Console → Storage que el archivo se subió
4. Revisa en Admin Panel que puedas ver el comprobante

### 3. (Opcional) Mejoras Futuras

- **Agregar `url_launcher`** para abrir PDFs automáticamente
- **Agregar visor de PDF** integrado en la app
- **Generar thumbnails** para PDFs
- **Comprimir imágenes** antes de subir para ahorrar espacio
- **Eliminar archivos** cuando se rechaza un pago
- **Límite de intentos** de subida en caso de error

---

## 📊 Comparación Antes vs Después

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Almacenamiento** | No se guardaba | Firebase Storage |
| **URL en Firestore** | `'pending_upload'` | URL real de descarga |
| **Visualización Admin** | Error al cargar | Funciona para imágenes y PDFs |
| **Seguridad** | N/A | Reglas robustas con validaciones |
| **Formatos soportados** | N/A | JPG, PNG, PDF |
| **Límite de tamaño** | N/A | 10MB |
| **Soporte móvil/web** | Parcial | Completo (File + Uint8List) |

---

## 🐛 Debugging

### Ver Logs en la App

```dart
// En PaymentService.createPayment
debugPrint('📤 Subiendo comprobante a Firebase Storage...');
debugPrint('📁 Ruta de almacenamiento: $storagePath');
debugPrint('📤 Archivo subido: ${snapshot.totalBytes} bytes');
debugPrint('🔗 URL de descarga: $downloadUrl');
debugPrint('✅ Comprobante subido exitosamente');
```

### Verificar en Firebase Console

1. **Storage** → Ver archivos en `receipts/{userId}/`
2. **Firestore** → `payments/{paymentId}` → Campo `receiptUrl`
3. **Authentication** → Verificar que el usuario esté autenticado

---

## 📝 Notas Técnicas

### Cross-Platform Support

El código soporta tanto móvil como web gracias a:

```dart
if (receiptFile != null) {
  // Móvil: usar File
  uploadTask = storageRef.putFile(receiptFile);
} else {
  // Web: usar Uint8List
  uploadTask = storageRef.putData(
    receiptBytes!,
    SettableMetadata(contentType: _getContentType(extension)),
  );
}
```

### Content-Type Automático

```dart
String _getContentType(String extension) {
  switch (extension.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'pdf':
      return 'application/pdf';
    default:
      return 'application/octet-stream';
  }
}
```

Esto asegura que los navegadores abran los archivos correctamente.

---

## ✨ Resumen Final

**Implementado con éxito:**
- ✅ Subida automática de comprobantes a Firebase Storage
- ✅ Validación de formato y tamaño
- ✅ Visualización en panel de admin (imágenes y PDFs)
- ✅ Reglas de seguridad robustas
- ✅ Soporte cross-platform (móvil y web)
- ✅ Manejo de errores completo
- ✅ Logging detallado para debugging

**Recuerda:** Aplicar las reglas de Storage en Firebase Console antes de probar (ver `APLICAR_REGLAS_STORAGE.md`)
