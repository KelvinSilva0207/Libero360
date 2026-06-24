import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../data/stats_summary_model.dart';
import '../viewmodels/stats_summary_viewmodel.dart';

class StatsSummaryTab extends StatelessWidget {
  const StatsSummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final viewModel = context.watch<StatsSummaryViewModel>();
    final summary = viewModel.summary;

    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (viewModel.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(viewModel.error!, textAlign: TextAlign.center,
                  style: TextStyle(color: _textSec(isDark), fontSize: 14)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<StatsSummaryViewModel>().load(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (summary == null || summary.totalMatches == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_volleyball, size: 64, color: _textSec(isDark).withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Aún no hay partidos finalizados',
                style: TextStyle(color: _textSec(isDark), fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<StatsSummaryViewModel>().load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _WinLossCards(summary: summary, isDark: isDark),
          const SizedBox(height: 16),
          _StatsRow(summary: summary, isDark: isDark),
          const SizedBox(height: 16),
          _WinrateChart(summary: summary, isDark: isDark),
          const SizedBox(height: 16),
          if (summary.typeLabels.length >= 2)
            _MatchTypeChart(summary: summary, isDark: isDark),
          if (summary.typeLabels.length >= 2) const SizedBox(height: 16),
          _RecentMatches(summary: summary, isDark: isDark),
        ],
      ),
    );
  }

  Color _textSec(bool isDark) => isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
}

class _WinLossCards extends StatelessWidget {
  final StatsSummaryModel summary;
  final bool isDark;
  const _WinLossCards({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Victorias', value: '${summary.wins}',
          color: AppColors.success, isDark: isDark,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Derrotas', value: '${summary.losses}',
          color: AppColors.error, isDark: isDark,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Total', value: '${summary.totalMatches}',
          color: AppColors.primary, isDark: isDark,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _StatCard({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final StatsSummaryModel summary;
  final bool isDark;
  const _StatsRow({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(child: _MiniStat(label: 'Efectividad', value: '${summary.winrate.toStringAsFixed(1)}%', isDark: isDark)),
          Container(width: 1, height: 40, color: border),
          Expanded(child: _MiniStat(label: 'Duración prom.', value: summary.averageDurationFormatted, isDark: isDark)),
          Container(width: 1, height: 40, color: border),
          Expanded(child: _MiniStat(label: 'Mejor racha', value: '${summary.bestStreak}', isDark: isDark)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _MiniStat({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 11)),
      ],
    );
  }
}

class _WinrateChart extends StatelessWidget {
  final StatsSummaryModel summary;
  final bool isDark;
  const _WinrateChart({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EFECTIVIDAD', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: summary.winValues[0],
                          color: AppColors.success,
                          radius: 40,
                          title: '${summary.winValues[0].toInt()}',
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: summary.winValues[1],
                          color: AppColors.error,
                          radius: 40,
                          title: '${summary.winValues[1].toInt()}',
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendDot(color: AppColors.success, label: 'Victorias ${summary.winValues[0].toInt()}', isDark: isDark),
                    const SizedBox(height: 8),
                    _LegendDot(color: AppColors.error, label: 'Derrotas ${summary.winValues[1].toInt()}', isDark: isDark),
                    const SizedBox(height: 8),
                    Text('${summary.winrate.toStringAsFixed(1)}%',
                        style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  const _LegendDot({required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12)),
      ],
    );
  }
}

class _MatchTypeChart extends StatelessWidget {
  final StatsSummaryModel summary;
  final bool isDark;
  const _MatchTypeChart({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final colors = [AppColors.primary, AppColors.accent, const Color(0xFF8B5CF6), AppColors.success];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIPOS DE PARTIDO', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(summary.typeLabels.length, (i) => PieChartSectionData(
                        value: summary.typeValues[i],
                        color: colors[i % colors.length],
                        radius: 35,
                        title: '${summary.typeValues[i].toInt()}',
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      )),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(summary.typeLabels.length, (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: _LegendDot(color: colors[i % colors.length], label: '${summary.typeLabels[i]} ${summary.typeValues[i].toInt()}', isDark: isDark),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentMatches extends StatelessWidget {
  final StatsSummaryModel summary;
  final bool isDark;
  const _RecentMatches({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ÚLTIMOS PARTIDOS', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          if (summary.recentMatches.isEmpty)
            Text('Sin partidos recientes', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 13))
          else
            ...summary.recentMatches.map((m) => _RecentMatchRow(match: m, isDark: isDark)),
        ],
      ),
    );
  }
}

class _RecentMatchRow extends StatelessWidget {
  final RecentMatchItem match;
  final bool isDark;
  const _RecentMatchRow({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: match.isWin ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.rival, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text(match.tipoPartido, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 11)),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd/MM/yy').format(match.fecha), style: TextStyle(color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (match.isWin ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              match.marcador,
              style: TextStyle(
                color: match.isWin ? AppColors.success : AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
