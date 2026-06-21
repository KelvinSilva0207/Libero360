import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';

class PlayersDrawer extends StatefulWidget {
  final List<Player> benchPlayers;
  final ValueChanged<Player> onSubstitute;

  const PlayersDrawer({
    super.key,
    required this.benchPlayers,
    required this.onSubstitute,
  });

  @override
  State<PlayersDrawer> createState() => _PlayersDrawerState();
}

class _PlayersDrawerState extends State<PlayersDrawer> {
  String _filter = '';

  List<Player> get _filtered {
    if (_filter.isEmpty) return widget.benchPlayers;
    final q = _filter.toLowerCase();
    return widget.benchPlayers.where((p) {
      final fullName =
          '${p.firstNames} ${p.lastNames} ${p.nombre} ${p.displayName}'
              .toLowerCase();
      return fullName.contains(q) ||
          '${p.numero ?? ''}'.contains(q) ||
          p.cedula.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearch(),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin jugadores en banca',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _playerTile(_filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          const Text(
            'Banca',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.benchPlayers.length}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, color: Colors.white38, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar...',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          prefixIcon: const Padding(
            padding: EdgeInsetsDirectional.only(start: 8, end: 4),
            child: Icon(Icons.search, color: Colors.white24, size: 18),
          ),
          suffixIcon: _filter.isNotEmpty
              ? GestureDetector(
                  onTap: () => setState(() => _filter = ''),
                  child: const Padding(
                    padding: EdgeInsetsDirectional.only(end: 8),
                    child: Icon(Icons.clear, color: Colors.white38, size: 16),
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (v) => setState(() => _filter = v),
      ),
    );
  }

  Widget _playerTile(Player player) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.3),
            child: Text(
              '${player.numero ?? '?'}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName.isNotEmpty
                      ? player.displayName
                      : '${player.firstNames} ${player.lastNames}'.trim(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  player.posicionLabel,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => widget.onSubstitute(player),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: AppColors.accent, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
