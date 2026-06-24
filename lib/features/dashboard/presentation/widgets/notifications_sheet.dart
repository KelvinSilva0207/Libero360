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
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final textPri = isDark ? Colors.white : AppColors.textPrimary;
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
                const Text(
                  '3 nuevas',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = _notifications[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: n.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text(n.icon, style: const TextStyle(fontSize: 16))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: textPri,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              n.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSec,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: textSec,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pushSlide(const NotificationsScreen());
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Ver todas',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifItem {
  final String icon;
  final String title;
  final String subtitle;
  final String timeAgo;
  final Color color;

  const _NotifItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.color,
  });
}

const _notifications = [
  _NotifItem(
    icon: '👤',
    title: 'Nuevo atleta registrado',
    subtitle: 'María González',
    timeAgo: 'Hace 5 min',
    color: Color(0xFF0081CF),
  ),
  _NotifItem(
    icon: '🏆',
    title: 'Camila lleva',
    subtitle: '5 MVP esta temporada',
    timeAgo: 'Hace 2 horas',
    color: Color(0xFFFF8C00),
  ),
  _NotifItem(
    icon: '⚠',
    title: 'David',
    subtitle: '3 ausencias consecutivas',
    timeAgo: 'Hace 1 día',
    color: Color(0xFFEF4444),
  ),
];
