import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/utils/name_formatter.dart';
import '../../../data/stats_dashboard_model.dart';

class HallOfFameSection extends StatelessWidget {
  final List<HallOfFameEntry> entries;
  final bool isDark;

  const HallOfFameSection({
    super.key,
    required this.entries,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          _emptyState()
        else
          ...List.generate(entries.length, (i) => _rankRow(entries[i])),
      ],
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        Icon(Icons.leaderboard, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text('HALL OF FAME',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            )),
        const Spacer(),
        Text('TOP 10',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }

  Widget _rankRow(HallOfFameEntry entry) {
    final cs = Theme.of(context).colorScheme;
    final p = entry.player;
    final bg = cs.surfaceContainerHighest;
    final border = cs.outlineVariant;

    final medalColors = {
      1: AppColors.accent,
      2: cs.onSurfaceVariant,
      3: cs.tertiary,
    };
    final isMedal = medalColors.containsKey(entry.rank);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: entry.rank == 1
              ? AppColors.accent.withValues(alpha: 0.06)
              : bg,
          borderRadius: BorderRadius.circular(12),
          border: entry.rank == 1
              ? Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3), width: 1)
              : Border.all(color: border, width: 0.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: isMedal
                  ? Icon(Icons.emoji_events,
                      color: medalColors[entry.rank], size: 18)
                  : Text('${entry.rank}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              backgroundImage: p.fotoUrl != null
                  ? NetworkImage(p.fotoUrl!)
                  : null,
              child: p.fotoUrl == null
                  ? Text(
                      NameFormatter.avatarInitial(p),
                      style:
                          const TextStyle(color: AppColors.accent, fontSize: 12))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    NameFormatter.playerDisplayName(p),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(p.posicionLabel,
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 10)),
                      if (entry.mvpCount > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.star,
                            size: 10, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text('${entry.mvpCount}',
                            style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 10)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text('${entry.eficiencia.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: entry.eficiencia >= 50
                      ? AppColors.success
                      : AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.border : AppColors.lightBorder),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 40,
                color: (isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary)
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Aún no hay datos',
                style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
