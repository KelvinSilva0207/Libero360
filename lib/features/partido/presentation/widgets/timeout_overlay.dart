import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../controllers/match_controller.dart';

class TimeoutOverlay extends StatefulWidget {
  final int countdown;
  final int initialCountdown;
  final bool isLocal;
  final String teamName;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;
  final TimeoutState state;

  const TimeoutOverlay({
    super.key,
    required this.countdown,
    required this.initialCountdown,
    required this.isLocal,
    required this.teamName,
    required this.onCancel,
    required this.onDismiss,
    required this.state,
  });

  @override
  State<TimeoutOverlay> createState() => _TimeoutOverlayState();
}

class _TimeoutOverlayState extends State<TimeoutOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isLocal ? AppColors.accent : AppColors.primary;

    if (widget.state == TimeoutState.finished) {
      return _buildFinished(context, color);
    }

    return _buildCountdown(context, color);
  }

  Widget _buildCountdown(BuildContext context, Color color) {
    final progress = widget.initialCountdown > 0
        ? widget.countdown / widget.initialCountdown
        : 0.0;
    final isUrgent = widget.countdown <= 3;

    return GestureDetector(
      onTap: () {},
      child: Container(
        color: Colors.black87,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TIEMPO MUERTO',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.teamName,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => Transform.scale(
                scale: isUrgent ? _pulseAnim.value : 1.0,
                child: child,
              ),
              child: Text(
                '${widget.countdown}',
                style: TextStyle(
                  color: isUrgent ? Colors.redAccent : Colors.white,
                  fontSize: 96,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUrgent ? Colors.redAccent : color,
                  ),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close, size: 18, color: Colors.white54),
              label: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinished(BuildContext context, Color color) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black87,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: color, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Tiempo muerto finalizado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.teamName,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: widget.onDismiss,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Reanudar'),
            ),
          ],
        ),
      ),
    );
  }
}
