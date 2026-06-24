import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../data/rotation_stats_model.dart';
import '../viewmodels/rotation_stats_viewmodel.dart';
import 'rotation_detail_sheet.dart';

class RotationStatsTab extends StatefulWidget {
  const RotationStatsTab({super.key});

  @override
  State<RotationStatsTab> createState() => _RotationStatsTabState();
}

class _RotationStatsTabState extends State<RotationStatsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RotationStatsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final vm = context.watch<RotationStatsViewModel>();

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
                onPressed: () => context.read<RotationStatsViewModel>().load(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.summaries.isEmpty || vm.summaries.every((s) => s.totalPoints == 0)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay, size: 64, color: _sec(isDark).withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Aún no hay datos de rotaciones',
                style: TextStyle(color: _sec(isDark), fontSize: 15)),
            Text('Finaliza un partido para ver estadísticas',
                style: TextStyle(color: _sec(isDark), fontSize: 12)),
          ],
        ),
      );
    }

    final best = vm.bestRotation;

    return RefreshIndicator(
      onRefresh: () => context.read<RotationStatsViewModel>().load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _RotationCards(summaries: vm.summaries, isDark: isDark, onTap: _openDetail),
          const SizedBox(height: 16),
          _RotationsBarChart(summaries: vm.summaries, isDark: isDark),
          const SizedBox(height: 16),
          if (best != null) _BestRotationCard(summary: best, isDark: isDark),
        ],
      ),
    );
  }

  void _openDetail(int rotationIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RotationDetailSheet(rotationIndex: rotationIndex),
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
}

class _RotationCards extends StatelessWidget {
  final List<RotationStatsSummary> summaries;
  final bool isDark;
  final void Function(int) onTap;

  const _RotationCards({
    required this.summaries,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ROTACIONES', style: TextStyle(
          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5,
        )),
        const SizedBox(height: 12),
        ...List.generate(summaries.length, (i) {
          final s = summaries[i];
          return _RotationCard(
            label: s.label,
            wins: s.totalPointsWon,
            losses: s.totalPointsLost,
            winrate: s.winrate,
            isDark: isDark,
            onTap: () => onTap(s.rotationIndex),
          );
        }),
      ],
    );
  }
}

class _RotationCard extends StatelessWidget {
  final String label;
  final int wins;
  final int losses;
  final double winrate;
  final bool isDark;
  final VoidCallback onTap;

  const _RotationCard({
    required this.label,
    required this.wins,
    required this.losses,
    required this.winrate,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(label, style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14,
                  )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _DotText(color: AppColors.success, text: '$wins V', isDark: isDark),
                        const SizedBox(width: 12),
                        _DotText(color: AppColors.error, text: '$losses D', isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: winrate / 100,
                        backgroundColor: AppColors.error.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(AppColors.success),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('${winrate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: winrate >= 50 ? AppColors.success : AppColors.error,
                    fontSize: 16, fontWeight: FontWeight.bold,
                  )),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: _sec(isDark), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
}

class _DotText extends StatelessWidget {
  final Color color;
  final String text;
  final bool isDark;
  const _DotText({required this.color, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13)),
      ],
    );
  }
}

class _RotationsBarChart extends StatelessWidget {
  final List<RotationStatsSummary> summaries;
  final bool isDark;

  const _RotationsBarChart({required this.summaries, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final maxNet = summaries.fold<int>(0, (m, s) => s.netPoints.abs() > m ? s.netPoints.abs() : m);

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
          Text('DIFERENCIA DE PUNTOS', style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5,
          )),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxNet > 0 ? maxNet.toDouble() : 1.0,
                minY: -(maxNet > 0 ? maxNet.toDouble() : 1.0),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final s = summaries[groupIndex];
                      return BarTooltipItem(
                        '${s.label}\n${s.netPoints >= 0 ? "+" : ""}${s.netPoints}',
                         const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= summaries.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(summaries[idx].label,
                              style: TextStyle(color: _sec(isDark), fontSize: 11, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxNet > 0 ? (maxNet / 4).ceilToDouble().clamp(1.0, double.infinity) : 1.0,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: border.withValues(alpha: 0.3),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(summaries.length, (i) {
                  final s = summaries[i];
                  final isPositive = s.netPoints >= 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: s.netPoints.toDouble().clamp(-999, 999),
                        color: isPositive ? AppColors.success : AppColors.error,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _sec(bool d) => d ? AppColors.textSecondary : AppColors.lightTextSecondary;
}

class _BestRotationCard extends StatelessWidget {
  final RotationStatsSummary summary;
  final bool isDark;

  const _BestRotationCard({required this.summary, required this.isDark});

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
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text('ROTACIÓN MÁS EFECTIVA', style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(summary.label, style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18,
                  )),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatChip(label: '${summary.winrate.toStringAsFixed(0)}%', color: AppColors.accent),
                        const SizedBox(width: 8),
                        _StatChip(label: '+${summary.netPoints}', color: AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('${summary.totalPointsWon} a favor',
                            style: TextStyle(color: AppColors.success, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text('${summary.totalPointsLost} en contra',
                            style: TextStyle(color: AppColors.error, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
