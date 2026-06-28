import 'package:flutter/foundation.dart';
import '../../data/stats_dashboard_model.dart';
import '../../data/stats_dashboard_service.dart';
import '../../../estadisticas/data/stat_event_bus.dart';

class StatsDashboardViewModel extends ChangeNotifier {
  final StatsDashboardService _service;

  StatsDashboardData? _data;
  bool _loading = true;
  String? _error;
  bool _athleteOfMonthAnimated = false;
  bool _loaded = false;
  VoidCallback? _eventBusHandler;

  StatsDashboardViewModel({StatsDashboardService? service})
      : _service = service ?? StatsDashboardService();

  StatsDashboardData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;
  bool get athleteOfMonthAnimated => _athleteOfMonthAnimated;

  Future<void> load() async {
    _loading = _data == null;
    _error = null;
    if (_loading) notifyListeners();

    try {
      _data = await _service.loadDashboard();
      _loading = false;
      _loaded = true;
      _athleteOfMonthAnimated = false;
      _subscribeToBus();
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }

    notifyListeners();
  }

  void _subscribeToBus() {
    _unsubscribeFromBus();
    _eventBusHandler = () {
      if (_loaded) load();
    };
    StatEventBus.instance.addListener(_eventBusHandler!);
  }

  void _unsubscribeFromBus() {
    if (_eventBusHandler != null) {
      StatEventBus.instance.removeListener(_eventBusHandler!);
      _eventBusHandler = null;
    }
  }

  void markAthleteOfMonthAnimated() {
    _athleteOfMonthAnimated = true;
  }

  @override
  void dispose() {
    _unsubscribeFromBus();
    super.dispose();
  }
}
