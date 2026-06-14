import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/match_config.dart';
import '../viewmodels/partido_viewmodel.dart';
import '../widgets/scoreboard_widget.dart';
import '../widgets/full_court_widget.dart';
import '../widgets/player_stats_dialog.dart';

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
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) async {
                  if (didPop) return;
                  if (context.mounted) _showExitConfirmation(context, vm);
                },
                child: Scaffold(
                  backgroundColor: AppColors.background,
                  endDrawer: _buildEndDrawer(context, vm),
                  body: SafeArea(
                    child: isWide
                        ? _buildDesktopLayout(context, vm)
                        : _buildMobileLayout(context, vm),
                  ),
                ),
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
          totalSets: vm.setsPorPartido,
          isActive: vm.isPartidoActivo,
          isFinalized: vm.isFinalizado,
          setScores: vm.setScores,
          onLocalNameTap: () => _editarNombre(context, vm, true),
          onVisitorNameTap: () => _editarNombre(context, vm, false),
          onLocalScoreTap: vm.sumarPuntoLocal,
          onLocalScoreLongPress: () => vm.restarPuntoLocal(),
          onVisitorScoreTap: vm.sumarPuntoVisitante,
          onVisitorScoreLongPress: () => vm.restarPuntoVisitante(),
          onSetTap: vm.isFinalizado ? null : (s) => vm.cambiarSet(s),
        ),
        if (!vm.isFinalizado) _buildScoreButtons(vm),
        if (!vm.isFinalizado) _buildInfoPanel(vm),
        if (!vm.isFinalizado && vm.jugadores.length >= 6) Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: FullCourtWidget(
              jugadoresLocal: vm.jugadores,
              jugadoresVisitante: vm.jugadoresVisitante,
              rotacionLocal: vm.rotacionLocal,
              rotacionVisitante: vm.rotacionVisitante,
              isLocalServing: vm.isLocalServing,
              onRotarLocal: vm.rotarLocal,
              onRotarVisitante: vm.rotarVisitante,
              onCambiarServicio: vm.cambiarServicio,
            ),
          ),
        ),
        if (vm.isFinalizado) _buildFinalResult(vm) else _buildBottomBar(vm),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, PartidoViewModel vm) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
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
              totalSets: vm.setsPorPartido,
              isActive: vm.isPartidoActivo,
              isFinalized: vm.isFinalizado,
              setScores: vm.setScores,
              onLocalNameTap: () => _editarNombre(context, vm, true),
              onVisitorNameTap: () => _editarNombre(context, vm, false),
              onLocalScoreTap: vm.sumarPuntoLocal,
              onLocalScoreLongPress: () => vm.restarPuntoLocal(),
              onVisitorScoreTap: vm.sumarPuntoVisitante,
              onVisitorScoreLongPress: () => vm.restarPuntoVisitante(),
              onSetTap: vm.isFinalizado ? null : (s) => vm.cambiarSet(s),
            ),
            if (!vm.isFinalizado) _buildScoreButtons(vm),
            if (!vm.isFinalizado) _buildInfoPanel(vm),
            if (!vm.isFinalizado && vm.jugadores.length >= 6) Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: FullCourtWidget(
                  jugadoresLocal: vm.jugadores,
                  jugadoresVisitante: vm.jugadoresVisitante,
                  rotacionLocal: vm.rotacionLocal,
                  rotacionVisitante: vm.rotacionVisitante,
                  isLocalServing: vm.isLocalServing,
                  onRotarLocal: vm.rotarLocal,
                  onRotarVisitante: vm.rotarVisitante,
                  onCambiarServicio: vm.cambiarServicio,
                ),
              ),
            ),
            if (vm.isFinalizado) _buildFinalResult(vm) else _buildBottomBar(vm),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, PartidoViewModel vm) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      toolbarHeight: 44,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => _showExitConfirmation(context, vm),
      ),
      title: const Text('Partido', style: TextStyle(color: Colors.white, fontSize: 15)),
      centerTitle: true,
      actions: [
        if (widget.config?.selectedPlayers.isNotEmpty == true)
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              tooltip: 'Ver atletas',
            ),
          ),
        _pausePlayBtn(vm),
        _settingsBtn(context, vm),
      ],
    );
  }

  Widget _pausePlayBtn(PartidoViewModel vm) {
    if (vm.isFinalizado) return const SizedBox.shrink();
    return IconButton(
      icon: Icon(
        vm.isPartidoActivo ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
      ),
      onPressed: vm.pausarReanudar,
    );
  }

  Widget _settingsBtn(BuildContext context, PartidoViewModel vm) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (v) {
        switch (v) {
          case 'config':
            _showConfigDialog(context, vm);
          case 'undo':
            vm.undoLastPoint();
          case 'end':
            _confirmEndDialog(context, vm);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'config',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.tune, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 8),
              const Text('Configuración'),
            ],
          ),
        ),
        if (!vm.isFinalizado) ...[
          const PopupMenuDivider(),
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
              children: [
                Icon(Icons.stop, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('Finalizar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showConfigDialog(BuildContext context, PartidoViewModel vm) {
    int puntos = vm.puntosPorSet;
    int sets = vm.setsPorPartido;
    int tiempo = vm.tiempoPorSet;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.tune, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text('Configuración', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _configLabel('Puntos para ganar el set'),
                const SizedBox(height: 8),
                _configChips(ctx, [15, 21, 25], puntos, (v) {
                  setDialogState(() => puntos = v);
                }),
                const SizedBox(height: 16),
                _configLabel('Sets por partido'),
                const SizedBox(height: 8),
                _configChips(ctx, [3, 5], sets, (v) {
                  setDialogState(() => sets = v);
                }),
                const SizedBox(height: 16),
                _configLabel('Tiempo por set'),
                const SizedBox(height: 8),
                _configChips(ctx, [0, 5, 10], tiempo, (v) {
                  setDialogState(() => tiempo = v);
                }, labels: {0: 'Sin límite', 5: '5 min', 10: '10 min'}),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                vm.actualizarConfiguracion(
                  puntosPorSet: puntos,
                  setsPorPartido: sets,
                  tiempoPorSet: tiempo,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _configLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _configChips(
    BuildContext ctx,
    List<int> values,
    int selected,
    ValueChanged<int> onChanged, {
    Map<int, String>? labels,
  }) {
    return Row(
      children: values.map((v) {
        final isSelected = v == selected;
        final label = labels?[v] ?? '$v';
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.accent : Colors.white24,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _confirmEndDialog(BuildContext context, PartidoViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Finalizar partido', style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que quieres finalizar el partido?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
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

  void _showExitConfirmation(BuildContext context, PartidoViewModel vm) {
    if (vm.match == null || vm.isFinalizado) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text('Salir del partido', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          '¿Seguro que quieres salir?\n\nSi finalizas el partido se guardará el resultado actual.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Volver al partido', style: TextStyle(color: AppColors.accent)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.eliminarPartido();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Salir sin guardar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.finalizarPartido();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Finalizar partido', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEndDrawer(BuildContext context, PartidoViewModel vm) {
    final config = widget.config;
    if (config == null || config.selectedPlayers.isEmpty) return const SizedBox.shrink();

    final players = List<Player>.from(config.selectedPlayers)
      ..sort((a, b) => (a.numero ?? 0).compareTo(b.numero ?? 0));

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Atletas (${players.length})',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: players.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                itemBuilder: (_, i) {
                  final p = players[i];
                  final parts = p.nombre.trim().split(RegExp(r'\s+'));
                  final firstName = parts.isNotEmpty ? parts[0] : p.nombre;
                  final lastNameInitial = parts.length > 1 ? parts.last[0].toUpperCase() : '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            '${p.numero}',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$firstName ${lastNameInitial.isNotEmpty ? '$lastNameInitial.' : ''}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.posicionLabel,
                            style: const TextStyle(
                              color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => PlayerStatsDialog(
                              player: p,
                              matchId: vm.match?.id ?? 0,
                              setNumero: vm.setActual,
                              puntoLocal: vm.puntosLocal,
                              puntoVisitante: vm.puntosVisitante,
                              esEquipoLocal: true,
                            ),
                          ),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, color: AppColors.accent, size: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: const Text(
                'Toca + para registrar estadísticas',
                style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreButtons(PartidoViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: vm.isPartidoActivo ? vm.sumarPuntoLocal : null,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                vm.nombreLocal.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: vm.isPartidoActivo ? vm.sumarPuntoVisitante : null,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                vm.nombreVisitante.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(PartidoViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: vm.isFinalizado ? null : () => _showSetSelector(context, vm),
            child: _infoChip(
              Icons.emoji_events,
              '${vm.setsLocal} - ${vm.setsVisitante}',
              'Set ${vm.setActual}/${vm.setsPorPartido}',
            ),
          ),
          const SizedBox(width: 8),
          _infoChip(
            Icons.timer_outlined,
            vm.isPartidoActivo ? 'En juego' : 'Pausado',
            'Estado',
          ),
          const SizedBox(width: 8),
          _infoChip(
            Icons.access_time,
            vm.tiempoTranscurrido,
            vm.isPartidoActivo ? 'Tiempo' : 'Detenido',
          ),
          if (vm.tiempoPorSet > 0) ...[
            const SizedBox(width: 8),
            _infoChip(
              Icons.hourglass_empty,
              '${vm.tiempoPorSet} min',
              'Límite',
            ),
          ],
          const Spacer(),
          Text(
            '${vm.puntosPorSet} pts/set',
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showSetSelector(BuildContext context, PartidoViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.swap_horiz, color: AppColors.accent, size: 18),
                SizedBox(width: 8),
                Text('Seleccionar set', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(vm.setsPorPartido, (i) {
                final setNum = i + 1;
                final isCurrent = setNum == vm.setActual;
                return GestureDetector(
                  onTap: () {
                    vm.cambiarSet(setNum);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? AppColors.accent : Colors.white24,
                        width: isCurrent ? 1 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'SET $setNum',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${vm.setScores.length > i ? vm.setScores[i].key : 0} - ${vm.setScores.length > i ? vm.setScores[i].value : 0}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white70 : Colors.white38,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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

  Widget _infoChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PartidoViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vm.nombreLocal.toUpperCase(),
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(width: 8),
            _restarBtn(vm.restarPuntoLocal, vm.puntosLocal > 0 && vm.isPartidoActivo),
            const SizedBox(width: 24),
            Text('QUITAR', style: TextStyle(color: Colors.white24, fontSize: 8, letterSpacing: 1)),
            const SizedBox(width: 24),
            _restarBtn(vm.restarPuntoVisitante, vm.puntosVisitante > 0 && vm.isPartidoActivo),
            const SizedBox(width: 8),
            Text(vm.nombreVisitante.toUpperCase(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _restarBtn(VoidCallback? onPressed, bool enabled) {
    return FloatingActionButton.small(
      onPressed: enabled ? onPressed : null,
      backgroundColor: AppColors.surfaceLight,
      child: const Icon(Icons.remove, color: Colors.white70),
    );
  }

  Widget _buildFinalResult(PartidoViewModel vm) {
    final winner = vm.setsLocal > vm.setsVisitante ? vm.nombreLocal : vm.nombreVisitante;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
          const SizedBox(height: 8),
          const Text('FINALIZADO', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(
            '$winner GANA',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            '${vm.setsLocal} - ${vm.setsVisitante}',
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 28),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Volver'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
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
}
