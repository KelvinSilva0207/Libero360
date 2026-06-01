import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';

class PlayerStatsDialog extends StatefulWidget {
  final Player player;
  final int matchId;
  final int setNumero;
  final int puntoLocal;
  final int puntoVisitante;
  final bool esEquipoLocal;

  const PlayerStatsDialog({
    super.key,
    required this.player,
    required this.matchId,
    required this.setNumero,
    required this.puntoLocal,
    required this.puntoVisitante,
    required this.esEquipoLocal,
  });

  @override
  State<PlayerStatsDialog> createState() => _PlayerStatsDialogState();
}

class _PlayerStatsDialogState extends State<PlayerStatsDialog> {
  final List<_StatAction> _actions = [
    _StatAction('Ataque', Icons.sports_kabaddi, 'ataque'),
    _StatAction('Defensa', Icons.shield, 'defensa'),
    _StatAction('Bloqueo', Icons.pan_tool, 'bloqueo'),
    _StatAction('Servicio', Icons.sports_volleyball, 'servicio'),
    _StatAction('Error', Icons.error_outline, 'error'),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: widget.esEquipoLocal ? AppColors.accent : AppColors.primary,
                  child: Text('${widget.player.numero ?? "?"}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.player.nombre,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.player.posicionLabel,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 12),
            const Text('REGISTRAR ACCIÓN',
              style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            ...(_actions.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StatRow(action: a),
            ))),
          ],
        ),
      ),
    );
  }
}

class _StatAction {
  final String label;
  final IconData icon;
  final String key;
  _StatAction(this.label, this.icon, this.key);
}

class _StatRow extends StatelessWidget {
  final _StatAction action;
  const _StatRow({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
            ),
            child: Center(
              child: Icon(action.icon, color: AppColors.accent, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(action.label,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          _StatBtn(icon: Icons.thumb_down_alt, color: Colors.redAccent, onTap: () {
            _registrar(context, action.key, false);
          }),
          const SizedBox(width: 6),
          _StatBtn(icon: Icons.thumb_up_alt, color: Colors.green, onTap: () {
            _registrar(context, action.key, true);
          }),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _registrar(BuildContext context, String tipo, bool positivo) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${positivo ? "+" : "-"} $tipo registrado'),
        backgroundColor: positivo ? Colors.green.shade800 : Colors.red.shade800,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _StatBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
