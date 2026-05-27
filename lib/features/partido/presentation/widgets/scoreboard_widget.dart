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
  final int totalSets;
  final bool isActive;
  final bool isFinalized;
  final List<MapEntry<int, int>> setScores;
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
    required this.totalSets,
    required this.isActive,
    required this.setScores,
    this.isFinalized = false,
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
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
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
          _buildSetRow(),
          const SizedBox(height: 8),
          _buildTeamRow(
            name: localName,
            points: localPoints,
            sets: localSets,
            color: AppColors.accent,
            onNameTap: onLocalNameTap,
            onScoreTap: onLocalScoreTap,
            onScoreLongPress: onLocalScoreLongPress,
          ),
          const SizedBox(height: 4),
          _buildTeamRow(
            name: visitorName,
            points: visitorPoints,
            sets: visitorSets,
            color: AppColors.primary,
            onNameTap: onVisitorNameTap,
            onScoreTap: onVisitorScoreTap,
            onScoreLongPress: onVisitorScoreLongPress,
          ),
          const SizedBox(height: 6),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildSetRow() {
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 4),
      child: Row(
        children: [
          for (int i = 0; i < totalSets; i++)
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  decoration: BoxDecoration(
                    color: (i + 1) == currentSet && isActive
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'S${i + 1}',
                    style: TextStyle(
                      color: (i + 1) == currentSet && isActive
                          ? AppColors.accent
                          : Colors.white38,
                      fontSize: 9,
                      fontWeight: (i + 1) == currentSet
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 36,
            child: Text(
              'TOT',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required String name,
    required int points,
    required int sets,
    required Color color,
    required VoidCallback? onNameTap,
    required VoidCallback? onScoreTap,
    VoidCallback? onScoreLongPress,
  }) {
    final total = setScores.fold(
      0,
      (int s, e) => s + (name == localName ? e.key : e.value),
    );

    return Row(
      children: [
        SizedBox(
          width: 68,
          child: GestureDetector(
            onTap: onNameTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.edit, color: Colors.white24, size: 8),
              ],
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              for (int i = 0; i < totalSets; i++)
                Expanded(
                  child: _SetScoreCell(
                    score: i < setScores.length
                        ? (name == localName
                            ? setScores[i].key
                            : setScores[i].value)
                        : null,
                    isCurrentSet: (i + 1) == currentSet && isActive,
                    isComplete: i < setScores.length &&
                        (i + 1) < currentSet,
                    isLocal: name == localName,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$total',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (name == localName) ...[
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onScoreTap,
            onLongPress: onScoreLongPress,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color.withValues(alpha: 0.2) : Colors.white10,
              ),
              child: Center(
                child: Text(
                  '$points',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isActive ? color : Colors.white24,
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onScoreTap,
            onLongPress: onScoreLongPress,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color.withValues(alpha: 0.2) : Colors.white10,
              ),
              child: Center(
                child: Text(
                  '$points',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isActive ? color : Colors.white24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: isFinalized
                ? Colors.green.withValues(alpha: 0.15)
                : isActive
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : Colors.white10,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isFinalized
                ? 'FINALIZADO'
                : isActive
                    ? 'SET $currentSet · $localSets - $visitorSets'
                    : 'PAUSADO',
            style: TextStyle(
              color: isFinalized
                  ? Colors.green
                  : isActive
                      ? AppColors.accent
                      : Colors.redAccent,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _SetScoreCell extends StatelessWidget {
  final int? score;
  final bool isCurrentSet;
  final bool isComplete;
  final bool isLocal;

  const _SetScoreCell({
    this.score,
    required this.isCurrentSet,
    required this.isComplete,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null;
    final displayScore = hasScore ? '$score' : '-';
    final wonSet = isComplete && hasScore;
    final showHighlight = isCurrentSet || wonSet;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: BoxDecoration(
          color: showHighlight
              ? (wonSet
                  ? (isLocal
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : AppColors.primary.withValues(alpha: 0.08))
                  : Colors.white.withValues(alpha: 0.05))
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          displayScore,
          style: TextStyle(
            color: wonSet
                ? (isLocal ? AppColors.accent : AppColors.primary)
                : isCurrentSet
                    ? Colors.white
                    : Colors.white38,
            fontSize: 13,
            fontWeight: wonSet
                ? FontWeight.w900
                : isCurrentSet
                    ? FontWeight.bold
                    : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
