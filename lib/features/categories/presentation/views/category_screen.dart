import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/category_config.dart';
import '../../../../core/themes/app_colors.dart';
import '../viewmodels/category_viewmodel.dart';
import '../widgets/category_editor_dialog.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text('Categorías', style: TextStyle(color: cs.onSurface)),
        actions: [
          Consumer<CategoryViewModel>(
            builder: (_, vm, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.search, color: vm.hasFilter ? AppColors.accent : cs.onSurfaceVariant),
                  onPressed: () => _showSearch(context, vm),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.accent),
                  onPressed: () => _create(vm),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<CategoryViewModel>(
        builder: (_, vm, __) {
          if (vm.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          if (vm.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(vm.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => vm.load(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  ),
                ],
              ),
            );
          }

          final categories = vm.filtered;

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, color: cs.onSurface.withValues(alpha: 0.38), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    vm.hasFilter ? 'Sin resultados' : 'Sin categorías',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _create(vm),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear categoría'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (_, i) => _buildCard(vm, categories[i], cs),
          );
        },
      ),
    );
  }

  Widget _buildCard(CategoryViewModel vm, CategoryConfig cat, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
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
        title: Text(cat.name, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500)),
        subtitle: Row(
          children: [
            Text('${cat.minAge}-${cat.maxAge} años', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            if (cat.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'default',
                  style: TextStyle(color: cs.primary, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: cs.onSurface.withValues(alpha: 0.6), size: 18),
              onPressed: cat.isDefault ? null : () => _edit(vm, cat),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              onPressed: () => _delete(vm, cat),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(CategoryViewModel vm) async {
    final result = await showDialog<CategoryConfig>(
      context: context,
      builder: (_) => CategoryEditorDialog(viewModel: vm),
    );
    if (result != null && mounted) {
      await vm.save(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoría "${result.name}" creada'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    }
  }

  Future<void> _edit(CategoryViewModel vm, CategoryConfig cat) async {
    final result = await showDialog<CategoryConfig>(
      context: context,
      builder: (_) => CategoryEditorDialog(existing: cat, viewModel: vm),
    );
    if (result != null && mounted) {
      await vm.save(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoría "${result.name}" actualizada'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    }
  }

  Future<void> _delete(CategoryViewModel vm, CategoryConfig cat) async {
    final cs = Theme.of(context).colorScheme;
    final athleteCount = await vm.countAthletesUsing(cat.name);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text('Eliminar categoría', style: TextStyle(color: cs.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Eliminar "${cat.name}"?', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
            if (athleteCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$athleteCount atleta${athleteCount == 1 ? '' : 's'} usar${athleteCount == 1 ? 'á' : 'án'} esta categoría. Se recalculará automáticamente.',
                        style: const TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final ok = await vm.delete(cat.id!);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoría "${cat.name}" eliminada'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar la categoría'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSearch(BuildContext context, CategoryViewModel vm) {
    showSearch(
      context: context,
      delegate: _CategorySearchDelegate(vm),
    );
  }
}

class _CategorySearchDelegate extends SearchDelegate<void> {
  final CategoryViewModel vm;
  _CategorySearchDelegate(this.vm);

  @override
  String get searchFieldLabel => 'Buscar categoría...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surfaceContainerHighest,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: cs.onSurfaceVariant),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(Icons.arrow_back, color: cs.onSurface),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    vm.setQuery(query);
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = vm.filtered;
    if (categories.isEmpty) {
      return Center(
        child: Text('Sin resultados', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 14)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: categories.map((cat) => ListTile(
        title: Text(cat.name, style: TextStyle(color: cs.onSurface)),
        subtitle: Text('${cat.minAge}-${cat.maxAge} años', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
        trailing: Text('#${cat.sortOrder}', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.38))),
      )).toList(),
    );
  }
}
