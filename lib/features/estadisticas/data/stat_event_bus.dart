import 'package:flutter/foundation.dart';

class StatEventBus extends ChangeNotifier {
  static final StatEventBus _instance = StatEventBus._();
  static StatEventBus get instance => _instance;
  StatEventBus._();

  int? _lastPlayerId;
  int? _lastMatchId;

  int? get lastPlayerId => _lastPlayerId;
  int? get lastMatchId => _lastMatchId;

  void notifyEvent(int playerId, int matchId) {
    _lastPlayerId = playerId;
    _lastMatchId = matchId;
    notifyListeners();
  }
}
