import '../../estadisticas/data/local_db/database_service.dart';
import '../../estadisticas/data/models/models.dart';
import 'athlete_stats_model.dart';

class AthleteStatsService {
  final DatabaseService _db = DatabaseService.instance;

  Future<AthleteStatsData> calculate(int playerId) async {
    await _db.initialize();
    final events = await _db.getEventsByPlayer(playerId);
    final allMatches = await _db.getAllMatches();

    final radarSkills = _computeRadarSkills(events);
    final barData = _computeBarData(events);
    final pieData = _computePieData(playerId, allMatches, events);
    final matchHistory = _computeMatchHistory(playerId, allMatches, events);
    final lineData = _computeLineData(matchHistory);
    final mvpScore = _computeMvpScore(barData, pieData, events);
    final efficiency = _computeEfficiency(events);

    return AthleteStatsData(
      radarSkills: radarSkills,
      barData: barData,
      pieData: pieData,
      lineData: lineData,
      matchHistory: matchHistory,
      mvpScore: mvpScore,
      efficiency: efficiency,
    );
  }

  List<RadarSkill> _computeRadarSkills(List<StatEvent> events) {
    final attackPos = <StatEvent>[];
    final attackNeg = <StatEvent>[];
    final attackTotal = <StatEvent>[];
    final blockPos = <StatEvent>[];
    final blockTotal = <StatEvent>[];
    final defensePos = <StatEvent>[];
    final defenseTotal = <StatEvent>[];
    final servePos = <StatEvent>[];
    final serveNeg = <StatEvent>[];
    final serveTotal = <StatEvent>[];
    final receptionPos = <StatEvent>[];
    final receptionTotal = <StatEvent>[];
    var totalNegatives = 0;

    for (final e in events) {
      switch (e.tipoAccion) {
        case TipoAccion.ataque:
          attackTotal.add(e);
          if (e.resultado == ResultadoAccion.positivo) attackPos.add(e);
          if (e.resultado == ResultadoAccion.negativo) attackNeg.add(e);
        case TipoAccion.bloqueo:
          blockTotal.add(e);
          if (e.resultado == ResultadoAccion.positivo) blockPos.add(e);
        case TipoAccion.defensa:
          defenseTotal.add(e);
          if (e.resultado == ResultadoAccion.positivo) defensePos.add(e);
        case TipoAccion.saque:
          serveTotal.add(e);
          if (e.resultado == ResultadoAccion.positivo) servePos.add(e);
          if (e.resultado == ResultadoAccion.negativo) serveNeg.add(e);
        case TipoAccion.recepcion:
          receptionTotal.add(e);
          if (e.resultado == ResultadoAccion.positivo) receptionPos.add(e);
        case TipoAccion.colocacion:
        case TipoAccion.errorContrario:
          break;
      }
      if (e.resultado == ResultadoAccion.negativo) totalNegatives++;
    }

    return [
      RadarSkill(name: 'Ataque', value: _efficiencyPct(attackPos.length, attackNeg.length, attackTotal.length)),
      RadarSkill(name: 'Bloqueo', value: _ratePct(blockPos.length, blockTotal.length)),
      RadarSkill(name: 'Defensa', value: _ratePct(defensePos.length, defenseTotal.length)),
      RadarSkill(name: 'Servicio', value: _efficiencyPct(servePos.length, serveNeg.length, serveTotal.length)),
      RadarSkill(name: 'Recepción', value: _ratePct(receptionPos.length, receptionTotal.length)),
      RadarSkill(name: 'Disciplina', value: _disciplineScore(events.length, totalNegatives)),
    ];
  }

  double _efficiencyPct(int positives, int negatives, int total) {
    if (total == 0) return 0;
    final pct = ((positives - negatives) / total) * 100;
    return pct.clamp(0, 100);
  }

  double _ratePct(int successes, int total) {
    if (total == 0) return 0;
    return (successes / total) * 100;
  }

