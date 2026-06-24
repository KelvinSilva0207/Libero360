import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/dashboard_model.dart';

class TeamStatusSection extends StatelessWidget {
  final TeamStatus status;
  final bool isDark;

  const TeamStatusSection({
    super.key,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final borderClr = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? Colors.white : AppColors.textPrimary;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderClr),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Estado del Equipo', isDark),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statusTile(
                    icon: '⚠',
                    label: 'Reposo médico',
                    value: '${status.medicalRestCount} atletas',
                    color: AppColors.error,
                    textPri: textPri,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _statusTile(
                    icon: '🚫',
                    label: 'Ausencias',
                    value: '${status.absenceCount} atletas',
                    color: AppColors.warning,
                    textPri: textPri,
                  )),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _statusTile(
                    icon: '🔥',
                    label: 'Racha',
                    value: '${status.winStreak} victorias consecutivas',
                    color: AppColors.accent,
                    textPri: textPri,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _statusTile(
                    icon: '⭐',
                    label: 'MVP actual',
                    value: status.currentMvp ?? 'N/A',
                    color: AppColors.primary,
                    textPri: textPri,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusTile({
    required String icon,
    required String label,
    required String value,
    required Color color,
    required Color textPri,
  }) {
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: textPri,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: textSec)),
        ],
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
