import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../data/statistics_service.dart';
import '../../data/statistics_models.dart';
import 'athlete_statistics_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _service = StatisticsService();
  SeasonSummary? _summary;
  List<AthleteStats>? _athleteStats;
  AttendanceStats? _attendanceStats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await DatabaseService.instance.initialize();
      final results = await Future.wait([
        _service.loadSeasonSummary(),
        _service.loadAthleteStats(),
        _service.loadAttendanceStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as SeasonSummary;
        _athleteStats = results[1] as List<AthleteStats>;
        _attendanceStats = results[2] as AttendanceStats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final bg = isDark ? const Color(0xFF071126) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF101B3A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFFA6B1D0) : const Color(0xFF64748B);
    const accent = Color(0xFFFF8C00);
    const primary = Color(0xFF0081CF);
    const success = Color(0xFF22C55E);
    final border = isDark ? const Color(0xFF1E2D5A) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        title: const Text('Estadísticas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center,
                            style: TextStyle(color: textSecondary, fontSize: 14)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _SeasonCard(summary: _summary!, textPrimary: textPrimary, textSecondary: textSecondary,
                          accent: accent, cardBg: cardBg, border: border),
                      const SizedBox(height: 16),
                      _CompetitionsCard(summary: _summary!, textPrimary: textPrimary, textSecondary: textSecondary,
                          accent: accent, cardBg: cardBg, border: border, primary: primary),
                      const SizedBox(height: 16),
                      _AttendanceOverviewCard(stats: _attendanceStats!, textPrimary: textPrimary,
                          textSecondary: textSecondary, accent: accent, cardBg: cardBg, border: border, success: success),
                      const SizedBox(height: 16),
                      _TopAthletesCard(athletes: _athleteStats!, textPrimary: textPrimary,
                          textSecondary: textSecondary, accent: accent, cardBg: cardBg, border: border,
                          onTapAthlete: _openAthleteStats),
                    ],
                  ),
                ),
    );
  }

  void _openAthleteStats(AthleteStats stats) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AthleteStatisticsScreen(athleteStats: stats),
    ));
  }
}

class _SeasonCard extends StatelessWidget {
  final SeasonSummary summary;
  final Color textPrimary, textSecondary, accent, cardBg, border;

  const _SeasonCard({required this.summary, required this.textPrimary, required this.textSecondary,
    required this.accent, required this.cardBg, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFF8C00), size: 22),
              const SizedBox(width: 8),
              Text('TEMPORADA', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBox(label: 'Partidos', value: '${summary.totalMatches}', color: textPrimary, subColor: textSecondary),
              _StatBox(label: 'Victorias', value: '${summary.wins}', color: const Color(0xFF22C55E), subColor: textSecondary),
              _StatBox(label: 'Derrotas', value: '${summary.losses}', color: const Color(0xFFEF4444), subColor: textSecondary),
            ],
          ),
          if (summary.mvpName != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFF8C00), size: 18),
                const SizedBox(width: 6),
                Text('MVP temporada: ', style: TextStyle(color: textSecondary, fontSize: 13)),
                Text(summary.mvpName!, style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold)),
                Text('  (${summary.mvpPoints} pts)', style: TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color, subColor;

  const _StatBox({required this.label, required this.value, required this.color, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: subColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _CompetitionsCard extends StatelessWidget {
  final SeasonSummary summary;
  final Color textPrimary, textSecondary, accent, cardBg, border, primary;

  const _CompetitionsCard({required this.summary, required this.textPrimary, required this.textSecondary,
    required this.accent, required this.cardBg, required this.border, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFF8C00), size: 22),
              const SizedBox(width: 8),
              Text('COMPETICIONES', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          _CompRow(label: 'Amistosos', value: summary.amistosos, color: primary, icon: Icons.fitness_center),
          _CompRow(label: 'Ligas', value: summary.ligas, color: accent, icon: Icons.emoji_events),
          _CompRow(label: 'Torneos', value: summary.torneos, color: const Color(0xFF8B5CF6), icon: Icons.military_tech),
          _CompRow(label: 'Prácticas', value: summary.practicas, color: const Color(0xFF22C55E), icon: Icons.school),
        ],
      ),
    );
  }
}

class _CompRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _CompRow({required this.label, required this.value, required this.color, required this.icon});

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
          Text('$value', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AttendanceOverviewCard extends StatelessWidget {
  final AttendanceStats? stats;
  final Color textPrimary, textSecondary, accent, cardBg, border, success;

  const _AttendanceOverviewCard({required this.stats, required this.textPrimary, required this.textSecondary,
    required this.accent, required this.cardBg, required this.border, required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF22C55E), size: 22),
              const SizedBox(width: 8),
              Text('ASISTENCIA', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          if (stats != null) ...[
            Row(
              children: [
                Text('${stats!.promedioGlobal.toStringAsFixed(0)}%', style: TextStyle(color: success, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Text('Promedio', style: TextStyle(color: textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Text('${stats!.totalEntrenamientos} entrenamientos', style: TextStyle(color: textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Text('TOP ASISTENCIA', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            ...stats!.topAttendance.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(p.name, style: TextStyle(color: textPrimary, fontSize: 13)),
                  const Spacer(),
                  Text('${p.pct.toStringAsFixed(0)}%', style: TextStyle(color: success, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
          ] else
            Text('Sin datos', style: TextStyle(color: textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _TopAthletesCard extends StatelessWidget {
  final List<AthleteStats>? athletes;
  final Color textPrimary, textSecondary, accent, cardBg, border;
  final void Function(AthleteStats) onTapAthlete;

  const _TopAthletesCard({required this.athletes, required this.textPrimary, required this.textSecondary,
    required this.accent, required this.cardBg, required this.border, required this.onTapAthlete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF0081CF), size: 22),
              const SizedBox(width: 8),
              Text('TOP ATLETAS', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          if (athletes != null && athletes!.isNotEmpty)
            ...athletes!.take(5).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return InkWell(
                onTap: () => onTapAthlete(s),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text('${i + 1}', style: TextStyle(color: i < 3 ? accent : textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: accent.withValues(alpha: 0.15),
                        child: Text(
                          s.player.nombre.isNotEmpty ? s.player.nombre[0].toUpperCase() : '?',
                          style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.player.nombre, style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('${s.totalPuntos} pts  •  ${s.eficiencia.toStringAsFixed(0)}% ef.', style: TextStyle(color: textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('${s.puntosGanadores}', style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            })
          else
            Text('Sin datos', style: TextStyle(color: textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
