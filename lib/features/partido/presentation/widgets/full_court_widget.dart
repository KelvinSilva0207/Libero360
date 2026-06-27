import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../estadisticas/data/models/models.dart';

class FullCourtWidget extends StatefulWidget {
  final List<Player> jugadoresLocal;
  final List<Player> jugadoresVisitante;
  final int rotacionLocal;
  final int rotacionVisitante;
  final bool isLocalServing;
  final VoidCallback? onRotarLocal;
  final VoidCallback? onRotarVisitante;
  final VoidCallback? onCambiarServicio;
  final void Function(int index1, int index2, bool esLocal)? onSwapPlayers;
  final bool interactive;

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
    this.onSwapPlayers,
    this.interactive = false,
  });

  @override
  State<FullCourtWidget> createState() => _FullCourtWidgetState();
}

class _FullCourtWidgetState extends State<FullCourtWidget> {
  int? _selectedLocal;
  int? _selectedVisitante;

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
                painter: _MatchCourtPainter(),
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

  void _selectPlayer(int index, bool esLocal) {
    if (!widget.interactive) return;
    setState(() {
      if (esLocal) {
        if (_selectedLocal == null) {
          _selectedLocal = index;
        } else if (_selectedLocal == index) {
          _selectedLocal = null;
        } else {
          widget.onSwapPlayers?.call(_selectedLocal!, index, true);
          _selectedLocal = null;
        }
      } else {
        if (_selectedVisitante == null) {
          _selectedVisitante = index;
        } else if (_selectedVisitante == index) {
          _selectedVisitante = null;
        } else {
          widget.onSwapPlayers?.call(_selectedVisitante!, index, false);
          _selectedVisitante = null;
        }
      }
    });
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
              color: widget.isLocalServing ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isLocalServing ? Icons.volunteer_activism : Icons.sports_volleyball,
                  size: 12,
                  color: widget.isLocalServing ? Colors.green : Colors.white38,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isLocalServing ? 'SACANDO' : 'RECIBE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: widget.isLocalServing ? Colors.green : Colors.white38,
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
            onPressed: widget.onRotarLocal,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Rotar local',
          ),
          Text('LOCAL', style: TextStyle(color: AppColors.accent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(width: 16),
          if (widget.onCambiarServicio != null)
            TextButton.icon(
              onPressed: widget.onCambiarServicio,
              icon: Icon(Icons.swap_horiz, size: 12, color: widget.isLocalServing ? Colors.green : Colors.white38),
              label: Text(
                widget.isLocalServing ? 'Quitar saque' : 'Dar saque',
                style: TextStyle(fontSize: 9, color: widget.isLocalServing ? Colors.green : Colors.white38),
              ),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
            ),
          const SizedBox(width: 16),
          Text('VISIT', style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
          IconButton(
            icon: const Icon(Icons.rotate_right, size: 16, color: Colors.white54),
            onPressed: widget.onRotarVisitante,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Rotar visitante',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayers({required bool esLocal, required BoxConstraints constraints}) {
    final jugadores = esLocal ? widget.jugadoresLocal : widget.jugadoresVisitante;
    final rotacion = esLocal ? widget.rotacionLocal : widget.rotacionVisitante;
    final selected = esLocal ? _selectedLocal : _selectedVisitante;
    if (jugadores.length < 6) return const SizedBox.shrink();

    return Stack(
      children: [
        for (int i = 0; i < 6; i++)
          Positioned(
            left: _posX(esLocal, _servingOrderToDisplay(i, rotacion), constraints),
            top: _posY(esLocal, _servingOrderToDisplay(i, rotacion), constraints),
            child: GestureDetector(
              onTap: () => _selectPlayer(i, esLocal),
              child: _MiniAvatar(
                player: jugadores[i],
                isServer: esLocal == true && widget.isLocalServing && i == 0,
                isLocal: esLocal,
                isSelected: selected == i,
              ),
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
  final bool isSelected;

  const _MiniAvatar({
    required this.player,
    required this.isServer,
    required this.isLocal,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLocal ? AppColors.accent : AppColors.primary;
    return AnimatedScale(
      scale: isSelected ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: isSelected ? 16 : 14,
                backgroundColor: isSelected ? Colors.white : color,
                child: CircleAvatar(
                  radius: isSelected ? 13 : 11,
                  backgroundColor: color,
                  child: Text(
                    '${player.numero ?? "?"}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 11),
                  ),
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
            NameFormatter.playerMatchName(player),
            style: TextStyle(fontSize: 7, color: isSelected ? Colors.white : Colors.white38, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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

class _MatchCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF1A1A2E));

    final linePaint = Paint()
      ..color = const Color(0x3DFFFFFF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final faintPaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 1;

    canvas.drawRect(Rect.fromLTWH(1, 1, w - 2, h - 2), linePaint);

    final netY = h / 2;
    canvas.drawLine(Offset(0, netY), Offset(w, netY), linePaint);

    canvas.drawLine(Offset(0, h * 0.22), Offset(w, h * 0.22), faintPaint);
    canvas.drawLine(Offset(0, h * 0.78), Offset(w, h * 0.78), faintPaint);

    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h * 0.5), faintPaint);
    canvas.drawLine(Offset(w / 2, h * 0.5), Offset(w / 2, h), faintPaint);

    final netPaint = Paint()
      ..color = const Color(0x61FFFFFF)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, netY), Offset(w, netY), netPaint);

    for (double x = 8; x < w - 8; x += 14) {
      canvas.drawLine(
        Offset(x, netY - 5),
        Offset(x + 7, netY - 5),
        Paint()..color = const Color(0x1AFFFFFF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

