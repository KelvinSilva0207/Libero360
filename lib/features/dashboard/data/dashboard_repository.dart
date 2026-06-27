import '../../../core/services/category_service.dart';
import '../../asistencia/data/medical_leave_repository.dart';
import '../../estadisticas/data/local_db/database_service.dart';
import '../../estadisticas/data/models/models.dart';
import '../../statistics/data/athlete_ranking_service.dart';
import '../../statistics/data/statistics_models.dart';
import 'dashboard_model.dart';
import '../../../core/utils/name_formatter.dart';

class DashboardRepository {
  final DatabaseService _db = DatabaseService.instance;
  final AthleteRankingService _rankingService = AthleteRankingService();
  final MedicalLeaveRepository _medicalRepo = MedicalLeaveRepository.instance;
  final CategoryService _catService = CategoryService.instance;

  Future<DashboardData> load({String? profileId, String? clubName, int clubMemberCount = 0, Set<String>? categoryFilter}) async {
    await _db.initialize();
    await _catService.load();

    var players = profileId != null
        ? await _db.getPlayersByProfile(profileId)
        : await _db.getAllPlayers();

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      players = players.where((p) => categoryFilter.contains(p.categoria)).toList();
    }
    final matches = await _db.getAllMatches();
    final attendance = await _db.getAllAttendanceRecords();
    final rankings = await _rankingService.loadRankings();

    final activeLeaves = await _medicalRepo.getActive();
    final medicalLeaveCount = activeLeaves.length;
    final athletesOnLeave = activeLeaves.map((l) => l.playerId).toSet();

    final teamInfo = _buildTeamInfo(clubName: clubName, clubMemberCount: clubMemberCount);
    final nextTraining = _findNextTraining(attendance);
    final nextMatch = _findNextMatch(matches);
    final athleteOfMonth = _buildAthleteOfMonth(players, rankings);
    final quickSummary = _buildQuickSummary(players, matches, attendance);
    final teamStatus = _buildTeamStatus(players, matches, rankings, attendance, medicalLeaveCount);
    final lastMatch = _buildLastMatch(matches);
    final recentActivity = _buildRecentActivity(matches, players, attendance, athletesOnLeave);

