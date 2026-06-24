import '../../../features/estadisticas/data/local_db/database_service.dart';
import 'rotation_stats_model.dart';

class RotationStatsRepository {
  final DatabaseService _db;

  RotationStatsRepository({DatabaseService? db})
      : _db = db ?? DatabaseService.instance;

  Future<List<RotationStatsSummary>> loadRotationSummaries() async {
    await _db.initialize();
    final records = await _db.getAllRotationStatsRecords();
    if (records.isEmpty) return [];

    final perRotation = <int, List<RotationStatsRecord>>{};
    final matchIds = <int>{};

    for (final r in records) {
      perRotation.putIfAbsent(r.rotationIndex, () => []).add(r);
      matchIds.add(r.matchId);
    }

    return List.generate(6, (i) {
      final items = perRotation[i] ?? [];
      final totalWon = items.fold<int>(0, (s, r) => s + r.pointsWon);
      final totalLost = items.fold<int>(0, (s, r) => s + r.pointsLost);
      return RotationStatsSummary(
        rotationIndex: i,
        totalPointsWon: totalWon,
        totalPointsLost: totalLost,
        totalMatches: matchIds.length,
      );
    });
  }

  Future<RotationStatsDetail> loadRotationDetail(int rotationIndex) async {
    await _db.initialize();
    final records = await _db.getAllRotationStatsRecords();
    final rotationRecords = records.where((r) => r.rotationIndex == rotationIndex).toList();

    final totalWon = rotationRecords.fold<int>(0, (s, r) => s + r.pointsWon);
    final totalLost = rotationRecords.fold<int>(0, (s, r) => s + r.pointsLost);

    final matchIds = rotationRecords.map((r) => r.matchId).toSet();
    final matchDurationMap = <int, int>{};
    for (final mid in matchIds) {
      final match = await _db.getMatchById(mid);
      if (match != null) {
        matchDurationMap[mid] = match.duracionSegundos;
      }
    }

    final perSet = <int, int>{};
    for (final r in rotationRecords) {
      perSet.update(
        r.setNumber,
        (v) => v + r.pointsWon - r.pointsLost,
        ifAbsent: () => r.pointsWon - r.pointsLost,
      );
    }

    final setHistory = perSet.entries.map((e) => RotationSetHistory(
      setNumber: e.key,
      rotationIndex: rotationIndex,
      netPoints: e.value,
    )).toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

    final serverPlayers = rotationRecords
        .where((r) => r.serverPlayerNumber > 0)
        .map((r) => r.serverPlayerNumber)
        .toSet()
        .toList();

    final allSlots = rotationRecords
        .where((r) => r.playerSlots.isNotEmpty)
        .map((r) => r.playerSlots)
        .toList();

    final avgDuration = matchDurationMap.isEmpty
        ? 0
        : matchDurationMap.values.fold<int>(0, (s, d) => s + d) ~/ matchDurationMap.length;

    return RotationStatsDetail(
      rotationIndex: rotationIndex,
      pointsWon: totalWon,
      pointsLost: totalLost,
      averageDurationSeconds: avgDuration,
      serverPlayerNumbers: serverPlayers,
      playerSlotsList: allSlots,
      setHistory: setHistory,
    );
  }

  Future<List<RotationSetHistory>> loadRotationSetHistory(int rotationIndex) async {
    final detail = await loadRotationDetail(rotationIndex);
    return detail.setHistory;
  }
}

class RotationStatsDetail {
  final int rotationIndex;
  final int pointsWon;
  final int pointsLost;
  final int averageDurationSeconds;
  final List<int> serverPlayerNumbers;
  final List<List<int>> playerSlotsList;
  final List<RotationSetHistory> setHistory;

  RotationStatsDetail({
    required this.rotationIndex,
    this.pointsWon = 0,
    this.pointsLost = 0,
    this.averageDurationSeconds = 0,
    this.serverPlayerNumbers = const [],
    this.playerSlotsList = const [],
    this.setHistory = const [],
  });

  int get totalPoints => pointsWon + pointsLost;
  double get winrate => totalPoints > 0 ? (pointsWon / totalPoints) * 100 : 0;
  String get avgDurationFormatted {
    final h = averageDurationSeconds ~/ 3600;
    final m = (averageDurationSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '$m min';
  }
}
