import 'package:flutter/foundation.dart';
import '../../../../features/estadisticas/data/models/models.dart';
import '../../../../features/estadisticas/data/stat_event_bus.dart';
import '../../data/player_stats_model.dart';
import '../../data/player_stats_repository.dart';

class PlayerStatsViewModel extends ChangeNotifier {
  final PlayerStatsRepository _repository;

  PlayerDetailStats? _stats;
  bool _loading = true;
  String? _error;
  Player? _currentPlayer;
  VoidCallback? _eventBusHandler;

  PlayerStatsViewModel({PlayerStatsRepository? repository})
      : _repository = repository ?? PlayerStatsRepository();

  PlayerDetailStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(Player player) async {
    _currentPlayer = player;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _repository.loadPlayerStats(player);
      _loading = false;
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
      final affectedPlayerId = StatEventBus.instance.lastPlayerId;
      if (affectedPlayerId != null && _currentPlayer != null && affectedPlayerId == _currentPlayer!.id) {
        load(_currentPlayer!);
      }
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
