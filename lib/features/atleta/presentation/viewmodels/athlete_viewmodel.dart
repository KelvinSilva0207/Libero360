import 'package:flutter/foundation.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/athlete_repository.dart';

class AthleteViewModel extends ChangeNotifier {
  final AthleteRepository _repository = AthleteRepository();

  List<Player> _athletes = [];
  List<Player> _trashed = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  Posicion? _filterPosicion;

  List<Player> get athletes => _athletes;
  List<Player> get trashed => _trashed;
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  Posicion? get filterPosicion => _filterPosicion;

  List<Player> get filtered {
    var result = _athletes;
    if (_query.isNotEmpty) {
      final lower = _query.toLowerCase();
      result = result.where((p) =>
        p.displayName.toLowerCase().contains(lower) ||
        (p.numero?.toString() ?? '').contains(lower) ||
        p.cedula.replaceAll('.', '').contains(lower)
      ).toList();
    }
    if (_filterPosicion != null) {
      result = result.where((p) => p.posicion == _filterPosicion).toList();
    }
    return result;
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setFilterPosicion(Posicion? p) {
    _filterPosicion = p;
    notifyListeners();
  }

  Future<void> load({String? profileId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _athletes = await _repository.getActive(profileId: profileId);
      _loading = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }

  Future<void> loadTrashed() async {
    try {
      _trashed = await _repository.getDeleted();
    } catch (_) {}
    notifyListeners();
  }

  Future<bool> save(Player player, {String? profileId}) async {
    try {
      player.profileId = player.profileId ?? profileId;
      await _repository.save(player);
      await load(profileId: profileId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> softDelete(int id, {String? deletedBy, String? reason, String? profileId}) async {
    try {
      await _repository.softDelete(id, deletedBy: deletedBy, reason: reason);
      await load(profileId: profileId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> restore(int id, {String? profileId}) async {
    try {
      await _repository.restore(id);
      await loadTrashed();
      await load(profileId: profileId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> permanentDelete(int id, {String? profileId}) async {
    try {
      await _repository.permanentDelete(id);
      await loadTrashed();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
