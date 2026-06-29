import 'package:flutter/foundation.dart';
import '../../../../core/models/category_config.dart';
import '../../../../core/services/category_service.dart';
import '../../../../core/services/log_service.dart';
import '../../../estadisticas/data/local_db/database_service.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryService _service = CategoryService.instance;
  final LogService _log = LogService.instance;

  List<CategoryConfig> _categories = [];
  String _query = '';
  bool _loading = true;
  String? _error;

  List<CategoryConfig> get categories => _categories;
  List<CategoryConfig> get filtered {
    if (_query.isEmpty) return _categories;
    final lower = _query.toLowerCase();
    return _categories.where((c) =>
      c.name.toLowerCase().contains(lower) ||
      '${c.minAge}-${c.maxAge}'.contains(lower)
    ).toList();
  }

  String get query => _query;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasFilter => _query.isNotEmpty;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.load();
      _categories = _service.getAll();
      _loading = false;
      _log.auto('🟢 CATEGORÍAS cargadas: ${_categories.length}', source: 'CategoryViewModel');
    } catch (e) {
      _error = e.toString();
      _loading = false;
      _log.error('🔴 Error al cargar categorías: $e', source: 'CategoryViewModel');
    }
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  Future<CategoryConfig?> save(CategoryConfig config) async {
    try {
      final saved = await _service.save(config);
      _log.system('🟢 CATEGORÍA ${config.id == null ? "creada" : "actualizada"}: ${saved.name}', source: 'CategoryViewModel');
      await load();
      return saved;
    } catch (e) {
      _error = e.toString();
      _log.error('🔴 Error al guardar categoría: $e', source: 'CategoryViewModel');
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(int id) async {
    try {
      final ok = await _service.delete(id);
      if (ok) {
        _log.system('🟢 CATEGORÍA eliminada: id=$id', source: 'CategoryViewModel');
        await load();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      _log.error('🔴 Error al eliminar categoría: $e', source: 'CategoryViewModel');
      notifyListeners();
      return false;
    }
  }

  bool nameExists(String name, {int? excludeId}) {
    return _service.nameExists(name, excludeId: excludeId);
  }

  Future<int> countAthletesUsing(String name) async {
    try {
      final db = DatabaseService.instance;
      await db.initialize();
      final athletes = await db.getActivePlayers();
      return athletes.where((p) => p.categoria == name).length;
    } catch (_) {
      return 0;
    }
  }

  String? validate(CategoryConfig config) {
    if (config.name.trim().isEmpty) return 'El nombre no puede estar vacío';
    if (config.minAge < 0) return 'La edad mínima no puede ser negativa';
    if (config.maxAge < config.minAge) return 'La edad máxima debe ser mayor o igual a la mínima';
    if (config.sortOrder < 1) return 'El orden debe ser mayor a 0';
    if (nameExists(config.name.trim(), excludeId: config.id)) return 'Ya existe una categoría con ese nombre';
    return null;
  }
}
