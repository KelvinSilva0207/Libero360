import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/court_state.dart';
import 'court_painter.dart';

class CourtWidget extends StatelessWidget {
  final CourtState state;
  final ValueChanged<int>? onZoneTap;
  final VoidCallback? onTogglePerspective;

  const CourtWidget({
    super.key,
    required this.state,
    this.onZoneTap,
    this.onTogglePerspective,
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
                _buildZoneBackground(zone, w, h),
              for (final zone in state.zones.where((z) => z.hasAthlete))
                _buildAthleteCircle(zone, w, h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoneBackground(CourtZone zone, double w, double h) {
    final visualPos = state.visualPositionForZone(zone.zoneNumber);
    final pos = _zoneRect(visualPos, w, h);

    return Positioned(
      left: pos.left,
      top: pos.top,
      width: pos.width,
      height: pos.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onZoneTap?.call(zone.zoneNumber),
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withValues(alpha: 0.06),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: zone.hasAthlete
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: zone.zoneNumber == 1
                    ? AppColors.accent.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: zone.hasAthlete ? 0.10 : 0.05),
              ),
            ),
            child: _buildEmptyZone(zone.zoneNumber),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyZone(int zoneNumber) {
    return Center(
      child: Text(
        '$zoneNumber',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.20),
          fontSize: 28,
          fontWeight: FontWeight.w200,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildAthleteCircle(CourtZone zone, double w, double h) {
    final visualPos = state.visualPositionForZone(zone.zoneNumber);
    final pos = _zoneRect(visualPos, w, h);
    final isServer = zone.zoneNumber == 1;

    return AnimatedPositioned(
      key: ValueKey('athlete_${zone.athleteNumber}'),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: pos.left,
      top: pos.top,
      width: pos.width,
      height: pos.height,
      child: _AthleteContent(zone: zone, isServer: isServer),
    );
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

class _AthleteContent extends StatelessWidget {
  final CourtZone zone;
  final bool isServer;

  const _AthleteContent({required this.zone, required this.isServer});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isServer
              ? AppColors.accent.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
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
                  size: zone.athleteNumber != null ? 14 : 0,
                  color: AppColors.accent,
                ),
              ),
            ),
          Text(
            '${zone.athleteNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          if (zone.isLibero)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIB',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
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
