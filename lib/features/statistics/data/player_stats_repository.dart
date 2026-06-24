import '../../../features/estadisticas/data/local_db/database_service.dart';
import '../../../features/estadisticas/data/models/models.dart';
import 'player_stats_model.dart';

class PlayerStatsRepository {
  final DatabaseService _db;

  PlayerStatsRepository({DatabaseService? db}) : _db = db ?? DatabaseService.instance;

  Future<PlayerDetailStats> loadPlayerStats(Player player) async {
    await _db.initialize();
    final events = await _db.getEventsByPlayer(player.id);
    final allMatches = await _db.getAllMatches();
    final allEvents = await _db.getAllEvents();

    int attack = 0, block = 0, serve = 0, defense = 0, reception = 0, errors = 0;
    final Map<int, int> pointsBySet = {};
    final matchIds = <int>{};

    for (final e in events) {
      matchIds.add(e.matchId);
      if (e.resultado == ResultadoAccion.negativo) {
        errors++;
        continue;
      }
      if (e.resultado != ResultadoAccion.positivo) continue;

      pointsBySet[e.setNumero] = (pointsBySet[e.setNumero] ?? 0) + 1;

      switch (e.tipoAccion) {
        case TipoAccion.ataque: attack++;
        case TipoAccion.bloqueo: block++;
        case TipoAccion.saque: serve++;
        case TipoAccion.defensa: defense++;
        case TipoAccion.recepcion: reception++;
        case TipoAccion.colocacion: break;
        case TipoAccion.errorContrario: break;
      }
    }

    final mvpCount = _calcMvpCount(events, allEvents);
    final wins = _calcWins(player.id, matchIds, allMatches, events);
    final losses = _calcLosses(player.id, matchIds, allMatches, events);

    int ligas = 0, torneos = 0, amistosos = 0, practicas = 0;
    for (final m in allMatches) {
      if (!matchIds.contains(m.id)) continue;
      switch (m.tipoPartido) {
        case TipoPartido.liga: ligas++;
        case TipoPartido.torneo: torneos++;
        case TipoPartido.amistoso: amistosos++;
        case TipoPartido.practica: practicas++;
      }
    }

    final maxVal = [attack, block, serve, defense, reception]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final radarMax = maxVal > 0 ? maxVal : 1.0;

    final perSet = pointsBySet.entries
        .map((e) => SetStat(setNumber: e.key, points: e.value))
        .toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    return PlayerDetailStats(
      player: player,
      totalMvp: mvpCount,
      attackCount: attack,
      blockCount: block,
      serveCount: serve,
      defenseCount: defense,
      receptionCount: reception,
      errorCount: errors,
      totalWins: wins,
      totalLosses: losses,
      ligas: ligas,
      torneos: torneos,
      amistosos: amistosos,
      practicas: practicas,
      perSetStats: perSet,
      maxRadarValue: radarMax,
    );
  }

  int _calcMvpCount(List<StatEvent> playerEvents, List<StatEvent> allEvents) {
    final matchIds = playerEvents.map((e) => e.matchId).toSet();
    int mvp = 0;
    for (final mid in matchIds) {
      final matchEvents = allEvents.where((e) => e.matchId == mid).toList();
      if (matchEvents.isEmpty) continue;
      final Map<int, int> pointsByPlayer = {};
      for (final e in matchEvents) {
        if (e.resultado == ResultadoAccion.positivo) {
          pointsByPlayer[e.playerId] = (pointsByPlayer[e.playerId] ?? 0) + 1;
        }
      }
      if (pointsByPlayer.isEmpty) continue;
      final topPlayerId = pointsByPlayer.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      if (topPlayerId == playerEvents.first.playerId) {
        mvp++;
      }
    }
    return mvp;
  }

  int _calcWins(int playerId, Set<int> matchIds, List<Match> allMatches,
      List<StatEvent> playerEvents) {
    int wins = 0;
    for (final m in allMatches) {
      if (!matchIds.contains(m.id)) continue;
      if (m.estado != EstadoPartido.finalizado) continue;
      if (m.setsLocal > m.setsVisitante) wins++;
    }
    return wins;
  }

  int _calcLosses(int playerId, Set<int> matchIds, List<Match> allMatches,
      List<StatEvent> playerEvents) {
    int losses = 0;
    for (final m in allMatches) {
      if (!matchIds.contains(m.id)) continue;
      if (m.estado != EstadoPartido.finalizado) continue;
      if (m.setsLocal <= m.setsVisitante) losses++;
    }
    return losses;
  }
}
