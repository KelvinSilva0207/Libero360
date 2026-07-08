import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/models.dart';

class MatchHistoryCard extends StatefulWidget {
  final Match match;
  final VoidCallback? onDuplicate;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;

  const MatchHistoryCard({
    super.key,
    required this.match,
    this.onDuplicate,
    this.onExport,
    this.onDelete,
    this.onViewDetails,
  });

  @override
  State<MatchHistoryCard> createState() => _MatchHistoryCardState();
}

class _MatchHistoryCardState extends State<MatchHistoryCard> {
  bool _expanded = false;
  bool _loadingStats = false;
  Map<TipoAccion, int> _statistics = {};
  bool _statsLoaded = false;

  static const _typeLabels = {
    TipoAccion.ataque: 'Ataques',
    TipoAccion.saque: 'Saques',
    TipoAccion.bloqueo: 'Bloqueos',
    TipoAccion.defensa: 'Defensas',
    TipoAccion.recepcion: 'Recepciones',
  };

  static const _typeIcons = {
    TipoAccion.ataque: Icons.sports_kabaddi,
    TipoAccion.saque: Icons.sports_volleyball,
    TipoAccion.bloqueo: Icons.shield,
    TipoAccion.defensa: Icons.pan_tool,
    TipoAccion.recepcion: Icons.pan_tool,
  };

  Future<void> _loadStats() async {
    if (_statsLoaded || _loadingStats) return;
    setState(() => _loadingStats = true);
    try {
      final stats = await DatabaseService.instance.countAllEventTypes(widget.match.id);
      if (mounted) {
        setState(() {
          _statistics = stats;
          _statsLoaded = true;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
    });
    if (_expanded) _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = widget.match;
    final dateStr = DateFormat('dd/MM/yyyy').format(m.fecha);
    final isWin = m.setsLocal > m.setsVisitante;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? cs.primary.withValues(alpha: 0.2)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _toggle,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isWin
                              ? cs.tertiary.withValues(alpha: 0.2)
                              : cs.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isWin ? Icons.emoji_events_rounded : Icons.sports_volleyball_rounded,
                          color: isWin ? cs.tertiary : cs.error,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m.equipoLocal} vs ${m.equipoVisitante}',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '$dateStr · ${m.resultadoSets}',
                                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                                ),
                                if (m.tipoPartido != TipoPartido.amistoso) ...[
                                  const SizedBox(width: 6),
                                  _Badge(label: m.tipoPartidoLabel, color: cs.primary),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_horiz_rounded, size: 16, color: cs.onSurfaceVariant),
                        onSelected: (v) {
                          if (v == 'duplicate') widget.onDuplicate?.call();
                          if (v == 'export') widget.onExport?.call();
                          if (v == 'delete') widget.onDelete?.call();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
                          const PopupMenuItem(value: 'export', child: Text('Exportar')),
                          const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_expanded) _buildExpandedContent(cs, m),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ColorScheme cs, Match m) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _divider(cs),
          const SizedBox(height: 8),
          // Duration
          if (m.duracionSegundos > 0) ...[
            _infoRow(cs, Icons.timer_outlined, 'Duración', _formatDuration(m.duracionSegundos)),
            const SizedBox(height: 4),
          ],
          // Competition
          if (m.competitionName != null && m.competitionName!.isNotEmpty) ...[
            _infoRow(cs, Icons.emoji_events_outlined, 'Competición', m.competitionName!),
            const SizedBox(height: 4),
          ],
          // Location
          if (m.lugar != null && m.lugar!.isNotEmpty) ...[
            _infoRow(cs, Icons.location_on_outlined, 'Lugar', m.lugar!),
            const SizedBox(height: 4),
          ],
          // Statistics
          if (_loadingStats)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                  ),
                  const SizedBox(width: 8),
                  Text('Cargando estadísticas...',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                ],
              ),
            ),
          if (_statsLoaded && _statistics.isNotEmpty) ...[
            const SizedBox(height: 4),
            _divider(cs),
            const SizedBox(height: 8),
            Text('ESTADÍSTICAS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.8,
                )),
            const SizedBox(height: 8),
            _buildStatsGrid(cs),
          ],
          if (_statsLoaded && _statistics.isEmpty) ...[
            const SizedBox(height: 4),
            _divider(cs),
            const SizedBox(height: 8),
            Text('Sin estadísticas registradas',
                style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11)),
          ],
          const SizedBox(height: 8),
          // View details button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onViewDetails,
              icon: Icon(Icons.open_in_new_rounded, size: 14, color: cs.primary),
              label: Text('Ver detalles',
                  style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ColorScheme cs) {
    final relevant = <TipoAccion>[
      TipoAccion.ataque,
      TipoAccion.saque,
      TipoAccion.bloqueo,
      TipoAccion.defensa,
      TipoAccion.recepcion,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: relevant.where((t) => _statistics.containsKey(t)).map((tipo) {
        final count = _statistics[tipo] ?? 0;
        return Container(
          width: (MediaQuery.of(context).size.width - 80) / 3,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(_typeIcons[tipo] ?? Icons.circle, size: 16, color: cs.primary.withValues(alpha: 0.7)),
              const SizedBox(height: 4),
              Text('$count',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
              Text(
                _typeLabels[tipo] ?? tipo.name,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoRow(ColorScheme cs, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 13, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
        Expanded(
          child: Text(value,
              style: TextStyle(color: cs.onSurface, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ),
      ],
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w500)),
    );
  }
}
