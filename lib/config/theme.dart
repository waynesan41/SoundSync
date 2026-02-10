import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

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
  );
}