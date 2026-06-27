import 'package:flutter/material.dart';
import '../../../../core/services/category_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
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
  final _competenciaCtrl = TextEditingController();

  TipoPartido _tipoPartido = TipoPartido.amistoso;
  int _setsTotales = 5;

  // Step 2 – Match Config
  MatchFormat _formato = MatchFormat.bestOf5;
  Categoria _categoria = Categoria.libre;
  List<bool> _serviceOrder = [];
  bool _localServesSet1 = true;

  // Step 3 – Players
  List<Player> _allPlayers = [];
  final Set<int> _selectedIds = {};
  bool _loadingPlayers = true;
  String _filter = '';
  final Set<String> _matchCategoryFilter = {};
  final CategoryService _catService = CategoryService.instance;

  int _currentPage = 0;

  bool get _isCompetitivo =>
      _tipoPartido == TipoPartido.liga || _tipoPartido == TipoPartido.torneo;

  @override
  void initState() {
    super.initState();
    _serviceOrder = defaultServiceOrder(_setsTotales);
    _loadPlayers();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _localCtrl.dispose();
    _visitorCtrl.dispose();
    _competenciaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    try {
      await DatabaseService.instance.initialize();
      await _catService.load();
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

  void _irAlPaso(int page) {
    _pageCtrl.animateToPage(page,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _finalizar() {
    final local = _localCtrl.text.trim();
    final visitor = _visitorCtrl.text.trim();
    final selected =
        _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();

    final config = MatchConfig(
      localName: local.isNotEmpty ? local : 'Local',
      visitorName: visitor.isNotEmpty ? visitor : 'Visitante',
      setsTotales: _setsTotales,
      tipoPartido: _tipoPartido,
      lugar: null,
      competitionName: _isCompetitivo ? _competenciaCtrl.text.trim() : null,
      selectedPlayers: selected.take(12).toList(),
      formato: _formato,
      categoria: _categoria,
      serviceOrderPerSet: _serviceOrder,
      timeoutsPerSet: _categoria.timeoutsPerSet,
      timeoutDurationSeconds: _categoria.timeoutDurationSeconds,
    );

    Navigator.of(context).pop();
    Navigator.of(context, rootNavigator: true).push(
      slideRightRoute(MatchScreen(config: config)),
    );
  }

  List<Player> get _filteredPlayers {
    var result = _allPlayers;
    if (_matchCategoryFilter.isNotEmpty) {
      result = result.where((p) => _matchCategoryFilter.contains(p.categoria)).toList();
    }
    if (_filter.isNotEmpty) {
      final q = _filter.toLowerCase();
      result = result
          .where((p) =>
              NameFormatter.playerDisplayName(p).toLowerCase().contains(q) ||
              p.cedula.toLowerCase().contains(q) ||
              (p.numero?.toString() ?? '').contains(q))
          .toList();
    }
    return result;
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
                    _buildStep3(),
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
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
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
      children: [0, 1, 2].map((i) {
        final isActive = i == _currentPage;
        final isDone = i < _currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 24,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isActive
                ? AppColors.accent
                : (isDone
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : Colors.white24),
          ),
        );
      }).toList(),
    );
  }

  // ========== STEP 1 – Teams ==========

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
            style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5),
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
          if (_isCompetitivo) ...[
            const SizedBox(height: 12),
            _buildField(
                _competenciaCtrl,
                _tipoPartido == TipoPartido.liga
                    ? 'Nombre de la Liga'
                    : 'Nombre del Torneo',
                Icons.emoji_events),
          ],
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _irAlPaso(1),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Siguiente'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: TipoPartido.amistoso, child: Text('Amistoso')),
        DropdownMenuItem(value: TipoPartido.liga, child: Text('Liga')),
        DropdownMenuItem(value: TipoPartido.torneo, child: Text('Torneo')),
        DropdownMenuItem(value: TipoPartido.practica, child: Text('Práctica')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _tipoPartido = v);
      },
    );
  }

  // ========== STEP 2 – Match Config (Format, Category, Service, Timeouts) ==========

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CONFIGURACIÓN DEL PARTIDO',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 20),
            _buildFormatSelector(),
            const SizedBox(height: 16),
            _buildCategoriaDropdown(),
            const SizedBox(height: 16),
            _buildServiceSection(),
            const SizedBox(height: 16),
            _buildTimeoutSection(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _irAlPaso(0),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Atrás'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _irAlPaso(2),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Seleccionar Atletas'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.format_list_numbered,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text('Formato:',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          _formatChip(MatchFormat.bestOf3, '3 sets'),
          const SizedBox(width: 8),
          _formatChip(MatchFormat.bestOf5, '5 sets'),
        ],
      ),
    );
  }

  Widget _formatChip(MatchFormat fmt, String label) {
    final selected = _formato == fmt;
    return GestureDetector(
      onTap: () {
        setState(() {
          _formato = fmt;
          _setsTotales = fmt.totalSets;
          _serviceOrder = defaultServiceOrder(_setsTotales);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.accent : Colors.white24),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            )),
      ),
    );
  }

  Widget _buildCategoriaDropdown() {
    return DropdownButtonFormField<Categoria>(
      value: _categoria,
      dropdownColor: AppColors.surfaceLight,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Categoría',
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: const Padding(
          padding: EdgeInsetsDirectional.only(start: 12, end: 8),
          child: Icon(Icons.sports_volleyball, color: AppColors.primary, size: 20),
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: Categoria.u13, child: Text('U13')),
        DropdownMenuItem(value: Categoria.u15, child: Text('U15')),
        DropdownMenuItem(value: Categoria.u17, child: Text('U17')),
        DropdownMenuItem(value: Categoria.u19, child: Text('U19')),
        DropdownMenuItem(value: Categoria.libre, child: Text('Libre')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _categoria = v);
      },
    );
  }

  Widget _buildServiceSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_kabaddi, color: AppColors.primary, size: 18),
              SizedBox(width: 6),
              Text('Servicio',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('SET 1:',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(width: 8),
              _serviceToggle(true),
              const SizedBox(width: 6),
              _serviceToggle(false),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Rotación automática para los siguientes sets:',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(_serviceOrder.length, (i) {
              final isLocal = _serviceOrder[i];
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLocal
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: isLocal
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'SET ${i + 1}: ${isLocal ? 'Local' : 'Visitante'}',
                  style: TextStyle(
                    color: isLocal ? Colors.lightBlue : Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _serviceToggle(bool isLocal) {
    final selected = _localServesSet1 == isLocal;
    // also sync _serviceOrder[0]
    return GestureDetector(
      onTap: () {
        setState(() {
          _localServesSet1 = isLocal;
          _serviceOrder = [
            isLocal,
            ...defaultServiceOrder(_setsTotales).skip(1)
          ];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? (isLocal
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.orange.withValues(alpha: 0.3))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? (isLocal ? Colors.blue : Colors.orange)
                : Colors.white24,
          ),
        ),
        child: Text(
          isLocal ? 'Local' : 'Visitante',
          style: TextStyle(
            color: selected
                ? (isLocal ? Colors.lightBlue : Colors.orangeAccent)
                : Colors.white38,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeoutSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 6),
              Text('Tiempos Muertos',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Cantidad por set:',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const Spacer(),
              _timeoutStepper(
                  _categoria.timeoutsPerSet, (v) => _categoria = _categoria),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Duración (seg):',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const Spacer(),
              Text('${_categoria.timeoutDurationSeconds}s',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Valores predeterminados para ${_categoria.name.toUpperCase()}',
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _timeoutStepper(int value, void Function(int) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperBtn(Icons.remove, () {
          if (value > 0) onChanged(value - 1);
        }),
        const SizedBox(width: 8),
        Text('$value',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        _stepperBtn(Icons.add, () {
          if (value < 5) onChanged(value + 1);
        }),
      ],
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white54, size: 16),
      ),
    );
  }

  Widget _buildMatchCategoryFilter() {
    final cats = _catService.getAllNames();
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text('Todos', style: TextStyle(fontSize: 11, color: _matchCategoryFilter.isEmpty ? Colors.white : Colors.white54)),
              selected: _matchCategoryFilter.isEmpty,
              selectedColor: AppColors.accent.withValues(alpha: 0.3),
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() => _matchCategoryFilter.clear()),
            ),
          ),
          ...cats.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(cat, style: TextStyle(fontSize: 11, color: _matchCategoryFilter.contains(cat) ? Colors.white : Colors.white54)),
              selected: _matchCategoryFilter.contains(cat),
              selectedColor: AppColors.accent.withValues(alpha: 0.3),
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() {
                if (_matchCategoryFilter.contains(cat)) {
                  _matchCategoryFilter.remove(cat);
                } else {
                  _matchCategoryFilter.add(cat);
                }
              }),
            ),
          )),
        ],
      ),
    );
  }

  // ========== STEP 3 – Athletes ==========

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ELIGE A TUS ATLETAS',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5),
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
          _buildMatchCategoryFilter(),
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
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: _loadingPlayers
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : _allPlayers.isEmpty
                    ? _emptyState()
                    : _playerList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _irAlPaso(1),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Atrás'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _finalizar,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(
                    _selectedIds.isEmpty
                        ? 'Comenzar Partido'
                        : 'Iniciar (${_selectedIds.length})',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
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
          const Text('No hay atletas registrados',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Agrega atletas desde la sección Atletas',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
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
          color: selected
              ? AppColors.accent.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() {
          if (selected) {
            _selectedIds.remove(p.id);
          } else {
            _selectedIds.add(p.id);
          }
        }),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    selected ? AppColors.accent : AppColors.primary,
                child: Text('${p.numero}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(NameFormatter.playerDisplayName(p),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13)),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Text('Cédula: ${p.cedula}',
                            style:
                                const TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(width: 6),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(p.posicionLabel,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: (_) => setState(() {
                  if (selected) {
                    _selectedIds.remove(p.id);
                  } else {
                    _selectedIds.add(p.id);
                  }
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
