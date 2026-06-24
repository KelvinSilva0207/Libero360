import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../data/stats_dashboard_model.dart';

class RecentActivitySection extends StatelessWidget {
  final List<ActivityItem> activities;
  final bool isDark;

  const RecentActivitySection({
    super.key,
    required this.activities,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          _emptyState()
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? AppColors.border : AppColors.lightBorder),
              ),
            ),
            child: Column(
              children: List.generate(activities.length, (i) {
                return Column(
                  children: [
                    _activityRow(activities[i]),
                    if (i < activities.length - 1) _timelineConnector(),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        Icon(Icons.timeline, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text('ACTIVIDAD RECIENTE',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            )),
      ],
    );
  }

  Widget _activityRow(ActivityItem item) {
    final hoursAgo = DateTime.now().difference(item.timestamp).inHours;
    final timeStr = hoursAgo < 1
        ? 'Ahora'
        : hoursAgo < 24
            ? '${hoursAgo}h'
            : '${item.timestamp.day}/${item.timestamp.month}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _iconBg(item.type),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(item.icon,
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(timeStr,
              style: TextStyle(
                color: isDark
                    ? AppColors.textTertiary
                    : AppColors.lightTextTertiary,
                fontSize: 11,
              )),
        ],
      ),
    );
  }

  Widget _timelineConnector() {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.only(left: 15),
      color: (isDark ? AppColors.textTertiary : AppColors.lightTextTertiary)
          .withValues(alpha: 0.2),
    );
  }

  Color _iconBg(ActivityType type) {
    switch (type) {
      case ActivityType.mvp:
        return AppColors.accent.withValues(alpha: 0.15);
      case ActivityType.match:
        return AppColors.primary.withValues(alpha: 0.15);
      case ActivityType.training:
        return AppColors.info.withValues(alpha: 0.15);
      case ActivityType.medical:
        return AppColors.error.withValues(alpha: 0.15);
      case ActivityType.photo:
        return AppColors.success.withValues(alpha: 0.15);
    }
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.border : AppColors.lightBorder),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.timeline_outlined,
                size: 40,
                color: (isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary)
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Sin actividad reciente',
                style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