    return DashboardData(
      teamInfo: teamInfo,
      nextTraining: nextTraining,
      nextMatch: nextMatch,
      athleteOfMonth: athleteOfMonth,
      quickSummary: quickSummary,
      teamStatus: teamStatus,
      lastMatch: lastMatch,
      recentActivity: recentActivity,
    );
  }

  TeamInfo _buildTeamInfo({String? clubName, int clubMemberCount = 0}) {
    return TeamInfo(
      name: clubName ?? 'Club Águilas',
      category: 'Masculino',
      ageGroup: 'U17',
      memberCount: clubMemberCount,
    );
  }

  NextEvent? _findNextTraining(List<AttendanceRecord> attendance) {
    if (attendance.isEmpty) return null;
    final dayCounts = <int, int>{};
    for (final a in attendance) {
      final wd = a.fecha.weekday;
      dayCounts[wd] = (dayCounts[wd] ?? 0) + 1;
    }
    if (dayCounts.isEmpty) return null;
    final mostCommonDay = dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final now = DateTime.now();
    var daysUntil = mostCommonDay - now.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    final nextDate = DateTime(now.year, now.month, now.day + daysUntil, 19, 0);
    return NextEvent(
      title: 'Entrenamiento',
      dateTime: nextDate,
    );
  }

  NextEvent? _findNextMatch(List<Match> matches) {
    final upcoming = matches
        .where((m) => m.estado != EstadoPartido.finalizado && m.fecha.isAfter(DateTime.now()))
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.fecha.compareTo(b.fecha));
    final m = upcoming.first;
    return NextEvent(
      title: 'Partido vs ${m.equipoVisitante}',
      dateTime: m.fecha,
      subtitle: m.equipoLocal,
      location: m.lugar,
    );
  }

  AthleteOfMonth? _buildAthleteOfMonth(List<Player> players, List<AthleteRankingScore> rankings) {
    if (rankings.isEmpty) return null;
    final top = rankings.first;
    final p = top.player;
    return AthleteOfMonth(
      playerId: p.id.toString(),
      name: NameFormatter.playerDisplayName(p),
      category: p.posicionLabel,
      position: p.posicionLabel,
      photoUrl: p.fotoUrl,
      mvpCount: rankings.where((r) => r.mvpCount > 0).length,
      eficiencia: top.score,
    );
  }

  QuickSummary _buildQuickSummary(List<Player> players, List<Match> matches, List<AttendanceRecord> attendance) {
    final finalized = matches.where((m) => m.estado == EstadoPartido.finalizado).toList();
    final wins = finalized.where((m) => m.setsLocal > m.setsVisitante).length;
    final winrate = finalized.isEmpty ? 0.0 : (wins / finalized.length) * 100;
    final trainingDates = attendance.map((a) => _dateKey(a.fecha)).toSet().length;
    return QuickSummary(
      athleteCount: players.length,
      matchCount: finalized.length,
      winRate: winrate,
      trainingCount: trainingDates,
    );
  }

  TeamStatus _buildTeamStatus(List<Player> players, List<Match> matches, List<AthleteRankingScore> rankings, List<AttendanceRecord> attendance, int medicalLeaveCount) {
    final medicalRest = medicalLeaveCount > 0 ? medicalLeaveCount : players.where((p) => p.atletaStatus == AthleteStatus.injured || p.estadoSalud == EstadoSalud.lesionado).length;
    final now = DateTime.now();
    final last30 = now.subtract(const Duration(days: 30));
    final recentAbsences = attendance.where((a) => a.fecha.isAfter(last30) && !a.asistio).length;

    final finalized = matches
        .where((m) => m.estado == EstadoPartido.finalizado)
        .toList();
    finalized.sort((a, b) => b.fecha.compareTo(a.fecha));
    int streak = 0;
    for (final m in finalized) {
      final isWin = m.setsLocal > m.setsVisitante;
      if (streak == 0 && isWin) {
        streak = 1;
      } else if (streak > 0 && isWin) {
        streak++;
      } else {
        break;
      }
    }

    String? currentMvp;
    if (rankings.isNotEmpty) {
      currentMvp = NameFormatter.playerDisplayName(rankings.first.player);
    }

    return TeamStatus(
      medicalRestCount: medicalRest,
      absenceCount: (recentAbsences ~/ 10).clamp(0, 99),
      winStreak: streak,
      currentMvp: currentMvp,
    );
  }

  LastMatch? _buildLastMatch(List<Match> matches) {
    final finalized = matches
        .where((m) => m.estado == EstadoPartido.finalizado)
        .toList();
    if (finalized.isEmpty) return null;
    finalized.sort((a, b) => b.fecha.compareTo(a.fecha));
    final last = finalized.first;
    return LastMatch(
      rivalName: last.equipoVisitante,
      setsFor: last.setsLocal,
      setsAgainst: last.setsVisitante,
      competition: last.competitionName ?? 'Partido',
      date: last.fecha,
      isWin: last.setsLocal > last.setsVisitante,
    );
  }

  List<ActivityItem> _buildRecentActivity(List<Match> matches, List<Player> players, List<AttendanceRecord> attendance, Set<int> athletesOnLeave) {
    final items = <ActivityItem>[];
    final finalized = matches.where((m) => m.estado == EstadoPartido.finalizado).toList();
    finalized.sort((a, b) => b.fecha.compareTo(a.fecha));

    final topMatch = finalized.isNotEmpty ? finalized.first : null;
    if (topMatch != null) {
      final isWin = topMatch.setsLocal > topMatch.setsVisitante;
      items.add(ActivityItem(
        icon: isWin ? '🏐' : '⚔',
        description: isWin
            ? 'Victoria vs ${topMatch.equipoVisitante}'
            : 'Derrota vs ${topMatch.equipoVisitante}',
        timestamp: topMatch.fecha,
        subtitle: '${topMatch.setsLocal} - ${topMatch.setsVisitante}',
        type: ActivityType.match,
      ));
    }

    if (attendance.isNotEmpty) {
      final lastAtt = attendance.reduce((a, b) => a.fecha.isAfter(b.fecha) ? a : b);
      items.add(ActivityItem(
        icon: '📅',
        description: 'Asistencia registrada',
        timestamp: lastAtt.fecha,
        subtitle: lastAtt.asistio
            ? '${_countPresent(attendance, lastAtt.fecha)} presentes'
            : '${_countAbsent(attendance, lastAtt.fecha)} ausentes',
        type: ActivityType.training,
      ));
    }

    final injuredPlayers = players.where((p) => athletesOnLeave.contains(p.id) || p.estadoSalud == EstadoSalud.lesionado).toList();
    if (injuredPlayers.isNotEmpty) {
      items.add(ActivityItem(
        icon: '⚠',
        description: '${NameFormatter.playerDisplayName(injuredPlayers.first)} en reposo médico',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: ActivityType.medical,
      ));
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items.take(5).toList();
  }

  int _countPresent(List<AttendanceRecord> attendance, DateTime date) {
    return attendance.where((a) => _dateKey(a.fecha) == _dateKey(date) && a.asistio).length;
  }

  int _countAbsent(List<AttendanceRecord> attendance, DateTime date) {
    return attendance.where((a) => _dateKey(a.fecha) == _dateKey(date) && !a.asistio).length;
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
