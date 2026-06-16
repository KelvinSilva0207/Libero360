import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/court_models.dart';

class RotationTimeline extends StatelessWidget {
  final List<RotationRecord> history;
  final int currentRotation;
  final List<PlayerAssignment?> currentLineup;

  const RotationTimeline({
    super.key,
    required this.history,
    required this.currentRotation,
    required this.currentLineup,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Historial de rotaciones',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rot. #${currentRotation + 1}',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (history.isEmpty && currentRotation == 0)
          _buildEmpty(colors)
        else
          _buildTimeline(colors),
      ],
    );
  }

  Widget _buildEmpty(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.sync_rounded, size: 32, color: colors.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              'Presiona "Ganó el saque" para rotar',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(ColorScheme colors) {
    final allRecords = List<RotationRecord>.from(history);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allRecords.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index < allRecords.length) {
          return _buildRecord(allRecords[index], allRecords.length - index, colors);
        }
        return _buildCurrentRecord(colors);
      },
    );
  }

  Widget _buildRecord(RotationRecord record, int num, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$num',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rotación #${record.rotationNumber + 1}',
                  style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatLineup(record.lineup),
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (record.wonServe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SAQUE',
                style: TextStyle(color: Color(0xFF22C55E), fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentRecord(ColorScheme colors) {
    final players = currentLineup.whereType<PlayerAssignment>().toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            colors.surface,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '●',
                style: TextStyle(color: AppColors.accent, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rotación actual #${currentRotation + 1}',
                  style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatLineup(players),
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ACTUAL',
              style: TextStyle(color: AppColors.accent, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLineup(List<PlayerAssignment> lineup) {
    return lineup.map((p) => '#${p.effectiveNumber}').join('  ·  ');
  }
}
