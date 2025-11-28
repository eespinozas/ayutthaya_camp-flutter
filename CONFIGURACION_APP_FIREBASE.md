# Configuración de la App con Firestore

## 📝 Guardar Variables de Configuración en Firestore

En lugar de tener valores hardcodeados en la app, puedes guardarlos en Firestore y cargarlos dinámicamente.

---

## 🏗️ Estructura Propuesta

### Colección: `config`

```
firestore/
  └─ config/
      ├─ app_settings/          # Configuración general de la app
      ├─ payment_settings/      # Configuración de pagos
      ├─ feature_flags/         # Features activas/inactivas
      └─ business_info/         # Información del negocio
```

---

## 📋 Documentos Recomendados

### 1. `config/app_settings`

```json
{
  "maintenance_mode": false,
  "min_app_version": "1.0.0",
  "force_update": false,
  "support_email": "soporte@ayutthayacamp.com",
  "support_phone": "+506 1234-5678",
  "default_class_capacity": 15,
  "max_advance_booking_days": 7,
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

**Casos de uso:**
- Activar modo mantenimiento sin actualizar la app
- Forzar actualización si hay una versión crítica
- Cambiar email/teléfono de soporte
- Ajustar límites de reservas

---

### 2. `config/payment_settings`

```json
{
  "enrollment_price": 30000,
  "currency": "CRC",
  "currency_symbol": "₡",
  "payment_methods": ["sinpe", "transferencia", "efectivo"],
  "require_receipt": true,
  "auto_approve_enabled": false,
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

**Casos de uso:**
- Cambiar precio de matrícula sin actualizar la app
- Habilitar/deshabilitar métodos de pago
- Configurar aprobación automática de pagos

---

### 3. `config/feature_flags`

```json
{
  "booking_enabled": true,
  "payments_enabled": true,
  "qr_checkin_enabled": true,
  "chat_support_enabled": false,
  "push_notifications_enabled": true,
  "admin_reports_enabled": true,
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

**Casos de uso:**
- Activar/desactivar funcionalidades sin actualizar
- Hacer A/B testing
- Lanzamiento gradual de features

---

### 4. `config/business_info`

```json
{
  "gym_name": "Ayutthaya Camp",
  "address": "San José, Costa Rica",
  "schedule": "Lun-Vie: 7am-10pm, Sáb: 9am-2pm",
  "about": "Gimnasio especializado en Muay Thai...",
  "social_media": {
    "facebook": "https://facebook.com/ayutthayacamp",
    "instagram": "https://instagram.com/ayutthayacamp",
    "whatsapp": "+506-1234-5678"
  },
  "updatedAt": "2025-01-15T10:00:00Z"
}
```

**Casos de uso:**
- Actualizar horarios sin actualizar la app
- Cambiar redes sociales
- Modificar información del negocio

---

## 🔒 Reglas de Seguridad en Firestore

Agrega estas reglas a `firestore.rules`:

```javascript
// Configuración de la app
match /config/{document} {
  // Lectura: todos (incluso no autenticados para app_settings)
  allow read: if true;

  // Escritura: solo admins
  allow write: if request.auth != null &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

---

## 💻 Código para Leer la Configuración

### Service: `lib/core/services/config_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache de configuración
  Map<String, dynamic>? _appSettings;
  Map<String, dynamic>? _paymentSettings;
  Map<String, dynamic>? _featureFlags;
  Map<String, dynamic>? _businessInfo;

  // Singleton
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  /// Cargar toda la configuración al inicio
  Future<void> loadConfig() async {
    debugPrint('🔧 Cargando configuración de Firebase...');

    try {
      // Cargar todas las configuraciones en paralelo
      final results = await Future.wait([
        _firestore.collection('config').doc('app_settings').get(),
        _firestore.collection('config').doc('payment_settings').get(),
        _firestore.collection('config').doc('feature_flags').get(),
        _firestore.collection('config').doc('business_info').get(),
      ]);

      _appSettings = results[0].data();
      _paymentSettings = results[1].data();
      _featureFlags = results[2].data();
      _businessInfo = results[3].data();

      debugPrint('✅ Configuración cargada:');
      debugPrint('   - App settings: ${_appSettings != null}');
      debugPrint('   - Payment settings: ${_paymentSettings != null}');
      debugPrint('   - Feature flags: ${_featureFlags != null}');
      debugPrint('   - Business info: ${_businessInfo != null}');
    } catch (e) {
      debugPrint('❌ Error cargando configuración: $e');
    }
  }

  /// Obtener un valor de app_settings
  T? getAppSetting<T>(String key, {T? defaultValue}) {
    return (_appSettings?[key] as T?) ?? defaultValue;
  }

  /// Obtener un valor de payment_settings
  T? getPaymentSetting<T>(String key, {T? defaultValue}) {
    return (_paymentSettings?[key] as T?) ?? defaultValue;
  }

  /// Verificar si una feature está habilitada
  bool isFeatureEnabled(String featureName, {bool defaultValue = false}) {
    return _featureFlags?[featureName] ?? defaultValue;
  }

  /// Obtener información del negocio
  T? getBusinessInfo<T>(String key, {T? defaultValue}) {
    return (_businessInfo?[key] as T?) ?? defaultValue;
  }

  /// Verificar si está en modo mantenimiento
  bool get isMaintenanceMode => getAppSetting('maintenance_mode', defaultValue: false);

  /// Obtener email de soporte
  String get supportEmail => getAppSetting('support_email', defaultValue: 'soporte@ayutthayacamp.com');

  /// Obtener precio de matrícula
  double get enrollmentPrice => getPaymentSetting('enrollment_price', defaultValue: 30000.0);

  /// Verificar si los pagos están habilitados
  bool get paymentsEnabled => isFeatureEnabled('payments_enabled', defaultValue: true);

  /// Recargar configuración (para cuando el admin cambie algo)
  Future<void> reload() async {
    _appSettings = null;
    _paymentSettings = null;
    _featureFlags = null;
    _businessInfo = null;
    await loadConfig();
  }
}
```

---

## 🚀 Uso en la App

### 1. Cargar al Inicio (`main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Cargar configuración
  final configService = ConfigService();
  await configService.loadConfig();

  // Verificar modo mantenimiento
  if (configService.isMaintenanceMode) {
    runApp(MaintenanceApp());
    return;
  }

  runApp(MyApp());
}
```

---

### 2. Usar en Cualquier Parte

```dart
// En la página de pagos
final enrollmentPrice = ConfigService().enrollmentPrice;

