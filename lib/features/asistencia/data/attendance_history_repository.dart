import 'package:libero360/features/estadisticas/data/local_db/database_service.dart';
import 'package:libero360/features/estadisticas/data/models/models.dart';
import 'attendance_history_model.dart';

class AttendanceHistoryRepository {
  final DatabaseService _db = DatabaseService.instance;

  Future<List<DailyAttendanceSummary>> load({
    int? year,
    int? month,
    String? category,
    int? selectedPlayerId,
  }) async {
    await _db.initialize();
    final records = await _db.getAttendanceRecords();
    final players = <int, Player>{};
    final allPlayers = await _db.getAllPlayers();
    for (final p in allPlayers) {
      players[p.id] = p;
    }

    final filtered = records.where((r) {
      if (year != null && r.fecha.year != year) return false;
      if (month != null && r.fecha.month != month) return false;
      if (category != null && category.isNotEmpty) {
        final p = players[r.playerId];
        if (p == null) return false;
        if (p.posicionLabel != category && p.categoria != category) return false;
      }
      if (selectedPlayerId != null && r.playerId != selectedPlayerId) return false;
      return true;
    }).toList();

    final grouped = <String, List<AttendanceRecord>>{};
    for (final r in filtered) {
      final key = _dateKey(r.fecha);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(r);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys.map((key) {
      final dayRecords = grouped[key]!;
      final parts = key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final present = dayRecords.where((r) => r.asistio).length;
      final medicalRest = dayRecords.where((r) {
        final p = players[r.playerId];
        return p != null && (p.estadoSalud == EstadoSalud.lesionado || p.atletaStatus == AthleteStatus.injured);
      }).length;
      return DailyAttendanceSummary(
        date: date,
        totalPlayers: dayRecords.length,
        presentCount: present,
        absentCount: dayRecords.length - present - medicalRest,
        medicalRestCount: medicalRest,
        records: dayRecords,
      );
    }).toList();
  }

  Future<Map<int, Player>> getPlayersMap() async {
    final allPlayers = await _db.getAllPlayers();
    return {for (final p in allPlayers) p.id: p};
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
