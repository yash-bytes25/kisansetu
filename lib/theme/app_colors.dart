import 'package:flutter/material.dart';

/// Centralized color palette for KisanSetu.
///
/// Designed with high contrast and agricultural aesthetics:
/// - Deep green primary reflecting agriculture and procurement
/// - Off-white/light warm backgrounds for high outdoor readability
/// - High-contrast dark typography suitable for all digital literacy levels
abstract final class AppColors {
  // Primary Agricultural Green
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF0C3B0E);
  static const Color primaryContainer = Color(0xFFE8F5E9);
  static const Color onPrimaryContainer = Color(0xFF002105);

  // Secondary & Accents
  static const Color secondary = Color(0xFF386A20);
  static const Color secondaryContainer = Color(0xFFD6F0C8);
  static const Color accentAmber = Color(0xFFE65100);

  // Background & Surfaces
  static const Color background = Color(0xFFF7F9F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEAEFE9);
  static const Color cardBorder = Color(0xFFD6DDD5);

  // Typography & Content
  static const Color textPrimary = Color(0xFF141A14);
  static const Color textSecondary = Color(0xFF3F4A3F);
  static const Color textTertiary = Color(0xFF6B756A);
  static const Color iconColor = Color(0xFF233523);

  // Status & Feedback
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color warning = Color(0xFFE65100);
  static const Color warningContainer = Color(0xFFFFF3E0);
}
