import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/profile_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../views/create_profile_screen.dart';

class ProfileSelector extends StatelessWidget {
  const ProfileSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final profile = vm.currentProfile;
    final cs = Theme.of(context).colorScheme;

    if (vm.profiles.isEmpty) {
      return InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (profile == null) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      color: cs.surface,
      onSelected: (id) => vm.selectProfile(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              profile.displayLabel,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                color: cs.onSurface.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
      itemBuilder: (_) => [
        ...vm.profiles.map(
          (p) => PopupMenuItem<String>(
            value: p.id,
            child: Row(
              children: [
                if (p.id == vm.currentProfile?.id)
                  Icon(Icons.check, color: AppColors.accent, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.clubName,
                          style: TextStyle(
                              color: cs.onSurface, fontSize: 13)),
                      Text(
                        '${p.category} · ${p.roleLabel}',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
