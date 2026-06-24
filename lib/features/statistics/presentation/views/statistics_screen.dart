import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../viewmodels/stats_dashboard_viewmodel.dart';
import '../widgets/dashboard/athlete_of_month_section.dart';
import '../widgets/dashboard/season_summary_section.dart';
import '../widgets/dashboard/charts_section.dart';
import '../widgets/dashboard/hall_of_fame_section.dart';
import '../widgets/dashboard/recent_matches_section.dart';
import '../widgets/dashboard/recent_activity_section.dart';
import '../views/player_stats_screen.dart';
import '../../../estadisticas/data/models/models.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatsDashboardViewModel()..load(),
      child: const _StatsDashboardShell(),
    );
  }
}

class _StatsDashboardShell extends StatefulWidget {
  const _StatsDashboardShell();

  @override
  State<_StatsDashboardShell> createState() => _StatsDashboardShellState();
}

class _StatsDashboardShellState extends State<_StatsDashboardShell> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final vm = context.watch<StatsDashboardViewModel>();
    final bg = isDark ? AppColors.background : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      body: _buildBody(vm, isDark),
    );
  }

  Widget _buildBody(StatsDashboardViewModel vm, bool isDark) {
    if (vm.loading) {
      return _loadingState(isDark);
    }

    if (vm.error != null) {
      return _errorState(vm, isDark);
    }

    final data = vm.data;
    if (data == null) {
      return _loadingState(isDark);
    }

    return RefreshIndicator(
      onRefresh: () => vm.load(),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _header(isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('ATLETA DEL MES', isDark),
                  const SizedBox(height: 12),
                  AthleteOfMonthSection(
                    athlete: data.athleteOfMonth,
                    isDark: isDark,
                    alreadyAnimated: vm.athleteOfMonthAnimated,
                    onAnimated: vm.markAthleteOfMonthAnimated,
                    onViewProfile: () => _openPlayerProfile(
                        context, data.athleteOfMonth?.player),
                  ),
                  const SizedBox(height: 28),
                  SeasonSummarySection(
                      summary: data.seasonSummary, isDark: isDark),
                  const SizedBox(height: 28),
                  ChartsSection(charts: data.charts, isDark: isDark),
                  const SizedBox(height: 28),
                  HallOfFameSection(
                      entries: data.hallOfFame, isDark: isDark),
                  const SizedBox(height: 28),
                  RecentMatchesSection(
                    matches: data.recentMatches,
                    isDark: isDark,
                    onMatchTap: (matchId) =>
                        _openMatchSummary(context, matchId),
                  ),
                  const SizedBox(height: 28),
                  RecentActivitySection(
                      activities: data.recentActivity, isDark: isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 12, 20, 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Estadísticas',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Row(
      children: [
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

  Widget _loadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 16),
          Text('Cargando estadísticas...',
              style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _errorState(StatsDashboardViewModel vm, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(vm.error!, textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 14)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => vm.load(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlayerProfile(BuildContext context, Player? player) {
    if (player == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerStatsScreen(player: player),
      ),
    );
  }

  void _openMatchSummary(BuildContext context, int matchId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resumen del partido #$matchId (próximamente)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
