import 'package:flutter/foundation.dart';
import '../../data/stats_summary_model.dart';
import '../../data/stats_repository.dart';

class StatsSummaryViewModel extends ChangeNotifier {
  final StatsRepository _repository;

  StatsSummaryModel? _summary;
  bool _loading = true;
  String? _error;

  StatsSummaryViewModel({StatsRepository? repository})
      : _repository = repository ?? StatsRepository();

  StatsSummaryModel? get summary => _summary;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await _repository.loadSummary();
      _loading = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }

    notifyListeners();
  }
}
