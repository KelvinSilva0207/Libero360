import 'package:flutter/foundation.dart';
import '../../../../features/estadisticas/data/models/models.dart';
import '../../data/player_stats_model.dart';
import '../../data/player_stats_repository.dart';

class PlayerStatsViewModel extends ChangeNotifier {
  final PlayerStatsRepository _repository;

  PlayerDetailStats? _stats;
  bool _loading = true;
  String? _error;

  PlayerStatsViewModel({PlayerStatsRepository? repository})
      : _repository = repository ?? PlayerStatsRepository();

  PlayerDetailStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(Player player) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _repository.loadPlayerStats(player);
      _loading = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }

    notifyListeners();
  }
}
