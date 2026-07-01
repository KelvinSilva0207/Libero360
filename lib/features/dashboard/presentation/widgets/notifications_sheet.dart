import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../notifications/presentation/views/notifications_screen.dart';

class NotificationsSheet {
  static void show(BuildContext context, {required bool isDark}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSheetContent(isDark: isDark),
    );
  }
}

class _NotificationSheetContent extends StatelessWidget {
  final bool isDark;

  const _NotificationSheetContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final textPri = isDark ? cs.onSurface : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.border : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPri,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pushSlide(const NotificationsScreen());
                  },
                  child: Text(
                    'Ver todas',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceLight : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        size: 32, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin notificaciones',
                    style: TextStyle(
                      color: textPri,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Las notificaciones importantes aparecerán aquí',
                    style: TextStyle(color: textSec, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
