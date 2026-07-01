import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/dashboard_model.dart';

class TeamStatusSection extends StatelessWidget {
  final TeamStatus status;
  final bool isDark;
  final VoidCallback? onMedicalTap;
  final VoidCallback? onAbsenceTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onMvpTap;

  const TeamStatusSection({
    super.key,
    required this.status,
    required this.isDark,
    this.onMedicalTap,
    this.onAbsenceTap,
    this.onStreakTap,
    this.onMvpTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final borderClr = isDark ? AppColors.border : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderClr),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Estado del Equipo', isDark),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatusTileWidget(
                  icon: '⚠',
                  label: 'Reposo médico',
                  value: '${status.medicalRestCount} atletas',
                  color: AppColors.error,
                  isDark: isDark,
                  onTap: onMedicalTap,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StatusTileWidget(
                  icon: '🚫',
                  label: 'Ausencias',
                  value: '${status.absenceCount} atletas',
                  color: AppColors.warning,
                  isDark: isDark,
                  onTap: onAbsenceTap,
                )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _StatusTileWidget(
                  icon: '🔥',
                  label: 'Racha',
                  value: '${status.winStreak} victorias consecutivas',
                  color: AppColors.accent,
                  isDark: isDark,
                  onTap: onStreakTap,
                )),
                const SizedBox(width: 8),
                Expanded(child: _StatusTileWidget(
                  icon: '⭐',
                  label: 'MVP actual',
                  value: status.currentMvp ?? 'N/A',
                  color: AppColors.primary,
                  isDark: isDark,
                  onTap: onMvpTap,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textSecondary : AppColors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _StatusTileWidget extends StatefulWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatusTileWidget({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_StatusTileWidget> createState() => _StatusTileWidgetState();
}

class _StatusTileWidgetState extends State<_StatusTileWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textPri = widget.isDark ? cs.onSurface : AppColors.textPrimary;
    final textSec = widget.isDark ? AppColors.textSecondary : AppColors.textTertiary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovered ? Matrix4.diagonal3Values(1.03, 1.03, 1.0) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _isHovered ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [BoxShadow(
                    color: widget.color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 8),
              Text(widget.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: textPri,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 1),
              Text(widget.label,
                  style: TextStyle(fontSize: 10, color: textSec)),
            ],
          ),
        ),
      ),
    );
  }
}
