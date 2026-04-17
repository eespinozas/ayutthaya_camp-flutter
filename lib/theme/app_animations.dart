import 'package:flutter/animation.dart';

/// Ayutthaya Camp - Animation System
/// Duraciones y curves centralizadas
class AppAnimations {
  AppAnimations._(); // Constructor privado

  // ============================================================================
  // DURATIONS
  // ============================================================================

  /// 100ms - Micro-interacciones muy rápidas
  static const Duration instant = Duration(milliseconds: 100);

  /// 150ms - Transiciones rápidas (hover, ripple)
  static const Duration fast = Duration(milliseconds: 150);

  /// 200ms - Transiciones normales (default)
  static const Duration normal = Duration(milliseconds: 200);

  /// 300ms - Transiciones medias (modals, overlays)
  static const Duration medium = Duration(milliseconds: 300);

  /// 500ms - Transiciones lentas (page transitions)
  static const Duration slow = Duration(milliseconds: 500);

  /// 1000ms - Animaciones largas (loaders, skeleton)
  static const Duration long = Duration(milliseconds: 1000);

  // ============================================================================
  // CURVES (Material Design)
  // ============================================================================

  /// Standard - Entrada y salida suave
  static const Curve standardCurve = Curves.easeInOutCubic;

  /// Decelerate - Entrada rápida, salida suave
  static const Curve decelerateCurve = Curves.easeOut;

  /// Accelerate - Entrada suave, salida rápida
  static const Curve accelerateCurve = Curves.easeIn;

  /// Spring - Efecto de rebote sutil
  static const Curve springCurve = Curves.elasticOut;

  // ============================================================================
  // ANIMATION CONFIGS
  // ============================================================================

  /// Configuración para ripple effects
  static const Duration rippleDuration = fast;

  /// Configuración para hover states
  static const Duration hoverDuration = fast;

  /// Configuración para modals/dialogs
  static const Duration dialogDuration = medium;

  /// Configuración para page transitions
  static const Duration pageTransitionDuration = medium;

  /// Configuración para bottom sheets
  static const Duration bottomSheetDuration = medium;

  /// Configuración para snackbars
  static const Duration snackbarDuration = fast;

  /// Configuración para loading indicators
  static const Duration loadingDuration = long;
}
