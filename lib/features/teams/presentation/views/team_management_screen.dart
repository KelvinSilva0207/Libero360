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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(vm.currentClub?.name ?? 'Equipo Técnico'),
        actions: [
          if (vm.canInvite())
            IconButton(
              icon: Icon(Icons.person_add_alt_1, color: cs.primary),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteMemberScreen())),
            ),
        ],
      ),
      body: vm.loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : vm.currentClub == null
              ? _noClubView(context, cs)
              : _clubView(context, vm, cs),
    );
  }

  Widget _noClubView(BuildContext context, ColorScheme cs) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2, size: 80, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('Sin club',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5), fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CreateClubScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Crear club'),
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
            ),
          ],
        ),
      );

  Widget _clubView(BuildContext context, ClubViewModel vm, ColorScheme cs) {
    final members = vm.members;
    final owner = members.where((m) => m.isOwner).toList();
    final entrenadores =
        members.where((m) => m.role == ClubRole.entrenador && m.isActive).toList();
    final asistentes =
        members.where((m) => m.role == ClubRole.asistente && m.isActive).toList();
    final pending = members.where((m) => !m.isActive).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(cs, 'Propietario', Icons.workspace_premium),
        const SizedBox(height: 8),
        ...owner.map((m) => _memberTile(context, vm, m, cs)),
        const SizedBox(height: 24),
        _sectionHeader(cs, 'Entrenadores', Icons.sports_volleyball),
        const SizedBox(height: 8),
        ...entrenadores.map((m) => _memberTile(context, vm, m, cs)),
        if (entrenadores.isEmpty) _emptyText(cs, 'Sin entrenadores'),
        const SizedBox(height: 24),
        _sectionHeader(cs, 'Asistentes', Icons.assignment),
        const SizedBox(height: 8),
        ...asistentes.map((m) => _memberTile(context, vm, m, cs)),
        if (asistentes.isEmpty) _emptyText(cs, 'Sin asistentes'),
        const SizedBox(height: 24),
        if (pending.isNotEmpty) ...[
          _sectionHeader(cs, 'Pendientes', Icons.hourglass_empty),
          const SizedBox(height: 8),
          ...pending.map((m) => _memberTile(context, vm, m, cs)),
          const SizedBox(height: 24),
        ],
        if (vm.isOwner) ...[
          _sectionHeader(cs, 'Peligro', Icons.warning),
          const SizedBox(height: 8),
          _dangerZone(context, vm, cs),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _sectionHeader(ColorScheme cs, String title, IconData icon) => Row(
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      );

  Widget _emptyText(ColorScheme cs, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 28),
        child: Text(text,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
      );

  Widget _memberTile(
      BuildContext context, ClubViewModel vm, ClubMember member, ColorScheme cs) {
    final isSelf = member.userId == vm.uid;
    final indicatorColor = member.isActive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFC107);

    return Card(
      color: cs.surfaceContainerHighest,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.isOwner ? cs.primary : cs.surfaceContainerHigh,
          child: Text(
            member.displayName.isNotEmpty
                ? member.displayName[0].toUpperCase()
                : '?',
            style:
                TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(member.displayName, style: TextStyle(color: cs.onSurface)),
            if (isSelf)
              Text(' (tú)',
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13)),
          ],
        ),
        subtitle: Text(
          _roleLabel(member.role),
          style:
              TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: indicatorColor),
            ),
            if (vm.isOwner && !member.isOwner)
              PopupMenuButton<String>(
                color: cs.surfaceContainerHighest,
                onSelected: (v) =>
                    _handleMemberAction(context, vm, member, v, cs),
                itemBuilder: (_) => [
                  if (member.role != ClubRole.entrenador)
                    const PopupMenuItem(
                        value: 'make_entrenador',
                        child: Text('Hacer entrenador')),
                  if (member.role != ClubRole.asistente)
                    const PopupMenuItem(
                        value: 'make_asistente',
                        child: Text('Hacer asistente')),
                  const PopupMenuItem(
                      value: 'remove',
                      child:
                          Text('Eliminar', style: TextStyle(color: Colors.red))),
                  if (!member.isActive)
                    const PopupMenuItem(
                        value: 'resend',
                        child: Text('Reenviar invitación')),
                ],
                icon: Icon(Icons.more_vert,
                    color: cs.onSurface.withValues(alpha: 0.5)),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMemberAction(BuildContext context, ClubViewModel vm,
      ClubMember member, String action, ColorScheme cs) async {
    switch (action) {
      case 'make_entrenador':
        final err = await vm.updateMemberRole(member.id, ClubRole.entrenador);
        if (err != null) _showError(context, err);
      case 'make_asistente':
        final err = await vm.updateMemberRole(member.id, ClubRole.asistente);
        if (err != null) _showError(context, err);
      case 'remove':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: cs.surfaceContainerHighest,
            title: Text('Eliminar miembro',
                style: TextStyle(color: cs.onSurface)),
            content: Text('¿Eliminar a ${member.displayName} del club?',
                style:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Eliminar',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true) {
          final err = await vm.removeMember(member.id);
          if (err != null) _showError(context, err);
        }
    }
  }

  Widget _dangerZone(BuildContext context, ClubViewModel vm, ColorScheme cs) {
    final others =
        vm.members.where((m) => m.userId != vm.uid && m.isActive).toList();
    return Column(
      children: [
        Card(
          color: cs.errorContainer,
          child: ExpansionTile(
            leading: Icon(Icons.warning, color: cs.error),
            title: Text('Zona de peligro', style: TextStyle(color: cs.error)),
            children: [
              if (others.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.swap_horiz, color: cs.error),
                  title: Text('Transferir propiedad',
                      style: TextStyle(color: cs.onSurface)),
                  subtitle: Text('Elige un nuevo propietario',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5))),
                  onTap: () => _showTransferDialog(context, vm, others, cs),
                ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: cs.error),
                title: Text('Eliminar club',
                    style: TextStyle(color: cs.error)),
                subtitle: Text('Esta acción no se puede deshacer',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5))),
                onTap: () => _deleteClub(context, vm, cs),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showTransferDialog(BuildContext context, ClubViewModel vm,
      List<ClubMember> candidates, ColorScheme cs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text('Transferir propiedad',
            style: TextStyle(color: cs.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: candidates
              .map((m) => ListTile(
                    leading: CircleAvatar(
                      child: Text(m.displayName[0].toUpperCase()),
                    ),
                    title: Text(m.displayName,
                        style: TextStyle(color: cs.onSurface)),
                    subtitle: Text(_roleLabel(m.role),
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6))),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: cs.surfaceContainerHighest,
                          title: Text('Confirmar',
                              style: TextStyle(color: cs.onSurface)),
                          content: Text(
                              '¿Transferir propiedad a ${m.displayName}?',
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7))),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Cancelar')),
                            TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: Text('Transferir',
                                    style: TextStyle(color: cs.primary))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final err = await vm.transferOwnership(m.userId);
                        if (err != null) _showError(context, err);
                      }
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _deleteClub(BuildContext context, ClubViewModel vm, ColorScheme cs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text('¿Eliminar club?', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Se eliminarán todos los datos del club ${vm.currentClub?.name}. ¿Estás seguro?',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
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
