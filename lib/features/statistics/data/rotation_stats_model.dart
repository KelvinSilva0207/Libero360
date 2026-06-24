class RotationStatsRecord {
  int id;
  int matchId;
  int setNumber;
  int rotationIndex;
  int pointsWon;
  int pointsLost;
  int serverPlayerNumber;
  List<int> playerSlots;

  RotationStatsRecord({
    this.id = 0,
    required this.matchId,
    required this.setNumber,
    required this.rotationIndex,
    this.pointsWon = 0,
    this.pointsLost = 0,
    this.serverPlayerNumber = 0,
    this.playerSlots = const [],
  });

  int get totalPoints => pointsWon + pointsLost;
  double get effectiveness => totalPoints > 0 ? (pointsWon / totalPoints) * 100 : 0;
}

class RotationStatsSummary {
  final int rotationIndex;
  final int totalPointsWon;
  final int totalPointsLost;
  final int totalMatches;

  RotationStatsSummary({
    required this.rotationIndex,
    this.totalPointsWon = 0,
    this.totalPointsLost = 0,
    this.totalMatches = 0,
  });

  int get totalPoints => totalPointsWon + totalPointsLost;
  double get winrate => totalPoints > 0 ? (totalPointsWon / totalPoints) * 100 : 0;
  int get netPoints => totalPointsWon - totalPointsLost;
  String get label => 'R${rotationIndex + 1}';
}

class RotationSetHistory {
  final int setNumber;
  final int rotationIndex;
  final int netPoints;

  RotationSetHistory({
    required this.setNumber,
    required this.rotationIndex,
    required this.netPoints,
  });

  String get label => 'R${rotationIndex + 1}';
  String get netLabel => netPoints >= 0 ? '+$netPoints' : '$netPoints';
}
