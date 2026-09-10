import 'package:flutter/material.dart';

/// Centralized responsive layout breakpoints and helper utilities for KisanSetu.
///
/// Designed to provide:
/// - Compact, information-dense multi-column operational views on Desktop (Chrome, macOS, Windows)
/// - Balanced flexible views on Tablet (iPad, Android tablets, foldables)
/// - High-contrast, large-touch-target (>= 48dp) views on Mobile
abstract final class ResponsiveLayout {
  static const double mobileMax = 600.0;
  static const double desktopMin = 850.0;
  static const double largeDesktopMin = 1200.0;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMin;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileMax && w < desktopMin;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  /// Returns value based on screen width
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= desktopMin) return desktop;
    if (w >= mobileMax && tablet != null) return tablet;
    return mobile;
  }
}

/// Widget builder that adapts layout based on parent container constraints.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)? tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints) desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveLayout.desktopMin) {
          return desktop(context, constraints);
        }
        if (constraints.maxWidth >= ResponsiveLayout.mobileMax && tablet != null) {
          return tablet!(context, constraints);
        }
        return mobile(context, constraints);
      },
    );
  }
}
