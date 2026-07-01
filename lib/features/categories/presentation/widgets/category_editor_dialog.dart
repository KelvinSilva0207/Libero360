import 'package:flutter/material.dart';
import '../../../../core/models/category_config.dart';
import '../../../../core/themes/app_colors.dart';
import '../viewmodels/category_viewmodel.dart';

class CategoryEditorDialog extends StatefulWidget {
  final CategoryConfig? existing;
  final CategoryViewModel viewModel;

  const CategoryEditorDialog({
    super.key,
    this.existing,
    required this.viewModel,
  });

  @override
  State<CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<CategoryEditorDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _minAgeCtrl;
  late TextEditingController _maxAgeCtrl;
  late TextEditingController _sortCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _minAgeCtrl = TextEditingController(text: e?.minAge.toString() ?? '');
    _maxAgeCtrl = TextEditingController(text: e?.maxAge.toString() ?? '');
    _sortCtrl = TextEditingController(text: e?.sortOrder.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minAgeCtrl.dispose();
    _maxAgeCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final min = int.tryParse(_minAgeCtrl.text);
    final max = int.tryParse(_maxAgeCtrl.text);
    final sort = int.tryParse(_sortCtrl.text);

    if (name.isEmpty) {
      setState(() => _error = 'El nombre no puede estar vacío');
      return;
    }
    if (min == null || max == null || sort == null) {
      setState(() => _error = 'Los campos numéricos son requeridos');
      return;
    }
    if (min < 0) {
      setState(() => _error = 'La edad mínima no puede ser negativa');
      return;
    }
    if (max < min) {
      setState(() => _error = 'La edad máxima debe ser mayor o igual a la mínima');
      return;
    }
    if (sort < 1) {
      setState(() => _error = 'El orden debe ser mayor a 0');
      return;
    }

    final config = CategoryConfig(
      id: widget.existing?.id,
      name: name,
      minAge: min,
      maxAge: max,
      sortOrder: sort,
      isDefault: widget.existing?.isDefault ?? false,
    );

    final validationError = widget.viewModel.validate(config);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    Navigator.pop(context, config);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;
    return AlertDialog(
      backgroundColor: cs.surfaceContainerHighest,
      title: Text(
        isEditing ? 'Editar categoría' : 'Nueva categoría',
        style: TextStyle(color: cs.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            _field('Nombre', _nameCtrl),
            const SizedBox(height: 8),
            _field('Edad mínima', _minAgeCtrl, numeric: true),
            const SizedBox(height: 8),
            _field('Edad máxima', _maxAgeCtrl, numeric: true),
            const SizedBox(height: 8),
            _field('Orden', _sortCtrl, numeric: true),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        TextButton(
          onPressed: _save,
          child: Text('Guardar', style: TextStyle(color: AppColors.accent)),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool numeric = false}) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
