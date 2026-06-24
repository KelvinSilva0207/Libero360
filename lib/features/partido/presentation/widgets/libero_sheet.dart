import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';

class LiberoSheet extends StatelessWidget {
  final Player libero;
  final List<Player> courtPlayers;
  final ValueChanged<Player> onSwapIn;
  final VoidCallback onCancel;

  const LiberoSheet({
    super.key,
    required this.libero,
    required this.courtPlayers,
    required this.onSwapIn,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final name = libero.displayName.isNotEmpty
        ? libero.displayName
        : '${libero.firstNames} ${libero.lastNames}'.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _liberoAvatar(libero.numero ?? 0),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold,
                  )),
                  Row(
                    children: [
                      _libBadge(),
                      const SizedBox(width: 6),
                      Text(libero.posicionLabel,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.swap_vert, color: Colors.white38, size: 16),
              SizedBox(width: 8),
              Text('Cambiar por:',
                style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...courtPlayers.map((p) => _courtPlayerTile(p, context)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () { Navigator.of(context).pop(); onCancel(); },
            icon: const Icon(Icons.close, size: 16, color: Colors.white38),
            label: const Text('Cancelar', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _courtPlayerTile(Player p, BuildContext context) {
    final pName = p.displayName.isNotEmpty
        ? p.displayName
        : '${p.firstNames} ${p.lastNames}'.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () { Navigator.of(context).pop(); onSwapIn(p); },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  child: Text('${p.numero ?? '?'}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(pName,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _liberoAvatar(int number) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text('$number',
          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _libBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('LIB',
        style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
