import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/rotation_data.dart';

class RotationHistoryWidget extends StatelessWidget {
  final List<SetRotationState> sets;

  const RotationHistoryWidget({super.key, required this.sets});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: sets.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin rotaciones aún',
                          style: TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: sets.length,
                        itemBuilder: (_, i) => _SetSection(set: sets[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.white54, size: 20),
          const SizedBox(width: 10),
          const Text(
            'Historial de rotaciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${sets.length} set${sets.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SetSection extends StatelessWidget {
  final SetRotationState set;
  const _SetSection({required this.set});

  @override
  Widget build(BuildContext context) {
    final rotations = set.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SET ${set.setNumber}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${rotations.length} rotac.',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        ...rotations.asMap().entries.map((entry) {
          return _RotationCard(
            snapshot: entry.value,
            index: entry.key,
            isLast: entry.key == rotations.length - 1 &&
                set.rotationIndex == entry.value.rotationIndex,
          );
        }),
      ],
    );
  }
}

class _RotationCard extends StatelessWidget {
  final RotationSnapshot snapshot;
  final int index;
  final bool isLast;

  const _RotationCard({
    required this.snapshot,
    required this.index,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final slots = snapshot.slots;
    final topRow = slots.sublist(0, 3);
    final bottomRow = slots.sublist(3, 6);
    final timeStr = _formatTime(snapshot.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLast
            ? AppColors.accent.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLast
              ? AppColors.accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (isLast)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ACTUAL',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              Text(
                'R${snapshot.rotationIndex + 1}',
                style: TextStyle(
                  color: isLast ? AppColors.accent : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (snapshot.serverNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SERVIDOR #${snapshot.serverNumber}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildGrid(topRow, bottomRow),
          if (snapshot.totalPoints > 0) ...[
            const SizedBox(height: 6),
            _buildStatsRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(List<int?> topRow, List<int?> bottomRow) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildRow(topRow, isTop: true),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          _buildRow(bottomRow, isTop: false),
        ],
      ),
    );
  }

  Widget _buildRow(List<int?> slots, {required bool isTop}) {
    return Row(
      children: slots.asMap().entries.map((entry) {
        final num = entry.value;
        final col = entry.key;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: col < 2
                  ? Border(
                      right: BorderSide(
                          color: Colors.white.withValues(alpha: 0.06)))
                  : null,
              color: isTop ? null : Colors.white.withValues(alpha: 0.02),
            ),
            child: Text(
              num != null ? '$num' : '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: num != null ? Colors.white : Colors.white10,
                fontSize: 14,
                fontWeight: num != null ? FontWeight.w600 : FontWeight.w300,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statChip('A favor', snapshot.pointsWon, Colors.greenAccent),
        const SizedBox(width: 8),
        _statChip('En contra', snapshot.pointsLost, Colors.redAccent),
        const SizedBox(width: 8),
        _statChip('Efectividad', snapshot.effectiveness.round(), AppColors.accent,
            suffix: '%'),
      ],
    );
  }

  Widget _statChip(String label, int value, Color color,
      {String suffix = ''}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              '$value$suffix',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
