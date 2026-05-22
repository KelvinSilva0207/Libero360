import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/player.dart';

class RosterManagementSheet extends StatefulWidget {
  final List<Player> currentRoster;

  const RosterManagementSheet({super.key, required this.currentRoster});

  @override
  State<RosterManagementSheet> createState() => _RosterManagementSheetState();
}

class _RosterManagementSheetState extends State<RosterManagementSheet> {
  final _searchCtrl = TextEditingController();
  List<Player> _allPlayers = [];
  List<Player> _filtered = [];
  Set<int> _selectedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.currentRoster.map((p) => p.id).toSet();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await DatabaseService.instance.initialize();
      final players = await DatabaseService.instance.getAllPlayers();
      if (mounted) {
        setState(() {
          _allPlayers = players;
          _filtered = players;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = _allPlayers.where((p) {
        if (q.isEmpty) return true;
        return p.nombre.toLowerCase().contains(lower) ||
            p.cedula.toLowerCase().contains(lower) ||
            p.numero.toString().contains(lower);
      }).toList();
    });
  }

  void _toggle(Player p) {
    setState(() {
      if (_selectedIds.contains(p.id)) {
        _selectedIds.remove(p.id);
      } else {
        _selectedIds.add(p.id);
      }
    });
  }

  List<Player> get _selectedPlayers =>
      _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _header(),
          _searchBar(),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            )
          else
            Expanded(child: _playersList()),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          const Text('Gestionar Plantilla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _search,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, cédula o número...',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _playersList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search, color: Colors.white24, size: 48),
            const SizedBox(height: 8),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'Sin resultados para "${_searchCtrl.text}"'
                  : 'No hay atletas registrados.\nVe a Atletas para agregar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final p = _filtered[index];
        final selected = _selectedIds.contains(p.id);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: selected ? AppColors.accent : Colors.grey.shade700,
              child: Text('${p.numero}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            title: Text(p.nombre, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Row(
              children: [
                if (p.cedula.isNotEmpty) ...[
                  Text(p.cedula, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(width: 8),
                  Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24)),
                  const SizedBox(width: 8),
                ],
                Text(p.posicionLabel, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
            trailing: Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected ? AppColors.accent : Colors.white24,
              size: 22,
            ),
            onTap: () => _toggle(p),
          ),
        );
      },
    );
  }

  Widget _bottomBar() {
    final count = _selectedIds.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$count jugador${count == 1 ? '' : 'es'} seleccionado${count == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: count == 0
                  ? null
                  : () => Navigator.pop(context, _selectedPlayers),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: Colors.white12,
              ),
              child: const Text('Aplicar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
