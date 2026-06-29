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
    final textPri = isDark ? Colors.white : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final borderClr = isDark ? AppColors.border : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: activities.isEmpty ? BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderClr),
          ) : const BoxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Actividad Reciente', isDark),
              if (activities.isEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceLight : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.history_rounded,
                            size: 28, color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin actividad reciente',
                        style: TextStyle(
                          color: textPri,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Las actividades del equipo aparecerán aquí',
                        style: TextStyle(color: textSec, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              if (activities.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...List.generate(activities.length, (i) {
                  final a = activities[i];
                  final isLast = i == activities.length - 1;
                  return _ActivityRowWidget(
                    item: a,
                    isLast: isLast,
                    isDark: isDark,
                  );
                }),
              ],
            ],
          ),
        ),
      );
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

class _ActivityRowWidget extends StatefulWidget {
  final ActivityItem item;
  final bool isLast;
  final bool isDark;

  const _ActivityRowWidget({
    required this.item,
    required this.isLast,
    required this.isDark,
  });

  @override
  State<_ActivityRowWidget> createState() => _ActivityRowWidgetState();
}

class _ActivityRowWidgetState extends State<_ActivityRowWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textPri = widget.isDark ? Colors.white : AppColors.textPrimary;
    final textSec = widget.isDark ? AppColors.textSecondary : AppColors.textTertiary;
    final a = widget.item;
    final isLast = widget.isLast;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 6,
          bottom: isLast ? 6 : 6,
        ),
        margin: EdgeInsets.only(bottom: isLast ? 0 : 4),
        decoration: BoxDecoration(
          color: _isHovered
              ? (widget.isDark ? AppColors.surfaceLight : AppColors.lightSurface)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.isDark ? AppColors.surfaceLight : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(a.icon, style: const TextStyle(fontSize: 18))),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: widget.isDark ? AppColors.border : AppColors.lightBorder,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.description,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textPri,
                        ),
                      ),
                      if (a.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          a.subtitle!,
                          style: TextStyle(fontSize: 12, color: textSec),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _timeAgo(a.timestamp),
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
        ),
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
}
