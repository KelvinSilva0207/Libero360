import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
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
    final vm = context.watch<AthleteOfMonthViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(isDark: isDark),
        const SizedBox(height: 12),
        _CategoryFilter(
          categories: AthleteOfMonthViewModel.categorias,
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
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 48, color: _sec(isDark).withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('Aún no hay datos de ranking',
              style: TextStyle(color: _sec(isDark), fontSize: 14)),
          Text('Finaliza partidos para generar estadísticas',
              style: TextStyle(color: _sec(isDark), fontSize: 12)),
        ],
      ),
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
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
    final p = athlete.player;
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;

    final medalColors = {
      1: AppColors.accent,
      2: Colors.grey.shade400,
      3: Colors.brown.shade300,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: rank == 1
              ? AppColors.accent.withValues(alpha: 0.06)
              : bg,
          borderRadius: BorderRadius.circular(12),
          border: rank == 1
              ? Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1)
              : Border.all(color: border, width: 0.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: medalColors.containsKey(rank)
                  ? Icon(Icons.emoji_events, color: medalColors[rank], size: 18)
                  : Text('$rank',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        fontSize: 12, fontWeight: FontWeight.w600,
                      )),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              backgroundImage: p.fotoUrl != null ? NetworkImage(p.fotoUrl!) : null,
              child: p.fotoUrl == null
                  ? Text(p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.accent, fontSize: 12))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                p.displayName.isNotEmpty ? p.displayName : p.nombre,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontSize: 13, fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(athlete.score.toStringAsFixed(0),
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14, fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }
}
