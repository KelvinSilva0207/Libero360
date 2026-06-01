import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';

class VolleyballCourtWidget extends StatelessWidget {
  final List<Player> jugadores;
  final Player? seleccionado;
  final ValueChanged<Player> onSeleccionar;
  final bool esLocal;
  final int rotacion;
  final bool isServing;
  final VoidCallback? onRotar;
  final VoidCallback? onCambiarServicio;
  final void Function(int index, int numero)? onNumeroEdit;

  const VolleyballCourtWidget({
    super.key,
    required this.jugadores,
    required this.seleccionado,
    required this.onSeleccionar,
    this.esLocal = true,
    this.rotacion = 0,
    this.isServing = false,
    this.onRotar,
    this.onCambiarServicio,
    this.onNumeroEdit,
  });

  @override
  Widget build(BuildContext context) {
    final displayPlayers = jugadores.length >= 6 ? jugadores : <Player>[];

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
              aspectRatio: 16 / 10,
              child: CustomPaint(
                painter: _CourtPainter(esLocal: esLocal),
                child: displayPlayers.isEmpty
                    ? const Center(
                        child: Text('Selecciona 6 jugadores',
                            style: TextStyle(color: Colors.white38, fontSize: 13)),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              for (int i = 0; i < 6 && i < displayPlayers.length; i++)
                                Positioned(
                                  left: _posX(_servingOrderToDisplay(i), constraints),
                                  top: _posY(_servingOrderToDisplay(i), constraints),
                                  child: _PlayerAvatar(
                                    player: displayPlayers[i],
                                    posIndex: _servingOrderToDisplay(i),
                                    isSelected: displayPlayers[i].id == seleccionado?.id,
                                    isLibero: displayPlayers[i].posicion == Posicion.libre,
                                    isServer: isServing && i == 0,
                                    onTap: () => onSeleccionar(displayPlayers[i]),
                                    onNumeroEdit: onNumeroEdit,
                                  ),
                                ),
                              _buildZoneLabels(constraints),
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
              color: isServing ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isServing ? Icons.volunteer_activism : Icons.sports_volleyball,
                  size: 12,
                  color: isServing ? Colors.green : Colors.white38,
                ),
                const SizedBox(width: 4),
                Text(
                  isServing ? 'SACANDO' : 'RECIBE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isServing ? Colors.green : Colors.white38,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            esLocal ? 'LOCAL' : 'VISITANTE',
            style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
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
            icon: const Icon(Icons.rotate_left, size: 18, color: Colors.white54),
            onPressed: onRotar,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Rotar (sentido horario)',
          ),
          if (onCambiarServicio != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onCambiarServicio,
              icon: Icon(Icons.swap_horiz, size: 14, color: isServing ? Colors.green : Colors.white38),
              label: Text(
                isServing ? 'Quitar saque' : 'Dar saque',
                style: TextStyle(fontSize: 10, color: isServing ? Colors.green : Colors.white38),
              ),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
            ),
          ],
        ],
      ),
    );
  }

  int _servingOrderToDisplay(int servingIdx) {
    const baseMapping = [5, 2, 1, 0, 3, 4];
    const rotPerm = [1, 2, 5, 0, 3, 4];
    int pos = baseMapping[servingIdx];
    for (int r = 0; r < rotacion; r++) {
      pos = rotPerm[pos];
    }
    return pos;
  }

  double _posX(int displayIdx, BoxConstraints c) {
    final w = c.maxWidth;
    final col = displayIdx % 3;
    switch (col) {
      case 0: return w * 0.10;
      case 1: return w * 0.42;
      case 2: return w * 0.74;
      default: return 0;
    }
  }

  double _posY(int displayIdx, BoxConstraints c) {
    final h = c.maxHeight;
    final row = displayIdx < 3 ? 0 : 1;
    return row == 0 ? h * 0.06 : h * 0.56;
  }

  Widget _buildZoneLabels(BoxConstraints c) {
    final w = c.maxWidth;
    final h = c.maxHeight;
    return Stack(
      children: [
        Positioned(left: w * 0.50 - 10, top: h * 0.50 - 8,
          child: Text('NET', style: TextStyle(color: Colors.white.withValues(alpha: 0.12), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        Positioned(left: w * 0.05, top: h * 0.27,
          child: const Text('Z4', style: TextStyle(color: Colors.white10, fontSize: 8)),
        ),
        Positioned(left: w * 0.44, top: h * 0.27,
          child: const Text('Z3', style: TextStyle(color: Colors.white10, fontSize: 8)),
        ),
        Positioned(right: w * 0.05, top: h * 0.27,
          child: const Text('Z2', style: TextStyle(color: Colors.white10, fontSize: 8)),
        ),
        Positioned(left: w * 0.05, bottom: h * 0.27,
          child: const Text('Z5', style: TextStyle(color: Colors.white10, fontSize: 8)),
        ),
        Positioned(left: w * 0.44, bottom: h * 0.27,
          child: const Text('Z6', style: TextStyle(color: Colors.white10, fontSize: 8)),
        ),
        Positioned(right: w * 0.05, bottom: h * 0.27,
          child: const Text('Z1', style: TextStyle(color: Colors.white10, fontSize: 8)),
        ),
      ],
    );
  }
}

class _PlayerAvatar extends StatefulWidget {
  final Player player;
  final int posIndex;
  final bool isSelected;
  final bool isLibero;
  final bool isServer;
  final VoidCallback onTap;
  final void Function(int index, int numero)? onNumeroEdit;

  const _PlayerAvatar({
    required this.player,
    required this.posIndex,
    required this.isSelected,
    required this.isLibero,
    required this.isServer,
    required this.onTap,
    this.onNumeroEdit,
  });

  @override
  State<_PlayerAvatar> createState() => _PlayerAvatarState();
}

class _PlayerAvatarState extends State<_PlayerAvatar> {
  late TextEditingController _numeroCtrl;

  @override
  void initState() {
    super.initState();
    _numeroCtrl = TextEditingController(text: widget.player.numero?.toString() ?? '');
  }

  @override
  void didUpdateWidget(_PlayerAvatar old) {
    super.didUpdateWidget(old);
    if (old.player.numero != widget.player.numero) {
      _numeroCtrl.text = widget.player.numero?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    super.dispose();
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${_zoneLabel(widget.posIndex)} · #${widget.player.numero ?? "?"}',
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: _numeroCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Número de camiseta',
            labelStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              final n = int.tryParse(_numeroCtrl.text.trim());
              if (n != null) widget.onNumeroEdit?.call(widget.posIndex, n);
              Navigator.pop(ctx);
            },
            child: const Text('Asignar', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  String _zoneLabel(int index) {
    const labels = ['Z4', 'Z3', 'Z2', 'Z5', 'Z6', 'Z1'];
    return index < labels.length ? labels[index] : 'Z?';
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = widget.isLibero ? AppColors.accent : AppColors.primary;
    final glowColor = widget.isSelected
        ? AppColors.accent
        : (widget.isLibero ? AppColors.accent : AppColors.primary);

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onNumeroEdit != null ? _showEditDialog : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: widget.isSelected ? 0.6 : 0.3),
                      blurRadius: widget.isSelected ? 14 : 8,
                      spreadRadius: widget.isSelected ? 4 : 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: avatarColor,
                  child: Text(
                    '${widget.player.numero ?? "?"}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              if (widget.isServer)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                    child: const Icon(Icons.sports_volleyball, size: 10, color: Colors.white),
                  ),
                ),
              if (widget.isSelected)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                    child: const Icon(Icons.touch_app, size: 9, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _posShort(widget.player.posicion),
            style: TextStyle(
              fontSize: 8,
              color: widget.isSelected ? Colors.orange : Colors.white38,
              fontWeight: FontWeight.bold,
            ),
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

class _CourtPainter extends CustomPainter {
  final bool esLocal;

  const _CourtPainter({this.esLocal = true});

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

    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), linePaint);

    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), faintPaint);
    canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.75), faintPaint);

    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h / 2), faintPaint);
    canvas.drawLine(Offset(w / 2, h / 2), Offset(w / 2, h), faintPaint);

    final netPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), netPaint);

    for (double x = 8; x < w - 8; x += 14) {
      canvas.drawLine(Offset(x, h / 2 - 5), Offset(x + 7, h / 2 - 5), Paint()..color = Colors.white10);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
