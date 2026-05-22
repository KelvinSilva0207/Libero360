import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;
  final AppButtonType type;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.expanded = true,
    this.type = AppButtonType.primary,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final child = _buildChild();
    if (!expanded) return child;
    return SizedBox(width: double.infinity, height: height ?? 52, child: child);
  }

  Widget _buildChild() {
    Widget content;
    if (isLoading) {
      content = const SizedBox(
        width: 22, height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textOnPrimary),
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 10),
          ],
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        ],
      );
    }

    switch (type) {
      case AppButtonType.primary:
        return FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          ),
          child: content,
        );
      case AppButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceLight,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: content,
        );
      case AppButtonType.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
      case AppButtonType.social:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.borderLight),
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: content,
        );
    }
  }
}

enum AppButtonType { primary, secondary, ghost, social }

class SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onPressed;

  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderLight),
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
