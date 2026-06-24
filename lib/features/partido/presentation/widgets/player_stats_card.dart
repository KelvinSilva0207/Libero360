import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/player_action.dart';

class PlayerStatsCard extends StatelessWidget {
  final Player player;
  final List<PlayerActionEvent> actions;
  final int rank;

  const PlayerStatsCard({
    super.key,
    required this.player,
    required this.actions,
    this.rank = 0,
  });

  int get _totalScore =>
      actions.fold(0, (sum, a) => sum + a.type.value);

  Map<ActionType, int> get _counts {
    final map = <ActionType, int>{};
    for (final a in actions) {
      map[a.type] = (map[a.type] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final name = player.displayName.isNotEmpty
        ? player.displayName
        : '${player.firstNames} ${player.lastNames}'.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accent.withValues(alpha: 0.25),
                child: Text(
                  '${player.numero ?? '?'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      player.posicionLabel,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (rank == 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.3),
                        Colors.orange.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'MVP',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildStatRow('⚔ Ataques', _counts[ActionType.ataque] ?? 0),
          ..._buildStatRow('🧱 Bloqueos', _counts[ActionType.bloqueo] ?? 0),
          ..._buildStatRow('🏐 Servicios', _counts[ActionType.servicio] ?? 0),
          ..._buildStatRow('🛡 Defensas', _counts[ActionType.defensa] ?? 0),
          ..._buildStatRow('🙌 Recepciones', _counts[ActionType.recepcion] ?? 0),
          ..._buildStatRow('❌ Errores', _counts[ActionType.error] ?? 0),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Puntaje total',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              Text(
                '$_totalScore',
                style: TextStyle(
                  color: _totalScore >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (rank > 0 && rank <= 3) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  rank == 1
                      ? Icons.emoji_events
                      : rank == 2
                          ? Icons.looks_two
                          : Icons.looks_3,
                  color: Colors.amber.shade300,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '#$rank',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStatRow(String label, int count) {
    if (count == 0) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
