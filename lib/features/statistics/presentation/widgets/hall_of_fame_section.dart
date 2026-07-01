import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../data/statistics_models.dart';
import '../viewmodels/athlete_of_month_viewmodel.dart';

class HallOfFameSection extends StatelessWidget {
  final List<AthleteRankingScore> rankings;
  final bool isDark;

  const HallOfFameSection({
    super.key,
    required this.rankings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vm = context.watch<AthleteOfMonthViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(isDark: isDark),
        const SizedBox(height: 12),
        _CategoryFilter(
          categories: vm.categorias,
          selected: vm.selectedCategory,
          isDark: isDark,
          onSelected: vm.setCategory,
        ),
        const SizedBox(height: 12),
        if (rankings.isEmpty)
          _EmptyState(isDark: isDark)
        else
          ...List.generate(
            rankings.length > 10 ? 10 : rankings.length,
            (i) => _RankingRow(
              rank: i + 1,
              athlete: rankings[i],
              isDark: isDark,
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final bool isDark;
  const _SectionHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.leaderboard, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text('HALL OF FAME', style: TextStyle(
          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5,
        )),
        const Spacer(),
        Text('TOP 10', style: TextStyle(
          color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold,
        )),
      ],
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final bool isDark;
  final ValueChanged<String> onSelected;

  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final sel = cat == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onSelected(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: sel ? null : Border.all(color: border, width: 0.5),
                  ),
                  child: Text(cat, style: TextStyle(
                    color: sel ? Colors.white : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                    fontSize: 12, fontWeight: FontWeight.w600,
                  )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, size: 48,
                color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary),
            const SizedBox(height: 12),
            Text('Sin datos en este período',
                style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int rank;
  final AthleteRankingScore athlete;
  final bool isDark;

  const _RankingRow({
    required this.rank,
    required this.athlete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textPri = isDark ? cs.onSurface : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;
    final medal = rank == 1 ? '🥇' : (rank == 2 ? '🥈' : (rank == 3 ? '🥉' : '$rank.'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(medal, style: TextStyle(
              fontSize: rank <= 3 ? 20 : 14,
              fontWeight: FontWeight.w800,
              color: rank <= 3 ? null : textPri,
            )),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            backgroundImage: athlete.player.fotoUrl != null
                ? NetworkImage(athlete.player.fotoUrl!)
                : null,
            child: athlete.player.fotoUrl == null
                ? Text(
                    NameFormatter.playerShortName(athlete.player)
                        .substring(0, 1),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NameFormatter.playerDisplayName(athlete.player),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textPri),
                ),
                Text(
                  '${athlete.player.posicionLabel ?? ''} · ${athlete.score.toStringAsFixed(1)} pts',
                  style: TextStyle(color: textSec, fontSize: 11),
                ),
              ],
            ),
          ),
          if (athlete.mvpCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${athlete.mvpCount}x MVP',
                  style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
