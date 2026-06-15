import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/local_db/database_service.dart';
import '../../data/models/models.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Player> _players = [];
  List<Match> _matches = [];
  bool _loading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      await DatabaseService.instance.initialize();
      _players = await DatabaseService.instance.getPlayers();
      _matches = await DatabaseService.instance.getAllMatches();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Estadísticas', style: TextStyle(color: Colors.white, fontSize: 15)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: AppColors.surface,
            child: Row(
              children: [
                _tabButton('Partidos', 0),
                _tabButton('Atletas', 1),
                _tabButton('Asistencia', 2),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : IndexedStack(
              index: _selectedTab,
              children: [
                _buildMatchesTab(),
                _buildAthletesTab(),
                _buildAttendanceTab(),
              ],
            ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.accent : Colors.white38,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== MATCHES TAB ====================

  Widget _buildMatchesTab() {
    final finished = _matches.where((m) => m.isFinalizado).toList();
    final wins = finished.where((m) => m.setsLocal > m.setsVisitante).length;
    final losses = finished.where((m) => m.setsLocal < m.setsVisitante).length;

    final byType = <TipoPartido, List<Match>>{};
    for (final m in finished) {
      byType.putIfAbsent(m.tipoPartido, () => []);
      byType[m.tipoPartido]!.add(m);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSeasonCard(finished.length, wins, losses),
        const SizedBox(height: 12),
        _buildMatchTypeCards(byType),
        const SizedBox(height: 12),
        const Text('TODOS LOS PARTIDOS',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        ...finished.take(20).map(_buildMatchCard),
        if (finished.isEmpty)
          _buildEmpty('No hay partidos finalizados'),
      ],
    );
  }

  Widget _buildSeasonCard(int total, int wins, int losses) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF1A1A3E)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bigStat('Partidos', '$total', Colors.white70),
              _bigStat('Victorias', '$wins', const Color(0xFF22C55E)),
              _bigStat('Derrotas', '$losses', const Color(0xFFEF4444)),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: wins / total,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text('${(wins / total * 100).toStringAsFixed(0)}% efectividad',
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Widget _bigStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildMatchTypeCards(Map<TipoPartido, List<Match>> byType) {
    if (byType.isEmpty) return const SizedBox.shrink();
    return Column(
      children: byType.entries.map((e) {
              final tipo = e.key;
              String label;
              switch (tipo) {
                case TipoPartido.amistoso: label = 'Amistoso';
                case TipoPartido.liga: label = 'Liga';
                case TipoPartido.torneo: label = 'Torneo';
                case TipoPartido.practica: label = 'Práctica';
              }
              final count = e.value.length;
        final w = e.value.where((m) => m.setsLocal > m.setsVisitante).length;
        final icon = e.key == TipoPartido.liga || e.key == TipoPartido.torneo
            ? Icons.emoji_events_rounded
            : e.key == TipoPartido.practica
                ? Icons.school_rounded
                : Icons.sports_rounded;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('$count partidos', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Text('$w/${count - w}',
                  style: TextStyle(
                    color: w > count - w ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchCard(Match m) {
    final winner = m.setsLocal > m.setsVisitante;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: winner ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            winner ? Icons.emoji_events : Icons.sports_volleyball,
            color: winner ? const Color(0xFFEAB308) : Colors.white38,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m.equipoLocal} vs ${m.equipoVisitante}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                Text('${m.tipoPartidoLabel} - ${m.setsLocal}-${m.setsVisitante}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Text('${m.setsLocal} - ${m.setsVisitante}',
            style: TextStyle(
              color: winner ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ATHLETES TAB ====================

  Widget _buildAthletesTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('TOP ATHLETAS',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        ..._players.take(10).map((p) => _buildPlayerStatCard(p)),
        if (_players.isEmpty) _buildEmpty('No hay atletas registrados'),
      ],
    );
  }

  Widget _buildPlayerStatCard(Player p) {
    final playerMatches = _matches.where((m) => m.isFinalizado).toList();
    final wins = playerMatches.where((m) => m.setsLocal > m.setsVisitante).length;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('${p.numero ?? "?"}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(p.posicionLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${playerMatches.length}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Partidos', style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ATTENDANCE TAB ====================

  Widget _buildAttendanceTab() {
    return FutureBuilder<List<Player>>(
      future: DatabaseService.instance.getPlayers(),
      builder: (context, snapshot) {
        final players = snapshot.data ?? _players;
        return FutureBuilder<List<AttendanceRecord>>(
          future: DatabaseService.instance.getAttendanceRecords(),
          builder: (context, snapshot2) {
            final records = snapshot2.data ?? [];
            final totalTrainings = records.map((r) =>
              DateTime(r.fecha.year, r.fecha.month, r.fecha.day)).toSet().length;

            int totalPresent = 0;
            int totalRecords = records.length;
            for (final r in records) {
              if (r.asistio) totalPresent++;
            }
            final avgPct = totalRecords > 0 ? (totalPresent / totalRecords * 100).toStringAsFixed(1) : '0';

            final playerStats = <int, Map<String, int>>{};
            int neverMissed = 0;
            int mostAbsences = 0;
            String mostAbsencesName = '';
            int bestStreak = 0;
            String bestStreakName = '';

            for (final p in players) {
              final pRecords = records.where((r) => r.playerId == p.id).toList();
              if (pRecords.isEmpty) continue;
              final present = pRecords.where((r) => r.asistio).length;
              final absent = pRecords.where((r) => !r.asistio).length;
              playerStats[p.id] = {'present': present, 'absent': absent};

              if (absent == 0) neverMissed++;
              if (absent > mostAbsences) {
                mostAbsences = absent;
                mostAbsencesName = p.nombre;
              }

              int streak = 0;
              for (final r in pRecords..sort((a, b) => a.fecha.compareTo(b.fecha))) {
                if (r.asistio) {
                  streak++;
                  if (streak > bestStreak) {
                    bestStreak = streak;
                    bestStreakName = p.nombre;
                  }
                } else {
                  streak = 0;
                }
              }
            }

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _bigStat('Entrenos', '$totalTrainings', Colors.white70),
                          _bigStat('Promedio', '$avgPct%', AppColors.accent),
                          _bigStat('Nunca faltó', '$neverMissed', const Color(0xFF22C55E)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (mostAbsencesName.isNotEmpty || bestStreakName.isNotEmpty) ...[
                        const Divider(color: Colors.white10),
                        if (mostAbsencesName.isNotEmpty)
                          _statRow(Icons.warning_amber_rounded, 'Más faltas: $mostAbsencesName ($mostAbsences)',
                            const Color(0xFFEF4444)),
                        if (bestStreakName.isNotEmpty)
                          _statRow(Icons.local_fire_department_rounded, 'Mejor racha: $bestStreakName ($bestStreak)',
                            const Color(0xFF22C55E)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('DETALLE POR ATLETA',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                ...players.map((p) {
                  final stats = playerStats[p.id];
                  if (stats == null) return const SizedBox.shrink();
                  final present = stats['present'] ?? 0;
                  final absent = stats['absent'] ?? 0;
                  final total = present + absent;
                  final pct = total > 0 ? (present / total * 100).toStringAsFixed(0) : '0';

                  bool isExcused = false;
                  if (p.atletaStatus == AthleteStatus.excused || p.atletaStatus == AthleteStatus.resting || p.atletaStatus == AthleteStatus.injured) {
                    isExcused = true;
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isExcused ? AppColors.accent.withValues(alpha: 0.2) : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isExcused ? AppColors.accent.withValues(alpha: 0.2) : AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isExcused ? Icons.event_busy_rounded : Icons.person_rounded,
                            color: isExcused ? AppColors.accent : Colors.white54,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(p.nombre, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                  if (isExcused) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(p.atletaStatus.label,
                                        style: const TextStyle(color: AppColors.accent, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: total > 0 ? present / total : 0,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isExcused ? AppColors.accent : double.parse(pct) >= 80 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('$pct%', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
                if (players.where((p) => playerStats.containsKey(p.id)).isEmpty)
                  _buildEmpty('No hay registros de asistencia'),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(message, style: const TextStyle(color: Colors.white24, fontSize: 13)),
      ),
    );
  }
}
