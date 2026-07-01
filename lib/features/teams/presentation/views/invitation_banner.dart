import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/club_viewmodel.dart';
import '../../data/team_models.dart';

class InvitationBanner extends StatelessWidget {
  const InvitationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vm = context.watch<ClubViewModel>();
    final pending = vm.pendingInvitations;

    if (pending.isEmpty) return const SizedBox.shrink();

    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        children: pending.map((inv) => _invitationTile(context, vm, inv, cs)).toList(),
      ),
    );
  }

  Widget _invitationTile(
      BuildContext context, ClubViewModel vm, ClubInvitation inv, ColorScheme cs) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.mail, color: cs.primary),
      title: Text(
        '${inv.inviterDisplayName} te invitó a ${inv.clubName}',
        style: TextStyle(color: cs.onSurface, fontSize: 14),
      ),
      subtitle: Text(
        'Rol: ${_roleLabel(inv.role)}',
        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.check_circle, color: cs.primary),
            onPressed: () => _accept(context, vm, inv),
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: cs.error),
            onPressed: () => _reject(context, vm, inv),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(
      BuildContext context, ClubViewModel vm, ClubInvitation inv) async {
    final err = await vm.acceptInvitation(inv);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  Future<void> _reject(
      BuildContext context, ClubViewModel vm, ClubInvitation inv) async {
    final err = await vm.rejectInvitation(inv);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  String _roleLabel(ClubRole role) {
    switch (role) {
      case ClubRole.owner:
        return '👑 Propietario';
      case ClubRole.entrenador:
        return '🏐 Entrenador';
      case ClubRole.asistente:
        return '📋 Asistente';
    }
  }
}
