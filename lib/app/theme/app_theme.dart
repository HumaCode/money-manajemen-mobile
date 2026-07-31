import 'package:flutter/material.dart';

/// MoneyFlow Design System
/// Consistent with web version: dark luxury theme
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bgDeep = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF111827);
  static const Color bgCardHover = Color(0xFF1A2332);
  static const Color bgInput = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)

  // Borders
  static const Color cardBorder = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)

  // Text
  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF6B7280);

  // Accent (brand)
  static const Color accent = Color(0xFF7DD3A8);
  static const Color accentGlow = Color(0x4D7DD3A8); // rgba(125,211,168,0.3)

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);

  // Gradients
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDeep, Color(0xFF0D1220), bgCard],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7DD3A8), Color(0xFF4FB88A)],
  );
}

class AppRadius {
  AppRadius._();
  static const double card = 14.0;
  static const double button = 12.0;
  static const double pill = 999.0;
}

class AppTextStyles {
  AppTextStyles._();

  // Swap fontFamily to GoogleFonts.inter() if google_fonts package is added
  static const String fontFamily = 'Inter';

  static const TextStyle brand = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle tagline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle loaderLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}

final ThemeData moneyFlowTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bgDeep,
  fontFamily: AppTextStyles.fontFamily,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accent,
    secondary: AppColors.info,
    surface: AppColors.bgCard,
    error: AppColors.error,
  ),
);
