import 'package:flutter/material.dart';
import '../../../../core/models/category_config.dart';
import '../../../../core/services/category_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/services/log_service.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final _service = CategoryService.instance;
  final _log = LogService.instance;
  List<CategoryConfig> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.load();
    setState(() {
      _categories = _service.getAll();
      _loading = false;
    });
  }

  Future<void> _create() async {
    final result = await _showEditor();
    if (result != null && mounted) {
      await _service.save(result);
      _log.system('CATEGORY created: ${result.name}', source: 'CategoryManager');
      await _load();
    }
  }

  Future<void> _edit(CategoryConfig cat) async {
    final result = await _showEditor(existing: cat);
    if (result != null && mounted) {
      await _service.save(result);
      _log.system('CATEGORY updated: ${result.name}', source: 'CategoryManager');
      await _load();
    }
  }

  Future<void> _delete(CategoryConfig cat) async {
    if (cat.isDefault) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se puede eliminar una categoría predeterminada')),
        );
      }
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar categoría', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${cat.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _service.delete(cat.id!);
      _log.error('CATEGORY deleted: ${cat.name}', source: 'CategoryManager');
      await _load();
    }
  }

  Future<CategoryConfig?> _showEditor({CategoryConfig? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final minAgeCtrl = TextEditingController(text: existing?.minAge.toString() ?? '');
    final maxAgeCtrl = TextEditingController(text: existing?.maxAge.toString() ?? '');
    final sortCtrl = TextEditingController(text: existing?.sortOrder.toString() ?? '');

    final result = await showDialog<CategoryConfig>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(existing != null ? 'Editar categoría' : 'Nueva categoría', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Nombre', nameCtrl),
              const SizedBox(height: 8),
              _field('Edad mínima', minAgeCtrl, numeric: true),
              const SizedBox(height: 8),
              _field('Edad máxima', maxAgeCtrl, numeric: true),
              const SizedBox(height: 8),
              _field('Orden', sortCtrl, numeric: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final min = int.tryParse(minAgeCtrl.text);
              final max = int.tryParse(maxAgeCtrl.text);
              final sort = int.tryParse(sortCtrl.text);
              if (name.isEmpty || min == null || max == null || sort == null) return;
              Navigator.pop(ctx, CategoryConfig(
                id: existing?.id,
                name: name,
                minAge: min,
                maxAge: max,
                sortOrder: sort,
                isDefault: existing?.isDefault ?? false,
              ));
            },
            child: const Text('Guardar', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    return result;
  }

  Widget _field(String label, TextEditingController ctrl, {bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Categorías', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: _create,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_outlined, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      const Text('Sin categorías', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _create,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear categoría'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${cat.sortOrder}',
                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        title: Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        subtitle: Text('${cat.minAge}-${cat.maxAge} años', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 18),
                              onPressed: cat.isDefault ? null : () => _edit(cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: cat.isDefault ? null : () => _delete(cat),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
