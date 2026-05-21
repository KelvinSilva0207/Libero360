import 'package:flutter/material.dart';
import '../../../estadisticas/data/models/models.dart';

class VolleyballCourtWidget extends StatelessWidget {
  final List<Player> jugadores;
  final Player? seleccionado;
  final ValueChanged<Player> onSeleccionar;
  final bool esLocal;
  final void Function(int index, int numero)? onNumeroEdit;

  const VolleyballCourtWidget({
    super.key,
    required this.jugadores,
    required this.seleccionado,
    required this.onSeleccionar,
    this.esLocal = true,
    this.onNumeroEdit,
  });

  @override
  Widget build(BuildContext context) {
    final displayPlayers = jugadores.length >= 6 ? jugadores.take(6).toList() : <Player>[];

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border.all(color: Colors.white24, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: const _CourtPainter(),
          child: displayPlayers.isEmpty
              ? const Center(
                  child: Text('Sin jugadores', style: TextStyle(color: Colors.white38, fontSize: 14)),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        for (int i = 0; i < displayPlayers.length; i++)
                          Positioned(
                            left: _pos(i, constraints).dx,
                            top: _pos(i, constraints).dy,
                            child: _PlayerAvatar(
                              player: displayPlayers[i],
                              index: i,
                              isSelected: displayPlayers[i].id == seleccionado?.id,
                              isLibero: displayPlayers[i].posicion == Posicion.libre,
                              onTap: () => onSeleccionar(displayPlayers[i]),
                              onNumeroEdit: onNumeroEdit,
                            ),
                          ),
                        _buildPositionLabels(context, constraints),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Offset _pos(int index, BoxConstraints c) {
    final w = c.maxWidth;
    final h = c.maxHeight;
    switch (index) {
      case 0: return Offset(w * 0.5 - 22, h * 0.08);
      case 1: return Offset(w * 0.15 - 22, h * 0.35);
      case 2: return Offset(w * 0.85 - 22, h * 0.35);
      case 3: return Offset(w * 0.5 - 22, h * 0.62);
      case 4: return Offset(w * 0.15 - 22, h * 0.85);
      case 5: return Offset(w * 0.85 - 22, h * 0.85);
      default: return Offset.zero;
    }
  }

  Widget _buildPositionLabels(BuildContext context, BoxConstraints c) {
    final w = c.maxWidth;
    final h = c.maxHeight;
    return Stack(
      children: [
        Positioned(
          left: w * 0.5 - 16, top: h * 0.5 - 10,
          child: const Text('RED', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        Positioned(
          left: 4, top: h * 0.02,
          child: const Text('P1', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
        Positioned(
          left: 4, top: h * 0.22,
          child: const Text('P6', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
        Positioned(
          right: 4, top: h * 0.22,
          child: const Text('P5', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
        Positioned(
          left: 4, top: h * 0.72,
          child: const Text('P2', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
        Positioned(
          right: 4, top: h * 0.72,
          child: const Text('P4', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
        Positioned(
          left: w * 0.5 - 12, top: h * 0.92,
          child: const Text('P3', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
      ],
    );
  }
}

class _PlayerAvatar extends StatefulWidget {
  final Player player;
  final int index;
  final bool isSelected;
  final bool isLibero;
  final VoidCallback onTap;
  final void Function(int index, int numero)? onNumeroEdit;

  const _PlayerAvatar({
    required this.player,
    required this.index,
    required this.isSelected,
    required this.isLibero,
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
    _numeroCtrl = TextEditingController(text: '${widget.player.numero}');
  }

  @override
  void didUpdateWidget(_PlayerAvatar old) {
    super.didUpdateWidget(old);
    if (old.player.numero != widget.player.numero) {
      _numeroCtrl.text = '${widget.player.numero}';
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
        title: Text('Jugador #${widget.player.numero}'),
        content: TextField(
          controller: _numeroCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Número de camiseta',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final n = int.tryParse(_numeroCtrl.text.trim());
              if (n != null) {
                widget.onNumeroEdit?.call(widget.index, n);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = widget.isLibero ? const Color(0xFFFF8C00) : const Color(0xFF0081CF);
    final glowColor = widget.isSelected
        ? const Color(0xFFFF8C00)
        : (widget.isLibero ? const Color(0xFFFF8C00) : const Color(0xFF0081CF));

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onNumeroEdit != null ? _showEditDialog : null,
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
                      color: glowColor.withOpacity(widget.isSelected ? 0.6 : 0.3),
                      blurRadius: widget.isSelected ? 14 : 8,
                      spreadRadius: widget.isSelected ? 4 : 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: avatarColor,
                  child: Text(
                    '${widget.player.numero}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              if (widget.isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF8C00)),
                    child: const Icon(Icons.add, size: 10, color: Colors.white),
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
      case Posicion.colocador: return 'COL';
      case Posicion.opuesto: return 'OP';
      case Posicion.central: return 'CTR';
      case Posicion.receptor: return 'REC';
      case Posicion.libre: return 'LIB';
    }
  }
}

class _CourtPainter extends CustomPainter {
  const _CourtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF0F172A));

    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final faintPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    canvas.drawRect(Rect.fromLTWH(1, 1, w - 2, h - 2), linePaint);

    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), linePaint);

    canvas.drawLine(Offset(w * 0.25, h / 2), Offset(w * 0.25, h), faintPaint);
    canvas.drawLine(Offset(w * 0.75, h / 2), Offset(w * 0.75, h), faintPaint);
    canvas.drawLine(Offset(w * 0.25, 0), Offset(w * 0.25, h / 2), faintPaint);
    canvas.drawLine(Offset(w * 0.75, 0), Offset(w * 0.75, h / 2), faintPaint);

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
