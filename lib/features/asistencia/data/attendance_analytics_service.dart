import 'package:libero360/features/estadisticas/data/local_db/database_service.dart';
import 'package:libero360/features/estadisticas/data/models/models.dart';
import 'medical_leave_repository.dart';
import '../../../core/utils/name_formatter.dart';

class AttendanceAnalyticsService {
  final DatabaseService _db = DatabaseService.instance;
  final MedicalLeaveRepository _medicalRepo = MedicalLeaveRepository.instance;

  Future<AttendanceAnalytics> compute({int? year, int? month}) async {
    await _db.initialize();
    final records = await _db.getAttendanceRecords();
    final allPlayers = await _db.getAllPlayers(includeDeleted: false);
    final activeLeaves = await _medicalRepo.getActive();
    final playerOnLeave = activeLeaves.map((l) => l.playerId).toSet();
    final players = <int, Player>{for (final p in allPlayers) p.id: p};

    final filtered = records.where((r) {
      if (year != null && r.fecha.year != year) return false;
      if (month != null && r.fecha.month != month) return false;
      return true;
    }).toList();

    final playerStats = <int, PlayerAttendanceStats>{};
    for (final r in filtered) {
      playerStats.putIfAbsent(r.playerId, () => PlayerAttendanceStats(playerId: r.playerId, playerName: players[r.playerId] != null ? NameFormatter.playerDisplayName(players[r.playerId]!) : '', playerPosition: players[r.playerId]?.posicionLabel ?? ''));
      if (r.asistio) {
        playerStats[r.playerId]!.present++;
      } else if (playerOnLeave.contains(r.playerId) || (players[r.playerId]?.estadoSalud == EstadoSalud.lesionado) || (players[r.playerId]?.atletaStatus == AthleteStatus.injured)) {
        playerStats[r.playerId]!.medicalRest++;
      } else {
        playerStats[r.playerId]!.absent++;
      }
    }

    final statsList = playerStats.values.toList();

    // Top attendance (most present)
    final topAttendance = statsList.where((s) => s.total > 0).toList()..sort((a, b) => b.present.compareTo(a.present));

    // Most absences
    final mostAbsences = statsList.where((s) => s.absent > 0).toList()..sort((a, b) => b.absent.compareTo(a.absent));

    // Most consistent (highest percentage, min 5 records)
    final mostConsistent = statsList.where((s) => s.total >= 5).toList()..sort((a, b) => b.percentage.compareTo(a.percentage));

    // Most improved (compare first half vs second half of period)
    final mostImproved = _computeMostImproved(filtered, playerStats, players);

    // Monthly evolution
    final monthlyEvolution = _computeMonthlyEvolution(records, playerOnLeave, players);

    // Pie chart data
    final totalPresent = statsList.fold(0, (s, p) => s + p.present);
    final totalAbsent = statsList.fold(0, (s, p) => s + p.absent);
    final totalRest = statsList.fold(0, (s, p) => s + p.medicalRest);

    return AttendanceAnalytics(
      topAttendance: topAttendance.take(10).toList(),
      mostAbsences: mostAbsences.take(5).toList(),
      mostConsistent: mostConsistent.take(5).toList(),
      mostImproved: mostImproved.take(5).toList(),
      monthlyEvolution: monthlyEvolution,
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      totalMedicalRest: totalRest,
      totalDays: filtered.map((r) => '${r.fecha.year}-${r.fecha.month}-${r.fecha.day}').toSet().length,
    );
  }

