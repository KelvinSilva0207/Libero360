import 'dart:async';
import 'package:flutter/foundation.dart';
import '../features/estadisticas/data/local_db/database_service.dart';
import '../features/estadisticas/data/models/models.dart';

class DashboardViewModel extends ChangeNotifier {
  int _athleteCount = 0;
  int _matchCount = 0;
  int _setCount = 0;
  bool _initialized = false;
  String? _error;
  String? _profileId;

  StreamSubscription<List<Player>>? _playerSub;
  StreamSubscription<List<Match>>? _matchSub;

  int get athleteCount => _athleteCount;
  int get matchCount => _matchCount;
  int get setCount => _setCount;
  String? get error => _error;

  Future<void> init({String? profileId}) async {
    if (_initialized) return;
    _initialized = true;
    _profileId = profileId;
    _playerSub?.cancel();
    _matchSub?.cancel();
    try {
      final db = DatabaseService.instance;
      await db.initialize();
      _playerSub = db.watchAllPlayers().listen((players) {
        if (_profileId != null) {
          players = players.where((p) => p.profileId == _profileId).toList();
        }
        _athleteCount = players.length;
        notifyListeners();
      });
      _matchSub = db.watchMatchesByState(EstadoPartido.finalizado).listen((matches) {
        if (_profileId != null) {
          matches = matches.where((m) => m.profileId == _profileId).toList();
        }
        _matchCount = matches.length;
        _setCount = matches.fold(0, (sum, m) => sum + m.setActual - 1);
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setProfile(String? profileId) {
    if (_profileId == profileId) return;
    _profileId = profileId;
    _initialized = false;
    _playerSub?.cancel();
    _matchSub?.cancel();
    init(profileId: profileId);
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _matchSub?.cancel();
    super.dispose();
  }
}
