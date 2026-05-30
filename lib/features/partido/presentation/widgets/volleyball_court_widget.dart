import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
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
        color: AppColors.surface,
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
                        _buildZoneLabels(constraints),
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
      case 0: return Offset(w * 0.12, h * 0.07);
      case 1: return Offset(w * 0.5 - 22, h * 0.07);
      case 2: return Offset(w * 0.75, h * 0.07);
      case 3: return Offset(w * 0.12, h * 0.62);
      case 4: return Offset(w * 0.5 - 22, h * 0.78);
      case 5: return Offset(w * 0.75, h * 0.62);
      default: return Offset.zero;
    }
  }

  Widget _buildZoneLabels(BoxConstraints c) {
    final w = c.maxWidth;
    final h = c.maxHeight;
    return Stack(
      children: [
        Positioned(left: w * 0.5 - 16, top: h * 0.5 - 10,
          child: const Text('RED', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        Positioned(left: 4, top: h * 0.2,
          child: const Text('Z4', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
        Positioned(left: w * 0.5 - 8, top: h * 0.2,
          child: const Text('Z3', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
        Positioned(right: 4, top: h * 0.2,
          child: const Text('Z2', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
        Positioned(left: 4, bottom: h * 0.2,
          child: const Text('Z5', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
        Positioned(left: w * 0.5 - 8, bottom: h * 0.2,
          child: const Text('Z6', style: TextStyle(color: Colors.white10, fontSize: 9)),
        ),
        Positioned(right: 4, bottom: h * 0.2,
          child: const Text('Z1', style: TextStyle(color: Colors.white10, fontSize: 9)),
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
        title: Text('Zona ${_zoneLabel(widget.index)} · #${widget.player.numero}',
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: _numeroCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Número de camiseta',
            labelStyle: const TextStyle(color: Colors.white54),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              final n = int.tryParse(_numeroCtrl.text.trim());
              if (n != null) widget.onNumeroEdit?.call(widget.index, n);
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
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
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
  const _CourtPainter();

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