  List<PlayerAttendanceStats> _computeMostImproved(List<AttendanceRecord> records, Map<int, PlayerAttendanceStats> stats, Map<int, Player> players) {
    if (records.isEmpty) return [];
    final sorted = List<AttendanceRecord>.from(records)..sort((a, b) => a.fecha.compareTo(b.fecha));
    if (sorted.length < 4) return [];
    final mid = sorted.length ~/ 2;
    final firstHalf = sorted.take(mid).toList();
    final secondHalf = sorted.skip(mid).toList();

    final firstStats = <int, _SimpleCount>{};
    for (final r in firstHalf) {
      firstStats.putIfAbsent(r.playerId, () => _SimpleCount());
      if (r.asistio) firstStats[r.playerId]!.present++;
      else firstStats[r.playerId]!.total++;
    }
    final secondStats = <int, _SimpleCount>{};
    for (final r in secondHalf) {
      secondStats.putIfAbsent(r.playerId, () => _SimpleCount());
      if (r.asistio) secondStats[r.playerId]!.present++;
      else secondStats[r.playerId]!.total++;
    }

    final improvements = <PlayerAttendanceStats>[];
    for (final entry in firstStats.entries) {
      final second = secondStats[entry.key];
      if (second == null) continue;
      final firstPct = entry.value.total > 0 ? entry.value.present / entry.value.total : 0.0;
      final secondPct = second.total > 0 ? second.present / second.total : 0.0;
      final improvement = secondPct - firstPct;
      if (improvement > 0.05) {
        final s = stats[entry.key];
        improvements.add(PlayerAttendanceStats(
          playerId: entry.key,
          playerName: s?.playerName ?? (players[entry.key] != null ? NameFormatter.playerDisplayName(players[entry.key]!) : ''),
          playerPosition: s?.playerPosition ?? players[entry.key]?.posicionLabel ?? '',
          present: s?.present ?? 0,
          absent: s?.absent ?? 0,
          medicalRest: s?.medicalRest ?? 0,
          improvement: improvement,
        ));
      }
    }
    improvements.sort((a, b) => b.improvement.compareTo(a.improvement));
    return improvements;
  }

  List<MonthlyPoint> _computeMonthlyEvolution(List<AttendanceRecord> records, Set<int> playerOnLeave, Map<int, Player> players) {
    final byMonth = <String, List<AttendanceRecord>>{};
    for (final r in records) {
      final key = '${r.fecha.year}-${r.fecha.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []);
      byMonth[key]!.add(r);
    }
    final sortedKeys = byMonth.keys.toList()..sort();
    return sortedKeys.map((key) {
      final recs = byMonth[key]!;
      final parts = key.split('-');
      final total = recs.length;
      final present = recs.where((r) => r.asistio).length;
      final rest = recs.where((r) => playerOnLeave.contains(r.playerId) || (players[r.playerId]?.estadoSalud == EstadoSalud.lesionado)).length;
      return MonthlyPoint(
        label: '${['','E','F','M','A','M','J','J','A','S','O','N','D'][int.parse(parts[1])]}',
        presentCount: present,
        absentCount: total - present - rest,
        restCount: rest,
        percentage: total > 0 ? (present / total * 100) : 0,
      );
    }).toList();
  }
}

class AttendanceAnalytics {
  final List<PlayerAttendanceStats> topAttendance;
  final List<PlayerAttendanceStats> mostAbsences;
  final List<PlayerAttendanceStats> mostConsistent;
  final List<PlayerAttendanceStats> mostImproved;
  final List<MonthlyPoint> monthlyEvolution;
  final int totalPresent;
  final int totalAbsent;
  final int totalMedicalRest;
  final int totalDays;

  const AttendanceAnalytics({
    required this.topAttendance,
    required this.mostAbsences,
    required this.mostConsistent,
    required this.mostImproved,
    required this.monthlyEvolution,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalMedicalRest,
    required this.totalDays,
  });
}

class PlayerAttendanceStats {
  final int playerId;
  final String playerName;
  final String playerPosition;
  int present;
  int absent;
  int medicalRest;
  double improvement;

  PlayerAttendanceStats({
    required this.playerId,
    required this.playerName,
    required this.playerPosition,
    this.present = 0,
    this.absent = 0,
    this.medicalRest = 0,
    this.improvement = 0,
  });

  int get total => present + absent + medicalRest;
  double get percentage => total > 0 ? (present / total * 100) : 0;
}

class MonthlyPoint {
  final String label;
  final int presentCount;
  final int absentCount;
  final int restCount;
  final double percentage;

  const MonthlyPoint({
    required this.label,
    required this.presentCount,
    required this.absentCount,
    required this.restCount,
    required this.percentage,
  });
}

class _SimpleCount {
  int present = 0;
  int total = 0;
}
