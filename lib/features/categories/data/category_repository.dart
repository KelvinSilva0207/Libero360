import '../../../core/models/category_config.dart';
import '../../../core/services/category_service.dart';

class CategoryRepository {
  final CategoryService _service = CategoryService.instance;

  Future<List<CategoryConfig>> getAll() async {
    await _service.load();
    return _service.getAll();
  }

  Future<List<String>> getAllNames() async {
    await _service.load();
    return _service.getAllNames();
  }

  Future<CategoryConfig> save(CategoryConfig config) async {
    return _service.save(config);
  }

  Future<bool> delete(int id) async {
    return _service.delete(id);
  }

  bool nameExists(String name, {int? excludeId}) {
    return _service.nameExists(name, excludeId: excludeId);
  }
}
