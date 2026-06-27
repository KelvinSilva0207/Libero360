import '../../../core/utils/name_formatter.dart';
import '../../../features/estadisticas/data/local_db/database_service.dart';
import '../../../features/estadisticas/data/models/models.dart';
import 'stats_summary_model.dart';

class StatsRepository {
  final DatabaseService _db;

  StatsRepository({DatabaseService? db}) : _db = db ?? DatabaseService.instance;

  Future<StatsSummaryModel> loadSummary() async {
    await _db.initialize();
    final matches = await _db.getAllMatches();
    final events = await _db.getAllEvents();
    final players = await _db.getAllPlayers();

    final finalized = matches.where((m) => m.estado == EstadoPartido.finalizado).toList();
    finalized.sort((a, b) => b.fecha.compareTo(a.fecha));

    final wins = finalized.where((m) => m.setsLocal > m.setsVisitante).length;
    final losses = finalized.length - wins;
    final winrate = finalized.isEmpty ? 0.0 : (wins / finalized.length) * 100;

    final totalDuration = finalized.fold<int>(0, (sum, m) => sum + m.duracionSegundos);
    final avgDuration = finalized.isEmpty ? 0 : totalDuration ~/ finalized.length;

    final ligas = finalized.where((m) => m.tipoPartido == TipoPartido.liga).length;
    final torneos = finalized.where((m) => m.tipoPartido == TipoPartido.torneo).length;
    final amistosos = finalized.where((m) => m.tipoPartido == TipoPartido.amistoso).length;
    final practicas = finalized.where((m) => m.tipoPartido == TipoPartido.practica).length;

    String? mvpName;
    int mvpPoints = 0;
    for (final p in players) {
      final playerEvents = events.where((e) => e.playerId == p.id);
      if (playerEvents.isEmpty) continue;
      final winners = playerEvents.where((e) => e.resultado == ResultadoAccion.positivo).length;
      if (winners > mvpPoints) {
        mvpPoints = winners;
        mvpName = NameFormatter.playerDisplayName(p);
      }
    }

    int bestStreak = 0;
    int currentStreak = 0;
    for (final m in finalized.reversed) {
      final isWin = m.setsLocal > m.setsVisitante;
      if (isWin) {
        currentStreak++;
        if (currentStreak > bestStreak) bestStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }

    final recent5 = finalized.take(5).toList();
    final recentItems = recent5.map((m) => RecentMatchItem(
      rival: m.rival,
      marcador: m.resultadoSets,
      isWin: m.setsLocal > m.setsVisitante,
      fecha: m.fecha,
      tipoPartido: m.tipoPartidoLabel,
    )).toList();

    final resultLabels = recent5.map((m) => _fechaCorta(m.fecha)).toList();
    final resultIsWins = recent5.map((m) => m.setsLocal > m.setsVisitante).toList();

    final typeLabels = <String>[];
    final typeValues = <double>[];
    if (ligas > 0) { typeLabels.add('Liga'); typeValues.add(ligas.toDouble()); }
    if (torneos > 0) { typeLabels.add('Torneo'); typeValues.add(torneos.toDouble()); }
    if (amistosos > 0) { typeLabels.add('Amistoso'); typeValues.add(amistosos.toDouble()); }
    if (practicas > 0) { typeLabels.add('Práctica'); typeValues.add(practicas.toDouble()); }

    return StatsSummaryModel(
      totalMatches: finalized.length,
      wins: wins,
      losses: losses,
      winrate: winrate,
      averageDurationSeconds: avgDuration,
      mvpName: mvpName,
      mvpPoints: mvpPoints,
      bestStreak: bestStreak,
      ligas: ligas,
      torneos: torneos,
      amistosos: amistosos,
      practicas: practicas,
      recentMatches: recentItems,
      winValues: [wins.toDouble(), losses.toDouble()],
      resultLabels: resultLabels,
      resultIsWins: resultIsWins,
      typeLabels: typeLabels,
      typeValues: typeValues,
    );
  }

  String _fechaCorta(DateTime d) => '${d.day}/${d.month}';
}
