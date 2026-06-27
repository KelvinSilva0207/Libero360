import 'package:flutter/foundation.dart';
import '../../data/attendance_analytics_service.dart';

class AttendanceAnalyticsViewModel extends ChangeNotifier {
  final AttendanceAnalyticsService _service = AttendanceAnalyticsService();

  AttendanceAnalytics? _analytics;
  bool _loading = false;
  int? _selectedYear;
  int? _selectedMonth;

  AttendanceAnalytics? get analytics => _analytics;
  bool get loading => _loading;
  int? get selectedYear => _selectedYear;
  int? get selectedMonth => _selectedMonth;

  Future<void> load({int? year, int? month}) async {
    _selectedYear = year;
    _selectedMonth = month;
    _loading = true;
    notifyListeners();
    try {
      _analytics = await _service.compute(year: year, month: month);
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }
}
