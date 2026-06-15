import '../../estadisticas/data/models/models.dart';

class SeasonSummary {
  final int totalMatches;
  final int wins;
  final int losses;
  final int amistosos;
  final int ligas;
  final int torneos;
  final int practicas;
  final double attendanceAvg;
  final List<String> neverMissed;
  final String bestStreak;
  final String? mvpName;
  final int mvpPoints;

  SeasonSummary({
    this.totalMatches = 0,
    this.wins = 0,
    this.losses = 0,
    this.amistosos = 0,
    this.ligas = 0,
    this.torneos = 0,
    this.practicas = 0,
    this.attendanceAvg = 0,
    this.neverMissed = const [],
    this.bestStreak = '',
    this.mvpName,
    this.mvpPoints = 0,
  });
}

class AthleteStats {
  final Player player;
  final int totalMatches;
  final int ligas;
  final int torneos;
  final int amistosos;
  final int practicas;
  final int puntosGanadores;
  final int puntosRegulares;
  final int errores;
  final int mvpCount;
  final double attendancePct;
  final int faltas;
  final int justificadas;

  AthleteStats({
    required this.player,
    this.totalMatches = 0,
    this.ligas = 0,
    this.torneos = 0,
    this.amistosos = 0,
    this.practicas = 0,
    this.puntosGanadores = 0,
    this.puntosRegulares = 0,
    this.errores = 0,
    this.mvpCount = 0,
    this.attendancePct = 0,
    this.faltas = 0,
    this.justificadas = 0,
  });

  int get totalPuntos => puntosGanadores + puntosRegulares;
  double get eficiencia => totalPuntos == 0 ? 0 : (puntosGanadores / totalPuntos) * 100;
}

class AttendanceStats {
  final int totalEntrenamientos;
  final double promedioGlobal;
  final List<PlayerAttendanceSummary> topAttendance;
  final List<PlayerAttendanceSummary> peorAttendance;

  AttendanceStats({
    this.totalEntrenamientos = 0,
    this.promedioGlobal = 0,
    this.topAttendance = const [],
    this.peorAttendance = const [],
  });
}

class PlayerAttendanceSummary {
  final String name;
  final double pct;
  final String? justificacion;
  final int diasAusente;

  PlayerAttendanceSummary({
    required this.name,
    required this.pct,
    this.justificacion,
    this.diasAusente = 0,
  });
}
