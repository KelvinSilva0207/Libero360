import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/club_viewmodel.dart';
import 'create_club_screen.dart';

class ClubSwitcher extends StatelessWidget {
  const ClubSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vm = context.watch<ClubViewModel>();

    if (vm.myClubs.isEmpty) {
      return InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateClubScreen()),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: cs.primary, size: 18),
              const SizedBox(width: 6),
              Text('Crear club', style: TextStyle(color: cs.onSurface, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      color: cs.surfaceContainerHighest,
      onSelected: (value) {
        if (value == '__create__') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateClubScreen()),
          );
        } else {
          vm.setCurrentClub(value);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2, color: cs.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              vm.currentClub?.name ?? 'Seleccionar club',
              style: TextStyle(color: cs.onSurface, fontSize: 14),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                color: cs.onSurface.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
      itemBuilder: (_) => [
        ...vm.myClubs.map(
          (club) => PopupMenuItem(
            value: club.id,
            child: Row(
              children: [
                if (club.id == vm.currentClub?.id)
                  Icon(Icons.check,
                      color: cs.primary, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(club.name,
                    style: TextStyle(
                      color: club.id == vm.currentClub?.id
                          ? cs.primary
                          : cs.onSurface,
                    )),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: '__create__',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, color: cs.primary, size: 18),
              const SizedBox(width: 8),
              Text('Crear club', style: TextStyle(color: cs.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}
