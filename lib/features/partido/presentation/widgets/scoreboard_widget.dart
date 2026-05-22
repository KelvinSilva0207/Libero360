import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class ScoreboardWidget extends StatelessWidget {
  final String localName;
  final String visitorName;
  final int localPoints;
  final int visitorPoints;
  final int localSets;
  final int visitorSets;
  final int currentSet;
  final bool isActive;
  final VoidCallback? onLocalNameTap;
  final VoidCallback? onVisitorNameTap;
  final VoidCallback? onLocalScoreTap;
  final VoidCallback? onLocalScoreLongPress;
  final VoidCallback? onVisitorScoreTap;
  final VoidCallback? onVisitorScoreLongPress;

  const ScoreboardWidget({
    super.key,
    required this.localName,
    required this.visitorName,
    required this.localPoints,
    required this.visitorPoints,
    required this.localSets,
    required this.visitorSets,
    required this.currentSet,
    required this.isActive,
    this.onLocalNameTap,
    this.onVisitorNameTap,
    this.onLocalScoreTap,
    this.onLocalScoreLongPress,
    this.onVisitorScoreTap,
    this.onVisitorScoreLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _team(
                name: localName,
                points: localPoints,
                sets: localSets,
                onNameTap: onLocalNameTap,
                onScoreTap: onLocalScoreTap,
                onScoreLongPress: onLocalScoreLongPress,
              ),
              _team(
                name: visitorName,
                points: visitorPoints,
                sets: visitorSets,
                onNameTap: onVisitorNameTap,
                onScoreTap: onVisitorScoreTap,
                onScoreLongPress: onVisitorScoreLongPress,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SET $currentSet',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                if (!isActive)
                  const Text(' · PAUSADO', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _team({
    required String name,
    required int points,
    required int sets,
    required VoidCallback? onNameTap,
    required VoidCallback? onScoreTap,
    VoidCallback? onScoreLongPress,
  }) {
    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: onNameTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.edit, color: Colors.white24, size: 10),
              ],
            ),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: onScoreTap,
            onLongPress: onScoreLongPress,
            child: Text(
              '$points',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
                height: 1.0,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final filled = index < sets;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: filled ? AppColors.primary : Colors.white38,
                    width: 2,
                  ),
                  color: filled ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
