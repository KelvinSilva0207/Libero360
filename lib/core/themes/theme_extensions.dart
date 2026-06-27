import 'package:flutter/material.dart';
import 'app_colors.dart';

extension ThemeColors on BuildContext {
  Color get surface => colorScheme.surface;
  Color get surfaceContainer => colorScheme.surfaceContainerHighest;
  Color get surfaceContainerLow => colorScheme.surfaceContainerLow;
  Color get primary => colorScheme.primary;
  Color get onPrimary => colorScheme.onPrimary;
  Color get primaryContainer => colorScheme.primaryContainer;
  Color get secondary => colorScheme.secondary;
  Color get onSecondary => colorScheme.onSecondary;
  Color get error => colorScheme.error;
  Color get onError => colorScheme.onError;
  Color get textPrimary => colorScheme.onSurface;
  Color get textSecondary => colorScheme.onSurfaceVariant;
  Color get textTertiary => colorScheme.outline;
  Color get border => colorScheme.outlineVariant;
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get info => AppColors.info;
  Color get scaffoldBg => colorScheme.surface;
  Color get cardBg => colorScheme.surfaceContainerHighest;
  Color get chipBg => colorScheme.surfaceContainerLow;
  Color get dividerClr => colorScheme.outlineVariant;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => colorScheme.brightness == Brightness.dark;
}
