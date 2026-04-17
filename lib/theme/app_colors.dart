import 'package:flutter/material.dart';

/// Ayutthaya Camp - Color System
/// Paleta de colores centralizada para toda la aplicación
class AppColors {
  AppColors._(); // Constructor privado

  // ============================================================================
  // BACKGROUNDS
  // ============================================================================

  /// Deep Black - Background principal
  static const Color background = Color(0xFF0F0F0F);

  /// Dark Gray - Cards y containers
  static const Color surface = Color(0xFF1A1A1A);

  /// Medium Gray - Inputs y elementos deshabilitados
  static const Color surfaceVariant = Color(0xFF2A2A2A);

  // ============================================================================
  // BRAND COLORS (Primary - Orange)
  // ============================================================================

  /// Orange Primary - Color principal del brand
  static const Color primary = Color(0xFFFF6A00);

  /// Orange Secondary - Variación más clara
  static const Color primaryLight = Color(0xFFFF8534);

  /// Orange Dark - Variación más oscura
  static const Color primaryDark = Color(0xFFCC5500);

  /// Primary Gradient - Gradiente principal
  static const List<Color> primaryGradient = [primary, primaryLight];

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  /// Success Green
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const List<Color> successGradient = [success, successDark];

  /// Warning Yellow-Red
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFEF4444);
  static const List<Color> warningGradient = [warning, warningDark];

  /// Error Red
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFDC2626);
  static const List<Color> errorGradient = [error, errorDark];

  /// Info Indigo
  static const Color info = Color(0xFF4F46E5);
  static const Color infoDark = Color(0xFF6366F1);
  static const List<Color> infoGradient = [info, infoDark];

  // ============================================================================
  // NEUTRAL COLORS
  // ============================================================================

  /// Neutral Gray
  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralDark = Color(0xFF4B5563);
  static const List<Color> neutralGradient = [neutral, neutralDark];

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  /// Primary text - Blanco
  static const Color textPrimary = Colors.white;

  /// Secondary text - Blanco 90%
  static Color get textSecondary => Colors.white.withValues(alpha: 0.9);

  /// Muted text - Blanco 70%
  static Color get textMuted => Colors.white.withValues(alpha: 0.7);

  /// Disabled text - Blanco 50%
  static Color get textDisabled => Colors.white.withValues(alpha: 0.5);

  /// Hint text - Blanco 40%
  static Color get textHint => Colors.white.withValues(alpha: 0.4);

  // ============================================================================
  // OVERLAY COLORS
  // ============================================================================

  /// Overlay oscuro para modals/dialogs
  static Color get overlayDark => Colors.black.withValues(alpha: 0.7);

  /// Overlay glassmorphism
  static Color get glassmorphism => Colors.white.withValues(alpha: 0.1);

  /// Overlay glassmorphism más visible
  static Color get glassmorphismStrong => Colors.white.withValues(alpha: 0.2);

  // ============================================================================
  // GRADIENTS BY USE CASE
  // ============================================================================

  /// Gradient para headers/banners
  static LinearGradient get headerGradient => const LinearGradient(
        colors: primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Gradient para botones primarios
  static LinearGradient get buttonGradient => const LinearGradient(
        colors: primaryGradient,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  /// Gradient para stats/KPIs de éxito
  static LinearGradient get successCardGradient => const LinearGradient(
        colors: successGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Gradient para stats/KPIs de advertencia
  static LinearGradient get warningCardGradient => const LinearGradient(
        colors: warningGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Gradient para stats/KPIs de info
  static LinearGradient get infoCardGradient => const LinearGradient(
        colors: infoGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ============================================================================
  // SHADOWS
  // ============================================================================

  /// Shadow con glow naranja
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Shadow con glow naranja fuerte
  static List<BoxShadow> get primaryGlowStrong => [
        BoxShadow(
          color: primary.withValues(alpha: 0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Shadow con glow de éxito
  static List<BoxShadow> get successGlow => [
        BoxShadow(
          color: success.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Shadow con glow de advertencia
  static List<BoxShadow> get warningGlow => [
        BoxShadow(
          color: warning.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Shadow con glow de info
  static List<BoxShadow> get infoGlow => [
        BoxShadow(
          color: info.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ============================================================================
  // BORDERS
  // ============================================================================

  /// Border sutil
  static Color get borderSubtle => Colors.white.withValues(alpha: 0.1);

  /// Border normal
  static Color get border => Colors.white.withValues(alpha: 0.2);

  /// Border enfatizado
  static Color get borderEmphasis => Colors.white.withValues(alpha: 0.3);

  /// Border primario
  static Color get borderPrimary => primary.withValues(alpha: 0.3);
}
