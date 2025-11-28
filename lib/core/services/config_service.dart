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
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Timeout al cargar configuración, usando valores por defecto');
          return [];
        },
      );

      if (results.isNotEmpty) {
        _appSettings = results[0].data();
        _paymentSettings = results[1].data();
        _featureFlags = results[2].data();
        _businessInfo = results[3].data();

        debugPrint('✅ Configuración cargada:');
        debugPrint('   - App settings: ${_appSettings != null}');
        debugPrint('   - Payment settings: ${_paymentSettings != null}');
        debugPrint('   - Feature flags: ${_featureFlags != null}');
        debugPrint('   - Business info: ${_businessInfo != null}');

        if (_appSettings == null || _paymentSettings == null || _featureFlags == null || _businessInfo == null) {
          debugPrint('⚠️ Algunos documentos de configuración no existen');
          debugPrint('   Ejecuta: python scripts/seed_config.py');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error cargando configuración: $e');
      debugPrint('   Stack: $stackTrace');
      debugPrint('   Se usarán valores por defecto');
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
  bool get isMaintenanceMode => getAppSetting<bool>('maintenance_mode', defaultValue: false) ?? false;

  /// Obtener email de soporte
  String get supportEmail => getAppSetting<String>('support_email', defaultValue: 'soporte@ayutthayacamp.com') ?? 'soporte@ayutthayacamp.com';

  /// Obtener teléfono de soporte
  String get supportPhone => getAppSetting<String>('support_phone', defaultValue: '+506-1234-5678') ?? '+506-1234-5678';

  /// Obtener capacidad por defecto de las clases
  int get defaultClassCapacity => getAppSetting<int>('default_class_capacity', defaultValue: 15) ?? 15;

  /// Obtener días máximos de reserva anticipada
  int get maxAdvanceBookingDays => getAppSetting<int>('max_advance_booking_days', defaultValue: 7) ?? 7;

  /// Obtener precio de matrícula
  double get enrollmentPrice {
    final price = getPaymentSetting('enrollment_price', defaultValue: 30000);
    return (price is int) ? price.toDouble() : (price as double);
  }

  /// Obtener símbolo de moneda
  String get currencySymbol => getPaymentSetting<String>('currency_symbol', defaultValue: '₡') ?? '₡';

  /// Obtener moneda
  String get currency => getPaymentSetting<String>('currency', defaultValue: 'CRC') ?? 'CRC';

  /// Obtener métodos de pago disponibles
  List<String> get paymentMethods {
    final methods = getPaymentSetting<List<dynamic>>('payment_methods', defaultValue: ['sinpe', 'transferencia', 'efectivo']);
    return methods?.map((e) => e.toString()).toList() ?? ['sinpe', 'transferencia', 'efectivo'];
  }

  /// Verificar si se requiere comprobante
  bool get requireReceipt => getPaymentSetting<bool>('require_receipt', defaultValue: true) ?? true;

  /// Verificar si la aprobación automática está habilitada
  bool get autoApproveEnabled => getPaymentSetting<bool>('auto_approve_enabled', defaultValue: false) ?? false;

  /// Verificar si los pagos están habilitados
  bool get paymentsEnabled => isFeatureEnabled('payments_enabled', defaultValue: true);

  /// Verificar si las reservas están habilitadas
  bool get bookingEnabled => isFeatureEnabled('booking_enabled', defaultValue: true);

  /// Verificar si el check-in con QR está habilitado
  bool get qrCheckinEnabled => isFeatureEnabled('qr_checkin_enabled', defaultValue: true);

  /// Verificar si el chat de soporte está habilitado
  bool get chatSupportEnabled => isFeatureEnabled('chat_support_enabled', defaultValue: false);

  /// Verificar si las notificaciones push están habilitadas
  bool get pushNotificationsEnabled => isFeatureEnabled('push_notifications_enabled', defaultValue: true);

  /// Verificar si los reportes de admin están habilitados
  bool get adminReportsEnabled => isFeatureEnabled('admin_reports_enabled', defaultValue: true);

  /// Obtener nombre del gimnasio
  String get gymName => getBusinessInfo<String>('gym_name', defaultValue: 'Ayutthaya Camp') ?? 'Ayutthaya Camp';

  /// Obtener dirección
  String get address => getBusinessInfo<String>('address', defaultValue: 'San José, Costa Rica') ?? 'San José, Costa Rica';

  /// Obtener horarios
  String get schedule => getBusinessInfo<String>('schedule', defaultValue: 'Lun-Vie: 7am-10pm, Sáb: 9am-2pm') ?? 'Lun-Vie: 7am-10pm, Sáb: 9am-2pm';

  /// Obtener descripción del negocio
  String get about => getBusinessInfo<String>('about', defaultValue: 'Gimnasio especializado en Muay Thai y Boxing') ?? 'Gimnasio especializado en Muay Thai y Boxing';

  /// Obtener redes sociales
  Map<String, dynamic> get socialMedia {
    final social = getBusinessInfo<Map<String, dynamic>>('social_media', defaultValue: {});
    return social ?? {
      'facebook': 'https://facebook.com/ayutthayacamp',
      'instagram': 'https://instagram.com/ayutthayacamp',
      'whatsapp': '+506-1234-5678',
    };
  }

  /// Recargar configuración (para cuando el admin cambie algo)
  Future<void> reload() async {
    debugPrint('🔄 Recargando configuración...');
    _appSettings = null;
    _paymentSettings = null;
    _featureFlags = null;
    _businessInfo = null;
    await loadConfig();
  }
}
