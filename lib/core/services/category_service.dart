import 'package:sembast/sembast.dart';
import '../../core/database/database_provider.dart';
import '../models/category_config.dart';

class CategoryService {
  static final CategoryService instance = CategoryService._internal();
  CategoryService._internal();

  Database? _db;
  final _store = intMapStoreFactory.store('categories');
  List<CategoryConfig> _categories = [];
  bool _loaded = false;

  static final List<CategoryConfig> _defaults = [
    const CategoryConfig(name: 'U9', minAge: 1, maxAge: 8, sortOrder: 1, isDefault: true),
    const CategoryConfig(name: 'U11', minAge: 9, maxAge: 10, sortOrder: 2, isDefault: true),
    const CategoryConfig(name: 'U13', minAge: 11, maxAge: 12, sortOrder: 3, isDefault: true),
    const CategoryConfig(name: 'U15', minAge: 13, maxAge: 14, sortOrder: 4, isDefault: true),
    const CategoryConfig(name: 'U17', minAge: 15, maxAge: 16, sortOrder: 5, isDefault: true),
    const CategoryConfig(name: 'U19', minAge: 17, maxAge: 18, sortOrder: 6, isDefault: true),
    const CategoryConfig(name: 'Libre', minAge: 19, maxAge: 99, sortOrder: 7, isDefault: true),
    const CategoryConfig(name: 'Master', minAge: 35, maxAge: 99, sortOrder: 99, isDefault: true),
  ];

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = await databasePath;
    _db = await databaseFactory.openDatabase(path);
    return _db!;
  }

  Future<void> load() async {
    if (_loaded) return;
    final db = await _database;
    final snapshots = await _store.find(db);
    if (snapshots.isEmpty) {
      _categories = List.from(_defaults);
      for (final cat in _categories) {
        final key = await _store.add(db, cat.toMap());
        (cat as dynamic).id = key;
      }
      _loaded = true;
      return;
    }
    var loaded = snapshots
        .map((e) => CategoryConfig.fromMap(e.value, id: e.key))
        .toList();

    final seen = <String>{};
    final duplicates = <int>[];
    final deduplicated = <CategoryConfig>[];
    for (final cat in loaded) {
      final key = cat.name.toLowerCase();
      if (seen.contains(key)) {
        duplicates.add(cat.id!);
      } else {
        seen.add(key);
        deduplicated.add(cat);
      }
    }
    for (final id in duplicates) {
      await _store.record(id).delete(db);
    }

    _categories = deduplicated..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _loaded = true;
  }

  Future<void> reload() async {
    _loaded = false;
    await load();
  }

  List<CategoryConfig> getAll() => List.unmodifiable(_categories);

  List<String> getAllNames() => _categories.map((c) => c.name).toList();

  bool nameExists(String name, {int? excludeId}) {
    return _categories.any((c) =>
      c.name.toLowerCase() == name.toLowerCase() &&
      (excludeId == null || c.id != excludeId));
  }

  String calculate(int age) {
    for (final cat in _categories) {
      if (cat.matchesAge(age)) return cat.name;
    }
    return _categories.isNotEmpty ? _categories.last.name : 'Sin categoría';
  }

  String calculateFromBirth(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return calculate(age);
  }

  Future<CategoryConfig> save(CategoryConfig config) async {
    final db = await _database;
    final map = config.toMap();
    if (config.id == null || config.id == 0) {
      final key = await _store.add(db, map);
      final saved = config.copyWith(id: key);
      _categories.add(saved);
      _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return saved;
    } else {
      await _store.record(config.id!).put(db, map);
      final index = _categories.indexWhere((c) => c.id == config.id);
      if (index != -1) {
        _categories[index] = config;
      } else {
        _categories.add(config);
      }
      _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return config;
    }
  }

  Future<bool> delete(int id) async {
    final db = await _database;
    await _store.record(id).delete(db);
    _categories.removeWhere((c) => c.id == id);
    return true;
  }
}
