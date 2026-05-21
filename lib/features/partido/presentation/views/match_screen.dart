import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/partido_viewmodel.dart';
import '../widgets/scoreboard_widget.dart';
import '../widgets/volleyball_court_widget.dart';
import '../widgets/action_buttons_widget.dart';

const _bg = Color(0xFF0F172A);
const _surface = Color(0xFF1E293B);
const _accent = Color(0xFFFF8C00);
const _primary = Color(0xFF0081CF);

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PartidoViewModel()..init(),
      child: Consumer<PartidoViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.match == null) {
          return Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo_libero.png', width: 80, height: 80),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: _accent),
                  const SizedBox(height: 12),
                  const Text('Iniciando partido...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
          );
        }

        if (vm.error != null && vm.match == null) {
          return Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(vm.error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => vm.init(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: FilledButton.styleFrom(backgroundColor: _accent),
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
              backgroundColor: _bg,
              body: SafeArea(
                child: isWide ? _buildDesktopLayout(context, vm) : _buildMobileLayout(context, vm),
              ),
              bottomNavigationBar: _buildBottomNav(context, vm, isWide),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              floatingActionButton: _buildFab(vm, isWide),
            );
          },
        );
      },
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
          onLocalScoreLongPress: vm.restarPuntoLocal,
          onVisitorScoreTap: vm.sumarPuntoVisitante,
          onVisitorScoreLongPress: vm.restarPuntoVisitante,
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
                onLocalScoreLongPress: vm.restarPuntoLocal,
                onVisitorScoreTap: vm.sumarPuntoVisitante,
                onVisitorScoreLongPress: vm.restarPuntoVisitante,
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
      backgroundColor: _surface,
      elevation: 0,
      toolbarHeight: 44,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Partido', style: TextStyle(color: Colors.white, fontSize: 15)),
      centerTitle: true,
      actions: [_pausePlayBtn(vm), _moreBtn(context, vm)],
    );
  }

  Widget _buildDesktopAppBar(BuildContext context, PartidoViewModel vm) {
    return Container(
      height: 48,
      color: _surface,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Partido', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
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
        if (v == 'end') {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Finalizar partido'),
              content: const Text('¿Seguro que quieres finalizar el partido?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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
        title: Text('Editar ${isLocal ? 'Local' : 'Visitante'}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre del equipo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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
            child: const Text('Guardar'),
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
                      color: vm.teamSeleccionado == 0 ? _accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  vm.nombreLocal,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: vm.teamSeleccionado == 0 ? _accent : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('vs', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => vm.seleccionarTeam(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: vm.teamSeleccionado == 1 ? _accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  vm.nombreVisitante,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: vm.teamSeleccionado == 1 ? _accent : Colors.white54,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.check_box_outlined, color: _accent, size: 16),
              const SizedBox(width: 6),
              const Text('¿CAMBIO?', style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: vm.jugadores.length > 6 ? vm.jugadores.length - 6 : 0,
              itemBuilder: (context, index) {
                final j = vm.jugadores[index + 6];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: vm.isPartidoActivo ? () => vm.seleccionarJugador(j) : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: j.id == vm.jugadorSeleccionado?.id ? _accent : Colors.grey.shade700,
                          child: Text(
                            '${j.numero}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('Banca', style: TextStyle(fontSize: 9, color: Colors.grey)),
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
      color: _surface,
      elevation: 12,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.people_outline, 'ROSTER', false),
            _navItem(Icons.analytics_outlined, 'ANALYTICS', false),
            if (!isWide) const SizedBox(width: 48),
            _navItem(Icons.grid_view_outlined, 'TACTICS', false),
            _navItem(Icons.settings_outlined, 'SETTINGS', false),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: active ? _primary : Colors.grey, size: 22),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: active ? _primary : Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFab(PartidoViewModel vm, bool isWide) {
    return FloatingActionButton(
      onPressed: vm.isPartidoActivo ? () => vm.rotarJugadores() : null,
      backgroundColor: _primary,
      elevation: 8,
      child: const Text('ROTAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

