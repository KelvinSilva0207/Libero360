import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
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
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit, color: Colors.white24, size: 12),
              ],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onScoreTap,
            onLongPress: onScoreLongPress,
            child: Text(
              '$points',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF8C00),
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final filled = index < sets;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: filled ? const Color(0xFF0081CF) : Colors.white38,
                    width: 2,
                  ),
                  color: filled ? const Color(0xFF0081CF).withOpacity(0.5) : Colors.transparent,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
