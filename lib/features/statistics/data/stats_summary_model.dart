class StatsSummaryModel {
  final int totalMatches;
  final int wins;
  final int losses;
  final double winrate;
  final int averageDurationSeconds;
  final String? mvpName;
  final int mvpPoints;
  final int bestStreak;
  final int ligas;
  final int torneos;
  final int amistosos;
  final int practicas;
  final List<RecentMatchItem> recentMatches;
  final List<String> winLabels;
  final List<double> winValues;
  final List<String> resultLabels;
  final List<bool> resultIsWins;
  final List<String> typeLabels;
  final List<double> typeValues;

  StatsSummaryModel({
    this.totalMatches = 0,
    this.wins = 0,
    this.losses = 0,
    this.winrate = 0,
    this.averageDurationSeconds = 0,
    this.mvpName,
    this.mvpPoints = 0,
    this.bestStreak = 0,
    this.ligas = 0,
    this.torneos = 0,
    this.amistosos = 0,
    this.practicas = 0,
    this.recentMatches = const [],
    this.winLabels = const ['Victorias', 'Derrotas'],
    this.winValues = const [0, 0],
    this.resultLabels = const [],
    this.resultIsWins = const [],
    this.typeLabels = const [],
    this.typeValues = const [],
  });

  String get averageDurationFormatted {
    final hours = averageDurationSeconds ~/ 3600;
    final minutes = (averageDurationSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '$minutes min';
  }
}

class RecentMatchItem {
  final String rival;
  final String marcador;
  final bool isWin;
  final DateTime fecha;
  final String tipoPartido;

  RecentMatchItem({
    required this.rival,
    required this.marcador,
    required this.isWin,
    required this.fecha,
    required this.tipoPartido,
  });
}