  double _disciplineScore(int totalEvents, int totalNegatives) {
    if (totalEvents == 0) return 100;
    final errorRate = totalNegatives / totalEvents;
    return (1 - errorRate) * 100;
  }

  ActionBarData _computeBarData(List<StatEvent> events) {
    var pos = 0;
    var reg = 0;
    var neg = 0;
    for (final e in events) {
      switch (e.resultado) {
        case ResultadoAccion.positivo: pos++;
        case ResultadoAccion.neutral: reg++;
        case ResultadoAccion.negativo: neg++;
      }
    }
    return ActionBarData(positives: pos, regulars: reg, negatives: neg);
  }

  WinPieData _computePieData(int playerId, List<Match> allMatches, List<StatEvent> events) {
    final matchIds = events.map((e) => e.matchId).toSet();
    var wins = 0;
    var losses = 0;
    var draws = 0;
    for (final m in allMatches) {
      if (!matchIds.contains(m.id)) continue;
      if (!m.isFinalizado) continue;
      if (m.setsLocal > m.setsVisitante) {
        wins++;
      } else if (m.setsLocal < m.setsVisitante) {
        losses++;
      } else {
        draws++;
      }
    }
    return WinPieData(wins: wins, losses: losses, draws: draws);
  }

  List<MatchPerformance> _computeMatchHistory(int playerId, List<Match> allMatches, List<StatEvent> events) {
    final matchEvents = <int, List<StatEvent>>{};
    for (final e in events) {
      matchEvents.putIfAbsent(e.matchId, () => []).add(e);
    }

    final performances = <MatchPerformance>[];
    for (final m in allMatches) {
      final playerEvents = matchEvents[m.id];
      if (playerEvents == null || playerEvents.isEmpty) continue;

      var pos = 0;
      var reg = 0;
      var neg = 0;
      for (final e in playerEvents) {
        switch (e.resultado) {
          case ResultadoAccion.positivo: pos++;
          case ResultadoAccion.neutral: reg++;
          case ResultadoAccion.negativo: neg++;
        }
      }

      final isLocal = playerEvents.any((e) => e.esEquipoLocal);
      final setsFor = isLocal ? m.setsLocal : m.setsVisitante;
      final setsAgainst = isLocal ? m.setsVisitante : m.setsLocal;
      final isWin = m.isFinalizado && setsFor > setsAgainst;
      final isDraw = m.isFinalizado && setsFor == setsAgainst;
      final total = pos + reg + neg;
      final score = total > 0 ? ((pos - neg) / total) * 100 : 0.0;

      performances.add(MatchPerformance(
        matchId: m.id,
        competition: m.competitionName ?? m.tipoPartidoLabel,
        rival: m.equipoLocal == (isLocal ? m.equipoLocal : m.equipoVisitante)
            ? m.equipoVisitante
            : m.equipoLocal,
        isWin: isWin,
        isDraw: isDraw,
        setsFor: setsFor,
        setsAgainst: setsAgainst,
        positiveActions: pos,
        regularActions: reg,
        negativeActions: neg,
        performanceScore: score,
        isMvp: _isPlayerMvp(playerEvents, pos),
      ));
    }

    performances.sort((a, b) {
      final aMatch = allMatches.firstWhere((m) => m.id == a.matchId);
      final bMatch = allMatches.firstWhere((m) => m.id == b.matchId);
      return bMatch.fecha.compareTo(aMatch.fecha);
    });

    return performances;
  }

  bool _isPlayerMvp(List<StatEvent> playerEvents, int positiveCount) {
    if (positiveCount < 3) return false;
    final totalPos = playerEvents.where((e) => e.resultado == ResultadoAccion.positivo).length;
    return totalPos > 0 && positiveCount > (playerEvents.length * 0.5);
  }

  List<LineChartPoint> _computeLineData(List<MatchPerformance> history) {
    final recent = history.take(10).toList();
    return recent.asMap().entries.map((e) => LineChartPoint(
      matchIndex: e.key,
      score: e.value.performanceScore,
    )).toList();
  }

