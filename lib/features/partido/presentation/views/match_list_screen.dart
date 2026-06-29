import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      await DatabaseService.instance.initialize();
      final active = await DatabaseService.instance.getMatchesByState(EstadoPartido.enProgreso);
      final paused = await DatabaseService.instance.getMatchesByState(EstadoPartido.pausado);
      final finished = await DatabaseService.instance.getMatchesByState(EstadoPartido.finalizado);
      if (!mounted) return;
      setState(() {
        _activeMatches = [...active, ...paused]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _finishedMatches = finished.take(10).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Partidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            Text('Gestiona entrenamientos y partidos oficiales',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMatches,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildActiveSection(cs),
                  const SizedBox(height: 24),
                  _buildHistorySection(cs),
                  const SizedBox(height: 24),
                  _buildActionsSection(cs),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.play_circle_rounded, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text('PARTIDOS ACTIVOS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 10),
        if (_activeMatches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(Icons.sports_volleyball_outlined, size: 36, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text('No hay partidos activos',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Inicia un nuevo partido desde el botón inferior',
                    style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          )
        else
          ..._activeMatches.map((m) => _buildActiveCard(cs, m)),
      ],
    );
  }

  Widget _buildActiveCard(ColorScheme cs, Match m) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(m.fecha);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${m.equipoLocal} vs ${m.equipoVisitante}',
                      style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Set ${m.setActual}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
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
            FilledButton(
              onPressed: () => _continuarPartido(m),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Continuar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
        Row(
          children: [
            Icon(Icons.history_rounded, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('HISTORIAL',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 10),
        if (_finishedMatches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Center(
              child: Text('Aún no hay partidos finalizados',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            ),
          )
        else
          ..._finishedMatches.map((m) => _buildHistoryTile(cs, m)),
      ],
    );
  }

  Widget _buildHistoryTile(ColorScheme cs, Match m) {
    final dateStr = DateFormat('dd/MM/yyyy').format(m.fecha);
    final isWin = m.setsLocal > m.setsVisitante;
    return Container(
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
              Container(
                width: 36,
                height: 36,
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
                    const SizedBox(height: 1),
                    Text('$dateStr · ${m.resultadoSets}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                isWin ? 'Ganado' : 'Perdido',
                style: TextStyle(
                  color: isWin ? AppColors.success : AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on_rounded, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text('ACCIONES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _nuevoPartido,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Nuevo Partido', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourtScreen())),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('Cancha de práctica', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurface,
              side: BorderSide(color: cs.outlineVariant),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _nuevoPartido() {
    showDialog(
      context: context,
      builder: (_) => const MatchStartDialog(),
    );
  }

  void _continuarPartido(Match m) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resumen: ${m.equipoLocal} ${m.resultadoSets} ${m.equipoVisitante}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
