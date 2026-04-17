import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Ayutthaya Camp - Typography System
/// Estilos de texto centralizados
class AppTextStyles {
  AppTextStyles._(); // Constructor privado

  // ============================================================================
  // HEADINGS
  // ============================================================================

  /// H1 - Títulos principales (Dashboard, Headers)
  static const TextStyle h1 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  /// H2 - Títulos de sección
  static const TextStyle h2 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// H3 - Subtítulos
  static const TextStyle h3 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// H4 - Títulos de cards
  static const TextStyle h4 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// H5 - Títulos pequeños
  static const TextStyle h5 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // ============================================================================
  // BODY TEXT
  // ============================================================================

  /// Body Large - Texto principal grande
  static const TextStyle bodyLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// Body - Texto principal
  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// Body Small - Texto secundario
  static const TextStyle bodySmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ============================================================================
  // CAPTIONS & LABELS
  // ============================================================================

  /// Caption - Texto pequeño (timestamps, badges)
  static TextStyle get caption => TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  /// Label - Labels de formularios, botones
  static const TextStyle label = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Label Small - Labels pequeños
  static const TextStyle labelSmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // ============================================================================
  // SPECIAL TEXT STYLES
  // ============================================================================

  /// KPI Value - Números grandes en stats
  static const TextStyle kpiValue = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  /// KPI Value Large - Números muy grandes
  static const TextStyle kpiValueLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 1.1,
  );

  /// KPI Label - Labels de KPIs
  static const TextStyle kpiLabel = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Button Text - Texto de botones
  static const TextStyle button = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  /// Button Text Small - Texto de botones pequeños
  static const TextStyle buttonSmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Crear estilo con color personalizado
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Crear estilo muted (70% opacity)
  static TextStyle muted(TextStyle style) {
    return style.copyWith(
      color: (style.color ?? AppColors.textPrimary).withValues(alpha: 0.7),
    );
  }

  /// Crear estilo disabled (50% opacity)
  static TextStyle disabled(TextStyle style) {
    return style.copyWith(
      color: (style.color ?? AppColors.textPrimary).withValues(alpha: 0.5),
    );
  }
}
