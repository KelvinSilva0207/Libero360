import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/dashboard_model.dart';
import '../../data/dashboard_repository.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/models.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();
  final DatabaseService _db = DatabaseService.instance;

  DashboardData? _data;
  bool _loading = true;
  String? _error;
  StreamSubscription<List<Player>>? _playerSub;
  StreamSubscription<List<Match>>? _matchSub;
  Timer? _debounce;

  DashboardData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({String? profileId}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.initialize();
      _data = await _repository.load(profileId: profileId);
      _loading = false;
      _subscribeToChanges(profileId);
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }

  void _subscribeToChanges(String? profileId) {
    _playerSub?.cancel();
    _matchSub?.cancel();
    _playerSub = _db.watchAllPlayers().listen((_) => _scheduleRefresh(profileId));
    _matchSub = _db.watchMatchesByState(EstadoPartido.finalizado).listen((_) => _scheduleRefresh(profileId));
  }

  void _scheduleRefresh(String? profileId) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _silentRefresh(profileId));
  }

  Future<void> _silentRefresh(String? profileId) async {
    try {
      _data = await _repository.load(profileId: profileId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh({String? profileId}) async {
    _error = null;
    try {
      _data = await _repository.load(profileId: profileId);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  void setProfile(String? profileId) {
    _playerSub?.cancel();
    _matchSub?.cancel();
    load(profileId: profileId);
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _matchSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
