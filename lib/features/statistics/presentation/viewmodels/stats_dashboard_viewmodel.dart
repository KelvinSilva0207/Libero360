import 'package:flutter/foundation.dart';
import '../../data/stats_dashboard_model.dart';
import '../../data/stats_dashboard_service.dart';

class StatsDashboardViewModel extends ChangeNotifier {
  final StatsDashboardService _service;

  StatsDashboardData? _data;
  bool _loading = true;
  String? _error;
  bool _athleteOfMonthAnimated = false;

  StatsDashboardViewModel({StatsDashboardService? service})
      : _service = service ?? StatsDashboardService();

  StatsDashboardData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;
  bool get athleteOfMonthAnimated => _athleteOfMonthAnimated;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _service.loadDashboard();
      _loading = false;
      _athleteOfMonthAnimated = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }

    notifyListeners();
  }

  void markAthleteOfMonthAnimated() {
    _athleteOfMonthAnimated = true;
  }
}
