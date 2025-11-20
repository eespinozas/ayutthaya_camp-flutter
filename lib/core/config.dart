// lib/core/app_config.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // primero intento dart-define (ideal para web)
  static const _fromDefine = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_fromDefine.isNotEmpty) return _normalize(_fromDefine);

    if (kIsWeb) return _normalize('http://localhost:3000'); // web usa localhost
    if (Platform.isAndroid) return _normalize('http://10.0.2.2:3000'); // emu Android
    return _normalize('http://localhost:3000'); // iOS sim / desktop
  }

  static String _normalize(String v) {
    // quita slash final
    if (v.endsWith('/')) return v.substring(0, v.length - 1);
    return v;
  }
}
