import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/log_service.dart';
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
  List<Season> _seasons = [];
  bool _loading = true;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  TipoPartido? _filterTipo;
  bool? _filterResultado; // true=ganados, false=perdidos, null=all
  int? _filterSeasonId;

  @override
  void initState() {
    super.initState();
    LogService.instance.auto('🟢 MatchListScreen — initState', source: 'MatchListScreen');
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text));
    _loadMatches();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    LogService.instance.auto('🔵 MatchListScreen — cargando partidos', source: 'MatchListScreen');
    try {
      await DatabaseService.instance.initialize();
      final active = await DatabaseService.instance.getMatchesByState(EstadoPartido.enProgreso);
      final paused = await DatabaseService.instance.getMatchesByState(EstadoPartido.pausado);
      final finished = await DatabaseService.instance.getMatchesByState(EstadoPartido.finalizado);
      final seasons = await DatabaseService.instance.getAllSeasons();
      if (!mounted) return;
      setState(() {
        _activeMatches = [...active, ...paused]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _finishedMatches = finished..sort((a, b) => b.fecha.compareTo(a.fecha));
        _seasons = seasons;
        _loading = false;
      });
      LogService.instance.auto('🟢 MatchListScreen — activos=${_activeMatches.length}, historial=${_finishedMatches.length}, seasons=${_seasons.length}', source: 'MatchListScreen');
    } catch (e) {
      LogService.instance.auto('🔴 MatchListScreen — error: $e', source: 'MatchListScreen');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Match> get _filteredFinished {
    var list = _finishedMatches;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) =>
        m.equipoLocal.toLowerCase().contains(q) ||
        m.equipoVisitante.toLowerCase().contains(q) ||
        (m.competitionName?.toLowerCase().contains(q) ?? false) ||
        (m.lugar?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    if (_filterTipo != null) {
      list = list.where((m) => m.tipoPartido == _filterTipo).toList();
    }

    if (_filterResultado != null) {
      list = list.where((m) {
        final won = m.setsLocal > m.setsVisitante;
        return _filterResultado == true ? won : !won;
      }).toList();
    }

    if (_filterSeasonId != null) {
      list = list.where((m) => m.seasonId == _filterSeasonId).toList();
    }

    return list;
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

  Future<void> _duplicateMatch(Match m) async {
    LogService.instance.auto('🟡 MatchListScreen — duplicar partido: ${m.equipoLocal} vs ${m.equipoVisitante}', source: 'MatchListScreen');
    final copy = Match.create(
      equipoLocal: m.equipoLocal,
      equipoVisitante: m.equipoVisitante,
      tipoPartido: m.tipoPartido,
      setsTotales: m.setsTotales,
      puntosParaGanarSet: m.puntosParaGanarSet,
      puntosDiferenciaSet: m.puntosDiferenciaSet,
      lugar: m.lugar,
    );
    copy.seasonId = m.seasonId;
    copy.competitionName = m.competitionName;
    copy.profileId = m.profileId;
    copy.clubId = m.clubId;
    await DatabaseService.instance.insertMatch(copy);
    _loadMatches();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Partido duplicado: ${m.equipoLocal} vs ${m.equipoVisitante}')),
      );
    }
  }

  Future<void> _exportMatch(Match m) async {
    LogService.instance.auto('🟡 MatchListScreen — exportar partido: ${m.equipoLocal} vs ${m.equipoVisitante}', source: 'MatchListScreen');
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(m.fecha);
    final winner = m.setsLocal > m.setsVisitante ? m.equipoLocal : m.equipoVisitante;
    final lines = <String>[
      '🏐 ${m.equipoLocal} vs ${m.equipoVisitante}',
      '📅 $dateStr',
      '📊 ${m.resultadoSets}',
      '🏆 Ganador: $winner',
      '',
      'Tipo: ${m.tipoPartidoLabel}',
      if (m.competitionName != null) 'Competición: ${m.competitionName}',
      if (m.lugar != null) 'Lugar: ${m.lugar}',
      'Duración: ${m.duracionSegundos}s',
    ];
    final text = lines.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado copiado al portapapeles')),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _filterTipo = null;
      _filterResultado = null;
      _filterSeasonId = null;
      _searchCtrl.clear();
    });
  }

  bool get _hasActiveFilters =>
    _filterTipo != null ||
    _filterResultado != null ||
    _filterSeasonId != null ||
    _searchQuery.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filteredCount = _filteredFinished.length;

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
                  if (_finishedMatches.isNotEmpty) ...[
                    _buildSearchBar(cs),
                    const SizedBox(height: 8),
                    _buildFilterChips(cs),
                    const SizedBox(height: 8),
                  ],
                  if (_activeMatches.isNotEmpty) ...[
                    _buildActiveSection(cs),
                    const SizedBox(height: 20),
                  ],
                  if (_finishedMatches.isNotEmpty) ...[
                    _buildHistorySection(cs, filteredCount),
                  ],
                  if (_activeMatches.isEmpty && _finishedMatches.isEmpty)
                    _buildEmptyState(cs),
                  if (_hasActiveFilters && filteredCount == 0)
                    _buildNoResults(cs),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs) {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'Buscar partidos...',
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, size: 18, color: cs.onSurfaceVariant),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear_rounded, size: 16, color: cs.onSurfaceVariant),
                onPressed: _searchCtrl.clear,
              )
            : null,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: TextStyle(color: cs.onSurface, fontSize: 13),
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildFilterChips(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(cs, 'Tipo', _filterTipo?.name, () {
            showModalBottomSheet(
              context: context,
              backgroundColor: cs.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  Text('Filtrar por tipo', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...TipoPartido.values.map((t) => ListTile(
                    leading: Radio<TipoPartido>(
                      value: t,
                      groupValue: _filterTipo,
                      onChanged: (v) {
                        Navigator.pop(ctx);
                        setState(() => _filterTipo = v);
                      },
                    ),
                    title: Text(t.name, style: TextStyle(color: cs.onSurface)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _filterTipo = t);
                    },
                  )),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _filterTipo = null);
                    },
                    child: const Text('Limpiar filtro'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          }),
          const SizedBox(width: 6),
          _buildChip(cs, 'Resultado',
            _filterResultado == null ? null : (_filterResultado! ? 'Ganados' : 'Perdidos'),
            () => setState(() {
              if (_filterResultado == null) {
                _filterResultado = true;
              } else if (_filterResultado == true) {
                _filterResultado = false;
              } else {
                _filterResultado = null;
              }
            }),
          ),
          const SizedBox(width: 6),
          if (_seasons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _buildChip(cs, 'Temporada',
                _seasons.where((s) => s.id == _filterSeasonId).firstOrNull?.label,
                () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: cs.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (ctx) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Container(width: 40, height: 4,
                            decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 12),
                        Text('Filtrar por temporada', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._seasons.map((s) => ListTile(
                          leading: Radio<int>(
                            value: s.id,
                            groupValue: _filterSeasonId,
                            onChanged: (v) {
                              Navigator.pop(ctx);
                              setState(() => _filterSeasonId = v);
                            },
                          ),
                          title: Text(s.label, style: TextStyle(color: cs.onSurface)),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _filterSeasonId = s.id);
                          },
                        )),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _filterSeasonId = null);
                          },
                          child: const Text('Limpiar filtro'),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded, size: 12, color: cs.error),
                      const SizedBox(width: 4),
                      Text('Limpiar', style: TextStyle(color: cs.error, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(ColorScheme cs, String label, String? value, VoidCallback onTap) {
    final active = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              active ? value! : label,
              style: TextStyle(
                color: active ? cs.primary : cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 4),
              Icon(Icons.close_rounded, size: 12, color: cs.primary),
            ] else ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down_rounded, size: 14, color: cs.onSurfaceVariant),
            ],
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
                decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary),
              ),
              const SizedBox(width: 6),
              Text('PARTIDOS ACTIVOS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant, letterSpacing: 1)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${_activeMatches.length}',
                    style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.bold)),
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
    final isPaused = m.estado == EstadoPartido.pausado;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPaused ? cs.error.withValues(alpha: 0.3) : cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isPaused ? Icons.pause_circle_rounded : Icons.sports_volleyball_rounded, size: 14,
                    color: isPaused ? cs.error : cs.primary),
                const SizedBox(width: 4),
                Text(isPaused ? 'PAUSADO' : m.tipoPartidoLabel,
                    style: TextStyle(color: isPaused ? cs.error : cs.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text(dateStr, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 16, color: cs.onSurfaceVariant),
                  onSelected: (v) {
                    if (v == 'delete') _deleteMatch(m);
                    if (v == 'duplicate') _duplicateMatch(m);
                    if (v == 'export') _exportMatch(m);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
                    const PopupMenuItem(value: 'export', child: Text('Exportar')),
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
                              color: cs.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(m.marcador,
                                style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    backgroundColor: cs.primary,
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

  Widget _buildHistorySection(ColorScheme cs, int filteredCount) {
    final displayList = _filteredFinished;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(_hasActiveFilters ? 'RESULTADOS ($filteredCount)' : 'ÚLTIMOS PARTIDOS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant, letterSpacing: 1)),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _clearFilters,
                  child: Icon(Icons.close_rounded, size: 14, color: cs.error),
                ),
              ],
            ],
          ),
        ),
        if (_hasActiveFilters)
          ...displayList.map((m) => _buildHistoryTile(cs, m))
        else ...[
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
                    Text('${m.equipoLocal} vs ${m.equipoVisitante}',
                        style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        Text('$dateStr · ${m.resultadoSets}',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                        if (m.tipoPartido != TipoPartido.amistoso) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(m.tipoPartidoLabel,
                                style: TextStyle(color: cs.primary, fontSize: 9, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, size: 16, color: cs.onSurfaceVariant),
                onSelected: (v) {
                  if (v == 'duplicate') _duplicateMatch(m);
                  if (v == 'export') _exportMatch(m);
                  if (v == 'delete') _deleteMatch(m);
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

  Widget _buildNoResults(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 36, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('Sin resultados', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Prueba con otros filtros', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('${m.equipoLocal} vs ${m.equipoVisitante}',
                style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(m.resultadoSets,
                style: TextStyle(color: cs.primary, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(m.isFinalizado
                ? (m.setsLocal > m.setsVisitante ? 'Ganó ${m.equipoLocal}' : 'Ganó ${m.equipoVisitante}')
                : m.estado.name,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 4),
            Text(DateFormat('dd/MM/yyyy HH:mm').format(m.fecha),
                style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
            if (m.competitionName != null) ...[
              const SizedBox(height: 4),
              Text(m.competitionName!,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () { Navigator.pop(ctx); _duplicateMatch(m); },
                  icon: Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Duplicar', style: TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () { Navigator.pop(ctx); _exportMatch(m); },
                  icon: Icon(Icons.share_rounded, size: 16),
                  label: const Text('Exportar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
