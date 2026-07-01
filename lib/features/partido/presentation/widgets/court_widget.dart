import 'package:flutter/material.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/court_state.dart';
import 'court_painter.dart';

class CourtWidget extends StatefulWidget {
  final CourtState state;
  final ValueChanged<int>? onZoneTap;
  final ValueChanged<int>? onZoneLongPress;
  final void Function(int fromZone, int toZone)? onZoneDragAccept;
  final VoidCallback? onTogglePerspective;
  final int? selectedZone;
  final int? captainNumber;
  final List<Player>? players;
  final bool readOnly;

  const CourtWidget({
    super.key,
    required this.state,
    this.onZoneTap,
    this.onZoneLongPress,
    this.onZoneDragAccept,
    this.onTogglePerspective,
    this.selectedZone,
    this.captainNumber,
    this.players,
    this.readOnly = false,
  });

  @override
  State<CourtWidget> createState() => _CourtWidgetState();
}

class _CourtWidgetState extends State<CourtWidget> {
  int? _dragSourceZone;
  int? _targetHoverZone;
  int? _dragFromZone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.15),
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
            if (widget.onTogglePerspective != null) _buildToggleBar(cs),
            _buildCourtBody(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          GestureDetector(
            onTap: widget.onTogglePerspective,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, size: 14, color: cs.onSurface.withValues(alpha: 0.38)),
                  const SizedBox(width: 4),
                  Text(
                    'Cambiar lado',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.54),
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

  Widget _buildCourtBody(ColorScheme cs) {
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
                      courtColor: cs.surface,
                      lineColor: cs.onSurface.withValues(alpha: 0.20),
                      netColor: cs.onSurface.withValues(alpha: 0.40),
                      attackLineColor: cs.onSurface.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              ),
              for (final zone in widget.state.zones)
                _buildZone(zone, w, h, cs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZone(CourtZone zone, double w, double h, ColorScheme cs) {
    final visualPos = widget.state.visualPositionForZone(zone.zoneNumber);
    final pos = _zoneRect(visualPos, w, h);
    final isSelected = widget.selectedZone == zone.zoneNumber;
    final isBeingDragged = _dragSourceZone == zone.zoneNumber;
    final isDragTarget = _targetHoverZone == zone.zoneNumber;
    final isCaptain = widget.captainNumber != null &&
        zone.athleteNumber == widget.captainNumber;

    final zoneColor = isSelected
        ? cs.primary.withValues(alpha: 0.20)
        : isDragTarget
            ? cs.tertiary.withValues(alpha: 0.20)
            : zone.hasAthlete
                ? cs.onSurface.withValues(alpha: 0.06)
                : cs.onSurface.withValues(alpha: 0.02);

    final borderColor = isSelected
        ? cs.primary
        : isDragTarget
            ? cs.tertiary
            : zone.zoneNumber == 1
                ? cs.primary.withValues(alpha: 0.25)
                : cs.outline.withValues(alpha: zone.hasAthlete ? 0.20 : 0.10);

    return Positioned(
      left: pos.left,
      top: pos.top,
      width: pos.width,
      height: pos.height,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) {
          if (widget.readOnly) return false;
          setState(() => _targetHoverZone = zone.zoneNumber);
          return true;
        },
        onLeave: (_) {
          setState(() => _targetHoverZone = null);
        },
        onAcceptWithDetails: (_) {
          setState(() {
            _targetHoverZone = null;
            _dragSourceZone = null;
          });
          if (_dragFromZone != null && _dragFromZone != zone.zoneNumber) {
            widget.onZoneDragAccept?.call(_dragFromZone!, zone.zoneNumber);
          }
          _dragFromZone = null;
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return Material(
            color: Colors.transparent,
            child: zone.hasAthlete && !widget.readOnly
                ? LongPressDraggable<int>(
                    data: zone.zoneNumber,
                    onDragStarted: () {
                      setState(() {
                        _dragSourceZone = zone.zoneNumber;
                        _dragFromZone = zone.zoneNumber;
                      });
                    },
                    onDragEnd: (_) {
                      setState(() {
                        _dragSourceZone = null;
                        _dragFromZone = null;
                      });
                    },
                    onDraggableCanceled: (_, __) {
                      setState(() {
                        _dragSourceZone = null;
                        _dragFromZone = null;
                      });
                    },
                    feedback: _buildDragFeedback(zone, cs),
                    childWhenDragging: _buildZoneContent(
                      zone, cs, isSelected, false, false, isCaptain,
                      borderColor, zoneColor, isHovering,
                    ),
                    child: _buildZoneContent(
                      zone, cs, isSelected, isBeingDragged, false, isCaptain,
                      borderColor, zoneColor, isHovering,
                    ),
                  )
                : _buildZoneContent(
                    zone, cs, isSelected, false, false, isCaptain,
                    borderColor, zoneColor, isHovering,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildDragFeedback(CourtZone zone, ColorScheme cs) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.secondary, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${zone.athleteNumber}',
              style: TextStyle(
                color: cs.onSecondaryContainer,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Z${zone.zoneNumber}',
              style: TextStyle(
                color: cs.onSecondaryContainer.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneContent(
    CourtZone zone,
    ColorScheme cs,
    bool isSelected,
    bool isBeingDragged,
    bool isDragTarget,
    bool isCaptain,
    Color borderColor,
    Color zoneColor,
    bool isHovering,
  ) {
    final effectiveOpacity = isBeingDragged ? 0.4 : 1.0;

    return Opacity(
      opacity: effectiveOpacity,
      child: InkWell(
        onTap: widget.readOnly
            ? null
            : () => widget.onZoneTap?.call(zone.zoneNumber),
        onLongPress: zone.hasAthlete && !widget.readOnly
            ? () => widget.onZoneLongPress?.call(zone.zoneNumber)
            : null,
        borderRadius: BorderRadius.circular(10),
        splashColor: cs.onSurface.withValues(alpha: 0.06),
        highlightColor: cs.onSurface.withValues(alpha: 0.03),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: zoneColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHovering
                  ? cs.tertiary
                  : borderColor,
              width: isSelected || isHovering ? 2 : 1,
            ),
          ),
          child: zone.hasAthlete
              ? _buildAthleteContent(zone, cs, isCaptain)
              : _buildEmptyZone(zone, cs),
        ),
      ),
    );
  }

  Widget _buildEmptyZone(CourtZone zone, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.2),
              border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.add, color: cs.primary, size: 18),
          ),
          const SizedBox(height: 2),
          Text(
            '${zone.zoneNumber}',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.20),
              fontSize: 11,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteContent(CourtZone zone, ColorScheme cs, bool isCaptain) {
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
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.3),
              ),
              child: Icon(
                Icons.sports_volleyball,
                size: 12,
                color: cs.primary,
              ),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${zone.athleteNumber}',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            if (isCaptain) ...[
              const SizedBox(width: 3),
              Icon(Icons.star, size: 14, color: cs.tertiary),
            ],
          ],
        ),
        Text(
          displayName,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.7),
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
              color: cs.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'LIB',
              style: TextStyle(
                color: cs.primary,
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
    if (number == null || widget.players == null) return null;
    try {
      return widget.players!.firstWhere((p) => p.numero == number);
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
