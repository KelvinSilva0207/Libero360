import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../teams/teams.dart';
import '../widgets/settings_card.dart';

class ClubSection extends StatelessWidget {
  const ClubSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClubViewModel>();
    final club = vm.currentClub;
    final cs = Theme.of(context).colorScheme;
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_2_rounded,
                    color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club?.name ?? 'Mi Club',
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      club != null ? 'Club activo' : 'Sin club seleccionado',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _actionButton(
            context,
            Icons.person_add_alt_1_rounded,
            'Invitar miembros',
            () => _navigateTo(context, const InviteMemberScreen()),
          ),
          const SizedBox(height: 8),
          _actionButton(
            context,
            Icons.swap_horiz_rounded,
            'Cambiar de club',
            () => _showClubSwitcher(context),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: cs.onSurface.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showClubSwitcher(BuildContext context) {
    final vm = context.read<ClubViewModel>();
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text('Seleccionar club',
            style: TextStyle(color: cs.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: vm.myClubs
                .map((club) => RadioListTile<String>(
                      title: Text(club.name,
                          style: TextStyle(
                            color: club.id == vm.currentClub?.id
                                ? cs.primary
                                : cs.onSurface,
                          )),
                      value: club.id,
                      groupValue: vm.currentClub?.id,
                      activeColor: cs.primary,
                      onChanged: (v) {
                        if (v != null) vm.setCurrentClub(v);
                        Navigator.pop(ctx);
                      },
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(ctx,
                  MaterialPageRoute(builder: (_) => const CreateClubScreen()));
            },
            child: Text('Crear club',
                style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
    );
  }
}
