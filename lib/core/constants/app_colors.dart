import 'package:flutter/material.dart';

/// Centralized color palette for Contractly.
///
/// Hex tokens are mirrored from the design spec — never hardcode hex values
/// in widget code; reference [AppColors] instead.
class AppColors {
  const AppColors._();

  // Brand
  static const Color brandPrimary = Color(0xFF1A1A2E);
  static const Color brandSurface = Color(0xFF16213E);
  static const Color brandCard = Color(0xFF0F3460);
  static const Color brandAccent = Color(0xFFE94560);
  static const Color brandAccentSoft = Color(0xFFFF6B6B);
  static const Color brandGold = Color(0xFFC9A84C);

  // Status
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color danger = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3FA7D6);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA0A0B0);
  static const Color textMuted = Color(0xFF6F6F80);

  // Layout
  static const Color divider = Color(0xFF1E2A45);
  static const Color glassFill = Color(0xFF0F3460);
  static const Color glassBorder = Color(0x14FFFFFF); // white @ 8%

  // Risk levels
  static const Color riskLow = success;
  static const Color riskMedium = warning;
  static const Color riskHigh = danger;

  // Status colors helper
  static Color statusBgFor(String status) {
    switch (status) {
      case 'active':
        return success.withValues(alpha: 0.15);
      case 'expiring_soon':
        return warning.withValues(alpha: 0.15);
      case 'expired':
        return danger.withValues(alpha: 0.15);
      case 'completed':
        return info.withValues(alpha: 0.15);
      case 'cancelled':
        return textMuted.withValues(alpha: 0.18);
      case 'draft':
      default:
        return textSecondary.withValues(alpha: 0.15);
    }
  }

  static Color statusFgFor(String status) {
    switch (status) {
      case 'active':
        return success;
      case 'expiring_soon':
        return warning;
      case 'expired':
        return danger;
      case 'completed':
        return info;
      case 'cancelled':
        return textMuted;
      case 'draft':
      default:
        return textSecondary;
    }
  }
}
