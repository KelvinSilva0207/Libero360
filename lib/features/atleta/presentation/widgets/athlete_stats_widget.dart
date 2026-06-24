import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/athlete_stats_model.dart';

class RadarChartCard extends StatelessWidget {
  final List<RadarSkill> skills;
  const RadarChartCard({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('Radar de Habilidades',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: RadarChart(
              RadarChartData(
                radarTouchData: RadarTouchData(enabled: false),
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.accent.withValues(alpha: 0.2),
                    borderColor: AppColors.accent,
                    borderWidth: 2,
                    entryRadius: 4,
                    dataEntries: skills.map((s) => RadarEntry(value: s.value)).toList(),
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(color: AppColors.border, width: 0.5),
                titlePositionPercentageOffset: 0.15,
                titleTextStyle: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                getTitle: (index, _) => RadarChartTitle(text: skills[index].name),
                tickCount: 4,
                ticksTextStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                tickBorderData: BorderSide(color: AppColors.border, width: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: skills.map((s) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: _skillColor(s.value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('${s.name} ${s.value.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Color _skillColor(double v) {
    if (v >= 70) return const Color(0xFF22C55E);
    if (v >= 40) return AppColors.accent;
    return const Color(0xFFEF4444);
  }
}

class BarChartCard extends StatelessWidget {
  final ActionBarData data;
  const BarChartCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final values = [data.positives, data.regulars, data.negatives];
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal.toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('Acciones', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxY * 1.3).ceilToDouble().clamp(3, double.infinity),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final labels = ['Positivos', 'Regulares', 'Negativos'];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[idx],
                            style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  horizontalInterval: (maxY * 1.3 / 4).ceilToDouble().clamp(1, double.infinity),
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.3),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _barGroup(0, data.positives.toDouble(), const Color(0xFF22C55E)),
                  _barGroup(1, data.regulars.toDouble(), AppColors.accent),
                  _barGroup(2, data.negatives.toDouble(), const Color(0xFFEF4444)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y, color: color, width: 24,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4), topRight: Radius.circular(4),
        ),
      ),
    ]);
  }
}

class PieChartCard extends StatelessWidget {
  final WinPieData data;
  const PieChartCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.total;
    final winRate = total > 0 ? (data.wins / total) * 100 : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('Victorias / Derrotas',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 55,
                    sections: [
                      if (data.wins > 0)
                        PieChartSectionData(
                          value: data.wins.toDouble(), color: const Color(0xFF22C55E),
                          radius: 38, showTitle: false,
                        ),
                      if (data.losses > 0)
                        PieChartSectionData(
                          value: data.losses.toDouble(), color: const Color(0xFFEF4444),
                          radius: 38, showTitle: false,
                        ),
                      if (data.draws > 0)
                        PieChartSectionData(
                          value: data.draws.toDouble(), color: const Color(0xFF8B5CF6),
                          radius: 38, showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${winRate.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('Victorias',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(const Color(0xFF22C55E), '${data.wins} G'),
              const SizedBox(width: 16),
              _legend(const Color(0xFFEF4444), '${data.losses} P'),
              if (data.draws > 0) ...[
                const SizedBox(width: 16),
                _legend(const Color(0xFF8B5CF6), '${data.draws} E'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class LineChartCard extends StatelessWidget {
  final List<LineChartPoint> points;
  const LineChartCard({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('Últimos 10 Partidos',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Sin datos', style: TextStyle(color: Colors.white38))),
            )
          else
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.3),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, reservedSize: 28,
                        interval: points.length > 6 ? (points.length / 5).ceilToDouble() : 1,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${idx + 1}',
                              style: const TextStyle(color: Colors.white38, fontSize: 9)),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points.asMap().entries.map((e) =>
                        FlSpot(e.key.toDouble(), e.value.score),
                      ).toList(),
                      isCurved: true,
                      color: AppColors.accent,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 3, color: AppColors.accent,
                          strokeWidth: 1.5, strokeColor: AppColors.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accent.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MatchHistoryCard extends StatelessWidget {
  final List<MatchPerformance> history;
  const MatchHistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('Historial de Partidos',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Sin partidos registrados', style: TextStyle(color: Colors.white38))),
            )
          else
            ...history.map((m) => _matchRow(m)),
        ],
      ),
    );
  }

  Widget _matchRow(MatchPerformance m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(m.competition,
                  style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (m.isMvp)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, color: AppColors.accent, size: 10),
                        SizedBox(width: 2),
                        Text('MVP', style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  m.isWin ? Icons.check_circle : (m.isDraw ? Icons.remove_circle : Icons.cancel),
                  size: 14,
                  color: m.isWin ? const Color(0xFF22C55E) : (m.isDraw ? const Color(0xFF8B5CF6) : const Color(0xFFEF4444)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${m.rival} ${m.setsFor}-${m.setsAgainst}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                Text(
                  m.performanceScore >= 0 ? '+${m.performanceScore.toStringAsFixed(0)}' : m.performanceScore.toStringAsFixed(0),
                  style: TextStyle(
                    color: m.performanceScore >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    fontSize: 13, fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${m.positiveActions}P · ${m.regularActions}R · ${m.negativeActions}N',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class RankingSection extends StatelessWidget {
  final TeamRankings rankings;
  const RankingSection({super.key, required this.rankings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Text('Ranking del Equipo',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _rankingGroup('MVP del Equipo', Icons.emoji_events, AppColors.accent, rankings.mvp.take(3).toList()),
          const SizedBox(height: 12),
          _rankingGroup('Mejor Atacante', Icons.flash_on, AppColors.primary, rankings.bestAttackers.take(3).toList()),
          const SizedBox(height: 12),
          _rankingGroup('Mejor Defensa', Icons.shield, const Color(0xFF22C55E), rankings.bestDefenders.take(3).toList()),
          const SizedBox(height: 12),
          _rankingGroup('Mejor Servicio', Icons.sports_volleyball, const Color(0xFF3B82F6), rankings.bestServers.take(3).toList()),
          const SizedBox(height: 12),
          _rankingGroup('Más Constante', Icons.auto_graph, const Color(0xFF8B5CF6), rankings.mostConsistent.take(3).toList()),
        ],
      ),
    );
  }

  Widget _rankingGroup(String title, IconData icon, Color color, List<TeamRankingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(title,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ...items.asMap().entries.map((entry) {
          final item = entry.value;
          final medals = ['🥇', '🥈', '🥉'];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(medals[entry.key], style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text('${item.numero ?? '-'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(item.playerName,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                Text(item.score.toStringAsFixed(0),
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