  double _computeMvpScore(ActionBarData bar, WinPieData pie, List<StatEvent> events) {
    final totalPos = bar.positives;
    final wins = pie.wins;
    final total = bar.total;
    final efficiency = total > 0 ? (bar.positives / total) * 100 : 0.0;
    return totalPos + (wins * 10) + (efficiency * 0.5) - bar.negatives;
  }

  double _computeEfficiency(List<StatEvent> events) {
    if (events.isEmpty) return 0;
    var pos = 0;
    var neg = 0;
    for (final e in events) {
      if (e.resultado == ResultadoAccion.positivo) pos++;
      if (e.resultado == ResultadoAccion.negativo) neg++;
    }
    final total = pos + neg;
    if (total == 0) return 0;
    return ((pos - neg) / total) * 100;
  }

  Future<TeamRankings> calculateTeamRankings() async {
    await _db.initialize();
    final players = await _db.getActivePlayers();
    final allEvents = await _db.getAllEvents();
    final allMatches = await _db.getAllMatches();

    final playerEvents = <int, List<StatEvent>>{};
    for (final e in allEvents) {
      if (e.playerId == 0) continue;
      playerEvents.putIfAbsent(e.playerId, () => []).add(e);
    }

    final rankingItems = <TeamRankingItem>[];
    final attackItems = <TeamRankingItem>[];
    final blockItems = <TeamRankingItem>[];
    final defenseItems = <TeamRankingItem>[];
    final serveItems = <TeamRankingItem>[];
    final consistentItems = <TeamRankingItem>[];

    for (final p in players) {
      final events = playerEvents[p.id] ?? [];
      final radar = _computeRadarSkills(events);
      final bar = _computeBarData(events);
      final mvpScore = _computeMvpScore(bar, _computePieData(p.id, allMatches, events), events);

      rankingItems.add(TeamRankingItem(
        rank: 0, playerName: p.displayName, playerId: p.id,
        score: mvpScore, numero: p.numero,
      ));

      final attackVal = radar.firstWhere((s) => s.name == 'Ataque').value;
      attackItems.add(TeamRankingItem(
        rank: 0, playerName: p.displayName, playerId: p.id,
        score: attackVal, numero: p.numero,
      ));

      final blockVal = radar.firstWhere((s) => s.name == 'Bloqueo').value;
      blockItems.add(TeamRankingItem(
        rank: 0, playerName: p.displayName, playerId: p.id,
        score: blockVal, numero: p.numero,
      ));

      final defenseVal = radar.firstWhere((s) => s.name == 'Defensa').value;
      defenseItems.add(TeamRankingItem(
        rank: 0, playerName: p.displayName, playerId: p.id,
        score: defenseVal, numero: p.numero,
      ));

      final serveVal = radar.firstWhere((s) => s.name == 'Servicio').value;
      serveItems.add(TeamRankingItem(
        rank: 0, playerName: p.displayName, playerId: p.id,
        score: serveVal, numero: p.numero,
      ));

      final disciplineVal = radar.firstWhere((s) => s.name == 'Disciplina').value;
      consistentItems.add(TeamRankingItem(
        rank: 0, playerName: p.displayName, playerId: p.id,
        score: disciplineVal, numero: p.numero,
      ));
    }

    return TeamRankings(
      mvp: _rank(rankingItems),
      bestAttackers: _rank(attackItems),
      bestBlockers: _rank(blockItems),
      bestDefenders: _rank(defenseItems),
      bestServers: _rank(serveItems),
      mostConsistent: _rank(consistentItems),
    );
  }

  List<TeamRankingItem> _rank(List<TeamRankingItem> items) {
    final sorted = List<TeamRankingItem>.from(items)
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.asMap().entries.map((e) => TeamRankingItem(
      rank: e.key + 1,
      playerName: e.value.playerName,
      playerId: e.value.playerId,
      score: e.value.score,
      numero: e.value.numero,
    )).toList();
  }
}
