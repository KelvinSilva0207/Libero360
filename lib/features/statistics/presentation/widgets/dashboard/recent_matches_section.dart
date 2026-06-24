import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../data/stats_dashboard_model.dart';

class RecentMatchesSection extends StatelessWidget {
  final List<DashboardMatchItem> matches;
  final bool isDark;
  final void Function(int matchId)? onMatchTap;

  const RecentMatchesSection({
    super.key,
    required this.matches,
    required this.isDark,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(),
        const SizedBox(height: 12),
        if (matches.isEmpty)
          _emptyState()
        else
          ...List.generate(matches.length, (i) => _matchCard(matches[i])),
      ],
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        Icon(Icons.history, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text('ÚLTIMOS PARTIDOS',
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

  Widget _matchCard(DashboardMatchItem match) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onMatchTap != null ? () => onMatchTap!(match.matchId) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: match.isWin
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match.isWin ? 'Victoria' : 'Derrota',
                      style: TextStyle(
                        color: match.isWin
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(match.tipoPartido,
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Local',
                            style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(match.competitionName ?? 'Equipo Local',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: match.isWin
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      match.marcador,
                      style: TextStyle(
                        color: match.isWin
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Visitante',
                            style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(match.rival,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 12,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${match.fecha.day}/${match.fecha.month}/${match.fecha.year}',
                    style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 11),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer_outlined,
                      size: 12,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary),
                  const SizedBox(width: 4),
                  Text(match.durationFormatted,
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 11)),
                  if (match.mvpName != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.star,
                        size: 12, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('MVP: ${match.mvpName}',
                        style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 11)),
                  ],
                ],
              ),
              if (onMatchTap != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => onMatchTap!(match.matchId),
                    icon: const Icon(Icons.summarize, size: 14),
                    label: const Text('Ver resumen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
            Icon(Icons.sports_volleyball_outlined,
                size: 40,
                color: (isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary)
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No hay partidos finalizados',
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
