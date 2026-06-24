import 'package:libero360/features/estadisticas/data/models/models.dart';

class DailyAttendanceSummary {
  final DateTime date;
  final int totalPlayers;
  final int presentCount;
  final int absentCount;
  final int medicalRestCount;
  final List<AttendanceRecord> records;

  const DailyAttendanceSummary({
    required this.date,
    required this.totalPlayers,
    required this.presentCount,
    required this.absentCount,
    required this.medicalRestCount,
    required this.records,
  });
}
