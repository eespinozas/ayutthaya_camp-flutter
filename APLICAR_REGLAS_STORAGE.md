# Configurar Firebase Storage para Comprobantes de Pago

## Resumen de Cambios

Se ha implementado la funcionalidad completa para subir y visualizar comprobantes de pago en Firebase Storage:

### ✅ Implementado:
1. **Subida de archivos a Firebase Storage** desde la app móvil/web
2. **Validación de formatos** (JPG, PNG, PDF)
3. **Validación de tamaño** (máximo 10MB)
4. **Visualización en panel de admin** con soporte para imágenes y PDFs
5. **Reglas de seguridad** para Storage

---

## Paso 1: Aplicar Reglas de Firebase Storage

### Método 1: Copiar y Pegar en Firebase Console (Recomendado)

#### 1.1 Abrir Firebase Console
1. Ve a https://console.firebase.google.com
2. Selecciona tu proyecto
3. En el menú lateral, haz clic en **Storage**
4. Haz clic en la pestaña **Rules**

#### 1.2 Copiar las Reglas
1. Abre el archivo `storage.rules` en este proyecto
2. Copia **TODO** el contenido del archivo

#### 1.3 Pegar y Publicar
1. En Firebase Console, **borra todo** el contenido actual en el editor de reglas
2. **Pega** el contenido que copiaste del archivo `storage.rules`
3. Haz clic en **Publicar**
4. Espera unos segundos hasta que veas el mensaje "Reglas publicadas correctamente"

---

### Método 2: Usar Firebase CLI (Avanzado)

Si tienes Firebase CLI instalado:

```bash
# Desde la raíz del proyecto
firebase deploy --only storage
```

---

## Paso 2: Verificar que Storage esté Habilitado

1. Ve a **Storage** en Firebase Console
2. Si ves un mensaje "Comenzar", haz clic en él
3. Selecciona la ubicación de tu bucket (ej: `us-central1`)
4. Acepta las reglas predeterminadas (las reemplazarás en el Paso 1)
5. Haz clic en **Listo**

---

## ¿Qué incluyen estas reglas?

### Estructura de Almacenamiento

Los comprobantes se guardan en la siguiente estructura:

```
receipts/
  └─ {userId}/
      ├─ {timestamp}_comprobante1.jpg
      ├─ {timestamp}_comprobante2.png
      └─ {timestamp}_comprobante3.pdf
```

### Permisos de Seguridad

✅ **Lectura (read)**:
- El usuario dueño del comprobante
- Usuarios con rol `admin`

✅ **Escritura (write)**:
- Solo el usuario dueño puede subir archivos a su carpeta
- Validaciones:
  - Tamaño máximo: 10MB
  - Formatos permitidos: JPG, PNG, PDF

❌ **Acceso denegado a cualquier otra ruta**

---

## Paso 3: Probar la Funcionalidad

### Como Usuario (Alumno)

1. **Hot Restart** de la app Flutter
2. Ve a la pantalla de **Pagos**
3. Haz clic en **Pagar Matrícula** o **Pagar Mensualidad**
4. Selecciona un plan
5. Adjunta un comprobante usando uno de estos métodos:
   - 📷 **Tomar Foto** - Abre la cámara
   - 🖼️ **Galería** - Selecciona una imagen de la galería
   - 📄 **Documento** - Selecciona un archivo PDF o imagen
6. Completa y envía el pago
7. Deberías ver el mensaje "Pago registrado exitosamente"

### Como Admin

1. Ve al **Panel de Admin** → **Pagos**
2. En la pestaña **Pendientes**, verás los pagos nuevos
3. Haz clic en **Ver Comprobante** para visualizar:
   - **Imágenes**: Se muestran directamente en el diálogo
   - **PDFs**: Se muestra un botón para abrir/descargar
4. Aprueba o rechaza el pago

---

## Verificar que las Reglas están Aplicadas

### En Firebase Console

1. Ve a **Storage** → **Rules**
2. Deberías ver las reglas que acabas de pegar
3. La fecha de publicación debe ser la actual

