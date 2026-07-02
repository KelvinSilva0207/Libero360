import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/profile_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../views/create_profile_screen.dart';

class CompactProfileSelector extends StatelessWidget {
  const CompactProfileSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final profile = vm.currentProfile;
    final cs = Theme.of(context).colorScheme;

    LogService.instance.auto('⚪ CompactProfileSelector — profiles=${vm.profiles.length}', source: 'CompactProfileSelector');

    if (vm.profiles.isEmpty) {
      LogService.instance.auto('⚪ CompactProfileSelector — sin perfiles, mostrar "Crear perfil"', source: 'CompactProfileSelector');
      return InkWell(
        onTap: () {
          LogService.instance.auto('🟡 CompactProfileSelector — navegar a CreateProfileScreen', source: 'CompactProfileSelector');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Crear perfil',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    if (profile == null) {
      LogService.instance.auto('🔴 CompactProfileSelector — sin club seleccionado', source: 'CompactProfileSelector');
      return InkWell(
        onTap: () => _showProfileSheet(context, vm),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                'Sin club seleccionado',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, color: cs.onSurface.withValues(alpha: 0.4), size: 18),
            ],
          ),
        ),
      );
    }

    LogService.instance.auto('🟢 CompactProfileSelector — perfil activo: ${profile.clubName}', source: 'CompactProfileSelector');

    return InkWell(
      onTap: () => _showProfileSheet(context, vm),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, size: 16, color: cs.primary),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  profile.clubName,
                  key: ValueKey(profile.id),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, color: cs.onSurface.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, ProfileViewModel vm) {
    final cs = Theme.of(context).colorScheme;
    LogService.instance.auto('🟡 CompactProfileSelector — abriendo selector de perfiles', source: 'CompactProfileSelector');

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Seleccionar perfil',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...vm.profiles.map((p) => _profileTile(ctx, p, vm, cs)),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Crear perfil', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    if (vm.profiles.length > 1) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showDeleteConfirm(context, vm, vm.currentProfile!);
                          },
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Eliminar', style: TextStyle(fontSize: 13, color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _profileTile(BuildContext ctx, ProfileModel p, ProfileViewModel vm, ColorScheme cs) {
    final isActive = p.id == vm.currentProfile?.id;
    return InkWell(
      onTap: () {
        vm.selectProfile(p.id);
        LogService.instance.auto('🟢 CompactProfileSelector — perfil cambiado a: ${p.clubName}', source: 'CompactProfileSelector');
        LogService.instance.auto('🔵 CompactProfileSelector — dashboard actualizado', source: 'CompactProfileSelector');
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent.withValues(alpha: 0.15) : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.shield_rounded,
                color: isActive ? AppColors.accent : cs.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.clubName,
                    style: TextStyle(
                      color: isActive ? cs.onSurface : cs.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.category} · ${p.roleLabel}',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.accent, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ProfileViewModel vm, ProfileModel profile) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Eliminar perfil', style: TextStyle(color: cs.onSurface)),
        content: Text('¿Eliminar "${profile.clubName}"?', style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.deleteProfile(profile.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
