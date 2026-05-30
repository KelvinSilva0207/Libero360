import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../data/match_config.dart';
import 'match_screen.dart';

class MatchStartDialog extends StatefulWidget {
  const MatchStartDialog({super.key});

  @override
  State<MatchStartDialog> createState() => _MatchStartDialogState();
}

class _MatchStartDialogState extends State<MatchStartDialog> {
  final _pageCtrl = PageController();
  final _localCtrl = TextEditingController();
  final _visitorCtrl = TextEditingController();

  TipoPartido _tipoPartido = TipoPartido.amistoso;
  int _setsTotales = 5;

  // Step 2
  List<Player> _allPlayers = [];
  final Set<int> _selectedIds = {};
  bool _loadingPlayers = true;
  String _filter = '';

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _localCtrl.dispose();
    _visitorCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    try {
      await DatabaseService.instance.initialize();
      final players = await DatabaseService.instance.getAllPlayers();
      if (mounted) {
        setState(() {
          _allPlayers = players;
          _loadingPlayers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPlayers = false);
    }
  }

  void _irAlPaso2() {
    _pageCtrl.animateToPage(1, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _finalizar() {
    final local = _localCtrl.text.trim();
    final visitor = _visitorCtrl.text.trim();
    final selected = _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();

    final config = MatchConfig(
      localName: local.isNotEmpty ? local : 'Local',
      visitorName: visitor.isNotEmpty ? visitor : 'Visitante',
      setsTotales: _setsTotales,
      tipoPartido: _tipoPartido,
      lugar: null,
      selectedPlayers: selected.take(12).toList(),
    );

    Navigator.of(context).pop();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => MatchScreen(config: config)),
    );
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 640, maxWidth: 480),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.surface, Color(0xFF141838)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nuevo Partido',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildStepIndicator(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [0, 1].map((i) {
        final isActive = i == _currentPage;
        final isDone = i < _currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 24, height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isActive ? AppColors.accent : (isDone ? AppColors.accent.withValues(alpha: 0.5) : Colors.white24),
          ),
        );
      }).toList(),
    );
  }

  // ========== STEP 1 ==========

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Text(
            'REGISTRO DE EQUIPOS',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ingresa los nombres o deja en blanco para usar valores por defecto',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 24),
          _buildField(_localCtrl, 'Equipo Local', Icons.shield),
          const SizedBox(height: 12),
          _buildField(_visitorCtrl, 'Equipo Visitante', Icons.shield_outlined),
          const SizedBox(height: 20),
          _buildTipoDropdown(),
          const SizedBox(height: 12),
          _buildSetsSelector(),
          const Spacer(),
          FilledButton.icon(
            onPressed: _irAlPaso2,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Siguiente'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildTipoDropdown() {
    return DropdownButtonFormField<TipoPartido>(
      value: _tipoPartido,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Tipo de Partido',
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: const Padding(
          padding: EdgeInsetsDirectional.only(start: 12, end: 8),
          child: Icon(Icons.category, color: AppColors.primary, size: 20),
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: TipoPartido.amistoso, child: Text('Amistoso')),
        DropdownMenuItem(value: TipoPartido.liga, child: Text('Liga')),
        DropdownMenuItem(value: TipoPartido.torneo, child: Text('Torneo')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _tipoPartido = v);
      },
    );
  }

  Widget _buildSetsSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 4, end: 8),
            child: Icon(Icons.format_list_numbered, color: AppColors.primary, size: 20),
          ),
          const Text('Sets a ganar:', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          _setChip(3),
          const SizedBox(width: 8),
          _setChip(5),
        ],
      ),
    );
  }

  Widget _setChip(int n) {
    final selected = _setsTotales == n;
    return GestureDetector(
      onTap: () => setState(() => _setsTotales = n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.accent : Colors.white24),
        ),
        child: Text(
          '$n',
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ========== STEP 2 ==========

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ELIGE A TUS ATLETAS',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _selectedIds.length >= 6
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Atletas seleccionados: ${_selectedIds.length}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _selectedIds.length >= 6 ? Colors.green : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, cédula o número...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              prefixIcon: const Padding(
                padding: EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(Icons.search, color: Colors.white24, size: 18),
              ),
              suffixIcon: _filter.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                      onPressed: () => setState(() => _filter = ''),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: _loadingPlayers
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _allPlayers.isEmpty
                    ? _emptyState()
                    : _playerList(),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _finalizar,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(
              _selectedIds.isEmpty ? 'Comenzar Partido' : 'Iniciar (${_selectedIds.length})',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          const Icon(Icons.people_outline, color: Colors.white24, size: 48),
          const SizedBox(height: 8),
          const Text('No hay atletas registrados', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Agrega atletas desde la sección Atletas', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _playerList() {
    final players = _filteredPlayers;
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: players.length,
      itemBuilder: (_, i) => _playerTile(players[i]),
    );
  }

  Widget _playerTile(Player p) {
    final selected = _selectedIds.contains(p.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.accent.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() {
          if (selected) { _selectedIds.remove(p.id); } else { _selectedIds.add(p.id); }
        }),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: selected ? AppColors.accent : AppColors.primary,
                child: Text('${p.numero}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Text('Cédula: ${p.cedula}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(p.posicionLabel, style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: (_) => setState(() {
                  if (selected) { _selectedIds.remove(p.id); } else { _selectedIds.add(p.id); }
                }),
                activeColor: AppColors.accent,
                checkColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
