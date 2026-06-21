import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/profile_card.dart';
import 'create_profile_screen.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Mis Perfiles'),
      ),
      body: _buildBody(vm, cs),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProfile(context),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Crear perfil',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBody(ProfileViewModel vm, ColorScheme cs) {
    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Error al cargar perfiles',
                style: TextStyle(color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(vm.error!, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => vm.loadProfiles(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (!vm.hasProfiles) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person_add_rounded,
                  color: AppColors.accent, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Sin perfiles aún',
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Crea un perfil para cada equipo o categoría\nque quieras administrar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...vm.profiles.map(
          (p) => ProfileCard(
            profile: p,
            isSelected: p.id == vm.currentProfile?.id,
            onSelect: () => vm.selectProfile(p.id),
            onDelete: vm.profiles.length > 1 ? () => _confirmDelete(context, vm, p.id) : null,
          ),
        ),
      ],
    );
  }

  void _createProfile(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateProfileScreen(),
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Perfil creado correctamente'),
            backgroundColor: Colors.green),
      );
    }
  }

  void _confirmDelete(BuildContext context, ProfileViewModel vm, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        title: const Text('Eliminar perfil'),
        content: const Text('¿Estás seguro de eliminar este perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.deleteProfile(id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
