import 'package:flutter/material.dart';

class AppTheme {
  // ============================================
  // BRAND COLORS - used across all 7 screens
  // ============================================

  // Primary blue - main app color, headers, buttons
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);

  // Green - confidence badges, success states, "on time"
  static const Color accent = Color(0xFF10B981);
  static const Color accentLight = Color(0xFFD1FAE5);

  // Red - errors, delays, alerts
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Yellow/Amber - warnings, "Leave NOW" alerts
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Purple - Crowd Intel screen, Link rail, transfer badges
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFEDE9FE);

  // ============================================
  // SURFACE COLORS - backgrounds and text
  // ============================================

  static const Color surface = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);

  // ============================================
  // THEME DATA - applied to the whole app
  // ============================================

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primary,
        brightness: Brightness.light,
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 1),
          ),
        ),
      );

  // ============================================
  // HELPER: returns the branded color for a route
  // ============================================

  static Color getRouteColor(String routeId) {
    switch (routeId) {
      case '271':
        return const Color(0xFF3B82F6); // Blue
      case 'B Line':
        return const Color(0xFF10B981); // Green
      case '245':
        return const Color(0xFFF97316); // Orange
      case '550':
        return const Color(0xFF8B5CF6); // Purple
      case '241':
        return const Color(0xFFF59E0B); // Amber
      case 'Link':
        return const Color(0xFF8B5CF6); // Purple (light rail)
      case '556':
        return const Color(0xFFEC4899); // Pink
      default:
        return primary;
    }
  }
}