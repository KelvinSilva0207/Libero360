import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/court_state.dart';
import '../../data/match_config.dart';
import '../../data/rotation_data.dart';
import '../controllers/match_controller.dart';
import '../viewmodels/partido_viewmodel.dart';
import '../widgets/court_widget.dart';
import '../widgets/match_header.dart';
import '../widgets/match_scoreboard.dart';
import '../widgets/players_drawer.dart';
import '../widgets/quick_stats_widget.dart';
import '../widgets/rotation_tab.dart';
import '../widgets/service_history_widget.dart';
import '../widgets/service_widget.dart';
import '../widgets/set_start_dialog.dart';
import '../widgets/substitution_dialog.dart';
import '../widgets/tactical_board_widget.dart';
import '../widgets/timeout_indicator.dart';
import '../widgets/timeout_overlay.dart';

class MatchScreen extends StatefulWidget {
  final MatchConfig? config;
  const MatchScreen({super.key, this.config});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final RotationManager _rotationManager;
  int _previousSet = 1;
  CourtPerspective _perspective = CourtPerspective.right;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _rotationManager = RotationManager();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rotationManager.dispose();
    super.dispose();
  }

  void _checkSetChange(PartidoViewModel vm) {
    final currentSet = vm.setActual;
    if (currentSet != _previousSet && currentSet > 1) {
      _previousSet = currentSet;
      _showSetStartDialog(currentSet, vm);
    }
  }

  Future<void> _showSetStartDialog(int setNumber, PartidoViewModel vm) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SetStartDialog(
        setNumber: setNumber,
        hasPreviousSet: setNumber > 1,
      ),
    );

    if (result == null || !mounted) return;

    _rotationManager.prepareNewSet(setNumber);
    if (result['usePrevious'] == true) {
      _rotationManager.usePreviousRotation();
    } else {
      final slots = result['slots'] as List<int?>;
      _rotationManager.setSlots(slots);
    }
  }

  void _onRotate() {
    _rotationManager.rotate();
  }

  void _onZoneTap(int zoneNumber) {
    showDialog(
      context: context,
      builder: (ctx) => _PlayerNumberPicker(
        onSelected: (number) {
          _rotationManager.assignPlayerByZone(zoneNumber, number);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _togglePerspective() {
    setState(() {
      _perspective = _perspective == CourtPerspective.right
          ? CourtPerspective.left
          : CourtPerspective.right;
    });
  }

  List<Player> _benchPlayers(PartidoViewModel vm) {
    final courtNumbers = _rotationManager.slots
        .whereType<int>()
        .toSet();
    return vm.jugadores
        .where((p) => !courtNumbers.contains(p.numero))
        .toList();
  }

  List<Player> _courtPlayers(PartidoViewModel vm) {
    final courtNumbers = _rotationManager.slots
        .whereType<int>()
        .toSet();
    return vm.jugadores
        .where((p) => courtNumbers.contains(p.numero))
        .toList();
  }

  Future<void> _onSubstitute(Player benchPlayer, PartidoViewModel vm) async {
    final courtPlayers = _courtPlayers(vm);
    if (courtPlayers.isEmpty) return;

    final playerOut = await showDialog<Player>(
      context: context,
      builder: (_) => SubstitutionDialog(
        courtPlayers: courtPlayers,
        benchPlayer: benchPlayer,
      ),
    );

    if (playerOut == null || !mounted) return;

    vm.addSubstitution(
      playerOutNumber: playerOut.numero ?? 0,
      playerInNumber: benchPlayer.numero ?? 0,
      playerOutName: playerOut.displayName.isNotEmpty
          ? playerOut.displayName
          : '${playerOut.firstNames} ${playerOut.lastNames}'.trim(),
      playerInName: benchPlayer.displayName.isNotEmpty
          ? benchPlayer.displayName
          : '${benchPlayer.firstNames} ${benchPlayer.lastNames}'.trim(),
      setNumber: vm.setActual,
      rotationIndex: _rotationManager.rotationIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PartidoViewModel(context.read<MatchController>())
        ..init(widget.config),
      child: Consumer<PartidoViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.match == null) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (vm.error != null && vm.match == null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(vm.error!, style: const TextStyle(color: Colors.white54)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => vm.init(widget.config),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          _checkSetChange(vm);

          return Stack(
            children: [
              ListenableBuilder(
                listenable: _rotationManager,
                builder: (context, _) {
                  final courtState = _rotationManager.courtState
                      .withPerspective(_perspective);

                  return Scaffold(
                backgroundColor: AppColors.background,
                endDrawer: PlayersDrawer(
                  benchPlayers: _benchPlayers(vm),
                  onSubstitute: (p) => _onSubstitute(p, vm),
                ),
                appBar: AppBar(
                  backgroundColor: AppColors.surface,
                  elevation: 0,
                  title: Text(
                    '${vm.nombreLocal} vs ${vm.nombreVisitante}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.accent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'JUEGO'),
                      Tab(text: 'ROTACIONES'),
                      Tab(text: 'PIZARRA'),
                    ],
                  ),
                  actions: [
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: Icon(
                          vm.editMode
                              ? Icons.edit
                              : Icons.edit_outlined,
                          color: vm.editMode
                              ? AppColors.accent
                              : Colors.white54,
                          size: 20,
                        ),
                        onPressed: vm.toggleEditMode,
                        tooltip: 'Editar',
                      ),
                    ),
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.people_outline, color: Colors.white54),
                        onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                        tooltip: 'Atletas',
                      ),
                    ),
                  ],
                ),
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJuegoTab(vm, courtState),
                    _buildRotacionesTab(vm),
                    _buildPizarraTab(),
                  ],
                ),
              );
            },
          ),
              if (vm.timeoutState != TimeoutState.idle)
                TimeoutOverlay(
                  countdown: vm.timeoutCountdown,
                  initialCountdown: vm.timeoutDurationSeconds,
                  isLocal: vm.activeTimeoutIsLocal,
                  teamName: vm.activeTimeoutIsLocal
                      ? vm.nombreLocal
                      : vm.nombreVisitante,
                  onCancel: vm.cancelTimeout,
                  onDismiss: vm.dismissTimeoutResult,
                  state: vm.timeoutState,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJuegoTab(PartidoViewModel vm, CourtState courtState) {
    return SingleChildScrollView(
      child: Column(
        children: [
          MatchHeader(
            localName: vm.nombreLocal,
            visitorName: vm.nombreVisitante,
            setActual: vm.setActual,
            setsTotales: vm.setsPorPartido,
          ),
          MatchScoreBoard(
            localScore: vm.puntosLocal,
            visitorScore: vm.puntosVisitante,
            localSets: vm.setsLocal,
            visitorSets: vm.setsVisitante,
            isLocalServing: vm.isLocalServing,
          ),
          _buildTimeoutRow(vm),
          CourtWidget(
            state: courtState,
            onZoneTap: _onZoneTap,
            onTogglePerspective: _togglePerspective,
          ),
          _buildServerioRow(),
          ServiceWidget(
            serverNumber: _rotationManager.currentServerNumber,
            consecutivePoints: _rotationManager.consecutivePoints,
            rotationCount: _rotationManager.rotationIndex,
          ),
          ServiceHistoryWidget(),
          QuickStatsWidget(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimeoutRow(PartidoViewModel vm) {
    final isActive = vm.isPartidoActivo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TimeoutIndicator(
              remaining: vm.localTimeoutsRemaining,
              max: vm.timeoutsPerSet,
              teamName: vm.nombreLocal,
              isLocal: true,
              onTap: isActive ? () => vm.startTimeout(true) : null,
              disabled: !isActive || vm.localTimeoutsRemaining == 0,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '⏱',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TimeoutIndicator(
              remaining: vm.visitorTimeoutsRemaining,
              max: vm.timeoutsPerSet,
              teamName: vm.nombreVisitante,
              isLocal: false,
              onTap: isActive ? () => vm.startTimeout(false) : null,
              disabled: !isActive || vm.visitorTimeoutsRemaining == 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerioRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Rotación #${_rotationManager.rotationIndex + 1}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _onRotate,
              icon: const Icon(Icons.rotate_right, size: 16),
              label: const Text('Rotar', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotacionesTab(PartidoViewModel vm) {
    return RotationTab(
      manager: _rotationManager,
      currentSet: vm.setActual,
      onRotate: _onRotate,
      onSlotTap: (slot) =>
          _onZoneTap(RotationManager.visualToZone[slot]),
    );
  }

  Widget _buildPizarraTab() {
    return const TacticalBoardWidget();
  }
}

class _PlayerNumberPicker extends StatelessWidget {
  final ValueChanged<int> onSelected;

  const _PlayerNumberPicker({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Número de jugador',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(20, (i) {
                final num = i + 1;
                return GestureDetector(
                  onTap: () => onSelected(num),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.3),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: Text(
                        '$num',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
