import 'package:flutter/material.dart';
import 'package:money_manajemen/app/constants/R/app_color.dart';

typedef AppColors = AppColor;



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
