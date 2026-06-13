import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import 'athlete_form_screen.dart';
import 'player_detail_screen.dart';

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
      case EstadoSalud.disponible: return const Color(0xFF22C55E);
      case EstadoSalud.lesionado: return const Color(0xFFEF4444);
      case EstadoSalud.enDuda: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Text('Roster', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
            icon: const Icon(Icons.search, color: Colors.white54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white54),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAthlete,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline, color: Colors.white24, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Aún no hay atletas', style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Agrega tu primer atleta', style: TextStyle(color: Colors.white38, fontSize: 13)),
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

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          return _athleteCard(_players[index]);
        },
      ),
    );
  }

  Widget _athleteCard(Player p) {
    final healthColor = _saludColor(p.estadoSalud);
    final parts = p.nombre.trim().split(RegExp(r'\s+'));
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: p))),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Number circle with position color
                Container(
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
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
                              parts.first,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastName.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                lastName,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
