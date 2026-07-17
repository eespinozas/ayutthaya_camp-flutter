import 'package:flutter/foundation.dart' show kIsWeb;

import 'app_constants.dart';

/// Flags de visibilidad de los tabs del BottomNavigationBar del alumno.
///
/// Para reactivar un tab oculto basta con cambiar su flag a `true`:
/// la lista de items y el mapeo de índices se reconstruyen solos.
class FeatureFlags {
  static const bool showInicioTab = true;
  static const bool showAgendarTab = true;
  static const bool showMisClasesTab = true;

  /// Oculto durante la Fase 1 de acceso libre (sin membresías ni pagos).
  /// Cambiar a `true` (o terminar la fase en [AppFlags.freeAccessPhase])
  /// para que el tab Pagos reaparezca.
  static const bool showPagosTab = !AppFlags.freeAccessPhase;

  /// Check-in por QR (botón central del nav): oculto en web.
  /// El QR del gimnasio se escanea presencialmente con el teléfono; en el
  /// navegador la cámara aporta poco y el paquete de escaneo pesa. Al ser
  /// `const`, el tree-shaking elimina el código del escáner del bundle web.
  static const bool enableQrCheckIn = !kIsWeb;
}
