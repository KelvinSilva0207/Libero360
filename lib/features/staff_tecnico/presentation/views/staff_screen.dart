import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../teams/presentation/viewmodels/club_viewmodel.dart';
import '../../../teams/data/team_models.dart' show ClubMember, ClubRole;
import '../../data/staff_tecnico_models.dart';
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
            final pendingInvitations = vm.invitations.where((i) => i.isPending).toList();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context, cs, clubVm.currentClub?.name),
                  const SizedBox(height: 20),
                  StaffSummaryCard(
                    activeCount: clubMembers.length,
                    pendingInvitationCount: clubVm.invitations.length,
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
                    ...clubMembers.map((m) => _clubMemberTile(context, m, cs, clubVm)),
                  if (pendingInvitations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionHeader(context, Icons.mail_rounded, 'Invitaciones Pendientes', cs),
                    const SizedBox(height: 8),
                    ...pendingInvitations.map((inv) => _invitationTile(context, inv, cs, vm)),
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

  Widget _header(BuildContext context, ColorScheme cs, String? clubName) {
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
            Text(
              clubName ?? 'Staff Técnico',
              style: TextStyle(color: cs.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
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

  Widget _invitationTile(BuildContext context, StaffInvitation inv, ColorScheme cs, StaffTecnicoViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.info.withValues(alpha: 0.2),
          child: const Icon(Icons.email_rounded, color: AppColors.info, size: 18),
        ),
        title: Text(inv.email, style: TextStyle(color: cs.onSurface, fontSize: 14)),
        subtitle: Text('${inv.role.displayName} · Pendiente', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 12)),
        trailing: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.error.withValues(alpha: 0.7), size: 18),
          onPressed: () => vm.cancelInvitation(inv),
        ),
      ),
    );
  }

  Widget _clubMemberTile(BuildContext context, ClubMember member, ColorScheme cs, ClubViewModel clubVm) {
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
