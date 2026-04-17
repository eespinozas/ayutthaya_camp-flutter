import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';

/// Botón con icono gradient y sombra glow
/// Usado en AppBars y headers
class GradientIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final List<Color>? gradientColors;
  final double size;
  final double iconSize;

  const GradientIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.gradientColors,
    this.size = 40.0,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? AppColors.primaryGradient;

    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
            boxShadow: AppColors.primaryGlow,
          ),
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
