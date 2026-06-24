import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../data/stats_dashboard_model.dart';

class SeasonSummarySection extends StatelessWidget {
  final SeasonSummaryCards summary;
  final bool isDark;

  const SeasonSummarySection({
    super.key,
    required this.summary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _CardData(Icons.emoji_events, 'Victorias', '${summary.wins}',
          AppColors.success),
      _CardData(Icons.cancel, 'Derrotas', '${summary.losses}',
          AppColors.error),
      _CardData(Icons.trending_up, 'Winrate',
          '${summary.winrate.toStringAsFixed(0)}%', AppColors.accent),
      _CardData(Icons.timer_outlined, 'Tiempo prom.',
          summary.averageDurationFormatted, AppColors.info),
      _CardData(Icons.sports_volleyball, 'Partidos',
          '${summary.totalMatches}', AppColors.primary),
      _CardData(Icons.star, 'MVP', '${summary.mvpAwards}',
          AppColors.warning),
      _CardData(Icons.calendar_today, 'Entrenamientos',
          '${summary.totalEntrenamientos}', AppColors.info),
      _CardData(
          Icons.healing, 'Reposos', '${summary.medicalLeaves}', AppColors.error),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('RESUMEN TEMPORADA'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _summaryCard(items[index]),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Icon(Icons.summarize, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(text,
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

  Widget _summaryCard(_CardData item) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: item.color, size: 20),
          const SizedBox(height: 8),
          Text(item.value,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 2),
          Text(item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 9,
              )),
        ],
      ),
    );
  }
}

class _CardData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  _CardData(this.icon, this.label, this.value, this.color);
}
