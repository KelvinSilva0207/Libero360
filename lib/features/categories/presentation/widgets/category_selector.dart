import 'package:flutter/material.dart';
import '../../../../core/models/category_config.dart';
import '../../../../core/services/category_service.dart';
import '../../../../core/themes/app_colors.dart';

class CategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;
  final String? label;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<CategoryConfig>>(
      future: _loadCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        final displayLabel = label ?? 'Categoría';

        return DropdownButtonFormField<String>(
          value: selectedCategory,
          dropdownColor: AppColors.surfaceLight,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            labelText: displayLabel,
            labelStyle: TextStyle(color: cs.onSurfaceVariant),
            prefixIcon: const Padding(
              padding: EdgeInsetsDirectional.only(start: 12, end: 8),
              child: Icon(Icons.category, color: AppColors.primary, size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
            items: [
            DropdownMenuItem(
              value: null,
              child: Text('Auto (según edad)', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            ),
            ...categories.map((c) => DropdownMenuItem(
              value: c.name,
              child: Text(c.name, style: TextStyle(color: cs.onSurface)),
            )),
          ],
          onChanged: onChanged,
        );
      },
    );
  }

  Future<List<CategoryConfig>> _loadCategories() async {
    final service = CategoryService.instance;
    await service.load();
    return service.getAll();
  }
}
