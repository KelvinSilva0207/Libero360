import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/player.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../data/match_config.dart';
import '../viewmodels/partido_viewmodel.dart';
import '../widgets/scoreboard_widget.dart';
import '../widgets/volleyball_court_widget.dart';
import '../widgets/action_buttons_widget.dart';
import '../widgets/roster_management_sheet.dart';

class MatchScreen extends StatefulWidget {
  final MatchConfig? config;
  const MatchScreen({super.key, this.config});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PartidoViewModel()..init(widget.config),
      child: Consumer<PartidoViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.match == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo_libero.png', width: 80, height: 80),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: AppColors.accent),
                  const SizedBox(height: 12),
                  const Text('Iniciando partido...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
          );
        }

        if (vm.error != null && vm.match == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(vm.error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => vm.init(widget.config),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  ),
                ],
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 768;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: isWide ? _buildDesktopLayout(context, vm) : _buildMobileLayout(context, vm),
              ),
              bottomNavigationBar: _buildBottomNav(context, vm, isWide),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              floatingActionButton: _buildFab(vm, isWide),
              endDrawer: _buildRosterDrawer(vm),
            );
          },
        );
      },
      ),
    );
  }

  Widget _buildRosterDrawer(PartidoViewModel vm) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.background,
              child: Row(
                children: [
                  const Icon(Icons.people, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  const Text('Roster del Partido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: vm.jugadores.length,
                itemBuilder: (context, index) {
                  final j = vm.jugadores[index];
                  final isStarter = index < 6;
                  final zIndex = index < 6 ? _zoneLabel(index) : 'SUP';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: j.id == vm.jugadorSeleccionado?.id ? AppColors.accent.withValues(alpha: 0.4) : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isStarter ? AppColors.primary : Colors.grey.shade700,
                        child: Text('${j.numero}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                      ),
                      title: Text(j.nombre, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Row(
                        children: [
                          Text(j.posicionLabel, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(zIndex, style: const TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          if (!isStarter) ...[
                            const SizedBox(width: 6),
                            const Text('Banca', style: TextStyle(color: Colors.white24, fontSize: 9)),
                          ],
                        ],
                      ),
                      onTap: () {
                        vm.seleccionarJugador(j);
                        if (index >= 6) vm.seleccionarTeam(vm.teamSeleccionado);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, PartidoViewModel vm) {
    return Column(
      children: [
        _buildAppBar(context, vm),
        ScoreboardWidget(
          localName: vm.nombreLocal,
          visitorName: vm.nombreVisitante,
          localPoints: vm.puntosLocal,
          visitorPoints: vm.puntosVisitante,
          localSets: vm.setsLocal,
          visitorSets: vm.setsVisitante,
          currentSet: vm.setActual,
          isActive: vm.isPartidoActivo,
          onLocalNameTap: () => _editarNombre(context, vm, true),
          onVisitorNameTap: () => _editarNombre(context, vm, false),
          onLocalScoreTap: vm.sumarPuntoLocal,
          onLocalScoreLongPress: () => vm.restarPuntoLocal(),
          onVisitorScoreTap: vm.sumarPuntoVisitante,
          onVisitorScoreLongPress: () => vm.restarPuntoVisitante(),
        ),
        _buildTeamSelector(context, vm),
        Expanded(
          child: Stack(
            children: [
              VolleyballCourtWidget(
                jugadores: vm.jugadores,
                seleccionado: vm.jugadorSeleccionado,
                onSeleccionar: vm.seleccionarJugador,
                esLocal: vm.teamSeleccionado == 0,
                onNumeroEdit: (i, n) => vm.actualizarNumeroJugador(i, n),
              ),
              Positioned(
                right: 6,
                top: 6,
                bottom: 6,
                width: 90,
                child: ActionButtonsWidget(
                  canAct: vm.isPartidoActivo,
                  hasSelection: vm.jugadorSeleccionado != null,
                  onPositiva: (tipo) => vm.registrarAccion(tipo, positivo: true),
                  onNegativa: (tipo) => vm.registrarAccion(tipo, positivo: false),
                  onErrorContrario: vm.registrarErrorContrario,
                ),
              ),
            ],
          ),
        ),
        _buildBenchBar(vm),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, PartidoViewModel vm) {
    return Row(
      children: [
        SizedBox(
          width: 340,
          child: Column(
            children: [
              _buildDesktopAppBar(context, vm),
              ScoreboardWidget(
                localName: vm.nombreLocal,
                visitorName: vm.nombreVisitante,
                localPoints: vm.puntosLocal,
                visitorPoints: vm.puntosVisitante,
                localSets: vm.setsLocal,
                visitorSets: vm.setsVisitante,
                currentSet: vm.setActual,
                isActive: vm.isPartidoActivo,
                onLocalNameTap: () => _editarNombre(context, vm, true),
                onVisitorNameTap: () => _editarNombre(context, vm, false),
                onLocalScoreTap: vm.sumarPuntoLocal,
                onLocalScoreLongPress: () => vm.restarPuntoLocal(),
                onVisitorScoreTap: vm.sumarPuntoVisitante,
                onVisitorScoreLongPress: () => vm.restarPuntoVisitante(),
              ),
              _buildTeamSelector(context, vm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: ActionButtonsWidget(
                    canAct: vm.isPartidoActivo,
                    hasSelection: vm.jugadorSeleccionado != null,
                    onPositiva: (tipo) => vm.registrarAccion(tipo, positivo: true),
                    onNegativa: (tipo) => vm.registrarAccion(tipo, positivo: false),
                    onErrorContrario: vm.registrarErrorContrario,
                  ),
                ),
              ),
              _buildBenchBar(vm),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: Colors.white12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: VolleyballCourtWidget(
              jugadores: vm.jugadores,
              seleccionado: vm.jugadorSeleccionado,
              onSeleccionar: vm.seleccionarJugador,
              esLocal: vm.teamSeleccionado == 0,
              onNumeroEdit: (i, n) => vm.actualizarNumeroJugador(i, n),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, PartidoViewModel vm) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      toolbarHeight: 44,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Partido', style: TextStyle(color: Colors.white, fontSize: 15)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.people_alt, color: vm.jugadores.length > 6 ? AppColors.accent : Colors.white54),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
          tooltip: 'Plantilla',
        ),
        _pausePlayBtn(vm),
        _moreBtn(context, vm),
      ],
    );
  }

  Widget _buildDesktopAppBar(BuildContext context, PartidoViewModel vm) {
    return Container(
      height: 48,
      color: AppColors.surface,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Partido', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: Icon(Icons.people_alt, color: vm.jugadores.length > 6 ? AppColors.accent : Colors.white54),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Plantilla',
          ),
          _pausePlayBtn(vm),
          _moreBtn(context, vm),
        ],
      ),
    );
  }

  Widget _pausePlayBtn(PartidoViewModel vm) {
    return IconButton(
      icon: Icon(vm.isPartidoActivo ? Icons.pause : Icons.play_arrow, color: Colors.white),
      onPressed: vm.pausarReanudar,
    );
  }

  Widget _moreBtn(BuildContext context, PartidoViewModel vm) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (v) {
        switch (v) {
          case 'undo':
            vm.undoLastPoint();
          case 'end':
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Finalizar partido', style: TextStyle(color: Colors.white)),
                content: const Text('¿Seguro que quieres finalizar el partido?', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      vm.finalizarPartido();
                    },
                    child: const Text('Finalizar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'undo',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.undo, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 8),
              const Text('Deshacer último punto'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'end',
          child: Row(
            children: [Icon(Icons.stop, color: Colors.red, size: 20), SizedBox(width: 8), Text('Finalizar')],
          ),
        ),
      ],
    );
  }

  void _editarNombre(BuildContext context, PartidoViewModel vm, bool isLocal) {
    final controller = TextEditingController(text: isLocal ? vm.nombreLocal : vm.nombreVisitante);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Editar ${isLocal ? 'Local' : 'Visitante'}', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Nombre del equipo',
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                if (isLocal) {
                  vm.actualizarNombreLocal(name);
                } else {
                  vm.actualizarNombreVisitante(name);
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelector(BuildContext context, PartidoViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => vm.seleccionarTeam(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: vm.teamSeleccionado == 0 ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  vm.nombreLocal,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: vm.teamSeleccionado == 0 ? AppColors.accent : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('vs', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => vm.seleccionarTeam(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: vm.teamSeleccionado == 1 ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  vm.nombreVisitante,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: vm.teamSeleccionado == 1 ? AppColors.accent : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchBar(PartidoViewModel vm) {
    final benchPlayers = vm.jugadores.length > 6 ? vm.jugadores.sublist(6) : <Player>[];
    if (benchPlayers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.check_box_outlined, color: AppColors.accent, size: 16),
              const SizedBox(width: 6),
              const Text('BANCA', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11)),
              const Spacer(),
              Text('${benchPlayers.length} jugadores', style: const TextStyle(color: Colors.white24, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: benchPlayers.length,
              itemBuilder: (context, index) {
                final j = benchPlayers[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: vm.isPartidoActivo ? () => vm.seleccionarJugador(j) : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: j.id == vm.jugadorSeleccionado?.id ? AppColors.accent : Colors.grey.shade700,
                          child: Text(
                            '${j.numero}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(j.posicionLabel, style: const TextStyle(fontSize: 7, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, PartidoViewModel vm, bool isWide) {
    return BottomAppBar(
      shape: isWide ? null : const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppColors.surface,
      elevation: 12,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.people_outline, 'PLANTILLA', false, onTap: () => _abrirPlantilla(context, vm)),
            _navItem(Icons.analytics_outlined, 'ANALYTICS', false),
            if (!isWide) const SizedBox(width: 48),
            _navItem(Icons.grid_view_outlined, 'TACTICS', false),
            _navItem(Icons.settings_outlined, 'SETTINGS', false),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppColors.primary : Colors.grey, size: 22),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: active ? AppColors.primary : Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirPlantilla(BuildContext context, PartidoViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await DatabaseService.instance.initialize();
      if (!mounted) return;
      final result = await showModalBottomSheet<List<Player>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RosterManagementSheet(currentRoster: vm.jugadores),
      );
      if (result != null && mounted) {
        vm.setJugadores(result);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error al abrir plantilla: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildFab(PartidoViewModel vm, bool isWide) {
    return FloatingActionButton(
      onPressed: vm.isPartidoActivo ? () => vm.rotarJugadores() : null,
      backgroundColor: AppColors.primary,
      elevation: 8,
      child: const Text('ROTAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  String _zoneLabel(int index) {
    const labels = ['Z4', 'Z3', 'Z2', 'Z5', 'Z6', 'Z1'];
    return index < labels.length ? labels[index] : 'Z?';
  }
}