// Verificar si una feature está activa
if (ConfigService().isFeatureEnabled('qr_checkin_enabled')) {
  // Mostrar opción de QR check-in
}

// Obtener email de soporte
final supportEmail = ConfigService().supportEmail;

// Verificar límites
final maxDays = ConfigService().getAppSetting<int>(
  'max_advance_booking_days',
  defaultValue: 7,
);
```

---

### 3. UI para Admin (Editar Configuración)

```dart
// Página de configuración para admin
class AdminConfigPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('config')
          .doc('feature_flags')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return ListView(
          children: [
            SwitchListTile(
              title: Text('Pagos Habilitados'),
              value: data['payments_enabled'] ?? true,
              onChanged: (value) async {
                await FirebaseFirestore.instance
                    .collection('config')
                    .doc('feature_flags')
                    .update({'payments_enabled': value});
              },
            ),
            SwitchListTile(
              title: Text('Modo Mantenimiento'),
              value: data['maintenance_mode'] ?? false,
              onChanged: (value) async {
                await FirebaseFirestore.instance
                    .collection('config')
                    .doc('app_settings')
                    .update({'maintenance_mode': value});
              },
            ),
            // Más switches...
          ],
        );
      },
    );
  }
}
```

---

## 🎯 Ventajas de Este Approach

| Ventaja | Descripción |
|---------|-------------|
| ✅ **Sin actualizar app** | Cambios en tiempo real |
| ✅ **Fácil de usar** | Ya tienes Firestore configurado |
| ✅ **Gratis** | No costos adicionales |
| ✅ **Flexible** | Puedes agregar cualquier configuración |
| ✅ **Cacheable** | Se carga una vez al inicio |
| ✅ **Admin-friendly** | Puedes hacer UI para que admin edite |

---

## 📝 Crear Configuración Inicial

### Script Python: `scripts/seed_config.py`

El script `seed_config.py` crea la configuración inicial en Firestore con valores por defecto.

**Uso:**

```bash
# Con variable de entorno (recomendado)
export FIREBASE_SERVICE_ACCOUNT=/ruta/al/service-account.json
python scripts/seed_config.py

# Con argumento de línea de comandos
python scripts/seed_config.py /ruta/al/service-account.json

# Con ubicación por defecto
python scripts/seed_config.py
```

El script crea 4 documentos en la colección `config`:
- `app_settings` - Configuración general de la app
- `payment_settings` - Configuración de pagos
- `feature_flags` - Features habilitadas/deshabilitadas
- `business_info` - Información del negocio

Para más detalles sobre cómo configurar el service account, ver: [`scripts/README.md`](scripts/README.md)

---

## 🔄 Alternativa: Firebase Remote Config

Si prefieres usar Remote Config (más robusto):

```yaml
# pubspec.yaml
dependencies:
  firebase_remote_config: ^4.4.0
```

**Ventajas adicionales:**
- ✅ A/B testing integrado
- ✅ Condiciones (por país, idioma, etc)
- ✅ Análisis de impacto de cambios

**Desventajas:**
- ⚠️ Más complejo de configurar
- ⚠️ Requiere paquete adicional

---

## 🎯 Resumen

Para tu app, **recomiendo usar Firestore** para configuración:

1. ✅ Ya tienes Firestore configurado
2. ✅ No requiere paquetes adicionales
3. ✅ Fácil de implementar y mantener
4. ✅ El admin puede editar desde una UI
5. ✅ Cambios en tiempo real

**Próximo paso:** ¿Quieres que implemente el `ConfigService` y la configuración inicial?
