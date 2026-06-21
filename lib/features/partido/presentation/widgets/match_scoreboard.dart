import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class MatchScoreBoard extends StatelessWidget {
  final int localScore;
  final int visitorScore;
  final int localSets;
  final int visitorSets;
  final bool isLocalServing;

  const MatchScoreBoard({
    super.key,
    this.localScore = 0,
    this.visitorScore = 0,
    this.localSets = 0,
    this.visitorSets = 0,
    this.isLocalServing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TeamScore(
                name: 'Local',
                score: localScore,
                color: AppColors.accent,
                isServing: isLocalServing,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _TeamScore(
                name: 'Visitante',
                score: visitorScore,
                color: AppColors.primary,
                isServing: !isLocalServing,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SetBadge(label: 'S1', won: localSets >= 1),
              _SetBadge(label: 'S2', won: localSets >= 2),
              _SetBadge(label: 'S3', won: localSets >= 3),
              const SizedBox(width: 24),
              _SetBadge(label: 'S1', won: visitorSets >= 1),
              _SetBadge(label: 'S2', won: visitorSets >= 2),
              _SetBadge(label: 'S3', won: visitorSets >= 3),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamScore extends StatelessWidget {
  final String name;
  final int score;
  final Color color;
  final bool isServing;

  const _TeamScore({
    required this.name,
    required this.score,
    required this.color,
    required this.isServing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isServing)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'SERVIDOR',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        Text(
          name,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          '$score',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _SetBadge extends StatelessWidget {
  final String label;
  final bool won;

  const _SetBadge({required this.label, required this.won});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: won ? Colors.green.withValues(alpha: 0.3) : Colors.white10,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: won ? Colors.green : Colors.white30,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
