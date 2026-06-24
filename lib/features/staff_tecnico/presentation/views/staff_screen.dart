import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../teams/presentation/viewmodels/club_viewmodel.dart';
import '../../../teams/data/team_models.dart' show ClubMember, ClubRole, ClubInvitation, ClubInvitationStatus;
import '../viewmodels/staff_tecnico_viewmodel.dart';
import '../widgets/invite_member_sheet.dart';
import '../widgets/staff_activity_timeline.dart';
import '../widgets/staff_summary_card.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffTecnicoViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Staff Técnico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<StaffTecnicoViewModel>().load(),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<StaffTecnicoViewModel, ClubViewModel>(
          builder: (_, vm, clubVm, __) {
            if (vm.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final clubMembers = clubVm.members.where((m) => m.isActive).toList();
            final pendingInv = clubVm.pendingInvitations;
            final acceptedInv = clubVm.acceptedInvitations;
            final rejectedInv = clubVm.rejectedInvitations;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context, cs, clubVm.currentClub?.name, clubVm.myRole),
                  const SizedBox(height: 20),
                  StaffSummaryCard(
                    activeCount: clubMembers.length,
                    pendingInvitationCount: pendingInv.length,
                    lastSync: 'Hace 5 minutos',
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader(context, Icons.people_rounded, 'Miembros del Club', cs,
                    trailing: TextButton.icon(
                      onPressed: () => _showInviteSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Invitar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (clubMembers.isEmpty)
                    _emptyState(context, cs, 'No hay miembros en el club')
                  else
                    ...clubMembers.map((m) => _clubMemberTile(context, m, cs)),
                  if (pendingInv.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionHeader(context, Icons.mail_rounded, 'Invitaciones Pendientes', cs),
                    const SizedBox(height: 8),
                    ...pendingInv.map((inv) => _clubInvitationTile(context, inv, cs, clubVm, ClubInvitationStatus.pending)),
                  ],
                  if (acceptedInv.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionHeader(context, Icons.check_circle_rounded, 'Invitaciones Aceptadas', cs),
                    const SizedBox(height: 8),
                    ...acceptedInv.map((inv) => _clubInvitationTile(context, inv, cs, clubVm, ClubInvitationStatus.accepted)),
                  ],
                  if (rejectedInv.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionHeader(context, Icons.cancel_rounded, 'Invitaciones Rechazadas', cs),
                    const SizedBox(height: 8),
                    ...rejectedInv.map((inv) => _clubInvitationTile(context, inv, cs, clubVm, ClubInvitationStatus.rejected)),
                  ],
                  const SizedBox(height: 24),
                  _sectionHeader(context, Icons.history_rounded, 'Actividad Reciente', cs),
                  const SizedBox(height: 8),
                  StaffActivityTimeline(activities: vm.activities),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ColorScheme cs, String? clubName, ClubRole? myRole) {
    final roleLabel = switch (myRole) {
      ClubRole.owner => 'Administrador',
      ClubRole.entrenador => 'Entrenador',
      ClubRole.asistente => 'Asistente',
      null => 'Invitado',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_2_rounded, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clubName ?? 'Staff Técnico',
                    style: TextStyle(color: cs.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (myRole != null)
                    Text(
                      'Tu rol: $roleLabel',
                      style: TextStyle(color: AppColors.accent, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Text(
            'Gestiona entrenadores y colaboradores del club.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title, ColorScheme cs, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _emptyState(BuildContext context, ColorScheme cs, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _clubInvitationTile(BuildContext context, ClubInvitation inv, ColorScheme cs, ClubViewModel clubVm, ClubInvitationStatus status) {
    final icon = switch (status) {
      ClubInvitationStatus.pending => Icons.hourglass_empty_rounded,
      ClubInvitationStatus.accepted => Icons.check_circle_rounded,
      ClubInvitationStatus.rejected => Icons.cancel_rounded,
      ClubInvitationStatus.expired => Icons.timer_off_rounded,
    };
    final color = switch (status) {
      ClubInvitationStatus.pending => AppColors.info,
      ClubInvitationStatus.accepted => const Color(0xFF4CAF50),
      ClubInvitationStatus.rejected => AppColors.error,
      ClubInvitationStatus.expired => Colors.grey,
    };
    final label = switch (status) {
      ClubInvitationStatus.pending => 'Pendiente',
      ClubInvitationStatus.accepted => 'Aceptada',
      ClubInvitationStatus.rejected => 'Rechazada',
      ClubInvitationStatus.expired => 'Expirada',
    };
    final roleLabel = switch (inv.role) {
      ClubRole.owner => 'Administrador',
      ClubRole.entrenador => 'Entrenador',
      ClubRole.asistente => 'Asistente',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(inv.clubName, style: TextStyle(color: cs.onSurface, fontSize: 14)),
        subtitle: Text('$roleLabel · $label', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 12)),
        trailing: status == ClubInvitationStatus.pending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                    onPressed: () => clubVm.acceptInvitation(inv),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 20),
                    onPressed: () => clubVm.rejectInvitation(inv),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _clubMemberTile(BuildContext context, ClubMember member, ColorScheme cs) {
    final roleLabel = switch (member.role) {
      ClubRole.owner => 'Administrador',
      ClubRole.entrenador => 'Entrenador',
      ClubRole.asistente => 'Asistente',
    };
    final isOwner = member.role == ClubRole.owner;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
          child: Text(
            member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(member.displayName, style: TextStyle(color: cs.onSurface, fontSize: 14)),
        subtitle: Text(
          '$roleLabel · ${member.email}',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 12),
        ),
        trailing: isOwner
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Dueño', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
              )
            : null,
      ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InviteMemberSheet(
        onInvite: (inv) => context.read<StaffTecnicoViewModel>().sendInvitation(inv),
      ),
    );
  }
}
