import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class RotationWidget extends StatefulWidget {
  final List<int> numeros;
  final int rotacion;
  final bool isServing;
  final bool interactive;
  final ValueChanged<int>? onRotate;
  final void Function(int posIndex)? onPositionTap;

  const RotationWidget({
    super.key,
    required this.numeros,
    this.rotacion = 0,
    this.isServing = false,
    this.interactive = false,
    this.onRotate,
    this.onPositionTap,
  });

  @override
  State<RotationWidget> createState() => _RotationWidgetState();
}

class _RotationWidgetState extends State<RotationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(RotationWidget old) {
    super.didUpdateWidget(old);
    if (old.rotacion != widget.rotacion) {
      _animCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positions = _getRotatedPositions();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: widget.isServing ? Colors.green.withValues(alpha: 0.15) : Colors.white10,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.volunteer_activism,
                size: 12,
                color: widget.isServing ? Colors.green : Colors.white38,
              ),
              const SizedBox(width: 4),
              Text(
                widget.isServing ? 'SACANDO' : 'RECIBE',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                  color: widget.isServing ? Colors.green : Colors.white38,
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _animCtrl,
          builder: (context, child) {
            return _buildCourt(positions);
          },
        ),
        if (widget.interactive && widget.onRotate != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () => widget.onRotate!(widget.rotacion),
              icon: const Icon(Icons.refresh, size: 14, color: AppColors.accent),
              label: const Text('Rotar', style: TextStyle(color: AppColors.accent, fontSize: 11)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ),
      ],
    );
  }

  List<int> _getRotatedPositions() {
    final base = List<int>.from(widget.numeros);
    while (base.length < 6) {
      base.add(0);
    }
    final rotated = List<int>.filled(6, 0);
    for (int i = 0; i < 6; i++) {
      rotated[(i + widget.rotacion) % 6] = base[i];
    }
    return rotated;
  }

  Widget _buildCourt(List<int> positions) {
    return Container(
      width: 150,
      height: 210,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surfaceLight,
      ),
      child: Column(
        children: [
          _buildRow(positions[2], positions[1], positions[0]),
          _buildDivider(),
          _buildRow(positions[3], positions[4], positions[5]),
          _buildNetLine(),
        ],
      ),
    );
  }

  Widget _buildRow(int left, int center, int right) {
    return Expanded(
      child: Row(
        children: [
          _buildPosition(left),
          _buildPosition(center),
          _buildPosition(right),
        ],
      ),
    );
  }

  Widget _buildPosition(int numero) {
    final isServer = widget.isServing && numero == widget.numeros.first;
    return Expanded(
      child: GestureDetector(
        onTap: numero > 0 ? () => widget.onPositionTap?.call(numero) : null,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isServer ? Colors.green.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isServer ? Colors.green : Colors.white12,
              width: isServer ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              numero > 0 ? '$numero' : '',
              style: TextStyle(
                color: isServer ? Colors.green : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 2,
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildNetLine() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
