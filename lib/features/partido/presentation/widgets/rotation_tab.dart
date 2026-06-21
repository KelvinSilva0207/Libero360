import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/rotation_data.dart';
import 'court_widget.dart';

class RotationTab extends StatelessWidget {
  final RotationManager manager;
  final int currentSet;
  final VoidCallback onRotate;
  final ValueChanged<int>? onSlotTap;

  const RotationTab({
    super.key,
    required this.manager,
    required this.currentSet,
    required this.onRotate,
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final courtState = manager.courtState;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSetSelector(),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: CourtWidget(
              state: courtState,
              onZoneTap: (zoneNum) => onSlotTap
                  ?.call(RotationManager.zoneToVisual[zoneNum] ?? zoneNum - 1),
            ),
          ),
          const SizedBox(height: 12),
          _buildRotationControls(context),
          const SizedBox(height: 16),
          _buildHistory(context),
          const SizedBox(height: 16),
          _buildStats(context),
        ],
      ),
    );
  }

  Widget _buildSetSelector() {
    final allSets = manager.allSets;
    if (allSets.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allSets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final set = allSets[index];
          final isActive = set.setNumber == currentSet;
          return GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.3)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? AppColors.accent : Colors.white12,
                ),
              ),
              child: Center(
                child: Text(
                  'Set ${set.setNumber}',
                  style: TextStyle(
                    color: isActive ? AppColors.accent : Colors.white54,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRotationControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rotación actual',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rotación #${manager.rotationIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onRotate,
            icon: const Icon(Icons.rotate_right, size: 18),
            label: const Text('Rotar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    final history = manager.history;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              const Text(
                'Historial de rotaciones',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${history.length} rotaciones',
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sin rotaciones aún',
                  style: TextStyle(color: Colors.white24, fontSize: 13),
                ),
              ),
            )
          else
            ...List.generate(history.length, (index) {
              final snap = history[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rotación #${snap.rotationIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(snap.timestamp),
                      style: const TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final stats = manager.stats;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, size: 14, color: Colors.white38),
              SizedBox(width: 6),
              Text(
                'Rendimiento por rotación',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: 'Puntos ganados',
                value: '${stats.pointsWon}',
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _StatCard(
                label: 'Puntos perdidos',
                value: '${stats.pointsLost}',
                color: Colors.redAccent,
              ),
              const SizedBox(width: 8),
              _StatCard(
                label: 'Efectividad',
                value: '${stats.effectiveness.toStringAsFixed(1)}%',
                color: AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
