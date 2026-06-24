import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/dashboard_model.dart';

class RecentActivityTimeline extends StatelessWidget {
  final List<ActivityItem> activities;
  final bool isDark;

  const RecentActivityTimeline({
    super.key,
    required this.activities,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final textPri = isDark ? Colors.white : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Actividad Reciente', isDark),
            const SizedBox(height: 14),
            ...List.generate(activities.length, (i) {
              final a = activities[i];
              final isLast = i == activities.length - 1;
              return _activityRow(a, isLast, textPri, textSec);
            }),
          ],
        ),
      ),
    );
  }

  Widget _activityRow(ActivityItem item, bool isLast, Color textPri, Color textSec) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceLight : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 16))),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark ? AppColors.border : AppColors.lightBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textPri,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: TextStyle(fontSize: 12, color: textSec),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(item.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: textSec,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    if (diff.inDays > 0) return 'Hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
    if (diff.inHours > 0) return 'Hace ${diff.inHours} h';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes} min';
    return 'Ahora';
  }

  static Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textSecondary : AppColors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}
