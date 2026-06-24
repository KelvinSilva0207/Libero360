import '../../estadisticas/data/models/models.dart';

class StatsDashboardData {
  final AthleteOfMonthData? athleteOfMonth;
  final SeasonSummaryCards seasonSummary;
  final ChartData charts;
  final List<HallOfFameEntry> hallOfFame;
  final List<DashboardMatchItem> recentMatches;
  final List<ActivityItem> recentActivity;

  StatsDashboardData({
    this.athleteOfMonth,
    required this.seasonSummary,
    required this.charts,
    required this.hallOfFame,
    required this.recentMatches,
    required this.recentActivity,
  });
}

class AthleteOfMonthData {
  final Player player;
  final int mvpCount;
  final int ataques;
  final int bloqueos;
  final int servicios;
  final int defensas;
  final int recepciones;
  final double attendancePct;
  final double eficiencia;

  AthleteOfMonthData({
    required this.player,
    this.mvpCount = 0,
    this.ataques = 0,
    this.bloqueos = 0,
    this.servicios = 0,
    this.defensas = 0,
    this.recepciones = 0,
    this.attendancePct = 0,
    this.eficiencia = 0,
  });
}

class SeasonSummaryCards {
  final int wins;
  final int losses;
  final double winrate;
  final int totalMatches;
  final int averageDurationSeconds;
  final int mvpAwards;
  final int totalEntrenamientos;
  final int medicalLeaves;

  SeasonSummaryCards({
    this.wins = 0,
    this.losses = 0,
    this.winrate = 0,
    this.totalMatches = 0,
    this.averageDurationSeconds = 0,
    this.mvpAwards = 0,
    this.totalEntrenamientos = 0,
    this.medicalLeaves = 0,
  });

  String get averageDurationFormatted {
    final h = averageDurationSeconds ~/ 3600;
    final m = (averageDurationSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}min';
  }
}

class ChartData {
  final int wins;
  final int losses;
  final List<bool> resultIsWins;
  final List<String> resultLabels;
  final List<String> typeLabels;
  final List<double> typeValues;
  final List<RotationBarItem> rotationData;

  ChartData({
    this.wins = 0,
    this.losses = 0,
    this.resultIsWins = const [],
    this.resultLabels = const [],
    this.typeLabels = const [],
    this.typeValues = const [],
    this.rotationData = const [],
  });
}

class RotationBarItem {
  final String label;
  final double effectiveness;

  RotationBarItem({required this.label, required this.effectiveness});
}

class HallOfFameEntry {
  final Player player;
  final double score;
  final int rank;
  final int mvpCount;
  final double eficiencia;

  HallOfFameEntry({
    required this.player,
    this.score = 0,
    this.rank = 0,
    this.mvpCount = 0,
    this.eficiencia = 0,
  });
}

class DashboardMatchItem {
  final int matchId;
  final String rival;
  final String marcador;
  final bool isWin;
  final DateTime fecha;
  final String tipoPartido;
  final String? mvpName;
  final int durationSeconds;
  final String? competitionName;
  final String? lugar;

  DashboardMatchItem({
    required this.matchId,
    required this.rival,
    required this.marcador,
    required this.isWin,
    required this.fecha,
    required this.tipoPartido,
    this.mvpName,
    this.durationSeconds = 0,
    this.competitionName,
    this.lugar,
  });

  String get durationFormatted {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}min';
  }
}

class ActivityItem {
  final String icon;
  final String description;
  final DateTime timestamp;
  final ActivityType type;

  ActivityItem({
    required this.icon,
    required this.description,
    required this.timestamp,
    required this.type,
  });
}

enum ActivityType { mvp, match, training, medical, photo }
