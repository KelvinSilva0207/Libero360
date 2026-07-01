import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../viewmodels/profile_viewmodel.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clubNameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  String _role = 'coach';
  bool _saving = false;

  final _roles = {
    'owner': 'Propietario',
    'coach': 'Entrenador',
    'assistant': 'Asistente',
    'viewer': 'Espectador',
  };

  @override
  void dispose() {
    _clubNameCtrl.dispose();
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Crear perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Información del perfil',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _clubNameCtrl,
                decoration: _inputDecoration(cs, 'Club', 'Ej: mi club'),
                style: TextStyle(color: cs.onSurface),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa el club' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration(
                    cs, 'Nombre del perfil', 'Ej: Águilas Masculino'),
                style: TextStyle(color: cs.onSurface),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryCtrl,
                decoration: _inputDecoration(
                    cs, 'Categoría', 'Ej: Masculino, Femenino, Sub17'),
                style: TextStyle(color: cs.onSurface),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: _inputDecoration(cs, 'Rol', null),
                dropdownColor: cs.surfaceContainerHighest,
                items: _roles.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: TextStyle(color: cs.onSurface)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:                           CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary),
                        )
                      : const Text('Crear perfil',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      ColorScheme cs, String label, String? hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
      hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final clubId = DateTime.now().millisecondsSinceEpoch.toString();
      await context.read<ProfileViewModel>().createProfile(
            clubId: clubId,
            clubName: _clubNameCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            category: _categoryCtrl.text.trim(),
            role: _role,
          );
      if (context.mounted) Navigator.pop(context, true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al crear perfil'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
