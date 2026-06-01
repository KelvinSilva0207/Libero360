import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';

class FullCourtWidget extends StatelessWidget {
  final List<Player> jugadoresLocal;
  final List<Player> jugadoresVisitante;
  final int rotacionLocal;
  final int rotacionVisitante;
  final bool isLocalServing;
  final VoidCallback? onRotarLocal;
  final VoidCallback? onRotarVisitante;
  final VoidCallback? onCambiarServicio;
  final void Function(int index, int numero)? onNumeroEditLocal;
  final void Function(int index, int numero)? onNumeroEditVisitante;

  const FullCourtWidget({
    super.key,
    required this.jugadoresLocal,
    required this.jugadoresVisitante,
    this.rotacionLocal = 0,
    this.rotacionVisitante = 0,
    this.isLocalServing = true,
    this.onRotarLocal,
    this.onRotarVisitante,
    this.onCambiarServicio,
    this.onNumeroEditLocal,
    this.onNumeroEditVisitante,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.white24, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            AspectRatio(
              aspectRatio: 16 / 12,
              child: CustomPaint(
                painter: _FullCourtPainter(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        _buildPlayers(esLocal: false, constraints: constraints),
                        _buildPlayers(esLocal: true, constraints: constraints),
                      ],
                    );
                  },
                ),
              ),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.black26,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isLocalServing ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLocalServing ? Icons.volunteer_activism : Icons.sports_volleyball,
                  size: 12,
                  color: isLocalServing ? Colors.green : Colors.white38,
                ),
                const SizedBox(width: 4),
                Text(
                  isLocalServing ? 'SACANDO' : 'RECIBE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isLocalServing ? Colors.green : Colors.white38,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'CANCHA COMPLETA',
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Colors.black26,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.rotate_left, size: 16, color: Colors.white54),
            onPressed: onRotarLocal,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Rotar local',
          ),
          Text('LOCAL', style: TextStyle(color: AppColors.accent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(width: 16),
          if (onCambiarServicio != null)
            TextButton.icon(
              onPressed: onCambiarServicio,
              icon: Icon(Icons.swap_horiz, size: 12, color: isLocalServing ? Colors.green : Colors.white38),
              label: Text(
                isLocalServing ? 'Quitar saque' : 'Dar saque',
                style: TextStyle(fontSize: 9, color: isLocalServing ? Colors.green : Colors.white38),
              ),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
            ),
          const SizedBox(width: 16),
          Text('VISIT', style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
          IconButton(
            icon: const Icon(Icons.rotate_right, size: 16, color: Colors.white54),
            onPressed: onRotarVisitante,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Rotar visitante',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayers({required bool esLocal, required BoxConstraints constraints}) {
    final jugadores = esLocal ? jugadoresLocal : jugadoresVisitante;
    final rotacion = esLocal ? rotacionLocal : rotacionVisitante;
    if (jugadores.length < 6) return const SizedBox.shrink();

    return Stack(
      children: [
        for (int i = 0; i < 6; i++)
          Positioned(
            left: _posX(esLocal, _servingOrderToDisplay(i, rotacion), constraints),
            top: _posY(esLocal, _servingOrderToDisplay(i, rotacion), constraints),
            child: _MiniAvatar(
              player: jugadores[i],
              isServer: esLocal == true && isLocalServing && i == 0,
              isLocal: esLocal,
            ),
          ),
      ],
    );
  }

  int _servingOrderToDisplay(int servingIdx, int rotacion) {
    const baseMapping = [5, 2, 1, 0, 3, 4];
    const rotPerm = [1, 2, 5, 0, 3, 4];
    int pos = baseMapping[servingIdx];
    for (int r = 0; r < rotacion; r++) {
      pos = rotPerm[pos];
    }
    return pos;
  }

  double _posX(bool esLocal, int displayIdx, BoxConstraints c) {
    final w = c.maxWidth;
    final col = displayIdx % 3;
    switch (col) {
      case 0: return w * 0.08;
      case 1: return w * 0.40;
      case 2: return w * 0.72;
      default: return 0;
    }
  }

  double _posY(bool esLocal, int displayIdx, BoxConstraints c) {
    final h = c.maxHeight;
    final row = displayIdx < 3 ? 0 : 1;
    const teamOffset = 0.03;
    if (esLocal) {
      return h * (0.55 + row * 0.15 + teamOffset);
    } else {
      return h * (teamOffset + row * 0.15);
    }
  }
}

class _MiniAvatar extends StatelessWidget {
  final Player player;
  final bool isServer;
  final bool isLocal;

  const _MiniAvatar({
    required this.player,
    required this.isServer,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLocal ? AppColors.accent : AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Text(
                '${player.numero ?? "?"}',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 11),
              ),
            ),
            if (isServer)
              Positioned(
                top: -3, right: -3,
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                  child: const Icon(Icons.sports_volleyball, size: 7, color: Colors.white),
                ),
              ),
          ],
        ),
        Text(
          _posShort(player.posicion),
          style: TextStyle(fontSize: 7, color: Colors.white38, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _posShort(Posicion p) {
    switch (p) {
      case Posicion.colocador: return 'ARM';
      case Posicion.opuesto: return 'OP';
      case Posicion.central: return 'CTR';
      case Posicion.receptor: return 'PUN';
      case Posicion.libre: return 'LIB';
      case Posicion.sinDefinir: return '—';
    }
  }
}

class _FullCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = AppColors.background);

    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final faintPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    canvas.drawRect(Rect.fromLTWH(1, 1, w - 2, h - 2), linePaint);

    final netY = h / 2;
    canvas.drawLine(Offset(0, netY), Offset(w, netY), linePaint);

    canvas.drawLine(Offset(0, h * 0.22), Offset(w, h * 0.22), faintPaint);
    canvas.drawLine(Offset(0, h * 0.78), Offset(w, h * 0.78), faintPaint);

    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h * 0.5), faintPaint);
    canvas.drawLine(Offset(w / 2, h * 0.5), Offset(w / 2, h), faintPaint);

    final netPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, netY), Offset(w, netY), netPaint);

    for (double x = 8; x < w - 8; x += 14) {
      canvas.drawLine(Offset(x, netY - 5), Offset(x + 7, netY - 5), Paint()..color = Colors.white10);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
