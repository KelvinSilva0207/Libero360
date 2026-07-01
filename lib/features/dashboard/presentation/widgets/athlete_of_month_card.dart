import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../statistics/presentation/views/statistics_screen.dart';
import '../../data/dashboard_model.dart';

class AthleteOfMonthCard extends StatelessWidget {
  final AthleteOfMonth? athlete;
  final bool isDark;

  const AthleteOfMonthCard({
    super.key,
    this.athlete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final borderClr = isDark ? AppColors.border : AppColors.lightBorder;
    final textPri = isDark ? cs.onSurface : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Atleta del Mes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPri,
                  ),
                ),
              ],
            ),
            if (athlete != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: athlete!.photoUrl != null
                        ? NetworkImage(athlete!.photoUrl!)
                        : null,
                    child: athlete!.photoUrl == null
                        ? Text(
                            athlete!.name.isNotEmpty
                                ? athlete!.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          athlete!.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPri,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${athlete!.position} · ${athlete!.category}',
                          style: TextStyle(color: textSec, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statBadge('MVP', '${athlete!.mvpCount}', AppColors.accent),
                  const SizedBox(width: 10),
                  _statBadge('Eficiencia', '${athlete!.eficiencia.toStringAsFixed(0)}%', AppColors.success),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.pushSlide(const StatisticsScreen()),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ver estadísticas',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
            if (athlete == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceLight : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.person_off_rounded, 
                            size: 24, color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sin datos este mes',
                        style: TextStyle(
                          color: textPri,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No hay suficientes partidos para calcular',
                        style: TextStyle(color: textSec, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
