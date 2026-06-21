import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class TimeoutIndicator extends StatelessWidget {
  final int remaining;
  final int max;
  final String teamName;
  final bool isLocal;
  final VoidCallback? onTap;
  final bool disabled;

  const TimeoutIndicator({
    super.key,
    required this.remaining,
    required this.max,
    required this.teamName,
    required this.isLocal,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLocal ? AppColors.accent : AppColors.primary;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: remaining > 0 ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: remaining > 0
                ? color.withValues(alpha: 0.3)
                : Colors.white10,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              teamName,
              style: TextStyle(
                color: remaining > 0 ? color : Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined,
                    size: 14,
                    color: remaining > 0 ? color : Colors.white24),
                const SizedBox(width: 4),
                Text(
                  '$remaining/$max',
                  style: TextStyle(
                    color: remaining > 0 ? Colors.white : Colors.white24,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
