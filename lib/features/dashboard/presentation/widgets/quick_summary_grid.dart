import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/dashboard_model.dart';

class QuickSummaryGrid extends StatelessWidget {
  final QuickSummary summary;
  final bool isDark;
  final VoidCallback? onAthleteTap;
  final VoidCallback? onMatchTap;
  final VoidCallback? onWinRateTap;
  final VoidCallback? onTrainingTap;

  const QuickSummaryGrid({
    super.key,
    required this.summary,
    required this.isDark,
    this.onAthleteTap,
    this.onMatchTap,
    this.onWinRateTap,
    this.onTrainingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Resumen Rápido', isDark),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              _SummaryTileWidget(
                icon: '👥',
                label: 'Atletas',
                value: '${summary.athleteCount}',
                color: AppColors.primary,
                isDark: isDark,
                onTap: onAthleteTap,
              ),
              _SummaryTileWidget(
                icon: '🏐',
                label: 'Partidos',
                value: '${summary.matchCount}',
                color: AppColors.accent,
                isDark: isDark,
                onTap: onMatchTap,
              ),
              _SummaryTileWidget(
                icon: '📈',
                label: 'Winrate',
                value: '${summary.winRate.toStringAsFixed(0)}%',
                color: AppColors.success,
                isDark: isDark,
                onTap: onWinRateTap,
              ),
              _SummaryTileWidget(
                icon: '📅',
                label: 'Entrenamientos',
                value: '${summary.trainingCount}',
                color: AppColors.info,
                isDark: isDark,
                onTap: onTrainingTap,
              ),
            ],
          ),
        ],
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

class _SummaryTileWidget extends StatefulWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _SummaryTileWidget({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  State<_SummaryTileWidget> createState() => _SummaryTileWidgetState();
}

class _SummaryTileWidgetState extends State<_SummaryTileWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.isDark ? AppColors.surface : AppColors.lightCard;
    final borderClr = widget.isDark ? AppColors.border : AppColors.lightBorder;
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? widget.color.withValues(alpha: 0.5) : borderClr,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.15)
                    : (widget.isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05)),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 6 : 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 22)),
              const Spacer(),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textPri,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  color: textSec,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
