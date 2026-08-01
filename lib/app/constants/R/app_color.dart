import 'package:flutter/material.dart';

/// MoneyFlow Design System - Color Palette
class AppColor {
  // Constructor to allow instantiation if needed (e.g. for R.colors)
  AppColor();

  // Background Colors
  static const Color bgDeep = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF111827);
  static const Color bgCardHover = Color(0xFF1A2332);
  static const Color bgInput = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)

  // Border & Divider Colors
  static const Color cardBorder = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color border = Color(0x0FFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Accent & Brand Colors
  static const Color primary = Color(0xFF7DD3A8);
  static const Color primaryGlow = Color(0x4D7DD3A8); // rgba(125,211,168,0.3)
  static const Color accent = Color(0xFF7DD3A8);
  static const Color accentGlow = Color(0x4D7DD3A8);

  // Status & Functional Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);

  // Category Colors
  static const Color categoryFood = Color(0xFFF59E0B);
  static const Color categoryTransport = Color(0xFF3B82F6);
  static const Color categoryShopping = Color(0xFFEC4899);
  static const Color categoryBills = Color(0xFF8B5CF6);
  static const Color categoryEntertainment = Color(0xFF10B981);
  static const Color categorySalary = Color(0xFF7DD3A8);
  static const Color categoryInvestment = Color(0xFF6366F1);

  // Basic Palette
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Gradients
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A0E1A),
      Color(0xFF0D1220),
      Color(0xFF111827),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7DD3A8),
      Color(0xFF4FB88A),
    ],
  );
}
