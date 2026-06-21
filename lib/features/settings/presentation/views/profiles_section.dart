import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../profiles/presentation/viewmodels/profile_viewmodel.dart';
import '../../../profiles/presentation/widgets/profile_card.dart';
import '../../../profiles/presentation/widgets/profile_selector.dart';
import '../../../profiles/presentation/views/create_profile_screen.dart';
import '../widgets/settings_card.dart';

class ProfilesSection extends StatelessWidget {
  const ProfilesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: const _ProfilesSectionBody(),
    );
  }
}

class _ProfilesSectionBody extends StatefulWidget {
  const _ProfilesSectionBody();

  @override
  State<_ProfilesSectionBody> createState() => _ProfilesSectionBodyState();
}

class _ProfilesSectionBodyState extends State<_ProfilesSectionBody> {
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

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Text('Perfil activo',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              const ProfileSelector(),
            ],
          ),
          if (vm.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vm.hasProfiles) ...[
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant, height: 1),
            const SizedBox(height: 8),
            ...vm.profiles.map(
              (p) => ProfileCard(
                profile: p,
                isSelected: p.id == vm.currentProfile?.id,
                onSelect: () => vm.selectProfile(p.id),
                onDelete: vm.profiles.length > 1
                    ? () => _confirmDelete(context, vm, p.id)
                    : null,
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text('Sin perfiles aún',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    'Crea un perfil para cada equipo o categoría.',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _createProfile(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Crear perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
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
      context.read<ProfileViewModel>().loadProfiles();
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
