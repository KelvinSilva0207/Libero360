import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../../core/utils/name_formatter.dart';
import 'athlete_form_screen.dart';
import 'player_detail_screen.dart';

class AthleteListScreen extends StatefulWidget {
  const AthleteListScreen({super.key});

  @override
  State<AthleteListScreen> createState() => _AthleteListScreenState();
}

class _AthleteListScreenState extends State<AthleteListScreen> {
  List<Player> _players = [];
  List<Player> _filteredPlayers = [];
  bool _loading = true;
  String? _error;
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  Posicion? _filterPosicion;
  EstadoSalud? _filterSalud;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await DatabaseService.instance.initialize();
      _players = await DatabaseService.instance.getAllPlayers();
      _applyFilters();
    } catch (e) {
      _error = 'Error al cargar: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addAthlete() async {
    final result = await context.pushSlide<bool>(const AthleteFormScreen());
    if (result == true) _load();
  }

  Color _saludColor(EstadoSalud e) {
    switch (e) {
      case EstadoSalud.disponible: return const Color(0xFF22C55E);
      case EstadoSalud.lesionado: return const Color(0xFFEF4444);
      case EstadoSalud.enDuda: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerHighest,
        title: Row(
          children: [
            Text('Roster', style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
            if (!_loading && _players.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_players.length}',
                  style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search, color: cs.onSurfaceVariant),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) { _searchCtrl.clear(); _applyFilters(); }
            }),
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: cs.onSurfaceVariant),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAthlete,
        backgroundColor: AppColors.accent,
        child: Icon(Icons.add, color: cs.onPrimary),
      ),
    );
  }

  Widget _buildBody() {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ],
        ),
      );
    }
    if (_players.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline, color: cs.onSurface.withValues(alpha: 0.38), size: 48),
            ),
            const SizedBox(height: 20),
            Text('Aún no hay atletas', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Agrega tu primer atleta', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _addAthlete,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Atleta'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Sort: captain first, then by number
    _players.sort((a, b) {
      if (a.esCapitan && !b.esCapitan) return -1;
      if (!a.esCapitan && b.esCapitan) return 1;
      return (a.numero ?? 999).compareTo(b.numero ?? 999);
    });

    return Column(
      children: [
        if (_showSearch) _buildSearchBar(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _load,
            child: _filteredPlayers.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, color: cs.onSurface.withValues(alpha: 0.38), size: 40),
                              const SizedBox(height: 8),
                              Text('Sin resultados', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _filteredPlayers.length,
                    itemBuilder: (context, index) {
                      return _athleteCard(_filteredPlayers[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredPlayers = _players.where((p) {
        if (query.isNotEmpty) {
          final name = NameFormatter.playerDisplayName(p).toLowerCase();
          final num = p.numero?.toString() ?? '';
          final cedula = p.cedula.toLowerCase();
          if (!name.contains(query) && !num.contains(query) && !cedula.contains(query)) return false;
        }
        if (_filterPosicion != null && p.posicion != _filterPosicion) return false;
        if (_filterSalud != null && p.estadoSalud != _filterSalud) return false;
        return true;
      }).toList();
    });
  }

  Widget _buildSearchBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => _applyFilters(),
          style: TextStyle(color: cs.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, número o cédula...',
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                    onPressed: () { _searchCtrl.clear(); _applyFilters(); },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtrar por posición', style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ...Posicion.values.map((p) => ChoiceChip(
                    label: Text(_posicionLabel(p), style: const TextStyle(fontSize: 12)),
                    selected: _filterPosicion == p,
                    selectedColor: AppColors.accent.withValues(alpha: 0.3),
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: TextStyle(color: _filterPosicion == p ? cs.onSurface : cs.onSurfaceVariant, fontSize: 12),
                    onSelected: (v) {
                      setSheetState(() => _filterPosicion = v ? p : null);
                    },
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Text('Filtrar por estado', style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ...EstadoSalud.values.map((s) => ChoiceChip(
                    label: Text(_saludLabel(s), style: const TextStyle(fontSize: 12)),
                    selected: _filterSalud == s,
                    selectedColor: _saludColor(s).withValues(alpha: 0.3),
                    backgroundColor: AppColors.surfaceLight,
                    labelStyle: TextStyle(color: _filterSalud == s ? cs.onSurface : cs.onSurfaceVariant, fontSize: 12),
                    onSelected: (v) {
                      setSheetState(() => _filterSalud = v ? s : null);
                    },
                  )),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _applyFilters();
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  child: const Text('Aplicar filtros'),
                ),
              ),
              if (_filterPosicion != null || _filterSalud != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      setSheetState(() {
                        _filterPosicion = null;
                        _filterSalud = null;
                      });
                    },
                    child: Text('Limpiar filtros', style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _posicionLabel(Posicion p) {
    switch (p) {
      case Posicion.colocador: return 'Armador';
      case Posicion.opuesto: return 'Opuesto';
      case Posicion.central: return 'Central';
      case Posicion.receptor: return 'Punta';
      case Posicion.libre: return 'Líbero';
      case Posicion.sinDefinir: return 'Todos';
    }
  }

  String _saludLabel(EstadoSalud s) {
    switch (s) {
      case EstadoSalud.disponible: return 'Disponible';
      case EstadoSalud.lesionado: return 'Lesionado';
      case EstadoSalud.enDuda: return 'En duda';
    }
  }

  Widget _athleteCard(Player p) {
    final cs = Theme.of(context).colorScheme;
    final healthColor = _saludColor(p.estadoSalud);
    final displayName = NameFormatter.playerDisplayName(p);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.pushSlide(PlayerDetailScreen(player: p)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'player-${p.id}',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: p.esCapitan
                          ? const LinearGradient(colors: [AppColors.accent, Color(0xFFFFA940)])
                          : LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.8),
                                AppColors.primary,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${p.numero ?? '-'}',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (p.esCapitan) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.star, color: AppColors.accent, size: 15),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.posicionLabel,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${p.edad} años',
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          if (p.cedula.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              p.cedula,
                              style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Health status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: healthColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.estadoSaludLabel,
                        style: TextStyle(color: healthColor, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
