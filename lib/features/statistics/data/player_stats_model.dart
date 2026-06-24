import '../../../features/estadisticas/data/models/models.dart';

class PlayerDetailStats {
  final Player player;
  final int totalMvp;
  final int attackCount;
  final int blockCount;
  final int serveCount;
  final int defenseCount;
  final int receptionCount;
  final int errorCount;
  final int totalWins;
  final int totalLosses;
  final int ligas;
  final int torneos;
  final int amistosos;
  final int practicas;
  final List<SetStat> perSetStats;
  final double maxRadarValue;

  PlayerDetailStats({
    required this.player,
    this.totalMvp = 0,
    this.attackCount = 0,
    this.blockCount = 0,
    this.serveCount = 0,
    this.defenseCount = 0,
    this.receptionCount = 0,
    this.errorCount = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.ligas = 0,
    this.torneos = 0,
    this.amistosos = 0,
    this.practicas = 0,
    this.perSetStats = const [],
    this.maxRadarValue = 100,
  });

  int get totalPositives =>
      attackCount + blockCount + serveCount + defenseCount + receptionCount;

  double get efficiency {
    final total = totalPositives + errorCount;
    if (total == 0) return 0;
    return (totalPositives / total) * 100;
  }

  double get radarAttack => maxRadarValue > 0 ? (attackCount / maxRadarValue) * 100 : 0;
  double get radarBlock => maxRadarValue > 0 ? (blockCount / maxRadarValue) * 100 : 0;
  double get radarServe => maxRadarValue > 0 ? (serveCount / maxRadarValue) * 100 : 0;
  double get radarDefense => maxRadarValue > 0 ? (defenseCount / maxRadarValue) * 100 : 0;
  double get radarReception => maxRadarValue > 0 ? (receptionCount / maxRadarValue) * 100 : 0;
}

class SetStat {
  final int setNumber;
  final int points;

  SetStat({required this.setNumber, required this.points});
}
