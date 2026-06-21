import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/profile_model.dart';

class ProfileCard extends StatelessWidget {
  final ProfileModel profile;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback? onDelete;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.isSelected,
    required this.onSelect,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.accent : cs.outlineVariant,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  profile.clubName.isNotEmpty
                      ? profile.clubName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.clubName,
                      style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    '${profile.category} · ${profile.roleLabel}',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16),
              )
            else
              OutlinedButton(
                onPressed: onSelect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Seleccionar', style: TextStyle(fontSize: 12)),
              ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded,
                    color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