### En la App

Si ves alguno de estos errores, verifica las reglas:

❌ `[firebase_storage/unauthorized]` - Las reglas no permiten la acción
❌ `[firebase_storage/invalid-argument]` - Formato de archivo no válido
❌ `[firebase_storage/quota-exceeded]` - Se excedió el límite de tamaño

---

## Solución de Problemas

### Error: "No se pudo subir el comprobante"

**Posibles causas:**
1. Las reglas de Storage no están aplicadas
2. El usuario no está autenticado
3. El archivo supera los 10MB
4. El formato no está permitido (solo JPG, PNG, PDF)

**Solución:**
- Verifica que las reglas estén publicadas en Firebase Console
- Cierra sesión y vuelve a iniciar sesión
- Intenta con un archivo más pequeño
- Verifica el formato del archivo

### Error: "Comprobante no disponible" en Admin

**Posibles causas:**
1. El admin no tiene permisos de lectura en las reglas
2. El archivo fue eliminado de Storage
3. La URL del archivo es incorrecta

**Solución:**
- Verifica que las reglas de Storage permitan lectura a admins
- Verifica en Firebase Console → Storage que el archivo existe
- Revisa los logs de la app para ver la URL exacta

### CORS (Solo en Web)

Si estás ejecutando la app en Flutter Web y ves errores de CORS:

1. Descarga e instala Google Cloud SDK
2. Ejecuta:
   ```bash
   gsutil cors set cors.json gs://TU-BUCKET-NAME.appspot.com
   ```

El archivo `cors.json` ya está incluido en este proyecto.

---

## Archivos Modificados

### Nuevos Archivos
- `storage.rules` - Reglas de seguridad de Firebase Storage
- `APLICAR_REGLAS_STORAGE.md` - Esta documentación

### Archivos Actualizados
- `lib/features/payments/services/payment_service.dart` - Implementa subida a Storage
- `lib/features/admin/presentation/pages/admin_pagos_page.dart` - Visualización de comprobantes

---

## Funcionalidades Implementadas

### Subida de Archivos (payment_service.dart)

```dart
// Nuevo método _uploadReceiptToStorage
- Soporta File (móvil) y Uint8List (web)
- Genera rutas únicas: receipts/{userId}/{timestamp}_{filename}
- Valida extensión del archivo
- Establece content-type correcto
- Retorna download URL
```

### Visualización en Admin (admin_pagos_page.dart)

```dart
// Método _viewReceipt actualizado
- Detecta tipo de archivo (imagen vs PDF)
- Muestra imágenes con Image.network
- Muestra PDFs con ícono y botón de descarga
- Maneja estado "pending_upload"
- Loading indicator mientras carga
- Error handling completo
```

---

## Próximos Pasos Opcionales

### 1. Agregar URL Launcher para PDFs

Instala el paquete `url_launcher`:

```yaml
dependencies:
  url_launcher: ^6.2.0
```

Y reemplaza el botón de "Abrir PDF" con:

```dart
import 'package:url_launcher/url_launcher.dart';

ElevatedButton.icon(
  onPressed: () async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  },
  icon: const Icon(Icons.open_in_new),
  label: const Text('Abrir PDF'),
)
```

### 2. Agregar Visor de PDF en la App

Instala un paquete de visor de PDF:

```yaml
dependencies:
  flutter_pdfview: ^1.3.2  # Para móvil
  # o
  syncfusion_flutter_pdfviewer: ^24.1.41  # Cross-platform
```

### 3. Thumbnails para PDFs

Genera thumbnails de los PDFs para mostrar previsualizaciones en la lista de pagos.

---

## Resumen

✅ Los usuarios pueden subir comprobantes (imagen o PDF)
✅ Los archivos se guardan en Firebase Storage
✅ Los admins pueden ver todos los comprobantes
✅ Reglas de seguridad protegen los archivos
✅ Validación de formato y tamaño
✅ Soporte para móvil y web

**Recuerda aplicar las reglas de Storage en Firebase Console antes de probar!**
