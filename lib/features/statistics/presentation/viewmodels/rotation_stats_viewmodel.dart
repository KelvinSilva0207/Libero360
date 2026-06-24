import 'package:flutter/foundation.dart';
import '../../data/rotation_stats_model.dart';
import '../../data/rotation_stats_repository.dart';

class RotationStatsViewModel extends ChangeNotifier {
  final RotationStatsRepository _repository;

  List<RotationStatsSummary> _summaries = [];
  RotationStatsDetail? _selectedDetail;
  bool _loading = true;
  bool _detailLoading = false;
  String? _error;

  RotationStatsViewModel({RotationStatsRepository? repository})
      : _repository = repository ?? RotationStatsRepository();

  List<RotationStatsSummary> get summaries => _summaries;
  RotationStatsDetail? get selectedDetail => _selectedDetail;
  bool get loading => _loading;
  bool get detailLoading => _detailLoading;
  String? get error => _error;

  RotationStatsSummary? get bestRotation {
    if (_summaries.isEmpty) return null;
    return _summaries.fold<RotationStatsSummary>(
      _summaries.first,
      (best, s) => s.winrate > best.winrate ? s : best,
    );
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _summaries = await _repository.loadRotationSummaries();
      _loading = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }

    notifyListeners();
  }

  Future<void> loadDetail(int rotationIndex) async {
    _detailLoading = true;
    notifyListeners();

    try {
      _selectedDetail = await _repository.loadRotationDetail(rotationIndex);
      _detailLoading = false;
    } catch (e) {
      _error = e.toString();
      _detailLoading = false;
    }

    notifyListeners();
  }
}
