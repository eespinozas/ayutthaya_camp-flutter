import 'package:flutter/material.dart';

/// Design Tokens for Ayutthaya Camp
/// Centralized design decisions for spacing, sizing, radius, shadows, and animations
class AppDesignTokens {
  AppDesignTokens._();

  // ============================================
  // SPACING
  // ============================================
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;
  static const double space3xl = 64.0;

  // ============================================
  // SIZING
  // ============================================

  // Icon Sizes
  static const double iconSizeXs = 16.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  // Button Heights
  static const double buttonHeightSm = 40.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;

  // Input Heights
  static const double inputHeight = 56.0;

  // Avatar Sizes
  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 48.0;
  static const double avatarSizeLg = 64.0;
  static const double avatarSizeXl = 96.0;

  // Container Widths (max-width for responsive)
  static const double containerWidthSm = 640.0;
  static const double containerWidthMd = 768.0;
  static const double containerWidthLg = 1024.0;
  static const double containerWidthXl = 1280.0;

  // ============================================
  // BORDER RADIUS
  // ============================================
  static const double radiusNone = 0.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2xl = 24.0;
  static const double radiusFull = 9999.0; // For pills/circular

  // Specific Component Radius
  static const double radiusButton = radiusMd;
  static const double radiusCard = radiusLg;
  static const double radiusInput = radiusMd;
  static const double radiusDialog = radiusXl;
  static const double radiusChip = radiusSm;

  // ============================================
  // SHADOWS (Elevation)
  // ============================================

  // No Shadow
  static const List<BoxShadow> shadowNone = [];

  // Subtle Shadow (cards, inputs)
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  // Standard Shadow (elevated cards)
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Prominent Shadow (modals, floating buttons)
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // Dramatic Shadow (dialogs, important overlays)
  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // Tiger Orange Glow (for accent elements)
  static const List<BoxShadow> shadowTigerGlow = [
    BoxShadow(
      color: Color(0x40FF6B00), // Tiger orange with opacity
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // ============================================
  // ANIMATION DURATIONS
  // ============================================
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 400);
  static const Duration animationSlower = Duration(milliseconds: 600);

  // ============================================
  // ANIMATION CURVES
  // ============================================
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveElastic = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;

  // ============================================
  // OPACITY LEVELS
  // ============================================
  static const double opacityDisabled = 0.38;
  static const double opacityInactive = 0.54;
  static const double opacityHover = 0.08;
  static const double opacityPressed = 0.12;
  static const double opacityOverlay = 0.16;

  // ============================================
  // Z-INDEX (Stacking Order)
  // ============================================
  static const int zIndexBackground = -1;
  static const int zIndexBase = 0;
  static const int zIndexRaised = 1;
  static const int zIndexDropdown = 10;
  static const int zIndexSticky = 20;
  static const int zIndexModal = 30;
  static const int zIndexPopover = 40;
  static const int zIndexTooltip = 50;

  // ============================================
  // BREAKPOINTS (Responsive Design)
  // ============================================
  static const double breakpointMobile = 480.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;
  static const double breakpointWide = 1280.0;

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get responsive padding based on screen width
  static EdgeInsets responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpointMobile) {
      return const EdgeInsets.all(spaceMd);
    } else if (width < breakpointTablet) {
      return const EdgeInsets.all(spaceLg);
    } else {
      return const EdgeInsets.all(spaceXl);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < breakpointMobile) {
      return const EdgeInsets.symmetric(horizontal: spaceMd);
    } else if (width < breakpointTablet) {
      return const EdgeInsets.symmetric(horizontal: spaceLg);
    } else {
      return const EdgeInsets.symmetric(horizontal: spaceXl);
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointTablet;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointTablet && width < breakpointDesktop;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointDesktop;
  }
}

/// Extension for easier access to design tokens in widgets
extension DesignTokensContext on BuildContext {
  /// Get responsive padding
  EdgeInsets get responsivePadding => AppDesignTokens.responsivePadding(this);

  /// Get responsive horizontal padding
  EdgeInsets get responsiveHorizontalPadding =>
      AppDesignTokens.responsiveHorizontalPadding(this);

  /// Check if mobile
  bool get isMobile => AppDesignTokens.isMobile(this);

  /// Check if tablet
  bool get isTablet => AppDesignTokens.isTablet(this);

  /// Check if desktop
  bool get isDesktop => AppDesignTokens.isDesktop(this);
}
