class SetEndRecord {
  final int setNumber;
  final int localScore;
  final int visitorScore;
  final int durationSeconds;
  final String winnerName;
  final String? mvpPlayerName;
  final int? mvpPoints;
  final String? bestServerName;
  final int? bestServerStreak;
  final int? bestRotationIndex;
  final int? bestRotationDiff;

  const SetEndRecord({
    required this.setNumber,
    required this.localScore,
    required this.visitorScore,
    required this.durationSeconds,
    required this.winnerName,
    this.mvpPlayerName,
    this.mvpPoints,
    this.bestServerName,
    this.bestServerStreak,
    this.bestRotationIndex,
    this.bestRotationDiff,
  });

  String get durationText {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return s > 0 ? '${m}m ${s}s' : '${m}m';
  }
}
