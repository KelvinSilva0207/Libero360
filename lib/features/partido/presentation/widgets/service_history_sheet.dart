import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/rotation_data.dart';

class ServiceHistorySheet extends StatelessWidget {
  final List<ServiceRecord> history;
  final List<Player> allPlayers;
  final int totalServices;
  final int bestStreak;
  final double averagePointsPerServe;

  const ServiceHistorySheet({
    super.key,
    required this.history,
    required this.allPlayers,
    this.totalServices = 0,
    this.bestStreak = 0,
    this.averagePointsPerServe = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
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
              _buildFutureStats(),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin registros de servicio',
                          style: TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 24, top: 4),
                        itemCount: history.length,
                        itemBuilder: (_, i) => _ServiceEntry(
                          record: history[i],
                          player: _findPlayer(history[i].playerNumber),
                          isActive: i == history.length - 1 &&
                              history[i].endTime == null,
                        ),
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
          const Icon(Icons.sports_volleyball,
              color: Colors.white54, size: 20),
          const SizedBox(width: 10),
          const Text(
            'Historial de servicio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${history.length} servicio${history.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _statBox('Total', '$totalServices', Icons.swap_vert),
          _statBox('Mejor racha', '$bestStreak pts', Icons.trending_up),
          _statBox('Promedio',
              averagePointsPerServe.toStringAsFixed(1), Icons.bar_chart),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white24, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
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

  Player? _findPlayer(int number) {
    try {
      return allPlayers.firstWhere((p) => p.numero == number);
    } catch (_) {
      return null;
    }
  }
}

class _ServiceEntry extends StatelessWidget {
  final ServiceRecord record;
  final Player? player;
  final bool isActive;

  const _ServiceEntry({
    required this.record,
    this.player,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = player != null
        ? NameFormatter.playerMatchName(player!)
        : '#${record.playerNumber}';
    final timeRange = _formatRange(record.startTime, record.endTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.green.withValues(alpha: 0.2)
                  : AppColors.accent.withValues(alpha: 0.15),
              border: Border.all(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.4)
                    : AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.sports_volleyball,
              color: isActive
                  ? Colors.green
                  : AppColors.accent.withValues(alpha: 0.7),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'S${record.setNumber}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${record.consecutivePoints} ptos',
                      style: TextStyle(
                        color: record.consecutivePoints > 0
                            ? Colors.greenAccent
                            : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeRange,
                      style: const TextStyle(
                          color: Colors.white24, fontSize: 10),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACTUAL',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (record.consecutivePoints > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${record.consecutivePoints}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatRange(DateTime start, DateTime? end) {
    final s = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    if (end == null) return '$s → actual';
    final e = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$s → $e';
  }
}
