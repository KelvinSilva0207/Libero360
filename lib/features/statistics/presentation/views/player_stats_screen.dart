import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/player_stats_model.dart';
import '../viewmodels/player_stats_viewmodel.dart';

class PlayerStatsScreen extends StatelessWidget {
  final Player player;

  const PlayerStatsScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final viewModel = context.watch<PlayerStatsViewModel>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surface : AppColors.lightCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(player.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(viewModel, isDark),
    );
  }

  Widget _buildBody(PlayerStatsViewModel vm, bool isDark) {
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
                  style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => vm.load(player),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final s = vm.stats;
    if (s == null) {
      return Center(child: Text('Sin datos', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _PlayerHeader(player: player, isDark: isDark),
        const SizedBox(height: 16),
        _ActionStats(stats: s, isDark: isDark),
        const SizedBox(height: 16),
        _RadarChartWidget(stats: s, isDark: isDark),
        if (s.perSetStats.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BarChartWidget(stats: s, isDark: isDark),
        ],
        const SizedBox(height: 16),
        _HistoryCard(stats: s, isDark: isDark),
        const SizedBox(height: 16),
        _TotalsCard(stats: s, isDark: isDark),
      ],
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  final Player player;
  final bool isDark;
  const _PlayerHeader({required this.player, required this.isDark});

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
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            backgroundImage: player.fotoUrl != null ? NetworkImage(player.fotoUrl!) : null,
            child: player.fotoUrl == null
                ? Text(
                    player.nombre.isNotEmpty ? player.nombre[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.accent, fontSize: 26, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.nombre, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (player.numero != null) ...[
                      Text('#${player.numero}', style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                    ],
                    Text(player.posicionLabel, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 13)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: player.atletaStatus.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(player.atletaStatus.label, style: TextStyle(color: player.atletaStatus.color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
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

class _ActionStats extends StatelessWidget {
  final PlayerDetailStats stats;
  final bool isDark;
  const _ActionStats({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final items = [
      ('MVP', '${stats.totalMvp}', Icons.emoji_events, AppColors.accent),
      ('Ataques', '${stats.attackCount}', Icons.flash_on, AppColors.primary),
      ('Bloqueos', '${stats.blockCount}', Icons.widgets, const Color(0xFF8B5CF6)),
      ('Servicios', '${stats.serveCount}', Icons.sports_volleyball, AppColors.success),
      ('Defensas', '${stats.defenseCount}', Icons.shield, AppColors.info),
      ('Recepciones', '${stats.receptionCount}', Icons.track_changes, const Color(0xFFEC4899)),
      ('Errores', '${stats.errorCount}', Icons.cancel_outlined, AppColors.error),
    ];

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
          Text('ESTADÍSTICAS', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(item.$3, color: item.$4, size: 18),
                const SizedBox(width: 10),
                Text(item.$1, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 13)),
                const Spacer(),
                Text(item.$2, style: TextStyle(color: item.$4, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _RadarChartWidget extends StatelessWidget {
  final PlayerDetailStats stats;
  final bool isDark;
  const _RadarChartWidget({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

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
          Text('RENDIMIENTO', style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
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
                    dataEntries: [
                      RadarEntry(value: stats.radarAttack),
                      RadarEntry(value: stats.radarBlock),
                      RadarEntry(value: stats.radarServe),
                      RadarEntry(value: stats.radarDefense),
                      RadarEntry(value: stats.radarReception),
                    ],
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder, width: 0.5),
                titlePositionPercentageOffset: 0.15,
                titleTextStyle: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
                getTitle: (index, angle) {
                  final labels = ['Ataque', 'Bloqueo', 'Servicio', 'Defensa', 'Recepción'];
                  return RadarChartTitle(text: labels[index]);
                },
                tickCount: 4,
                ticksTextStyle: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 10),
                tickBorderData: BorderSide(color: isDark ? AppColors.border : AppColors.lightBorder, width: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final PlayerDetailStats stats;
  final bool isDark;
  const _BarChartWidget({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final textColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final maxPoints = stats.perSetStats
        .fold<int>(0, (max, s) => s.points > max ? s.points : max);

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
          Text('PUNTOS POR SET', style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxPoints * 1.3).ceilToDouble().clamp(1, double.infinity),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= stats.perSetStats.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Set ${stats.perSetStats[idx].setNumber}',
                              style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxPoints * 1.3 / 4).ceilToDouble().clamp(1, double.infinity),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark ? AppColors.border : AppColors.lightBorder,
                    strokeWidth: 0.3,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: stats.perSetStats.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.points.toDouble(),
                        color: AppColors.accent,
                        width: 18,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final PlayerDetailStats stats;
  final bool isDark;
  const _HistoryCard({required this.stats, required this.isDark});

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
          Text('HISTORIAL', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _HistRow(label: 'Ligas', value: '${stats.ligas}', icon: Icons.emoji_events, color: AppColors.accent, isDark: isDark),
          _HistRow(label: 'Torneos', value: '${stats.torneos}', icon: Icons.military_tech, color: const Color(0xFF8B5CF6), isDark: isDark),
          _HistRow(label: 'Amistosos', value: '${stats.amistosos}', icon: Icons.fitness_center, color: AppColors.primary, isDark: isDark),
          _HistRow(label: 'Prácticas', value: '${stats.practicas}', icon: Icons.school, color: AppColors.success, isDark: isDark),
        ],
      ),
    );
  }
}

class _HistRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _HistRow({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final PlayerDetailStats stats;
  final bool isDark;
  const _TotalsCard({required this.stats, required this.isDark});

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
          Text('TOTAL', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _TotalBox(label: 'Victorias', value: '${stats.totalWins}', color: AppColors.success, isDark: isDark)),
              Expanded(child: _TotalBox(label: 'Derrotas', value: '${stats.totalLosses}', color: AppColors.error, isDark: isDark)),
              Expanded(child: _TotalBox(label: 'MVP', value: '${stats.totalMvp}', color: AppColors.accent, isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _TotalBox({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
