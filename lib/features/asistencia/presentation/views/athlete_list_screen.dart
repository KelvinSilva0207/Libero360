import 'package:flutter/material.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import 'athlete_form_screen.dart';

class AthleteListScreen extends StatefulWidget {
  const AthleteListScreen({super.key});

  @override
  State<AthleteListScreen> createState() => _AthleteListScreenState();
}

class _AthleteListScreenState extends State<AthleteListScreen> {
  List<Player> _players = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await DatabaseService.instance.initialize();
      _players = await DatabaseService.instance.getAllPlayers();
    } catch (e) {
      _error = 'Error al cargar: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addAthlete() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AthleteFormScreen()),
    );
    if (result == true) _load();
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Atletas', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAthlete,
        backgroundColor: const Color(0xFFFF8C00),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
    if (_players.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text('No hay atletas registrados', style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Presiona + para agregar uno', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFFF8C00),
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final p = _players[index];
          return _athleteCard(p);
        },
      ),
    );
  }

  Widget _athleteCard(Player p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: p.esCapitan ? const Color(0xFFFF8C00) : const Color(0xFF0081CF),
          child: Text(
            '${p.numero}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Text(p.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            if (p.esCapitan) ...[
              const SizedBox(width: 6),
              const Icon(Icons.star, color: Color(0xFFFF8C00), size: 16),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Text(p.posicionLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 12),
            Text('${p.edad} años', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _saludColor(p.estadoSalud).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            p.estadoSaludLabel,
            style: TextStyle(
              color: _saludColor(p.estadoSalud),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
