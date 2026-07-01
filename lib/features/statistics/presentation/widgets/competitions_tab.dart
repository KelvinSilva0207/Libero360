import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../viewmodels/athlete_of_month_viewmodel.dart';
import 'athlete_of_month_card.dart';
import 'hall_of_fame_section.dart';

class CompetitionsTab extends StatefulWidget {
  const CompetitionsTab({super.key});

  @override
  State<CompetitionsTab> createState() => _CompetitionsTabState();
}

class _CompetitionsTabState extends State<CompetitionsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AthleteOfMonthViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final vm = context.watch<AthleteOfMonthViewModel>();

    if (vm.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(vm.error!, textAlign: TextAlign.center,
                  style: TextStyle(color: _sec(isDark), fontSize: 14)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<AthleteOfMonthViewModel>().load(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AthleteOfMonthViewModel>().load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _PeriodSelector(isDark: isDark, vm: vm),
          const SizedBox(height: 16),
          if (vm.winner != null) ...[
            AthleteOfMonthCard(athlete: vm.winner!, isDark: isDark),
            const SizedBox(height: 16),
          ],
          HallOfFameSection(
            rankings: vm.filteredRankings,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
}

class _PeriodSelector extends StatelessWidget {
  final bool isDark;
  final AthleteOfMonthViewModel vm;

  const _PeriodSelector({required this.isDark, required this.vm});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline, size: 16, color: _sec(isDark)),
          const SizedBox(width: 8),
          Text('PERIODO', style: TextStyle(
            color: _sec(isDark), fontSize: 11,
            fontWeight: FontWeight.w600, letterSpacing: 1.5,
          )),
          const Spacer(),
          _PeriodChip(
            label: 'Actual',
            selected: vm.selectedPeriod == RankingPeriod.actual,
            isDark: isDark,
            onTap: () => vm.setPeriod(RankingPeriod.actual),
          ),
          const SizedBox(width: 4),
          _PeriodChip(
            label: 'Mes Ant.',
            selected: vm.selectedPeriod == RankingPeriod.mesAnterior,
            isDark: isDark,
            onTap: () => vm.setPeriod(RankingPeriod.mesAnterior),
          ),
          const SizedBox(width: 4),
          _PeriodChip(
            label: 'Temporada',
            selected: vm.selectedPeriod == RankingPeriod.temporada,
            isDark: isDark,
            onTap: () => vm.setPeriod(RankingPeriod.temporada),
          ),
          const SizedBox(width: 4),
          _PeriodChip(
            label: 'Histórico',
            selected: vm.selectedPeriod == RankingPeriod.historico,
            isDark: isDark,
            onTap: () => vm.setPeriod(RankingPeriod.historico),
          ),
        ],
      ),
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent
              : (isDark ? AppColors.background : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Theme.of(context).colorScheme.onPrimary : _sec(isDark),
          fontSize: 11, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
}
