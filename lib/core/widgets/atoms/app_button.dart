import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_design_tokens.dart';

/// Primary button with tiger orange gradient
class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonSize size;

  const AppPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.size = AppButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _getHeight(),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tigerOrange,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: _getHorizontalPadding(),
            vertical: AppDesignTokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusButton),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: _getIconSize()),
                    const SizedBox(width: AppDesignTokens.spaceSm),
                  ],
                  Text(
                    text,
                    style: _getTextStyle(),
                  ),
                ],
              ),
      ),
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppDesignTokens.buttonHeightSm;
      case AppButtonSize.medium:
        return AppDesignTokens.buttonHeightMd;
      case AppButtonSize.large:
        return AppDesignTokens.buttonHeightLg;
    }
  }

  double _getHorizontalPadding() {
    switch (size) {
      case AppButtonSize.small:
        return AppDesignTokens.spaceLg;
      case AppButtonSize.medium:
        return AppDesignTokens.spaceXl;
      case AppButtonSize.large:
        return AppDesignTokens.space2xl;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppDesignTokens.iconSizeSm;
      case AppButtonSize.medium:
        return AppDesignTokens.iconSizeMd;
      case AppButtonSize.large:
        return AppDesignTokens.iconSizeLg;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.labelMedium;
      case AppButtonSize.medium:
        return AppTextStyles.labelLarge;
      case AppButtonSize.large:
        return AppTextStyles.titleMedium;
    }
  }
}

/// Secondary button with outline
class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonSize size;

  const AppSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.size = AppButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _getHeight(),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          padding: EdgeInsets.symmetric(
            horizontal: _getHorizontalPadding(),
            vertical: AppDesignTokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusButton),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: _getIconSize()),
                    const SizedBox(width: AppDesignTokens.spaceSm),
                  ],
                  Text(
                    text,
                    style: _getTextStyle(),
                  ),
                ],
              ),
      ),
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppDesignTokens.buttonHeightSm;
      case AppButtonSize.medium:
        return AppDesignTokens.buttonHeightMd;
      case AppButtonSize.large:
        return AppDesignTokens.buttonHeightLg;
    }
  }

  double _getHorizontalPadding() {
    switch (size) {
      case AppButtonSize.small:
        return AppDesignTokens.spaceLg;
      case AppButtonSize.medium:
        return AppDesignTokens.spaceXl;
      case AppButtonSize.large:
        return AppDesignTokens.space2xl;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppDesignTokens.iconSizeSm;
      case AppButtonSize.medium:
        return AppDesignTokens.iconSizeMd;
      case AppButtonSize.large:
        return AppDesignTokens.iconSizeLg;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.labelMedium;
      case AppButtonSize.medium:
        return AppTextStyles.labelLarge;
      case AppButtonSize.large:
        return AppTextStyles.titleMedium;
    }
  }
}

/// Text button (tertiary style)
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonSize size;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.size = AppButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.tigerOrange,
        padding: EdgeInsets.symmetric(
          horizontal: _getHorizontalPadding(),
          vertical: AppDesignTokens.spaceSm,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _getIconSize()),
            const SizedBox(width: AppDesignTokens.spaceSm),
          ],
          Text(
            text,
            style: _getTextStyle(),
          ),
        ],
      ),
    );
  }

  double _getHorizontalPadding() {
    switch (size) {
      case AppButtonSize.small:
        return AppDesignTokens.spaceMd;
      case AppButtonSize.medium:
        return AppDesignTokens.spaceLg;
      case AppButtonSize.large:
        return AppDesignTokens.spaceXl;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppDesignTokens.iconSizeSm;
      case AppButtonSize.medium:
        return AppDesignTokens.iconSizeMd;
      case AppButtonSize.large:
        return AppDesignTokens.iconSizeLg;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.labelMedium;
      case AppButtonSize.medium:
        return AppTextStyles.labelLarge;
      case AppButtonSize.large:
        return AppTextStyles.titleMedium;
    }
  }
}

/// Button size enum
enum AppButtonSize {
  small,
  medium,
  large,
}
