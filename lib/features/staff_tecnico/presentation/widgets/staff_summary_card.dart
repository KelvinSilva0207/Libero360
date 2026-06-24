import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class StaffSummaryCard extends StatelessWidget {
  final int activeCount;
  final int pendingInvitationCount;
  final String lastSync;

  const StaffSummaryCard({
    super.key,
    required this.activeCount,
    required this.pendingInvitationCount,
    this.lastSync = '—',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _statItem(context, Icons.people_rounded, 'Entrenadores activos', '$activeCount', cs),
          Container(width: 1, height: 40, color: AppColors.borderLight.withValues(alpha: 0.3)),
          _statItem(context, Icons.mail_rounded, 'Invitaciones pendientes', '$pendingInvitationCount', cs),
          Container(width: 1, height: 40, color: AppColors.borderLight.withValues(alpha: 0.3)),
          _statItem(context, Icons.sync_rounded, 'Última sincronización', lastSync, cs),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, IconData icon, String label, String value, ColorScheme cs) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
