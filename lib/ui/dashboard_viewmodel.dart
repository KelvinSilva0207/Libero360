import 'dart:async';
import 'package:flutter/foundation.dart';
import '../features/estadisticas/data/local_db/database_service.dart';
import '../features/estadisticas/data/models/models.dart';

class DashboardViewModel extends ChangeNotifier {
  int _athleteCount = 0;
  int _matchCount = 0;
  int _setCount = 0;

  StreamSubscription<List<Player>>? _playerSub;
  StreamSubscription<List<Match>>? _matchSub;

  int get athleteCount => _athleteCount;
  int get matchCount => _matchCount;
  int get setCount => _setCount;

  void init() {
    _playerSub?.cancel();
    _matchSub?.cancel();
    final db = DatabaseService.instance;
    _playerSub = db.watchAllPlayers().listen((players) {
      _athleteCount = players.length;
      notifyListeners();
    });
    _matchSub = db.watchMatchesByState(EstadoPartido.finalizado).listen((matches) {
      _matchCount = matches.length;
      _setCount = matches.fold(0, (sum, m) => sum + m.setActual - 1);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _matchSub?.cancel();
    super.dispose();
  }
}
