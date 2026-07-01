import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../cancha/presentation/views/court_screen.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/match_config.dart';
import 'match_screen.dart';
import 'match_start_dialog.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  List<Match> _activeMatches = [];
  List<Match> _finishedMatches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    LogService.instance.auto('🟢 MatchListScreen — initState', source: 'MatchListScreen');
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    LogService.instance.auto('🔵 MatchListScreen — cargando partidos', source: 'MatchListScreen');
    try {
      await DatabaseService.instance.initialize();
      final active = await DatabaseService.instance.getMatchesByState(EstadoPartido.enProgreso);
      final paused = await DatabaseService.instance.getMatchesByState(EstadoPartido.pausado);
      final finished = await DatabaseService.instance.getMatchesByState(EstadoPartido.finalizado);
      if (!mounted) return;
      setState(() {
        _activeMatches = [...active, ...paused]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _finishedMatches = finished..sort((a, b) => b.fecha.compareTo(a.fecha));
        _loading = false;
      });
      LogService.instance.auto('🟢 MatchListScreen — activos=${_activeMatches.length}, historial=${_finishedMatches.length}', source: 'MatchListScreen');
    } catch (e) {
      LogService.instance.auto('🔴 MatchListScreen — error: $e', source: 'MatchListScreen');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteMatch(Match m) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        title: Text('Eliminar partido', style: TextStyle(color: cs.onSurface)),
        content: Text('¿Eliminar ${m.equipoLocal} vs ${m.equipoVisitante}?', style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: cs.onSurfaceVariant))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.instance.deleteMatch(m.id);
      _loadMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Partidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: cs.onSurfaceVariant),
            tooltip: 'Historial completo',
            onPressed: _finishedMatches.isNotEmpty
                ? () => _showFullHistory(cs)
                : null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMatches,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildNuevoPartidoCard(cs),
                  const SizedBox(height: 20),
                  if (_activeMatches.isNotEmpty) ...[
                    _buildActiveSection(cs),
                    const SizedBox(height: 20),
                  ],
                  if (_finishedMatches.isNotEmpty) ...[
                    _buildHistorySection(cs),
                  ],
                  if (_activeMatches.isEmpty && _finishedMatches.isEmpty)
                    _buildEmptyState(cs),
                ],
              ),
            ),
    );
  }

  Widget _buildNuevoPartidoCard(ColorScheme cs) {
    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _nuevoPartido,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.add_rounded, color: cs.onPrimaryContainer, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nuevo Partido',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
                    const SizedBox(height: 4),
                    Text('Configura equipos, reglas y jugadores',
                        style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
              ),
              const SizedBox(width: 6),
              Text('PARTIDOS ACTIVOS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant, letterSpacing: 1)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${_activeMatches.length}',
                    style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        ..._activeMatches.map((m) => _buildActiveCard(cs, m)),
      ],
    );
  }

  Widget _buildActiveCard(ColorScheme cs, Match m) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(m.fecha);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_volleyball_rounded, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(m.tipoPartidoLabel,
                    style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text(dateStr, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 16, color: cs.onSurfaceVariant),
                  onSelected: (v) {
                    if (v == 'delete') _deleteMatch(m);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${m.equipoLocal} vs ${m.equipoVisitante}',
                          style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Set ${m.setActual}',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(m.marcador,
                                style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _continuarPartido(m),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Continuar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('ÚLTIMOS PARTIDOS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant, letterSpacing: 1)),
            ],
          ),
        ),
        ..._finishedMatches.take(5).map((m) => _buildHistoryTile(cs, m)),
        if (_finishedMatches.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton.icon(
                onPressed: () => _showFullHistory(cs),
                icon: const Icon(Icons.history_rounded, size: 16),
                label: Text('Ver historial completo (${_finishedMatches.length})'),
                style: TextButton.styleFrom(foregroundColor: cs.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTile(ColorScheme cs, Match m) {
    final dateStr = DateFormat('dd/MM/yyyy').format(m.fecha);
    final isWin = m.setsLocal > m.setsVisitante;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _verResumen(m),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isWin ? AppColors.success.withValues(alpha: 0.2) : AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isWin ? Icons.emoji_events_rounded : Icons.sports_volleyball_rounded,
                  color: isWin ? AppColors.success : AppColors.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${m.equipoLocal} vs ${m.equipoVisitante}',
                        style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('$dateStr · ${m.resultadoSets}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isWin ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isWin ? 'Ganado' : 'Perdido',
                  style: TextStyle(
                    color: isWin ? AppColors.success : AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(Icons.sports_volleyball_outlined, size: 36, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text('No hay partidos',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Crea tu primer partido desde la card superior',
                style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showFullHistory(ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Historial completo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _finishedMatches.length,
                itemBuilder: (_, i) => _buildHistoryTile(cs, _finishedMatches[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nuevoPartido() {
    LogService.instance.auto('🟡 MatchListScreen — crear nuevo partido', source: 'MatchListScreen');
    showDialog(
      context: context,
      builder: (_) => const MatchStartDialog(),
    );
  }

  void _continuarPartido(Match m) {
    LogService.instance.auto('🟡 MatchListScreen — continuar partido: ${m.equipoLocal} vs ${m.equipoVisitante}', source: 'MatchListScreen');
    final config = MatchConfig(
      localName: m.equipoLocal,
      visitorName: m.equipoVisitante,
      setsTotales: m.setsTotales,
      tipoPartido: m.tipoPartido,
      categoria: Categoria.libre,
      timeoutsPerSet: 2,
      timeoutDurationSeconds: 30,
    );
    Navigator.push(context, slideRightRoute(MatchScreen(config: config)));
  }

  void _verResumen(Match m) {
    final cs = Theme.of(context).colorScheme;
    LogService.instance.auto('🟡 MatchListScreen — ver resumen: ${m.equipoLocal} ${m.resultadoSets} ${m.equipoVisitante}', source: 'MatchListScreen');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${m.equipoLocal} ${m.resultadoSets} ${m.equipoVisitante}'),
        backgroundColor: cs.primary,
      ),
    );
  }
}
