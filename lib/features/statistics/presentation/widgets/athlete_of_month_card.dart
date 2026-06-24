import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/statistics_models.dart';

class AthleteOfMonthCard extends StatefulWidget {
  final AthleteRankingScore athlete;
  final bool isDark;

  const AthleteOfMonthCard({
    super.key,
    required this.athlete,
    required this.isDark,
  });

  @override
  State<AthleteOfMonthCard> createState() => _AthleteOfMonthCardState();
}

class _AthleteOfMonthCardState extends State<AthleteOfMonthCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.athlete;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        final glow = 0.1 + _glowAnim.value * 0.15;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: glow),
                AppColors.accent.withValues(alpha: glow * 0.6),
                (widget.isDark ? AppColors.surface : AppColors.lightCard),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(isDark: widget.isDark),
              const SizedBox(height: 16),
              _PlayerRow(athlete: a, isDark: widget.isDark),
              const SizedBox(height: 16),
              _StatsGrid(athlete: a, isDark: widget.isDark),
              const SizedBox(height: 16),
              _ScoreBar(score: a.score, isDark: widget.isDark),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: AppColors.accent, size: 16),
              SizedBox(width: 6),
              Text('ATLETA DEL MES',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  )),
            ],
          ),
        ),
        const Spacer(),
        Icon(Icons.share_outlined,
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            size: 20),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final AthleteRankingScore athlete;
  final bool isDark;

  const _PlayerRow({required this.athlete, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final p = athlete.player;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
          backgroundImage: p.fotoUrl != null ? NetworkImage(p.fotoUrl!) : null,
          child: p.fotoUrl == null
              ? Text(
                  p.nombre.isNotEmpty
                      ? p.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.displayName.isNotEmpty ? p.displayName : p.nombre,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 4),
              Row(
                children: [
                  _LabelChip(text: p.posicionLabel, isDark: isDark),
                  const SizedBox(width: 6),
                  if (p.numero != null)
                    _LabelChip(text: '#${p.numero}', isDark: isDark),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('#1', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String text;
  final bool isDark;

  const _LabelChip({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            fontSize: 11,
          )),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final AthleteRankingScore athlete;
  final bool isDark;

  const _StatsGrid({required this.athlete, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(label: 'Ataques', value: '${athlete.ataques}', icon: Icons.sports_volleyball),
      _StatItem(label: 'Bloqueos', value: '${athlete.bloqueos}', icon: Icons.pan_tool),
      _StatItem(label: 'Servicios', value: '${athlete.servicios}', icon: Icons.sports_tennis),
      _StatItem(label: 'Defensa', value: '${athlete.defensas}', icon: Icons.shield),
      _StatItem(label: 'Recepciones', value: '${athlete.recepciones}', icon: Icons.swap_horiz),
      _StatItem(label: 'MVP', value: '${athlete.mvpCount}', icon: Icons.star),
      _StatItem(label: 'Asistencia', value: '${athlete.attendancePct.toStringAsFixed(0)}%', icon: Icons.check_circle),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: items.map((item) => SizedBox(
          width: (MediaQuery.of(context).size.width - 72) / 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 16, color: AppColors.accent),
              const SizedBox(height: 4),
              Text(item.value,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    fontSize: 14, fontWeight: FontWeight.bold,
                  )),
              Text(item.label,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                    fontSize: 9,
                  )),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  _StatItem({required this.label, required this.value, required this.icon});
}

class _ScoreBar extends StatelessWidget {
  final double score;
  final bool isDark;

  const _ScoreBar({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('SCORE', style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2,
            )),
            const Spacer(),
            Text(score.toStringAsFixed(0),
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 20, fontWeight: FontWeight.bold,
                )),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 1000).clamp(0.0, 1.0),
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
