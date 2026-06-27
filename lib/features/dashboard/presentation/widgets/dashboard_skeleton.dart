import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class DashboardSkeleton extends StatefulWidget {
  final bool isDark;

  const DashboardSkeleton({super.key, required this.isDark});

  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Alignment> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _slide = Tween<Alignment>(
      begin: const Alignment(-1.5, 0),
      end: const Alignment(1.5, 0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _headerSkeleton(),
            const SizedBox(height: 20),
            _cardSkeleton(200),
            const SizedBox(height: 20),
            _cardSkeleton(180),
            const SizedBox(height: 20),
            _gridSkeleton(),
            const SizedBox(height: 20),
            _cardSkeleton(140),
          ],
        );
      },
    );
  }

  Widget _shimmer(double width, double height, {double radius = 12}) {
    final base = widget.isDark ? AppColors.surfaceLight : AppColors.lightBorder;
    final highlight = widget.isDark ? AppColors.border : AppColors.lightSurface;
    final dx = _slide.value.x;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [base, highlight, base],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(dx - 1.5, 0),
          end: Alignment(dx + 1.5, 0),
        ),
      ),
    );
  }

  Widget _headerSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(180, 16),
                const SizedBox(height: 8),
                _shimmer(120, 12),
              ],
            ),
            const Spacer(),
            _shimmer(36, 36, radius: 10),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _shimmer(56, 56, radius: 28),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(140, 18),
                const SizedBox(height: 4),
                _shimmer(100, 12),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardSkeleton(double height) {
    final bg = widget.isDark ? AppColors.surface : AppColors.lightCard;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmer(44, 44, radius: 14),
                const SizedBox(width: 14),
                _shimmer(140, 16),
              ],
            ),
            const Spacer(),
            _shimmer(double.infinity, 12),
            const SizedBox(height: 8),
            _shimmer(80, 12),
          ],
        ),
      ),
    );
  }

  Widget _gridSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmer(100, 12),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: List.generate(4, (_) => _cardSkeleton(80)),
        ),
      ],
    );
  }
}
