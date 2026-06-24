import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../asistencia/presentation/views/athlete_list_screen.dart';
import '../../../estadisticas/presentation/views/play_by_play_screen.dart';
import '../../../statistics/presentation/views/statistics_screen.dart';
import '../../../asistencia/presentation/views/attendance_screen.dart';
import '../../../admin/presentation/views/admin_screen.dart';

class QuickAccessRow extends StatelessWidget {
  final bool isDark;

  const QuickAccessRow({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Accesos Rápidos', isDark),
            const SizedBox(height: 14),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return _quickButton(
                    icon: item.icon,
                    label: item.label,
                    color: item.color,
                    onTap: () {
                      context.pushSlide(item.pageBuilder());
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickButton({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 150),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.border : AppColors.lightBorder,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondary : AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _items = [
    _QuickItem('👥', 'Atletas', AppColors.primary, () => const AthleteListScreen()),
    _QuickItem('🏐', 'Partido', AppColors.accent, () => const PlayByPlayScreen()),
    _QuickItem('📈', 'Estadísticas', AppColors.success, () => const StatisticsScreen()),
    _QuickItem('📅', 'Asistencia', AppColors.info, () => const AttendanceScreen()),
    _QuickItem('☁', 'Staff', AppColors.warning, () => const AdminScreen()),
  ];

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

class _QuickItem {
  final String icon;
  final String label;
  final Color color;
  final Widget Function() pageBuilder;

  const _QuickItem(this.icon, this.label, this.color, this.pageBuilder);
}
