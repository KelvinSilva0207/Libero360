import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/club_viewmodel.dart';
import '../../data/team_models.dart';

class InvitationBanner extends StatelessWidget {
  const InvitationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClubViewModel>();
    final pending = vm.pendingInvitations;

    if (pending.isEmpty) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFFFF8C00).withValues(alpha: 0.15),
      child: Column(
        children: pending.map((inv) => _invitationTile(context, vm, inv)).toList(),
      ),
    );
  }

  Widget _invitationTile(
      BuildContext context, ClubViewModel vm, ClubInvitation inv) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.mail, color: Color(0xFFFF8C00)),
      title: Text(
        '${inv.inviterDisplayName} te invitó a ${inv.clubName}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        'Rol: ${_roleLabel(inv.role)}',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            onPressed: () => _accept(context, vm, inv),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
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
          SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  Future<void> _reject(
      BuildContext context, ClubViewModel vm, ClubInvitation inv) async {
    final err = await vm.rejectInvitation(inv);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red));
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
