import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/themes/app_colors.dart';
import '../viewmodels/attendance_analytics_viewmodel.dart';

class AttendanceAnalyticsScreen extends StatefulWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  State<AttendanceAnalyticsScreen> createState() => _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState extends State<AttendanceAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceAnalyticsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceAnalyticsViewModel>();
    final cs = Theme.of(context).colorScheme;
    final data = vm.analytics;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Estad\u00edsticas de Asistencia')),
      body: vm.loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : data == null
              ? Center(child: Text('No hay datos', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel(cs, 'Visi\u00f3n General'),
                      const SizedBox(height: 8),
                      _pieChart(cs, data),
                      const SizedBox(height: 20),
                      _sectionLabel(cs, 'Top Asistencia'),
                      const SizedBox(height: 8),
                      _barChart(cs, data),
                      const SizedBox(height: 20),
                      _sectionLabel(cs, 'Evoluci\u00f3n Mensual'),
                      const SizedBox(height: 8),
                      _lineChart(cs, data),
                      const SizedBox(height: 20),
                      _sectionLabel(cs, 'Rankings'),
                      const SizedBox(height: 8),
                      _rankings(cs, data),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionLabel(ColorScheme cs, String text) {
    return Text(text, style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _pieChart(ColorScheme cs, dynamic data) {
    final total = data.totalPresent + data.totalAbsent + data.totalMedicalRest;
    if (total == 0) return const SizedBox.shrink();
    final sections = [
      PieChartSectionData(value: data.totalPresent.toDouble(), color: const Color(0xFF22C55E), title: '${(data.totalPresent / total * 100).toStringAsFixed(0)}%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      PieChartSectionData(value: data.totalAbsent.toDouble(), color: const Color(0xFFEF4444), title: '${(data.totalAbsent / total * 100).toStringAsFixed(0)}%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      PieChartSectionData(value: data.totalMedicalRest.toDouble(), color: const Color(0xFF3B82F6), title: '${(data.totalMedicalRest / total * 100).toStringAsFixed(0)}%', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          SizedBox(height: 180, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 30, sectionsSpace: 2))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF22C55E), 'Asistencia (${data.totalPresent})'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFEF4444), 'Ausencia (${data.totalAbsent})'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF3B82F6), 'Reposo (${data.totalMedicalRest})'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _barChart(ColorScheme cs, dynamic data) {
    final top = data.topAttendance as List;
    if (top.isEmpty) return const SizedBox.shrink();
    final take = top.length > 5 ? 5 : top.length;
    final items = top.take(take).toList();
    final maxVal = (items[0].present as int).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.3,
            barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(getTooltipItem: (g, g2, g3, g4) => null)),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                final name = items[idx].playerName as String;
                return Padding(padding: const EdgeInsets.only(top: 4), child: Text(name.length > 8 ? '${name.substring(0, 7)}.' : name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 8)));
              }, reservedSize: 20)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, m) => Text('${v.toInt()}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)))),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxVal * 0.25, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border.withValues(alpha: 0.3), strokeWidth: 0.5)),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(items.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (items[i].present as int).toDouble(), color: const Color(0xFF22C55E), width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))])),
          ),
        ),
      ),
    );
  }

  Widget _lineChart(ColorScheme cs, dynamic data) {
    final evolution = data.monthlyEvolution as List;
    if (evolution.isEmpty) return const SizedBox.shrink();
    final spots = evolution.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.percentage)).toList();
    if (spots.isEmpty) return const SizedBox.shrink();
    final maxY = spots.fold(0.0, (max, s) => s.y > max ? s.y : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (evolution.length - 1).toDouble(),
            minY: 0,
            maxY: maxY * 1.2 > 0 ? maxY * 1.2 : 100,
            lineTouchData: LineTouchData(enabled: true, touchTooltipData: LineTouchTooltipData(getTooltipItems: (s) => s.map((e) => LineTooltipItem('${e.y.toStringAsFixed(0)}%', const TextStyle(color: Colors.white, fontSize: 10))).toList())),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= evolution.length) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 4), child: Text(evolution[idx].label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)));
              }, reservedSize: 20)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => Text('${v.toInt()}%', style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)))),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border.withValues(alpha: 0.3), strokeWidth: 0.5)),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(spots: spots, isCurved: true, preventCurveOverShooting: true, color: const Color(0xFF3B82F6), barWidth: 2.5, dotData: FlDotData(show: true, getDotPainter: (s, p, d, i) => FlDotCirclePainter(radius: 3, color: const Color(0xFF3B82F6), strokeWidth: 2, strokeColor: Colors.white)), belowBarData: BarAreaData(show: true, color: const Color(0xFF3B82F6).withValues(alpha: 0.1))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rankings(ColorScheme cs, dynamic data) {
    return Column(
      children: [
        _rankingCard(cs, '\u{1F3C6} Nunca faltan', data.mostConsistent, (s) => '${s.percentage.toStringAsFixed(0)}%', const Color(0xFF22C55E)),
        const SizedBox(height: 8),
        _rankingCard(cs, '\u26A0 M\u00e1s ausencias', data.mostAbsences, (s) => '${s.absent} ausencias', const Color(0xFFEF4444)),
        const SizedBox(height: 8),
        _rankingCard(cs, '\u{1F525} M\u00e1s constantes', data.mostConsistent, (s) => '${s.present} presentes', const Color(0xFFF59E0B)),
        const SizedBox(height: 8),
        _rankingCard(cs, '\u{1F4C8} Mayor mejora', data.mostImproved, (s) => '+${(s.improvement * 100).toStringAsFixed(0)}%', const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _rankingCard(ColorScheme cs, String title, List items, String Function(dynamic) subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Center(child: Text(title.substring(0, 2), style: TextStyle(fontSize: 12)))),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text('Sin datos', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 12))
          else
            ...items.take(5).toList().asMap().entries.map((entry) {
              final i = entry.key + 1;
              final s = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(width: 20, child: Text('$i.', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11))),
                    Expanded(child: Text(s.playerName, style: TextStyle(color: cs.onSurface, fontSize: 12))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text(subtitle(s), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
