import '../../../core/utils/name_formatter.dart';
import '../../estadisticas/data/local_db/database_service.dart';
import '../../estadisticas/data/models/models.dart';
import '../data/athlete_ranking_service.dart';
import '../data/rotation_stats_repository.dart';
import '../data/stats_dashboard_model.dart';

class StatsDashboardService {
  final DatabaseService _db = DatabaseService.instance;

  Future<StatsDashboardData> loadDashboard() async {
    final athletes = await _loadAthleteOfMonth();
    final summary = await _loadSeasonSummary();
    final charts = await _loadCharts();
    final hallOfFame = await _loadHallOfFame();
    final matches = await _loadRecentMatches();
    final activity = await _loadRecentActivity();

    return StatsDashboardData(
      athleteOfMonth: athletes,
      seasonSummary: summary,
      charts: charts,
      hallOfFame: hallOfFame,
      recentMatches: matches,
      recentActivity: activity,
    );
  }

  Future<AthleteOfMonthData?> _loadAthleteOfMonth() async {
    final rankingService = AthleteRankingService();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final rankings = await rankingService.loadRankings(
      startDate: start,
      endDate: end,
    );
    if (rankings.isEmpty) return null;

    final winner = rankings.first;
    final p = winner.player;
    final total = winner.ataques +
        winner.bloqueos +
        winner.servicios +
        winner.defensas +
        winner.recepciones;
    final double eficiencia =
        total > 0 ? (winner.ataques + winner.bloqueos + winner.servicios +
                winner.defensas + winner.recepciones) /
            total *
            100 : 0.0;

    return AthleteOfMonthData(
      player: p,
      mvpCount: winner.mvpCount,
      ataques: winner.ataques,
      bloqueos: winner.bloqueos,
      servicios: winner.servicios,
      defensas: winner.defensas,
      recepciones: winner.recepciones,
      attendancePct: winner.attendancePct,
      eficiencia: eficiencia,
    );
  }

  Future<SeasonSummaryCards> _loadSeasonSummary() async {
    final matches = await _db.getAllMatches();
    final events = await _db.getAllEvents();
    final players = await _db.getPlayers();
    final attendances = await _db.getAllAttendanceRecords();

    final finalized = matches
        .where((m) => m.estado == EstadoPartido.finalizado)
        .toList();
    final wins =
        finalized.where((m) => m.setsLocal > m.setsVisitante).length;
    final losses = finalized.length - wins;
    final winrate =
        finalized.isEmpty ? 0.0 : (wins / finalized.length) * 100;
    final totalDuration = finalized.fold<int>(
        0, (sum, m) => sum + m.duracionSegundos);
    final avgDuration =
        finalized.isEmpty ? 0 : totalDuration ~/ finalized.length;

    final matchIds = finalized.map((m) => m.id).toSet();
    int mvpAwards = 0;
    for (final mid in matchIds) {
      final matchEvents = events.where((e) => e.matchId == mid).toList();
      if (matchEvents.isEmpty) continue;
      Map<int, int> pointsByPlayer = {};
      for (final e in matchEvents) {
        if (e.resultado == ResultadoAccion.positivo) {
          pointsByPlayer[e.playerId] =
              (pointsByPlayer[e.playerId] ?? 0) + 1;
        }
      }
      if (pointsByPlayer.isNotEmpty) mvpAwards++;
    }

    final trainingDates =
        attendances.map((a) => _dateKey(a.fecha)).toSet().length;
    final medicalLeaves =
        players.where((p) => p.atletaStatus == AthleteStatus.injured).length;

    return SeasonSummaryCards(
      wins: wins,
      losses: losses,
      winrate: winrate,
      totalMatches: finalized.length,
      averageDurationSeconds: avgDuration,
      mvpAwards: mvpAwards,
      totalEntrenamientos: trainingDates,
      medicalLeaves: medicalLeaves,
    );
  }

  Future<ChartData> _loadCharts() async {
    final matches = await _db.getAllMatches();
    final finalized = matches
        .where((m) => m.estado == EstadoPartido.finalizado)
        .toList();
    finalized.sort((a, b) => b.fecha.compareTo(a.fecha));

    final wins =
        finalized.where((m) => m.setsLocal > m.setsVisitante).length;
    final losses = finalized.length - wins;

    final recent10 = finalized.take(10).toList();
    final resultIsWins =
        recent10.map((m) => m.setsLocal > m.setsVisitante).toList();
    final resultLabels = recent10
        .map((m) => '${m.fecha.day}/${m.fecha.month}')
        .toList();

    final ligas =
        finalized.where((m) => m.tipoPartido == TipoPartido.liga).length;
    final torneos =
        finalized.where((m) => m.tipoPartido == TipoPartido.torneo).length;
    final amistosos =
        finalized.where((m) => m.tipoPartido == TipoPartido.amistoso).length;
    final practicas = finalized
        .where((m) => m.tipoPartido == TipoPartido.practica)
        .length;

    final typeLabels = <String>[];
    final typeValues = <double>[];
    if (ligas > 0) {
      typeLabels.add('Liga');
      typeValues.add(ligas.toDouble());
    }
    if (torneos > 0) {
      typeLabels.add('Torneo');
      typeValues.add(torneos.toDouble());
    }
    if (amistosos > 0) {
      typeLabels.add('Amistoso');
      typeValues.add(amistosos.toDouble());
    }
    if (practicas > 0) {
      typeLabels.add('Práctica');
      typeValues.add(practicas.toDouble());
    }

    final rotationRepo = RotationStatsRepository();
    final rotations = await rotationRepo.loadRotationSummaries();
    final rotationData = rotations
        .where((r) => r.totalPoints > 0)
        .map((r) => RotationBarItem(
              label: r.label,
              effectiveness: r.winrate,
            ))
        .toList();

    return ChartData(
      wins: wins,
      losses: losses,
      resultIsWins: resultIsWins,
      resultLabels: resultLabels,
      typeLabels: typeLabels,
      typeValues: typeValues,
      rotationData: rotationData,
    );
  }

