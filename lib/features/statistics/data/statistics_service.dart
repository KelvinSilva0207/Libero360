import '../../estadisticas/data/local_db/database_service.dart';
import '../../estadisticas/data/models/models.dart';
import 'statistics_models.dart';

class StatisticsService {
  final DatabaseService _db = DatabaseService.instance;

  Future<SeasonSummary> loadSeasonSummary() async {
    final matches = await _db.getAllMatches();
    final players = await _db.getPlayers();
    final events = await _db.getAllEvents();
    final attendances = await _db.getAllAttendanceRecords();

    final finalizados = matches.where((m) => m.estado == EstadoPartido.finalizado).toList();
    final wins = finalizados.where((m) => m.setsLocal > m.setsVisitante).length;
    final losses = finalizados.length - wins;

    final amistosos = finalizados.where((m) => m.tipoPartido == TipoPartido.amistoso).length;
    final ligas = finalizados.where((m) => m.tipoPartido == TipoPartido.liga).length;
    final torneos = finalizados.where((m) => m.tipoPartido == TipoPartido.torneo).length;
    final practicas = finalizados.where((m) => m.tipoPartido == TipoPartido.practica).length;

    double attendanceAvg = 0;
    List<String> neverMissed = [];
    String bestStreak = '';
    if (attendances.isNotEmpty && players.isNotEmpty) {
      final presentes = attendances.where((a) => a.asistio).length;
      attendanceAvg = (presentes / attendances.length) * 100;

      for (final p in players) {
        final playerAtt = attendances.where((a) => a.playerId == p.id);
        if (playerAtt.isNotEmpty && playerAtt.every((a) => a.asistio)) {
          neverMissed.add(p.nombre);
        }
      }

      bestStreak = _calcBestStreak(attendances, players);
    }

    String? mvpName;
    int mvpPoints = 0;
    if (events.isNotEmpty && players.isNotEmpty) {
      for (final p in players) {
        final playerEvents = events.where((e) => e.playerId == p.id);
        final winners = playerEvents.where((e) => e.resultado == ResultadoAccion.positivo).length;
        if (winners > mvpPoints) {
          mvpPoints = winners;
          mvpName = p.nombre;
        }
      }
    }

    return SeasonSummary(
      totalMatches: finalizados.length,
      wins: wins,
      losses: losses,
      amistosos: amistosos,
      ligas: ligas,
      torneos: torneos,
      practicas: practicas,
      attendanceAvg: attendanceAvg,
      neverMissed: neverMissed,
      bestStreak: bestStreak,
      mvpName: mvpName,
      mvpPoints: mvpPoints,
    );
  }

  Future<List<AthleteStats>> loadAthleteStats() async {
    final players = await _db.getPlayers();
    final matches = await _db.getAllMatches();
    final events = await _db.getAllEvents();
    final attendances = await _db.getAllAttendanceRecords();

    final finalizados = matches.where((m) => m.estado == EstadoPartido.finalizado).toList();

    final List<AthleteStats> stats = [];
    for (final p in players) {
      final playerEvents = events.where((e) => e.playerId == p.id).toList();
      final playerAtt = attendances.where((a) => a.playerId == p.id).toList();

      final matchIds = playerEvents.map((e) => e.matchId).toSet();
      final totalMatches = matchIds.length;

      int ligas = 0, torneos = 0, amistosos = 0, practicas = 0;
      for (final m in finalizados) {
        if (matchIds.contains(m.id)) {
          switch (m.tipoPartido) {
            case TipoPartido.liga: ligas++;
            case TipoPartido.torneo: torneos++;
            case TipoPartido.amistoso: amistosos++;
            case TipoPartido.practica: practicas++;
          }
        }
      }

      final ganadores = playerEvents.where((e) => e.resultado == ResultadoAccion.positivo).length;
      final regulares = playerEvents.where((e) => e.resultado == ResultadoAccion.neutral).length;
      final errores = playerEvents.where((e) => e.resultado == ResultadoAccion.negativo).length;

      final mvpCount = _calcMvpCount(playerEvents, events);

      double attPct = 0;
      if (playerAtt.isNotEmpty) {
        attPct = (playerAtt.where((a) => a.asistio).length / playerAtt.length) * 100;
      }
      final faltas = playerAtt.where((a) => !a.asistio).length;
      final justificadas = playerAtt.where((a) => a.observaciones.isNotEmpty).length;

      stats.add(AthleteStats(
        player: p,
        totalMatches: totalMatches,
        ligas: ligas,
        torneos: torneos,
        amistosos: amistosos,
        practicas: practicas,
        puntosGanadores: ganadores,
        puntosRegulares: regulares,
        errores: errores,
        mvpCount: mvpCount,
        attendancePct: attPct,
        faltas: faltas,
        justificadas: justificadas,
      ));
    }

    stats.sort((a, b) => b.puntosGanadores.compareTo(a.puntosGanadores));
    return stats;
  }

