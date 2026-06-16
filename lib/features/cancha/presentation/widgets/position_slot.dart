import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../data/court_models.dart';

class PositionSlot extends StatelessWidget {
  final int index;
  final PlayerAssignment? assignment;
  final bool isServing;
  final bool isBeingEdited;
  final VoidCallback onTap;
  final VoidCallback? onEditNumber;
  final VoidCallback? onRemove;

  const PositionSlot({
    super.key,
    required this.index,
    this.assignment,
    this.isServing = false,
    this.isBeingEdited = false,
    required this.onTap,
    this.onEditNumber,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (assignment == null) {
      return _buildEmptySlot(colors);
    }

    return _buildFilledSlot(context, colors);
  }

  Widget _buildEmptySlot(ColorScheme colors) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.onSurfaceVariant.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.add_rounded,
                size: 16,
                color: colors.onSurfaceVariant.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilledSlot(BuildContext context, ColorScheme colors) {
    final p = assignment!;
    final number = p.effectiveNumber;
    final name = p.displayName;
    final isLibero = p.player.posicion.index == 4;

    final slotSize = 62.0;
    final avatarColor = isLibero ? AppColors.accent : colors.primary;
    final glowColor = isServing
        ? const Color(0xFF22C55E)
        : (isLibero ? AppColors.accent : colors.primary);

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showActions(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: slotSize,
        height: slotSize + 20,
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: slotSize,
                  height: slotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: isServing ? 0.5 : 0.2),
                        blurRadius: isServing ? 16 : 8,
                        spreadRadius: isServing ? 4 : 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 31,
                    backgroundColor: avatarColor,
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                if (isServing)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF22C55E),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.volunteer_activism, size: 12, color: Colors.white),
                    ),
                  ),
                if (isBeingEdited)
                  Positioned(
                    bottom: 0,
                    right: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                      child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: slotSize + 8,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isServing ? const Color(0xFF22C55E) : colors.onSurface,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              if (assignment != null) ...[
                Text(
                  assignment!.player.nombre,
                  style: TextStyle(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${assignment!.effectiveNumber} · Posición ${index + 1}',
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  if (onEditNumber != null)
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Editar número',
                        onTap: () {
                          Navigator.pop(ctx);
                          onEditNumber!();
                        },
                        color: colors.primary,
                      ),
                    ),
                  if (onRemove != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.person_remove_rounded,
                        label: 'Quitar',
                        onTap: () {
                          Navigator.pop(ctx);
                          onRemove!();
                        },
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
