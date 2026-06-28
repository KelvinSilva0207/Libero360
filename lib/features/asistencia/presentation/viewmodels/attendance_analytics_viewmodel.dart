import 'package:flutter/foundation.dart';
import '../../data/attendance_analytics_service.dart';
import '../../../estadisticas/data/stat_event_bus.dart';

class AttendanceAnalyticsViewModel extends ChangeNotifier {
  final AttendanceAnalyticsService _service = AttendanceAnalyticsService();

  AttendanceAnalytics? _analytics;
  bool _loading = false;
  int? _selectedYear;
  int? _selectedMonth;
  bool _loaded = false;
  VoidCallback? _eventBusHandler;

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
      _loaded = true;
      _subscribeToBus();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  void _subscribeToBus() {
    _unsubscribeFromBus();
    _eventBusHandler = () {
      if (_loaded) load(year: _selectedYear, month: _selectedMonth);
    };
    StatEventBus.instance.addListener(_eventBusHandler!);
  }

  void _unsubscribeFromBus() {
    if (_eventBusHandler != null) {
      StatEventBus.instance.removeListener(_eventBusHandler!);
      _eventBusHandler = null;
    }
  }

  @override
  void dispose() {
    _unsubscribeFromBus();
    super.dispose();
  }
}
