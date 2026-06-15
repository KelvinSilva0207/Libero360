import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/team_models.dart';
import '../viewmodels/club_viewmodel.dart';
import 'invite_member_screen.dart';
import 'create_club_screen.dart';

class TeamManagementScreen extends StatelessWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClubViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: Text(vm.currentClub?.name ?? 'Equipo Técnico'),
        actions: [
          if (vm.canInvite())
            IconButton(
              icon: const Icon(Icons.person_add_alt_1, color: Color(0xFFFF8C00)),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteMemberScreen())),
            ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
          : vm.currentClub == null
              ? _noClubView(context)
              : _clubView(context, vm),
    );
  }

  Widget _noClubView(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2, size: 80, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('Sin club', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateClubScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Crear club'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            ),
          ],
        ),
      );

  Widget _clubView(BuildContext context, ClubViewModel vm) {
    final members = vm.members;
    final owner = members.where((m) => m.isOwner).toList();
    final entrenadores = members
        .where((m) => m.role == ClubRole.entrenador && m.isActive)
        .toList();
    final asistentes = members
        .where((m) => m.role == ClubRole.asistente && m.isActive)
        .toList();
    final pending = members.where((m) => !m.isActive).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Propietario', Icons.workspace_premium),
        const SizedBox(height: 8),
        ...owner.map((m) => _memberTile(context, vm, m)),
        const SizedBox(height: 24),
        _sectionHeader('Entrenadores', Icons.sports_volleyball),
        const SizedBox(height: 8),
        ...entrenadores.map((m) => _memberTile(context, vm, m)),
        if (entrenadores.isEmpty)
          _emptyText('Sin entrenadores'),
        const SizedBox(height: 24),
        _sectionHeader('Asistentes', Icons.assignment),
        const SizedBox(height: 8),
        ...asistentes.map((m) => _memberTile(context, vm, m)),
        if (asistentes.isEmpty)
          _emptyText('Sin asistentes'),
        const SizedBox(height: 24),
        if (pending.isNotEmpty) ...[
          _sectionHeader('Pendientes', Icons.hourglass_empty),
          const SizedBox(height: 8),
          ...pending.map((m) => _memberTile(context, vm, m)),
          const SizedBox(height: 24),
        ],
        if (vm.isOwner) ...[
          _sectionHeader('Peligro', Icons.warning),
          const SizedBox(height: 8),
          _dangerZone(context, vm),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Row(
        children: [
          Icon(icon, color: const Color(0xFFFF8C00), size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      );

  Widget _emptyText(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 28),
        child: Text(text,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      );

  Widget _memberTile(BuildContext context, ClubViewModel vm, ClubMember member) {
    final isSelf = member.userId == vm.uid;
    final indicatorColor = member.isActive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFC107);

    return Card(
      color: const Color(0xFF1A1F3D),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.isOwner
              ? const Color(0xFFFF8C00)
              : const Color(0xFF2A2F55),
          child: Text(
            member.displayName.isNotEmpty
                ? member.displayName[0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(member.displayName,
                style: const TextStyle(color: Colors.white)),
            if (isSelf)
              Text(' (tú)',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          ],
        ),
        subtitle: Text(
          _roleLabel(member.role),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: indicatorColor),
            ),
            if (vm.isOwner && !member.isOwner)
              PopupMenuButton<String>(
                color: const Color(0xFF1A1F3D),
                onSelected: (v) => _handleMemberAction(context, vm, member, v),
                itemBuilder: (_) => [
                  if (member.role != ClubRole.entrenador)
                    const PopupMenuItem(value: 'make_entrenador', child: Text('Hacer entrenador')),
                  if (member.role != ClubRole.asistente)
                    const PopupMenuItem(value: 'make_asistente', child: Text('Hacer asistente')),
                  const PopupMenuItem(value: 'remove', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                  if (!member.isActive)
                    const PopupMenuItem(value: 'resend', child: Text('Reenviar invitación')),
                ],
                icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.5)),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMemberAction(BuildContext context, ClubViewModel vm,
      ClubMember member, String action) async {
    switch (action) {
      case 'make_entrenador':
        final err = await vm.updateMemberRole(member.id, ClubRole.entrenador);
        if (err != null) _showError(context, err);
        break;
      case 'make_asistente':
        final err = await vm.updateMemberRole(member.id, ClubRole.asistente);
        if (err != null) _showError(context, err);
        break;
      case 'remove':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F3D),
            title: const Text('Eliminar miembro',
                style: TextStyle(color: Colors.white)),
            content: Text('¿Eliminar a ${member.displayName} del club?',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true) {
          final err = await vm.removeMember(member.id);
          if (err != null) _showError(context, err);
        }
        break;
    }
  }

  Widget _dangerZone(BuildContext context, ClubViewModel vm) {
    final others = vm.members
        .where((m) => m.userId != vm.uid && m.isActive)
        .toList();
    return Column(
      children: [
        Card(
          color: const Color(0xFF2D1B1B),
          child: ExpansionTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: const Text('Zona de peligro',
                style: TextStyle(color: Colors.red)),
            children: [
              if (others.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Colors.red),
                  title: const Text('Transferir propiedad',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('Elige un nuevo propietario',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                  onTap: () => _showTransferDialog(context, vm, others),
                ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Eliminar club',
                    style: TextStyle(color: Colors.red)),
                subtitle: Text('Esta acción no se puede deshacer',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                onTap: () => _deleteClub(context, vm),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTransferDialog(
      BuildContext context, ClubViewModel vm, List<ClubMember> candidates) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3D),
        title: const Text('Transferir propiedad',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: candidates.map((m) =>
              ListTile(
                leading: CircleAvatar(
                  child: Text(m.displayName[0].toUpperCase()),
                ),
                title: Text(m.displayName,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(_roleLabel(m.role),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1F3D),
                      title: const Text('Confirmar',
                          style: TextStyle(color: Colors.white)),
                      content: Text(
                          '¿Transferir propiedad a ${m.displayName}?',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7))),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancelar')),
                        TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Transferir',
                                style: TextStyle(color: Color(0xFFFF8C00)))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final err = await vm.transferOwnership(m.userId);
                    if (err != null) _showError(context, err);
                  }
                },
              ),
          ).toList(),
        ),
      ),
    );
  }

  void _deleteClub(BuildContext context, ClubViewModel vm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3D),
        title:
            const Text('¿Eliminar club?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Se eliminarán todos los datos del club ${vm.currentClub?.name}. ¿Estás seguro?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final err = await vm.deleteClub();
      if (err != null) _showError(context, err);
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
