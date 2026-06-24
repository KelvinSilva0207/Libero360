class DashboardData {
  final TeamInfo teamInfo;
  final NextEvent? nextTraining;
  final NextEvent? nextMatch;
  final AthleteOfMonth? athleteOfMonth;
  final QuickSummary quickSummary;
  final TeamStatus teamStatus;
  final LastMatch? lastMatch;
  final List<ActivityItem> recentActivity;

  const DashboardData({
    required this.teamInfo,
    this.nextTraining,
    this.nextMatch,
    this.athleteOfMonth,
    required this.quickSummary,
    required this.teamStatus,
    this.lastMatch,
    required this.recentActivity,
  });
}

class TeamInfo {
  final String name;
  final String category;
  final String ageGroup;
  final String? photoUrl;

  const TeamInfo({
    required this.name,
    required this.category,
    required this.ageGroup,
    this.photoUrl,
  });
}

class NextEvent {
  final String title;
  final DateTime dateTime;
  final String? subtitle;
  final String? location;

  const NextEvent({
    required this.title,
    required this.dateTime,
    this.subtitle,
    this.location,
  });
}

class AthleteOfMonth {
  final String playerId;
  final String name;
  final String category;
  final String position;
  final String? photoUrl;
  final int mvpCount;
  final double eficiencia;

  const AthleteOfMonth({
    required this.playerId,
    required this.name,
    required this.category,
    required this.position,
    this.photoUrl,
    required this.mvpCount,
    required this.eficiencia,
  });
}

class QuickSummary {
  final int athleteCount;
  final int matchCount;
  final double winRate;
  final int trainingCount;

  const QuickSummary({
    required this.athleteCount,
    required this.matchCount,
    required this.winRate,
    required this.trainingCount,
  });
}

class TeamStatus {
  final int medicalRestCount;
  final int absenceCount;
  final int winStreak;
  final String? currentMvp;

  const TeamStatus({
    required this.medicalRestCount,
    required this.absenceCount,
    required this.winStreak,
    this.currentMvp,
  });
}

class LastMatch {
  final String rivalName;
  final int setsFor;
  final int setsAgainst;
  final String competition;
  final DateTime date;
  final String? photoUrl;
  final bool isWin;

  const LastMatch({
    required this.rivalName,
    required this.setsFor,
    required this.setsAgainst,
    required this.competition,
    required this.date,
    this.photoUrl,
    required this.isWin,
  });
}

enum ActivityType { mvp, match, training, medical, photo, absence, streak }

class ActivityItem {
  final String icon;
  final String description;
  final DateTime timestamp;
  final String? subtitle;
  final ActivityType type;

  const ActivityItem({
    required this.icon,
    required this.description,
    required this.timestamp,
    this.subtitle,
    required this.type,
  });
}
