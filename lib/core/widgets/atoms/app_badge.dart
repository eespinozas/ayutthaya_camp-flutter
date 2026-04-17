import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_design_tokens.dart';

/// Badge types for different states
enum AppBadgeType {
  success,
  error,
  warning,
  info,
  neutral,
  primary,
}

/// Status badge component
class AppBadge extends StatelessWidget {
  final String text;
  final AppBadgeType type;
  final AppBadgeSize size;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    this.type = AppBadgeType.neutral,
    this.size = AppBadgeSize.medium,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusChip),
        border: Border.all(
          color: _getBackgroundColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: _getIconSize(),
              color: _getTextColor(),
            ),
            SizedBox(width: AppDesignTokens.spaceXs),
          ],
          Text(
            text,
            style: _getTextStyle().copyWith(color: _getTextColor()),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppBadgeSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spaceSm,
          vertical: AppDesignTokens.spaceXs,
        );
      case AppBadgeSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spaceMd,
          vertical: AppDesignTokens.spaceSm,
        );
      case AppBadgeSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spaceLg,
          vertical: AppDesignTokens.spaceSm,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppBadgeSize.small:
        return AppDesignTokens.iconSizeXs;
      case AppBadgeSize.medium:
        return AppDesignTokens.iconSizeSm;
      case AppBadgeSize.large:
        return AppDesignTokens.iconSizeMd;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppBadgeSize.small:
        return AppTextStyles.labelSmall;
      case AppBadgeSize.medium:
        return AppTextStyles.labelMedium;
      case AppBadgeSize.large:
        return AppTextStyles.labelLarge;
    }
  }

  Color _getBackgroundColor() {
    switch (type) {
      case AppBadgeType.success:
        return AppColors.success;
      case AppBadgeType.error:
        return AppColors.error;
      case AppBadgeType.warning:
        return AppColors.warning;
      case AppBadgeType.info:
        return AppColors.info;
      case AppBadgeType.neutral:
        return AppColors.textSecondary;
      case AppBadgeType.primary:
        return AppColors.tigerOrange;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case AppBadgeType.success:
        return AppColors.success;
      case AppBadgeType.error:
        return AppColors.error;
      case AppBadgeType.warning:
        return AppColors.warning;
      case AppBadgeType.info:
        return AppColors.info;
      case AppBadgeType.neutral:
        return AppColors.textSecondary;
      case AppBadgeType.primary:
        return AppColors.tigerOrange;
    }
  }
}

/// Badge size enum
enum AppBadgeSize {
  small,
  medium,
  large,
}

/// Notification badge (dot with count)
class AppNotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const AppNotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlack,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
