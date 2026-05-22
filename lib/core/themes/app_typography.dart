import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => const TextStyle(
    fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => const TextStyle(
    fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.25,
  );

  static TextStyle get headlineLarge => const TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  static TextStyle get headlineMedium => const TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get headlineSmall => const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get titleLarge => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );

  static TextStyle get titleSmall => const TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textTertiary,
  );

  static TextStyle get labelLarge => const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );

  static TextStyle get labelMedium => const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );

  static TextStyle get labelSmall => const TextStyle(
    fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textTertiary,
  );

  static TextStyle get button => const TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary, letterSpacing: 0.5,
  );

  static TextStyle get buttonSmall => const TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textOnPrimary, letterSpacing: 0.3,
  );

  static TextStyle get caption => const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textTertiary, letterSpacing: 0.2,
  );

  static TextStyle get overline => const TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 1.0,
  );
}
