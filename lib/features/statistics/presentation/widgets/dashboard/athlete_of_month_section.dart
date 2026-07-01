import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/utils/name_formatter.dart';
import '../../../../estadisticas/data/models/models.dart';
import '../../../data/stats_dashboard_model.dart';

class AthleteOfMonthSection extends StatefulWidget {
  final AthleteOfMonthData? athlete;
  final bool isDark;
  final bool alreadyAnimated;
  final VoidCallback onAnimated;
  final VoidCallback onViewProfile;

  const AthleteOfMonthSection({
    super.key,
    required this.athlete,
    required this.isDark,
    this.alreadyAnimated = false,
    required this.onAnimated,
    required this.onViewProfile,
  });

  @override
  State<AthleteOfMonthSection> createState() => _AthleteOfMonthSectionState();
}

class _AthleteOfMonthSectionState extends State<AthleteOfMonthSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    if (!widget.alreadyAnimated && !_played) {
      _played = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ctrl.forward().then((_) {
          widget.onAnimated();
        });
      });
    }
  }

  @override
  void didUpdateWidget(AthleteOfMonthSection old) {
    super.didUpdateWidget(old);
    if (!widget.alreadyAnimated && !_played && !_ctrl.isCompleted) {
      _played = true;
      _ctrl.forward().then((_) {
        widget.onAnimated();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.athlete == null) {
      return _emptyState();
    }

    if (_ctrl.isCompleted || widget.alreadyAnimated) {
      return _buildCard();
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(scale: _scaleAnim, child: _buildCard()),
    );
  }

  Widget _buildCard() {
    final a = widget.athlete!;
    final p = a.player;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.04),
            (widget.isDark ? AppColors.surface : AppColors.lightCard),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),
          _playerInfo(p),
          const SizedBox(height: 16),
          _statsGrid(a),
          if (p.fotoUrl != null) ...[
            const SizedBox(height: 12),
            _teamPhoto(p),
          ],
          const SizedBox(height: 16),
          _viewProfileButton(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.onPrimary, size: 16),
              const SizedBox(width: 6),
              Text('ATLETA DEL MES',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
            ],
          ),
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.share_outlined, color: AppColors.accent, size: 18),
        ),
      ],
    );
  }

  Widget _playerInfo(Player p) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
          backgroundImage:
              p.fotoUrl != null ? NetworkImage(p.fotoUrl!) : null,
          child: p.fotoUrl == null
              ? Text(NameFormatter.avatarInitial(p),
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                NameFormatter.playerDisplayName(p),
                style: TextStyle(
                  color: widget.isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _infoChip(p.posicionLabel),
                  const SizedBox(width: 6),
                  _infoChip(p.numero != null ? '#${p.numero}' : ''),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.onPrimary, size: 18),
              const SizedBox(width: 4),
              Text('#1',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoChip(String text) {
    if (text.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (widget.isDark
                ? AppColors.textSecondary
                : AppColors.lightTextSecondary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: widget.isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 11)),
    );
  }

  Widget _statsGrid(AthleteOfMonthData a) {
    final bg = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.04);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.star, 'MVP', '${a.mvpCount}'),
          _statItem(Icons.sports_volleyball, 'Ataques', '${a.ataques}'),
          _statItem(Icons.pan_tool, 'Bloqueos', '${a.bloqueos}'),
          _statItem(Icons.sports_tennis, 'Servicios', '${a.servicios}'),
          _statItem(Icons.check_circle, 'Asist.', '${a.attendancePct.toStringAsFixed(0)}%'),
          _statItem(Icons.trending_up, 'Efic.', '${a.eficiencia.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              color: widget.isDark
                  ? AppColors.textPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            )),
        Text(label,
            style: TextStyle(
                color: widget.isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 9)),
      ],
    );
  }

  Widget _teamPhoto(Player p) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        p.fotoUrl!,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(),
      ),
    );
  }

  Widget _viewProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: widget.onViewProfile,
        icon: const Icon(Icons.person_search, size: 16),
        label: const Text('Ver perfil completo'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surface : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (widget.isDark ? AppColors.border : AppColors.lightBorder),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 48,
                color: (widget.isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary)
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Sin datos este mes',
                style: TextStyle(
                    color: widget.isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