  Future<List<HallOfFameEntry>> _loadHallOfFame() async {
    final rankingService = AthleteRankingService();
    final allTime = await rankingService.loadRankings();
    final entries = <HallOfFameEntry>[];
    for (int i = 0; i < allTime.length && i < 10; i++) {
      final r = allTime[i];
      final total = r.totalPositive + r.errores;
      final double eficiencia = total > 0 ? (r.totalPositive / total * 100) : 0.0;
      entries.add(HallOfFameEntry(
        player: r.player,
        score: r.score,
        rank: i + 1,
        mvpCount: r.mvpCount,
        eficiencia: eficiencia,
      ));
    }
    return entries;
  }

  Future<List<DashboardMatchItem>> _loadRecentMatches() async {
    final matches = await _db.getAllMatches();
    final events = await _db.getAllEvents();
    final players = await _db.getPlayers();
    final playerMap = {for (final p in players) p.id: p};

    final finalized = matches
        .where((m) => m.estado == EstadoPartido.finalizado)
        .toList();
    finalized.sort((a, b) => b.fecha.compareTo(a.fecha));
    final recent = finalized.take(5);

    return recent.map((m) {
      final matchEvents = events.where((e) => e.matchId == m.id).toList();
      String? mvpName;
      if (matchEvents.isNotEmpty) {
        Map<int, int> pointsByPlayer = {};
        for (final e in matchEvents) {
          if (e.resultado == ResultadoAccion.positivo) {
            pointsByPlayer[e.playerId] =
                (pointsByPlayer[e.playerId] ?? 0) + 1;
          }
        }
        if (pointsByPlayer.isNotEmpty) {
          final topId = pointsByPlayer.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          mvpName = playerMap[topId] != null ? NameFormatter.playerDisplayName(playerMap[topId]!) : null;
        }
      }

      return DashboardMatchItem(
        matchId: m.id,
        rival: m.rival,
        marcador: m.resultadoSets,
        isWin: m.setsLocal > m.setsVisitante,
        fecha: m.fecha,
        tipoPartido: m.tipoPartidoLabel,
        mvpName: mvpName,
        durationSeconds: m.duracionSegundos,
        competitionName: m.competitionName,
        lugar: m.lugar,
      );
    }).toList();
  }

  Future<List<ActivityItem>> _loadRecentActivity() async {
    final items = <ActivityItem>[];
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final events = await _db.getAllEvents();
    final matches = await _db.getAllMatches();
    final players = await _db.getPlayers();
    final attendances = await _db.getAllAttendanceRecords();
    final playerMap = {for (final p in players) p.id: p};

    final finalized = matches
        .where((m) => m.estado == EstadoPartido.finalizado)
        .toList();
    finalized.sort((a, b) => b.fecha.compareTo(a.fecha));

    for (final m in finalized.take(5)) {
      final matchEvents = events.where((e) => e.matchId == m.id).toList();
      if (matchEvents.isNotEmpty) {
        Map<int, int> pointsByPlayer = {};
        for (final e in matchEvents) {
          if (e.resultado == ResultadoAccion.positivo) {
            pointsByPlayer[e.playerId] =
                (pointsByPlayer[e.playerId] ?? 0) + 1;
          }
        }
        if (pointsByPlayer.isNotEmpty) {
          final topId = pointsByPlayer.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          final mvpName = playerMap[topId] != null ? NameFormatter.playerDisplayName(playerMap[topId]!) : 'Jugador';
          final result = m.setsLocal > m.setsVisitante ? 'ganado' : 'perdido';
          items.add(ActivityItem(
            icon: m.setsLocal > m.setsVisitante ? '🏆' : '❌',
            description: m.setsLocal > m.setsVisitante
                ? 'MVP $mvpName'
                : 'Derrota vs ${m.rival}',
            timestamp: m.fecha,
            type: ActivityType.mvp,
          ));
          items.add(ActivityItem(
            icon: '🏐',
            description:
                'Partido $result vs ${m.rival} (${m.tipoPartidoLabel})',
            timestamp: m.fecha,
            type: ActivityType.match,
          ));
        }
      }
    }

    final recentAttendances = attendances
        .where((a) => a.fecha.isAfter(startOfMonth))
        .toList();
    for (final a in recentAttendances.take(3)) {
      final pName = playerMap[a.playerId] != null ? NameFormatter.playerDisplayName(playerMap[a.playerId]!) : 'Jugador';
      if (a.asistio) {
        items.add(ActivityItem(
          icon: '📅',
          description: '$pName registró asistencia',
          timestamp: a.fecha,
          type: ActivityType.training,
        ));
      } else {
        items.add(ActivityItem(
          icon: '⚠',
          description: '$pName faltó al entrenamiento',
          timestamp: a.fecha,
          type: ActivityType.training,
        ));
      }
    }

    final injuredPlayers =
        players.where((p) => p.atletaStatus == AthleteStatus.injured).toList();
    for (final p in injuredPlayers) {
      items.add(ActivityItem(
        icon: '⚠',
        description: '${NameFormatter.playerDisplayName(p)} inició reposo médico',
        timestamp: p.statusStartDate ?? DateTime.now(),
        type: ActivityType.medical,
      ));
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.take(10).toList();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
