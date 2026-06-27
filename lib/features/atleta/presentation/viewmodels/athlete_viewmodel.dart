import 'package:flutter/foundation.dart';
import '../../../../core/services/category_service.dart';
import '../../../../core/services/log_service.dart';
import '../../../notifications/data/notification_service.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/athlete_repository.dart';
import '../../../../core/utils/name_formatter.dart';

class AthleteViewModel extends ChangeNotifier {
  final AthleteRepository _repository = AthleteRepository();
  final LogService _log = LogService.instance;
  final NotificationService _notif = NotificationService.instance;
  final CategoryService _catService = CategoryService.instance;

  List<Player> _athletes = [];
  List<Player> _trashed = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  Posicion? _filterPosicion;
  Set<String> _selectedCategories = {};

  List<Player> get athletes => _athletes;
  List<Player> get trashed => _trashed;
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  Posicion? get filterPosicion => _filterPosicion;
  Set<String> get selectedCategories => _selectedCategories;
  List<String> get allCategoryNames => _catService.getAllNames();

  bool get hasActiveFilter =>
      _query.isNotEmpty ||
      _filterPosicion != null ||
      _selectedCategories.isNotEmpty;

  List<Player> get filtered {
    var result = _athletes;
    if (_query.isNotEmpty) {
      final lower = _query.toLowerCase();
      result = result.where((p) =>
        NameFormatter.playerDisplayName(p).toLowerCase().contains(lower) ||
        (p.numero?.toString() ?? '').contains(lower) ||
        p.cedula.replaceAll('.', '').contains(lower)
      ).toList();
    }
    if (_filterPosicion != null) {
      result = result.where((p) => p.posicion == _filterPosicion).toList();
    }
    if (_selectedCategories.isNotEmpty) {
      result = result.where((p) => _selectedCategories.contains(p.categoria)).toList();
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

  void toggleCategory(String cat) {
    if (_selectedCategories.contains(cat)) {
      _selectedCategories.remove(cat);
    } else {
      _selectedCategories.add(cat);
    }
    notifyListeners();
  }

  void clearCategoryFilter() {
    _selectedCategories.clear();
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
      final isNew = player.id == 0;
      player.profileId = player.profileId ?? profileId;
      _log.system('Guardando atleta: ${NameFormatter.playerDisplayName(player)} (id=${player.id}, nuevo=$isNew)',
          source: 'AthleteViewModel');
      await _repository.save(player);
      if (isNew) {
        _notif.notifyAthleteCreated(NameFormatter.playerDisplayName(player), player.id);
        _log.event('Atleta registrado: ${NameFormatter.playerDisplayName(player)}', source: 'AthleteViewModel');
      } else {
        _log.auto('Atleta editado: ${NameFormatter.playerDisplayName(player)}', source: 'AthleteViewModel');
      }
      await load(profileId: profileId);
      return true;
    } catch (e) {
      _error = e.toString();
      _log.error('Error al guardar atleta: $e', source: 'AthleteViewModel');
      notifyListeners();
      return false;
    }
  }

  Future<bool> softDelete(int id, {String? deletedBy, String? reason, String? profileId}) async {
    try {
      await _repository.softDelete(id, deletedBy: deletedBy, reason: reason);
      _log.system('ATHLETE moved to trash — id=$id reason=$reason', source: 'AthleteViewModel');
      await load(profileId: profileId);
      return true;
    } catch (e) {
      _error = e.toString();
      _log.error('ATHLETE trash failed: $e', source: 'AthleteViewModel');
      notifyListeners();
      return false;
    }
  }

  Future<bool> restore(int id, {String? profileId}) async {
    try {
      await _repository.restore(id);
      _log.auto('ATHLETE restored — id=$id', source: 'AthleteViewModel');
      await loadTrashed();
      await load(profileId: profileId);
      return true;
    } catch (e) {
      _error = e.toString();
      _log.error('ATHLETE restore failed: $e', source: 'AthleteViewModel');
      notifyListeners();
      return false;
    }
  }

  Future<bool> permanentDelete(int id, {String? profileId}) async {
    try {
      await _repository.permanentDelete(id);
      _log.error('ATHLETE permanently deleted — id=$id', source: 'AthleteViewModel');
      await loadTrashed();
      return true;
    } catch (e) {
      _error = e.toString();
      _log.error('ATHLETE permanent delete failed: $e', source: 'AthleteViewModel');
      notifyListeners();
      return false;
    }
  }
}
