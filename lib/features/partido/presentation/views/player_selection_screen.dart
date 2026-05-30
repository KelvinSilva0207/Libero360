import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../data/match_config.dart';
import 'match_screen.dart';

class PlayerSelectionScreen extends StatefulWidget {
  final MatchConfig config;
  const PlayerSelectionScreen({super.key, required this.config});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  List<Player> _allPlayers = [];
  final Set<int> _selectedIds = {};
  bool _loading = true;
  String? _error;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await DatabaseService.instance.initialize();
      _allPlayers = await DatabaseService.instance.getAllPlayers();
    } catch (e) {
      _error = 'Error al cargar: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Player> get _filteredPlayers {
    if (_filter.isEmpty) return _allPlayers;
    final q = _filter.toLowerCase();
    return _allPlayers.where((p) =>
      p.nombre.toLowerCase().contains(q) ||
      p.cedula.toLowerCase().contains(q) ||
      (p.numero?.toString() ?? '').contains(q)
    ).toList();
  }

  void _togglePlayer(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _iniciarPartido() {
    final selected = _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();
    widget.config.selectedPlayers = selected.take(12).toList();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MatchScreen(config: widget.config)),
    );
  }

  Color _saludColor(EstadoSalud e) {
    switch (e) {
      case EstadoSalud.disponible: return Colors.green;
      case EstadoSalud.lesionado: return Colors.red;
      case EstadoSalud.enDuda: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombres = '${widget.config.localName} vs ${widget.config.visitorName}';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(nombres, style: const TextStyle(color: Colors.white, fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
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
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        _headerBar(),
        if (_allPlayers.isEmpty)
          Expanded(child: _emptyState())
        else
          Expanded(child: _playerList()),
      ],
    );
  }

  Widget _headerBar() {
    final tipoStr = widget.config.tipoPartido == TipoPartido.amistoso ? 'Amistoso'
        : widget.config.tipoPartido == TipoPartido.liga ? 'Liga' : 'Torneo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Text(
            '$tipoStr · ${widget.config.setsTotales} sets',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const Spacer(),
          Text(
            '${_selectedIds.length} seleccionados',
            style: TextStyle(color: _selectedIds.length >= 6 ? Colors.green : Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text('No hay atletas registrados', style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Agrega atletas desde la sección Atletas', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _playerList() {
    final players = _filteredPlayers;
    return Column(
      children: [
        if (_allPlayers.length > 6)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar atleta...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Padding(
                  padding: EdgeInsetsDirectional.only(start: 12, end: 8),
                  child: Icon(Icons.search, color: Colors.white24, size: 18),
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: players.length,
            itemBuilder: (context, index) => _playerTile(players[index]),
          ),
        ),
      ],
    );
  }

  Widget _playerTile(Player p) {
    final selected = _selectedIds.contains(p.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.accent.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _togglePlayer(p.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: selected ? AppColors.accent : AppColors.primary,
                child: Text('${p.numero}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('Cédula: ${p.cedula}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(p.posicionLabel, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _saludColor(p.estadoSalud)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.accent : Colors.white24,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _iniciarPartido,
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Saltar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _iniciarPartido,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: Text(_selectedIds.isEmpty
                    ? 'Comenzar Partido'
                    : 'Iniciar (${_selectedIds.length})'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