  Future<AthleteStats> loadAthleteStatsForPlayer(Player player) async {
    final all = await loadAthleteStats();
    return all.firstWhere(
      (s) => s.player.id == player.id,
      orElse: () => AthleteStats(player: player),
    );
  }

  Future<AttendanceStats> loadAttendanceStats() async {
    final players = await _db.getPlayers();
    final attendances = await _db.getAllAttendanceRecords();

    if (attendances.isEmpty) return AttendanceStats();

    final totalEntrenamientos = attendances.map((a) => a.fecha.toIso8601String().substring(0, 10)).toSet().length;
    final presentes = attendances.where((a) => a.asistio).length;
    final promedioGlobal = (presentes / attendances.length) * 100;

    final List<PlayerAttendanceSummary> summaries = [];
    for (final p in players) {
      final playerAtt = attendances.where((a) => a.playerId == p.id).toList();
      if (playerAtt.isEmpty) continue;
      final pct = (playerAtt.where((a) => a.asistio).length / playerAtt.length) * 100;
      final justificacion = playerAtt.where((a) => a.observaciones.isNotEmpty).toList();
      summaries.add(PlayerAttendanceSummary(
        name: p.nombre,
        pct: pct,
        justificacion: justificacion.isNotEmpty ? justificacion.first.observaciones : null,
        diasAusente: playerAtt.where((a) => !a.asistio).length,
      ));
    }

    summaries.sort((a, b) => b.pct.compareTo(a.pct));
    final top = summaries.take(5).toList();
    final bottom = summaries.reversed.take(5).toList();

    return AttendanceStats(
      totalEntrenamientos: totalEntrenamientos,
      promedioGlobal: promedioGlobal,
      topAttendance: top,
      peorAttendance: bottom,
    );
  }

  String _calcBestStreak(List<AttendanceRecord> attendances, List<Player> players) {
    String bestPlayer = '';
    int bestStreak = 0;
    for (final p in players) {
      final playerAtt = attendances.where((a) => a.playerId == p.id).toList();
      playerAtt.sort((a, b) => a.fecha.compareTo(b.fecha));
      int streak = 0;
      int maxStreak = 0;
      for (final a in playerAtt) {
        if (a.asistio) {
          streak++;
          if (streak > maxStreak) maxStreak = streak;
        } else {
          streak = 0;
        }
      }
      if (maxStreak > bestStreak) {
        bestStreak = maxStreak;
        bestPlayer = p.nombre;
      }
    }
    return '$bestPlayer ($bestStreak)';
  }

  int _calcMvpCount(List<StatEvent> playerEvents, List<StatEvent> allEvents) {
    final matchIds = playerEvents.map((e) => e.matchId).toSet();
    int mvp = 0;
    for (final mid in matchIds) {
      final matchEvents = allEvents.where((e) => e.matchId == mid).toList();
      if (matchEvents.isEmpty) continue;
      Map<int, int> pointsByPlayer = {};
      for (final e in matchEvents) {
        if (e.resultado == ResultadoAccion.positivo) {
          pointsByPlayer[e.playerId] = (pointsByPlayer[e.playerId] ?? 0) + 1;
        }
      }
      if (pointsByPlayer.isEmpty) continue;
      final topPlayerId = pointsByPlayer.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      if (topPlayerId == playerEvents.first.playerId) {
        mvp++;
      }
    }
    return mvp;
  }
}
