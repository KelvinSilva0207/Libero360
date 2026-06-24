import '../../estadisticas/data/local_db/database_service.dart';
import '../../estadisticas/data/models/models.dart';
import 'statistics_models.dart';

class AthleteRankingService {
  final DatabaseService _db = DatabaseService.instance;

  static const double pesoAtaque = 2.0;
  static const double pesoBloqueo = 3.0;
  static const double pesoServicio = 2.5;
  static const double pesoDefensa = 1.5;
  static const double pesoRecepcion = 1.5;
  static const double pesoMVP = 5.0;
  static const double pesoAsistencia = 2.0;

  Future<List<AthleteRankingScore>> loadRankings({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final players = await _db.getPlayers();
    final allEvents = await _db.getAllEvents();
    final attendances = await _db.getAllAttendanceRecords();

    final filteredEvents = _filterEventsByDate(allEvents, startDate, endDate);

    final List<AthleteRankingScore> rankings = [];

    for (final p in players) {
      final playerEvents =
          filteredEvents.where((e) => e.playerId == p.id).toList();

      final ataques = playerEvents
          .where((e) =>
              e.tipoAccion == TipoAccion.ataque &&
              e.resultado == ResultadoAccion.positivo)
          .length;
      final bloqueos = playerEvents
          .where((e) =>
              e.tipoAccion == TipoAccion.bloqueo &&
              e.resultado == ResultadoAccion.positivo)
          .length;
      final servicios = playerEvents
          .where((e) =>
              e.tipoAccion == TipoAccion.saque &&
              e.resultado == ResultadoAccion.positivo)
          .length;
      final defensas = playerEvents
          .where((e) =>
              e.tipoAccion == TipoAccion.defensa &&
              e.resultado == ResultadoAccion.positivo)
          .length;
      final recepciones = playerEvents
          .where((e) =>
              e.tipoAccion == TipoAccion.recepcion &&
              e.resultado == ResultadoAccion.positivo)
          .length;
      final errores = playerEvents
          .where((e) => e.resultado == ResultadoAccion.negativo)
          .length;

      final mvpCount = _calcMvpCountInEvents(playerEvents, allEvents);
      final attPct = _calcAttendancePct(p.id, attendances, startDate, endDate);

      final score = (ataques * pesoAtaque) +
          (bloqueos * pesoBloqueo) +
          (servicios * pesoServicio) +
          (defensas * pesoDefensa) +
          (recepciones * pesoRecepcion) +
          (mvpCount * pesoMVP) +
          (attPct * pesoAsistencia / 100);

      rankings.add(AthleteRankingScore(
        player: p,
        ataques: ataques,
        bloqueos: bloqueos,
        servicios: servicios,
        defensas: defensas,
        recepciones: recepciones,
        mvpCount: mvpCount,
        attendancePct: attPct,
        errores: errores,
        score: score,
      ));
    }

    rankings.sort((a, b) => b.score.compareTo(a.score));
    return rankings;
  }

  Future<AthleteMonthlyAward?> getCurrentMonthAward() async {
    final awards = await _db.getAllMonthlyAwards();
    final now = DateTime.now();
    final thisMonth = awards.where(
        (a) => a.year == now.year && a.month == now.month && a.rank == 1);
    return thisMonth.isNotEmpty ? thisMonth.first : null;
  }

  Future<List<AthleteMonthlyAward>> getHistoricalAwards() async {
    return await _db.getAllMonthlyAwards();
  }

  Future<void> persistMonthRankings(
      List<AthleteRankingScore> rankings) async {
    final now = DateTime.now();
    final existing = await _db.getAllMonthlyAwards();
    for (int i = 0; i < rankings.length && i < 10; i++) {
      final r = rankings[i];
      final already = existing.any((a) =>
          a.year == now.year &&
          a.month == now.month &&
          a.playerId == r.player.id);
      if (!already) {
        await _db.saveMonthlyAward(AthleteMonthlyAward(
          playerId: r.player.id,
          year: now.year,
          month: now.month,
          score: r.score,
          rank: i + 1,
        ));
      }
    }
  }

  List<StatEvent> _filterEventsByDate(
      List<StatEvent> events, DateTime? start, DateTime? end) {
    if (start == null && end == null) return events;
    return events.where((e) {
      if (start != null && e.timestamp.isBefore(start)) return false;
      if (end != null && e.timestamp.isAfter(end)) return false;
      return true;
    }).toList();
  }

  double _calcAttendancePct(int playerId, List<AttendanceRecord> attendances,
      DateTime? start, DateTime? end) {
    var playerAtt = attendances.where((a) => a.playerId == playerId);
    if (start != null || end != null) {
      playerAtt = playerAtt.where((a) {
        if (start != null && a.fecha.isBefore(start)) return false;
        if (end != null && a.fecha.isAfter(end)) return false;
        return true;
      });
    }
    final list = playerAtt.toList();
    if (list.isEmpty) return 0;
    return (list.where((a) => a.asistio).length / list.length) * 100;
  }

  int _calcMvpCountInEvents(
      List<StatEvent> playerEvents, List<StatEvent> allEvents) {
    final matchIds = playerEvents.map((e) => e.matchId).toSet();
    int mvp = 0;
    for (final mid in matchIds) {
      final matchEvents = allEvents.where((e) => e.matchId == mid).toList();
      if (matchEvents.isEmpty) continue;
      Map<int, int> pointsByPlayer = {};
      for (final e in matchEvents) {
        if (e.resultado == ResultadoAccion.positivo) {
          pointsByPlayer[e.playerId] =
              (pointsByPlayer[e.playerId] ?? 0) + 1;
        }
      }
      if (pointsByPlayer.isEmpty) continue;
      final topId =
          pointsByPlayer.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      if (topId == playerEvents.first.playerId) {
        mvp++;
      }
    }
    return mvp;
  }
}
