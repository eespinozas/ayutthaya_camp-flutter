import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_design_tokens.dart';

/// Avatar sizes
enum AppAvatarSize {
  small,
  medium,
  large,
  extraLarge,
}

/// User avatar component
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final AppAvatarSize size;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.medium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarWidget = CircleAvatar(
      radius: _getRadius(),
      backgroundColor: AppColors.tigerOrange,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              _getInitials(),
              style: _getTextStyle(),
            )
          : null,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusFull),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  double _getRadius() {
    switch (size) {
      case AppAvatarSize.small:
        return AppDesignTokens.avatarSizeSm / 2;
      case AppAvatarSize.medium:
        return AppDesignTokens.avatarSizeMd / 2;
      case AppAvatarSize.large:
        return AppDesignTokens.avatarSizeLg / 2;
      case AppAvatarSize.extraLarge:
        return AppDesignTokens.avatarSizeXl / 2;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppAvatarSize.small:
        return AppTextStyles.labelSmall.copyWith(
          color: AppColors.primaryBlack,
          fontWeight: FontWeight.w700,
        );
      case AppAvatarSize.medium:
        return AppTextStyles.labelLarge.copyWith(
          color: AppColors.primaryBlack,
          fontWeight: FontWeight.w700,
        );
      case AppAvatarSize.large:
        return AppTextStyles.titleMedium.copyWith(
          color: AppColors.primaryBlack,
          fontWeight: FontWeight.w700,
        );
      case AppAvatarSize.extraLarge:
        return AppTextStyles.headlineSmall.copyWith(
          color: AppColors.primaryBlack,
          fontWeight: FontWeight.w700,
        );
    }
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';

    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return parts[0][0].toUpperCase();
    }
  }
}

/// Avatar with online status indicator
class AppAvatarWithStatus extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final AppAvatarSize size;
  final bool isOnline;
  final VoidCallback? onTap;

  const AppAvatarWithStatus({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.medium,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppAvatar(
          imageUrl: imageUrl,
          name: name,
          size: size,
          onTap: onTap,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: _getStatusSize(),
            height: _getStatusSize(),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.textTertiary,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlack,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getStatusSize() {
    switch (size) {
      case AppAvatarSize.small:
        return 10;
      case AppAvatarSize.medium:
        return 12;
      case AppAvatarSize.large:
        return 14;
      case AppAvatarSize.extraLarge:
        return 16;
    }
  }
}

/// Avatar group (overlapping avatars)
class AppAvatarGroup extends StatelessWidget {
  final List<String?> imageUrls;
  final List<String?> names;
  final AppAvatarSize size;
  final int maxDisplay;

  const AppAvatarGroup({
    super.key,
    required this.imageUrls,
    required this.names,
    this.size = AppAvatarSize.small,
    this.maxDisplay = 3,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = imageUrls.length > maxDisplay ? maxDisplay : imageUrls.length;
    final remaining = imageUrls.length - displayCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(displayCount, (index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < displayCount - 1 ? 4 : 0,
            ),
            child: AppAvatar(
              imageUrl: imageUrls[index],
              name: names.length > index ? names[index] : null,
              size: size,
            ),
          );
        }),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: _getRadius(),
              backgroundColor: AppColors.surfaceBlack,
              child: Text(
                '+$remaining',
                style: _getTextStyle(),
              ),
            ),
          ),
      ],
    );
  }

  double _getRadius() {
    switch (size) {
      case AppAvatarSize.small:
        return AppDesignTokens.avatarSizeSm / 2;
      case AppAvatarSize.medium:
        return AppDesignTokens.avatarSizeMd / 2;
      case AppAvatarSize.large:
        return AppDesignTokens.avatarSizeLg / 2;
      case AppAvatarSize.extraLarge:
        return AppDesignTokens.avatarSizeXl / 2;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppAvatarSize.small:
        return AppTextStyles.labelSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );
      case AppAvatarSize.medium:
        return AppTextStyles.labelMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );
      case AppAvatarSize.large:
        return AppTextStyles.labelLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );
      case AppAvatarSize.extraLarge:
        return AppTextStyles.titleMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );
    }
  }
}
