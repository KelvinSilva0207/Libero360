import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/medical_leave_model.dart';
import '../viewmodels/medical_leave_viewmodel.dart';
import '../views/medical_leave_form_screen.dart';

class MedicalLeaveSection extends StatelessWidget {
  final Player player;
  const MedicalLeaveSection({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MedicalLeaveViewModel>();
    final leaves = vm.getLeavesByPlayer(player.id);
    final active = leaves.where((l) => l.isActive).toList();
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.healing_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text('Reposo M\u00e9dico', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.accent, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MedicalLeaveFormScreen(player: player)),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (active.isEmpty && leaves.isEmpty)
            _emptyState(cs)
          else if (active.isEmpty)
            _history(leaves, cs)
          else
            ...active.map((l) => _activeCard(l, cs)),
          if (active.isEmpty && leaves.length > 1) ...[
            const SizedBox(height: 8),
            Text('Historial (${leaves.length} registros)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            ...leaves.take(2).map((l) => _historyItem(l, cs)),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text('Sin reposos m\u00e9dicos registrados', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 12)),
      ),
    );
  }

  Widget _activeCard(MedicalLeave l, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Activo', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              if (l.isExpiringSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Pr\u00f3ximo a vencer', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l.reason, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Desde ${_fmt(l.startDate)}${l.endDate != null ? ' hasta ${_fmt(l.endDate!)}' : ''}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          if (l.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(l.notes, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _history(List<MedicalLeave> leaves, ColorScheme cs) {
    return Column(
      children: leaves.take(3).map((l) => _historyItem(l, cs)).toList(),
    );
  }

  Widget _historyItem(MedicalLeave l, ColorScheme cs) {
    final statusColor = switch (l.status) {
      MedicalLeaveStatus.finished => const Color(0xFF22C55E),
      MedicalLeaveStatus.cancelled => const Color(0xFFEF4444),
      _ => const Color(0xFF3B82F6),
    };
    final statusLabel = switch (l.status) {
      MedicalLeaveStatus.active => 'Activo',
      MedicalLeaveStatus.finished => 'Finalizado',
      MedicalLeaveStatus.cancelled => 'Cancelado',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(l.reason, style: const TextStyle(color: Colors.white, fontSize: 12))),
          Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
