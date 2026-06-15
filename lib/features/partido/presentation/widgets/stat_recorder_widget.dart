import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/match_event.dart';
import '../../../estadisticas/data/local_db/database_service.dart';

class StatRecorderWidget extends StatefulWidget {
  final int matchId;
  final int setNumero;
  final int rotacion;
  final String tipoPartido;
  final String? competenciaNombre;
  final List<Player> players;
  final VoidCallback? onEventRecorded;

  const StatRecorderWidget({
    super.key,
    required this.matchId,
    required this.setNumero,
    this.rotacion = 0,
    required this.tipoPartido,
    this.competenciaNombre,
    required this.players,
    this.onEventRecorded,
  });

  @override
  State<StatRecorderWidget> createState() => _StatRecorderWidgetState();
}

class _StatRecorderWidgetState extends State<StatRecorderWidget> {
  int? _selectedPlayerId;

  final List<_EventOption> _options = [
    _EventOption(EventType.winnerPoint, 'Ganador', '🔥', const Color(0xFF22C55E)),
    _EventOption(EventType.regularPoint, 'Regular', '✔', const Color(0xFF3B82F6)),
    _EventOption(EventType.error, 'Error', '✖', const Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              const Text('Registro de eventos',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('Rot: ${widget.rotacion + 1}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.players.map((p) => _buildPlayerChip(p)).toList(),
          ),
          if (_selectedPlayerId != null) ...[
            const SizedBox(height: 10),
            Row(
              children: _options.map((opt) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildEventButton(opt),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerChip(Player p) {
    final selected = _selectedPlayerId == p.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlayerId = selected ? null : p.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('${p.numero ?? "?"}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 6),
            Text(p.displayName.isNotEmpty ? p.displayName : p.nombre,
              style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventButton(_EventOption opt) {
    return GestureDetector(
      onTap: () => _recordEvent(opt.type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: opt.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: opt.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(opt.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(opt.label,
              style: TextStyle(color: opt.color, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _recordEvent(EventType type) async {
    if (_selectedPlayerId == null) return;
    try {
      final event = MatchEvent.create(
        athleteId: _selectedPlayerId!,
        matchId: widget.matchId,
        setNumero: widget.setNumero,
        eventType: type,
        tipoPartido: widget.tipoPartido,
        competenciaNombre: widget.competenciaNombre,
        rotacion: widget.rotacion,
      );
      await DatabaseService.instance.saveMatchEvent(event);
      setState(() => _selectedPlayerId = null);
      widget.onEventRecorded?.call();
    } catch (_) {}
  }
}

class _EventOption {
  final EventType type;
  final String label;
  final String emoji;
  final Color color;
  const _EventOption(this.type, this.label, this.emoji, this.color);
}
