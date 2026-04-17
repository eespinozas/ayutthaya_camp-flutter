import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_design_tokens.dart';

/// Standard app card with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final double? borderRadius;
  final bool showBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.shadows,
    this.borderRadius,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppDesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBlack,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDesignTokens.radiusCard,
        ),
        border: showBorder
            ? Border.all(
                color: AppColors.border,
                width: 1,
              )
            : null,
        boxShadow: shadows ?? AppDesignTokens.shadowSm,
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ??
            const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spaceMd,
              vertical: AppDesignTokens.spaceSm,
            ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppDesignTokens.radiusCard,
            ),
            child: cardContent,
          ),
        ),
      );
    }

    return Padding(
      padding: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.spaceMd,
            vertical: AppDesignTokens.spaceSm,
          ),
      child: cardContent,
    );
  }
}

/// Elevated card with prominent shadow
class AppElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AppElevatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      shadows: AppDesignTokens.shadowLg,
      child: child,
    );
  }
}

/// Card with tiger orange accent border
class AppAccentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AppAccentCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppDesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        border: Border.all(
          color: AppColors.tigerOrange,
          width: 2,
        ),
        boxShadow: AppDesignTokens.shadowTigerGlow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ??
            const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spaceMd,
              vertical: AppDesignTokens.spaceSm,
            ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
            child: cardContent,
          ),
        ),
      );
    }

    return Padding(
      padding: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.spaceMd,
            vertical: AppDesignTokens.spaceSm,
          ),
      child: cardContent,
    );
  }
}

/// Gradient card with tiger orange gradient background
class AppGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AppGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppDesignTokens.spaceMd),
      decoration: BoxDecoration(
        gradient: AppColors.tigerGradient,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        boxShadow: AppDesignTokens.shadowTigerGlow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ??
            const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spaceMd,
              vertical: AppDesignTokens.spaceSm,
            ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
            child: cardContent,
          ),
        ),
      );
    }

    return Padding(
      padding: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.spaceMd,
            vertical: AppDesignTokens.spaceSm,
          ),
      child: cardContent,
    );
  }
}
