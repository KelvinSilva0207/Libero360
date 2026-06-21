import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/substitution_record.dart';

class SubstitutionHistory extends StatelessWidget {
  final List<SubstitutionRecord> history;
  final List<Player> allPlayers;

  const SubstitutionHistory({
    super.key,
    required this.history,
    required this.allPlayers,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'Sin sustituciones',
          style: TextStyle(color: Colors.white24, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (_, i) {
        final s = history[i];
        final outPlayer = _findPlayer(s.playerOutNumber);
        final inPlayer = _findPlayer(s.playerInNumber);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              _playerBadge(s.playerOutNumber, outPlayer, Colors.redAccent),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.accent,
                  size: 16,
                ),
              ),
              _playerBadge(s.playerInNumber, inPlayer, Colors.greenAccent),
              const Spacer(),
              Text(
                '#${s.setNumber} · R${s.rotationIndex + 1}',
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _playerBadge(int number, Player? player, Color accent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: accent.withValues(alpha: 0.2),
          child: Text(
            '$number',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          player?.displayName.isNotEmpty == true
              ? player!.displayName
              : '#$number',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
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
