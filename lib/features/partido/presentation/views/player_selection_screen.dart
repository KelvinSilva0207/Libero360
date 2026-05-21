import 'package:flutter/material.dart';
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
      '${p.numero}'.contains(q)
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
    if (_selectedIds.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos 6 jugadores'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)));
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
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
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
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF8C00), size: 16),
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
                prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 18),
                filled: true,
                fillColor: const Color(0xFF1E293B),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFFFF8C00).withOpacity(0.5) : Colors.transparent,
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
                backgroundColor: selected ? const Color(0xFFFF8C00) : const Color(0xFF0081CF),
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
                            color: const Color(0xFF0081CF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(p.posicionLabel, style: const TextStyle(color: Color(0xFF0081CF), fontSize: 10, fontWeight: FontWeight.w500)),
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
                color: selected ? const Color(0xFFFF8C00) : Colors.white24,
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
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: _selectedIds.length < 6 ? null : _iniciarPartido,
          icon: const Icon(Icons.play_arrow),
          label: Text(_selectedIds.length < 6
              ? 'Selecciona ${6 - _selectedIds.length} más'
              : 'Iniciar Partido'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade800,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
