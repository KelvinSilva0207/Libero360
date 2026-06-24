import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/staff_tecnico_models.dart';

class StaffListTile extends StatelessWidget {
  final StaffMember member;
  final VoidCallback? onDelete;

  const StaffListTile({super.key, required this.member, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
          backgroundImage: member.fotoUrl != null && member.fotoUrl!.isNotEmpty
              ? NetworkImage(member.fotoUrl!)
              : null,
          child: member.fotoUrl == null || member.fotoUrl!.isEmpty
              ? Text(
                  member.nombre.isNotEmpty ? member.nombre[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Text(
          member.nombre,
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          member.correo,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roleBadge(member.role, cs),
            const SizedBox(width: 8),
            _statusDot(member.status, cs),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppColors.error.withValues(alpha: 0.7), size: 18),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(StaffRole role, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${role.icon} ${role.displayName}',
        style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statusDot(StaffStatus status, ColorScheme cs) {
    final color = switch (status) {
      StaffStatus.activo => AppColors.success,
      StaffStatus.sinConexion => AppColors.warning,
      StaffStatus.invitado => AppColors.info,
    };
    final label = switch (status) {
      StaffStatus.activo => '🟢 Activo',
      StaffStatus.sinConexion => '🟡 Sin conexión',
      StaffStatus.invitado => '🔵 Invitado',
    };
    return Tooltip(
      message: label,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}
