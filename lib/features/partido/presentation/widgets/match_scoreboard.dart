import 'package:flutter/material.dart';

class MatchScoreBoard extends StatefulWidget {
  final int localScore;
  final int visitorScore;
  final int localSets;
  final int visitorSets;
  final bool isLocalServing;
  final int setActual;
  final int setsTotales;
  final String localName;
  final String visitorName;
  final VoidCallback? onIncrementLocal;
  final VoidCallback? onIncrementVisitor;
  final VoidCallback? onDecrementLocal;
  final VoidCallback? onDecrementVisitor;
  final bool readOnly;

  const MatchScoreBoard({
    super.key,
    this.localScore = 0,
    this.visitorScore = 0,
    this.localSets = 0,
    this.visitorSets = 0,
    this.isLocalServing = true,
    this.setActual = 1,
    this.setsTotales = 5,
    this.localName = 'Local',
    this.visitorName = 'Visitante',
    this.onIncrementLocal,
    this.onIncrementVisitor,
    this.onDecrementLocal,
    this.onDecrementVisitor,
    this.readOnly = false,
  });

  @override
  State<MatchScoreBoard> createState() => _MatchScoreBoardState();
}

class _MatchScoreBoardState extends State<MatchScoreBoard>
    with TickerProviderStateMixin {
  int _prevLocalScore = 0;
  int _prevVisitorScore = 0;
  int _prevLocalSets = 0;
  int _prevVisitorSets = 0;
  late AnimationController _localScoreAnimCtrl;
  late AnimationController _visitorScoreAnimCtrl;
  late AnimationController _setWinAnimCtrl;
  late AnimationController _servePulseCtrl;

  @override
  void initState() {
    super.initState();
    _prevLocalScore = widget.localScore;
    _prevVisitorScore = widget.visitorScore;
    _prevLocalSets = widget.localSets;
    _prevVisitorSets = widget.visitorSets;

    _localScoreAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _visitorScoreAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _setWinAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _servePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(MatchScoreBoard old) {
    super.didUpdateWidget(old);
    if (widget.localScore > old.localScore) {
      _prevLocalScore = old.localScore;
      _localScoreAnimCtrl.forward(from: 0);
    }
    if (widget.visitorScore > old.visitorScore) {
      _prevVisitorScore = old.visitorScore;
      _visitorScoreAnimCtrl.forward(from: 0);
    }
    if (widget.localSets > old.localSets) {
      _prevLocalSets = old.localSets;
      _setWinAnimCtrl.forward(from: 0);
    }
    if (widget.visitorSets > old.visitorSets) {
      _prevVisitorSets = old.visitorSets;
      _setWinAnimCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _localScoreAnimCtrl.dispose();
    _visitorScoreAnimCtrl.dispose();
    _setWinAnimCtrl.dispose();
    _servePulseCtrl.dispose();
    super.dispose();
  }

  bool get _isGolden => widget.setActual == widget.setsTotales && widget.setsTotales >= 3;
  int get _setsToShow => widget.setsTotales;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildScoreRow(cs),
          const SizedBox(height: 6),
          _buildSetRow(cs),
          if (_isGolden)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'SET DE ORO — 15 PUNTOS',
                  style: TextStyle(
                    color: cs.error,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(ColorScheme cs) {
    final localScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _localScoreAnimCtrl,
      curve: Curves.easeOutBack,
    ));

    final visitorScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _visitorScoreAnimCtrl,
      curve: Curves.easeOutBack,
    ));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTeamSide(cs, true, localScale)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'VS',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.25),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: _buildTeamSide(cs, false, visitorScale)),
      ],
    );
  }

  Widget _buildTeamSide(ColorScheme cs, bool isLocal, Animation<double> scaleAnim) {
    final score = isLocal ? widget.localScore : widget.visitorScore;
    final name = isLocal ? widget.localName : widget.visitorName;
    final isServing = isLocal ? widget.isLocalServing : !widget.isLocalServing;
    final color = isLocal ? cs.primary : cs.tertiary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isServing)
          AnimatedBuilder(
            animation: _servePulseCtrl,
            builder: (context, child) {
              return Opacity(
                opacity: 0.5 + _servePulseCtrl.value * 0.5,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.3 + _servePulseCtrl.value * 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_volleyball, size: 10, color: cs.primary),
                      const SizedBox(width: 3),
                      Text(
                        'SAQUE',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          const SizedBox(height: 20),
        Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        AnimatedBuilder(
          animation: scaleAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: scaleAnim.value,
              child: child,
            );
          },
          child: _buildScoreNumber(context, cs, score, color, isLocal),
        ),
      ],
    );
  }

  Widget _buildScoreNumber(BuildContext context, ColorScheme cs, int score, Color color, bool isLocal) {
    if (widget.readOnly) {
      return Text(
        '$score',
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 44,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isLocal ? widget.onDecrementLocal : widget.onDecrementVisitor,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.remove, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$score',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ),
        InkWell(
          onTap: isLocal ? widget.onIncrementLocal : widget.onIncrementVisitor,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.add, size: 16, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildSetRow(ColorScheme cs) {
    final setsNeeded = widget.setsTotales ~/ 2 + 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(setsNeeded, (i) {
          final setNum = i + 1;
          final won = widget.localSets > i;
          return _SetBadge(
            label: 'S$setNum',
            won: won,
            isGolden: _isGolden && setNum == widget.setsTotales,
            isActive: widget.setActual == setNum,
            animCtrl: won && _prevLocalSets > i ? _setWinAnimCtrl : null,
          );
        }),
        const SizedBox(width: 24),
        ...List.generate(setsNeeded, (i) {
          final setNum = i + 1;
          final won = widget.visitorSets > i;
          return _SetBadge(
            label: 'S$setNum',
            won: won,
            isGolden: _isGolden && setNum == widget.setsTotales,
            isActive: widget.setActual == setNum,
            animCtrl: won && _prevVisitorSets > i ? _setWinAnimCtrl : null,
          );
        }),
      ],
    );
  }
}

class _SetBadge extends StatelessWidget {
  final String label;
  final bool won;
  final bool isGolden;
  final bool isActive;
  final AnimationController? animCtrl;

  const _SetBadge({
    required this.label,
    required this.won,
    this.isGolden = false,
    this.isActive = false,
    this.animCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final baseColor = isGolden
        ? cs.error
        : cs.primary;
    final bgColor = won
        ? baseColor.withValues(alpha: 0.25)
        : cs.onSurface.withValues(alpha: 0.06);
    final fgColor = won
        ? baseColor
        : cs.onSurface.withValues(alpha: 0.25);
    final borderColor = isActive
        ? baseColor.withValues(alpha: 0.5)
        : won
            ? baseColor.withValues(alpha: 0.3)
            : cs.outline.withValues(alpha: 0.15);

    Widget badge = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: fgColor,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (animCtrl != null) {
      badge = AnimatedBuilder(
        animation: animCtrl!,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + animCtrl!.value * 0.3,
            child: Opacity(
              opacity: 0.7 + animCtrl!.value * 0.3,
              child: child,
            ),
          );
        },
        child: badge,
      );
    }

    return badge;
  }
}
