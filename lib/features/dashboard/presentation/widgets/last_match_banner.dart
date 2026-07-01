import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../estadisticas/presentation/views/play_by_play_screen.dart';
import '../../../statistics/presentation/views/statistics_screen.dart';
import '../../data/dashboard_model.dart';

class LastMatchBanner extends StatelessWidget {
  final LastMatch? lastMatch;
  final bool isDark;

  const LastMatchBanner({
    super.key,
    this.lastMatch,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final borderClr = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? cs.onSurface : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;

    if (lastMatch == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderClr),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceLight : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.sports_volleyball_rounded,
                    size: 24, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 8),
              Text(
                'Sin partidos recientes',
                style: TextStyle(
                  color: textPri,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Los partidos finalizados aparecerán aquí',
                style: TextStyle(color: textSec, fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.pushSlide(const PlayByPlayScreen()),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Jugar partido'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final d = lastMatch!.date;
    final dateStr = '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: lastMatch!.isWin
                  ? AppColors.success.withValues(alpha: 0.25)
                  : AppColors.error.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: LinearGradient(
            colors: lastMatch!.isWin
                ? [AppColors.success.withValues(alpha: 0.8), AppColors.success.withValues(alpha: 0.3)]
                : [AppColors.error.withValues(alpha: 0.6), AppColors.error.withValues(alpha: 0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                lastMatch!.isWin ? Icons.emoji_events_rounded : Icons.sports_volleyball_rounded,
                size: 80,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(lastMatch!.isWin ? '🏆' : '⚔',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      const Text(
                        'Último Partido',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lastMatch!.rivalName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${lastMatch!.setsFor} - ${lastMatch!.setsAgainst}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${lastMatch!.competition} · $dateStr',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pushSlide(const StatisticsScreen()),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Ver resumen',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
