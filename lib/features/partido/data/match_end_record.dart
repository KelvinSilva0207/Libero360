import '../../estadisticas/data/models/models.dart';

class MatchEndRecord {
  final int? matchId;
  final String localName;
  final String visitorName;
  final int localSets;
  final int visitorSets;
  final int durationSeconds;
  final String winnerName;
  final String? mvpPlayerName;
  final int? mvpPoints;
  final String? bestServerName;
  final int? bestServerStreak;
  final String? bestScorerName;
  final int? bestScorerPoints;
  final String? bestBlockerName;
  final int? bestBlockerCount;
  final String? bestReceiverName;
  final int? bestReceiverCount;
  final int? bestRotationIndex;
  final int? bestRotationDiff;
  final String? photoPath;
  final DateTime startTime;
  final DateTime endTime;
  final List<MapEntry<int, int>> setScores;
  final Map<TipoAccion, int> statistics;

  const MatchEndRecord({
    this.matchId,
    required this.localName,
    required this.visitorName,
    required this.localSets,
    required this.visitorSets,
    required this.durationSeconds,
    required this.winnerName,
    this.mvpPlayerName,
    this.mvpPoints,
    this.bestServerName,
    this.bestServerStreak,
    this.bestScorerName,
    this.bestScorerPoints,
    this.bestBlockerName,
    this.bestBlockerCount,
    this.bestReceiverName,
    this.bestReceiverCount,
    this.bestRotationIndex,
    this.bestRotationDiff,
    this.photoPath,
    required this.startTime,
    required this.endTime,
    this.setScores = const [],
    this.statistics = const {},
  });

  String get durationText {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
