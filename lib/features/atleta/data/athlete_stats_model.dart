class RadarSkill {
  final String name;
  final double value;
  final String label;

  const RadarSkill({
    required this.name,
    required this.value,
    this.label = '',
  });
}

class MatchPerformance {
  final int matchId;
  final String competition;
  final String rival;
  final bool isWin;
  final bool isDraw;
  final int setsFor;
  final int setsAgainst;
  final int positiveActions;
  final int regularActions;
  final int negativeActions;
  final double performanceScore;
  final bool isMvp;

  const MatchPerformance({
    required this.matchId,
    required this.competition,
    required this.rival,
    required this.isWin,
    required this.isDraw,
    required this.setsFor,
    required this.setsAgainst,
    required this.positiveActions,
    required this.regularActions,
    required this.negativeActions,
    required this.performanceScore,
    this.isMvp = false,
  });

  String get resultLabel {
    if (isWin) return 'Victoria';
    if (isDraw) return 'Empate';
    return 'Derrota';
  }
}

class ActionBarData {
  final int positives;
  final int regulars;
  final int negatives;

  const ActionBarData({
    required this.positives,
    required this.regulars,
    required this.negatives,
  });

  int get total => positives + regulars + negatives;
}

class WinPieData {
  final int wins;
  final int losses;
  final int draws;

  const WinPieData({
    required this.wins,
    required this.losses,
    required this.draws,
  });

  int get total => wins + losses + draws;
}

class LineChartPoint {
  final int matchIndex;
  final double score;

  const LineChartPoint({
    required this.matchIndex,
    required this.score,
  });
}

class TeamRankingItem {
  final int rank;
  final String playerName;
  final int playerId;
  final double score;
  final int? numero;

  const TeamRankingItem({
    required this.rank,
    required this.playerName,
    required this.playerId,
    required this.score,
    this.numero,
  });
}

class TeamRankings {
  final List<TeamRankingItem> mvp;
  final List<TeamRankingItem> bestAttackers;
  final List<TeamRankingItem> bestBlockers;
  final List<TeamRankingItem> bestDefenders;
  final List<TeamRankingItem> bestServers;
  final List<TeamRankingItem> mostConsistent;

  const TeamRankings({
    required this.mvp,
    required this.bestAttackers,
    required this.bestBlockers,
    required this.bestDefenders,
    required this.bestServers,
    required this.mostConsistent,
  });
}

class AthleteStatsData {
  final List<RadarSkill> radarSkills;
  final ActionBarData barData;
  final WinPieData pieData;
  final List<LineChartPoint> lineData;
  final List<MatchPerformance> matchHistory;
  final double mvpScore;
  final double efficiency;

  const AthleteStatsData({
    required this.radarSkills,
    required this.barData,
    required this.pieData,
    required this.lineData,
    required this.matchHistory,
    required this.mvpScore,
    required this.efficiency,
  });
}
