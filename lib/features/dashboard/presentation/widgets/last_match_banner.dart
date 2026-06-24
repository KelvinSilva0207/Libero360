import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
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
    if (lastMatch == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final d = lastMatch!.date;
    final dateStr = '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
                right: -20,
                bottom: -20,
                child: Icon(
                  lastMatch!.isWin ? Icons.emoji_events_rounded : Icons.sports_volleyball_rounded,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(lastMatch!.isWin ? '🏆' : '⚔',
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        const Text(
                          'Último Partido',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lastMatch!.setsFor} - ${lastMatch!.setsAgainst}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.pushSlide(const StatisticsScreen());
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Ver resumen',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
