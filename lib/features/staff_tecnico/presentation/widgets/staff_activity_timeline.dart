import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/staff_tecnico_models.dart';

class StaffActivityTimeline extends StatelessWidget {
  final List<StaffActivity> activities;

  const StaffActivityTimeline({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 40, color: cs.onSurface.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              Text(
                'Sin actividad reciente',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(activities.length, (i) {
        final activity = activities[i];
        final isLast = i == activities.length - 1;
        return _activityRow(context, activity, isLast, cs);
      }),
    );
  }

  Widget _activityRow(BuildContext context, StaffActivity activity, bool isLast, ColorScheme cs) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(activity.type.icon, style: const TextStyle(fontSize: 14)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: AppColors.borderLight.withValues(alpha: 0.2),
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
                    activity.message,
                    style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(activity.createdAt),
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
