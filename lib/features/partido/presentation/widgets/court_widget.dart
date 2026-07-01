import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/court_state.dart';
import 'court_painter.dart';

class CourtWidget extends StatelessWidget {
  final CourtState state;
  final ValueChanged<int>? onZoneTap;
  final ValueChanged<int>? onZoneLongPress;
  final VoidCallback? onTogglePerspective;
  final int? selectedZone;
  final List<Player>? players;

  const CourtWidget({
    super.key,
    required this.state,
    this.onZoneTap,
    this.onZoneLongPress,
    this.onTogglePerspective,
    this.selectedZone,
    this.players,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onTogglePerspective != null) _buildToggleBar(),
            _buildCourtBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          GestureDetector(
            onTap: onTogglePerspective,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, size: 14, color: Colors.white38),
                  SizedBox(width: 4),
                  Text(
                    'Cambiar lado',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight > 0
            ? constraints.maxHeight
            : w * 0.75;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: CourtPainter(
                      courtColor: AppColors.surface,
                      lineColor: Colors.white.withValues(alpha: 0.20),
                      netColor: Colors.white.withValues(alpha: 0.40),
                      attackLineColor: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              ),
              for (final zone in state.zones)
                _buildZone(zone, w, h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZone(CourtZone zone, double w, double h) {
    final visualPos = state.visualPositionForZone(zone.zoneNumber);
    final pos = _zoneRect(visualPos, w, h);
    final isSelected = selectedZone == zone.zoneNumber;

    return Positioned(
      left: pos.left,
      top: pos.top,
      width: pos.width,
      height: pos.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onZoneTap?.call(zone.zoneNumber),
          onLongPress: zone.hasAthlete
              ? () => onZoneLongPress?.call(zone.zoneNumber)
              : null,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withValues(alpha: 0.06),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : zone.hasAthlete
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.accent
                    : zone.zoneNumber == 1
                        ? AppColors.accent.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: zone.hasAthlete ? 0.10 : 0.05),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: zone.hasAthlete
                ? _buildAthleteContent(zone)
                : _buildEmptyZone(zone),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyZone(CourtZone zone) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.2),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.add, color: AppColors.accent, size: 18),
          ),
          const SizedBox(height: 2),
          Text(
            '${zone.zoneNumber}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.20),
              fontSize: 11,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteContent(CourtZone zone) {
    final player = _playerForNumber(zone.athleteNumber);
    final displayName = player != null
        ? NameFormatter.courtName(player)
        : '#${zone.athleteNumber}';
    final isServer = zone.zoneNumber == 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isServer)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
              child: Icon(
                Icons.sports_volleyball,
                size: 12,
                color: AppColors.accent,
              ),
            ),
          ),
        Text(
          '${zone.athleteNumber}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
        Text(
          displayName,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        if (zone.isLibero)
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'LIB',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  Player? _playerForNumber(int? number) {
    if (number == null || players == null) return null;
    try {
      return players!.firstWhere((p) => p.numero == number);
    } catch (_) {
      return null;
    }
  }

  _ZoneRect _zoneRect(int visualPos, double w, double h) {
    const margin = 12.0;
    final col = visualPos % 3;
    final row = visualPos < 3 ? 0 : 1;
    final zoneW = (w - margin * 2) / 3;
    final zoneH = (h - margin * 2) / 2;
    return _ZoneRect(
      left: margin + col * zoneW,
      top: margin + row * zoneH,
      width: zoneW,
      height: zoneH,
    );
  }
}

class _ZoneRect {
  final double left;
  final double top;
  final double width;
  final double height;
  const _ZoneRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
