import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../viewmodels/club_viewmodel.dart';

class CreateClubScreen extends StatefulWidget {
  const CreateClubScreen({super.key});

  @override
  State<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ClubViewModel>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Crear club'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Icon(Icons.groups_2, size: 72, color: cs.primary),
            const SizedBox(height: 24),
            Text(
              'Nombre del club',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Ej: Academia Elite',
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Descripción (opcional)',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              style: TextStyle(color: cs.onSurface),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: Club de voleibol juvenil',
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'URL de foto (opcional)',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _photoCtrl,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'https://ejemplo.com/logo.png',
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _creating ? null : () => _create(context, vm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _creating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Crear club',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, ClubViewModel vm) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para el club')),
      );
      return;
    }

    final description = _descCtrl.text.trim();
    final photoUrl = _photoCtrl.text.trim();

    setState(() => _creating = true);
    final err = await vm.createClub(name, description: description, photoUrl: photoUrl.isNotEmpty ? photoUrl : null);
    setState(() => _creating = false);

    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      }
    } else {
      if (mounted) Navigator.pop(context);
    }
  }
}
