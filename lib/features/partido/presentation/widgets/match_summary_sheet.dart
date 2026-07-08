import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/models.dart';

class MatchSummarySheet extends StatefulWidget {
  final Match match;
  final VoidCallback? onDuplicate;
  final VoidCallback? onExport;

  const MatchSummarySheet({
    super.key,
    required this.match,
    this.onDuplicate,
    this.onExport,
  });

  @override
  State<MatchSummarySheet> createState() => _MatchSummarySheetState();
}

class _MatchSummarySheetState extends State<MatchSummarySheet> {
  Map<TipoAccion, int> _statistics = {};
  bool _loadingStats = true;

  static const _typeLabels = {
    TipoAccion.ataque: 'Ataques',
    TipoAccion.saque: 'Saques',
    TipoAccion.bloqueo: 'Bloqueos',
    TipoAccion.defensa: 'Defensas',
    TipoAccion.recepcion: 'Recepciones',
    TipoAccion.colocacion: 'Colocaciones',
    TipoAccion.errorContrario: 'Errores contrarios',
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DatabaseService.instance.countAllEventTypes(widget.match.id);
      if (mounted) setState(() { _statistics = stats; _loadingStats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = widget.match;
    final isWin = m.setsLocal > m.setsVisitante;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Center(
            child: Column(
              children: [
                Icon(
                  isWin ? Icons.emoji_events_rounded : Icons.sports_volleyball_rounded,
                  size: 28,
                  color: isWin ? cs.tertiary : cs.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  '${m.equipoLocal} vs ${m.equipoVisitante}',
                  style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  m.resultadoSets,
                  style: TextStyle(color: cs.primary, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isWin ? 'Ganó ${m.equipoLocal}' : 'Ganó ${m.equipoVisitante}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _divider(cs),
          const SizedBox(height: 12),
          // Details
          _detailRow(cs, Icons.calendar_today_rounded, DateFormat('dd/MM/yyyy HH:mm').format(m.fecha)),
          if (m.duracionSegundos > 0)
            _detailRow(cs, Icons.timer_outlined, _formatDuration(m.duracionSegundos)),
          if (m.competitionName != null && m.competitionName!.isNotEmpty)
            _detailRow(cs, Icons.emoji_events_outlined, m.competitionName!),
          if (m.lugar != null && m.lugar!.isNotEmpty)
            _detailRow(cs, Icons.location_on_outlined, m.lugar!),
          const SizedBox(height: 12),
          _divider(cs),
          const SizedBox(height: 12),
          // Statistics section
          Text('ESTADÍSTICAS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 8),
          if (_loadingStats)
            Row(
              children: [
                SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                ),
                const SizedBox(width: 8),
                Text('Cargando...', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          if (!_loadingStats && _statistics.isNotEmpty)
            ..._statistics.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(_typeLabels[e.key] ?? e.key.name,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  const Spacer(),
                  Text('${e.value}',
                      style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
          if (!_loadingStats && _statistics.isEmpty)
            Text('Sin estadísticas registradas',
                style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11)),
          const SizedBox(height: 16),
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () { Navigator.pop(context); widget.onDuplicate?.call(); },
                icon: Icon(Icons.copy_rounded, size: 16, color: cs.primary),
                label: Text('Duplicar', style: TextStyle(fontSize: 12, color: cs.primary)),
              ),
              TextButton.icon(
                onPressed: () { Navigator.pop(context); widget.onExport?.call(); },
                icon: Icon(Icons.share_rounded, size: 16, color: cs.primary),
                label: Text('Exportar', style: TextStyle(fontSize: 12, color: cs.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _detailRow(ColorScheme cs, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: cs.onSurface, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme cs) {
    return Container(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4));
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
