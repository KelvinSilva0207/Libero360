import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/log_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../statistics/data/rotation_stats_model.dart';
import '../../data/court_state.dart';
import '../../data/match_config.dart';
import '../../data/libero_config.dart';
import '../../data/match_end_record.dart';
import '../../data/player_action.dart';
import '../../data/rotation_data.dart';
import '../../data/set_end_record.dart';
import '../../data/timeline_event.dart';
import '../controllers/libero_manager.dart';
import '../widgets/rotation_history_widget.dart';
import '../controllers/match_controller.dart';
import '../viewmodels/partido_viewmodel.dart';
import '../widgets/court_widget.dart';
import '../widgets/match_end_dialog.dart';
import '../widgets/match_header.dart';
import '../widgets/match_timeline_sheet.dart';
import '../widgets/set_end_dialog.dart';
import '../widgets/match_scoreboard.dart';
import '../widgets/players_drawer.dart';
import '../widgets/libero_sheet.dart';
import '../widgets/player_action_anim.dart';
import '../widgets/player_action_sheet.dart';
import '../widgets/player_stats_card.dart';
import '../widgets/quick_stats_widget.dart';
import '../widgets/rotation_tab.dart';
import '../widgets/service_history_sheet.dart';
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
  int _prevLocalPoints = 0;
  int _prevVisitorPoints = 0;
  bool _prevLocalServing = true;
  int _prevTrackedSet = 1;
  CourtPerspective _perspective = CourtPerspective.right;
  int? _selectedZone;

  final List<PlayerActionEvent> _actionEvents = [];
  int _actionAnimCounter = 0;
  ActionType? _lastActionType;
  String? _lastActionPlayer;
  int _lastActionKey = 0;

  LiberoManager? _liberoManager;
  final DateTime _matchStartTime = DateTime.now();
  final Map<int, DateTime> _setStartTimes = {1: DateTime.now()};
  final List<TimelineEvent> _setEndEntries = [];
  int _eventIdCounter = 0;
  bool _matchEndShown = false;
  bool _initialAssignmentDone = false;
  MatchEndRecord? _matchEndRecord;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _rotationManager = RotationManager();
    if (widget.config?.liberoConfig.hasLiberos == true) {
      _liberoManager = LiberoManager(config: widget.config!.liberoConfig);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rotationManager.dispose();
    _liberoManager?.dispose();
    super.dispose();
  }

  void _trackPoints(PartidoViewModel vm) {
    final localPoints = vm.puntosLocal;
    final visitorPoints = vm.puntosVisitante;
    final currentSet = vm.setActual;

    // Sync serving state on set change (avoids false side-out detection)
    if (currentSet != _prevTrackedSet) {
      _prevLocalServing = vm.isLocalServing;
      _prevTrackedSet = currentSet;
      _prevLocalPoints = localPoints;
      _prevVisitorPoints = visitorPoints;
      LogService.instance.auto('🟡 Rotation — nuevo set $currentSet, servicio: ${vm.isLocalServing ? 'local' : 'visitante'}', source: 'MatchScreen');
      return;
    }

    if (localPoints > _prevLocalPoints) {
      _rotationManager.recordPointForCurrentRotation(localScored: true);
      LogService.instance.auto('🟢 Service — punto registrado (local)', source: 'MatchScreen');
    } else if (visitorPoints > _prevVisitorPoints) {
      _rotationManager.recordPointForCurrentRotation(localScored: false);
      LogService.instance.auto('🟢 Service — punto registrado (visitante)', source: 'MatchScreen');
    }

    // Side-out detection: serving team changed
    final currentServing = vm.isLocalServing;
    if (currentServing != _prevLocalServing) {
      if (currentServing && _rotationManager.isComplete()) {
        LogService.instance.auto('🟡 Rotation — side-out, local rota', source: 'MatchScreen');
        _rotationManager.rotate();
        _checkLiberoAutoZone();
      }
      if (!currentServing) {
        LogService.instance.auto('🟢 Service — local pierde saque', source: 'MatchScreen');
      }
      _prevLocalServing = currentServing;
    }

    _prevLocalPoints = localPoints;
    _prevVisitorPoints = visitorPoints;
  }

  String? _findPlayerName(int? number, PartidoViewModel vm) {
    if (number == null) return null;
    try {
      final p = vm.jugadores.firstWhere((p) => p.numero == number);
      return NameFormatter.playerMatchName(p);
    } catch (_) {
      return null;
    }
  }

  SetEndRecord _computeSetEndInfo(int setNumber, int finalLocal, int finalVisitor, PartidoViewModel vm) {
    // Duration
    final setStart = _setStartTimes[setNumber] ?? DateTime.now();
    final duration = DateTime.now().difference(setStart).inSeconds;

    // Winner
    final winnerName = finalLocal > finalVisitor ? vm.nombreLocal : vm.nombreVisitante;

    // MVP: top scorer by action point values
    String? mvpName;
    int? mvpPts;
    if (_actionEvents.isNotEmpty) {
      final pointsByPlayer = <int, int>{};
      for (final a in _actionEvents.where((a) => a.setNumber == setNumber)) {
        pointsByPlayer.update(a.playerNumber, (v) => v + a.type.value, ifAbsent: () => a.type.value);
      }
      if (pointsByPlayer.isNotEmpty) {
        final best = pointsByPlayer.entries.reduce((a, b) => a.value > b.value ? a : b);
        mvpName = _findPlayerName(best.key, vm) ?? '#${best.key}';
        mvpPts = best.value;
      }
    }

    // Best service: max consecutive points
    String? bestServer;
    int? bestStreak;
    final setServices = _rotationManager.serviceHistory.where((s) => s.setNumber == setNumber).toList();
    if (setServices.isNotEmpty) {
      final best = setServices.reduce((a, b) => a.consecutivePoints > b.consecutivePoints ? a : b);
      bestServer = _findPlayerName(best.playerNumber, vm) ?? '#${best.playerNumber}';
      bestStreak = best.consecutivePoints;
    }

    // Best rotation: max pointsWon - pointsLost
    int? bestRotIdx;
    int? bestRotDiff;
    final setRotations = vm.setActual == setNumber
        ? _rotationManager.history
        : _rotationManager.allSets
            .where((s) => s.setNumber == setNumber)
            .expand((s) => s.history)
            .toList();
    if (setRotations.isNotEmpty) {
      final diffs = <int, int>{};
      for (final r in setRotations) {
        diffs.update(r.rotationIndex, (v) => v + r.pointsWon - r.pointsLost,
            ifAbsent: () => r.pointsWon - r.pointsLost);
      }
      if (diffs.isNotEmpty) {
        final best = diffs.entries.reduce((a, b) => a.value > b.value ? a : b);
        bestRotIdx = best.key + 1;
        bestRotDiff = best.value;
      }
    }

    return SetEndRecord(
      setNumber: setNumber,
      localScore: finalLocal,
      visitorScore: finalVisitor,
      durationSeconds: duration,
      winnerName: winnerName,
      mvpPlayerName: mvpName,
      mvpPoints: mvpPts,
      bestServerName: bestServer,
      bestServerStreak: bestStreak,
      bestRotationIndex: bestRotIdx,
      bestRotationDiff: bestRotDiff,
    );
  }

  Future<void> _persistRotationStats(int matchId) async {
    final records = <RotationStatsRecord>[];
    for (final setState in _rotationManager.allSets) {
      for (final snap in setState.history) {
        records.add(RotationStatsRecord(
          matchId: matchId,
          setNumber: setState.setNumber,
          rotationIndex: snap.rotationIndex % 6,
          pointsWon: snap.pointsWon,
          pointsLost: snap.pointsLost,
          serverPlayerNumber: snap.serverNumber ?? 0,
          playerSlots: snap.slots.where((s) => s != null).cast<int>().toList(),
        ));
      }
    }
    if (records.isNotEmpty) {
      await DatabaseService.instance.saveRotationStatsRecords(records);
    }
  }

  int _eventValue(TipoAccion tipo, ResultadoAccion resultado) {
    if (resultado == ResultadoAccion.negativo) return -2;
    if (resultado == ResultadoAccion.neutral) return 1;
    switch (tipo) {
      case TipoAccion.ataque: return 3;
      case TipoAccion.saque: return 4;
      case TipoAccion.bloqueo: return 4;
      case TipoAccion.defensa: return 2;
      case TipoAccion.recepcion: return 2;
      case TipoAccion.colocacion: return 1;
      case TipoAccion.errorContrario: return 0;
    }
  }

  Future<MatchEndRecord> _computeMatchEndInfo(PartidoViewModel vm) async {
    final matchId = vm.match?.id;
    final events = matchId != null
        ? await DatabaseService.instance.getEventsByMatch(matchId)
        : <StatEvent>[];
    final allPlayers = await DatabaseService.instance.getAllPlayers();
    final playerNameMap = {for (final p in allPlayers) p.id: p.nombre};

    String? playerName(int id) => playerNameMap[id] ?? '#$id';

    // Per-player aggregates from persisted StatEvents
    final pointsByPlayer = <int, int>{};
    final attacksByPlayer = <int, int>{};
    final blocksByPlayer = <int, int>{};
    final receptionsByPlayer = <int, int>{};
    final servicesByPlayer = <int, int>{};

    for (final e in events) {
      final value = _eventValue(e.tipoAccion, e.resultado);
      pointsByPlayer.update(e.playerId, (v) => v + value, ifAbsent: () => value);

      if (e.tipoAccion == TipoAccion.ataque && e.resultado == ResultadoAccion.positivo) {
        attacksByPlayer.update(e.playerId, (v) => v + 1, ifAbsent: () => 1);
      }
      if (e.tipoAccion == TipoAccion.bloqueo) {
        blocksByPlayer.update(e.playerId, (v) => v + 1, ifAbsent: () => 1);
      }
      if (e.tipoAccion == TipoAccion.recepcion) {
        receptionsByPlayer.update(e.playerId, (v) => v + 1, ifAbsent: () => 1);
      }
      if (e.tipoAccion == TipoAccion.saque) {
        servicesByPlayer.update(e.playerId, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    // MVP
    String? mvpName;
    int? mvpPts;
    if (pointsByPlayer.isNotEmpty) {
      final best = pointsByPlayer.entries.reduce((a, b) => a.value > b.value ? a : b);
      mvpName = playerName(best.key);
      mvpPts = best.value;
    }

    // Best scorer (most positive attacks)
    String? bestScorerName;
    int? bestScorerPts;
    if (attacksByPlayer.isNotEmpty) {
      final best = attacksByPlayer.entries.reduce((a, b) => a.value > b.value ? a : b);
      bestScorerName = playerName(best.key);
      bestScorerPts = best.value;
    }

    // Best server (most services)
    String? bestServerStatName;
    int? bestServerStatCount;
    if (servicesByPlayer.isNotEmpty) {
      final best = servicesByPlayer.entries.reduce((a, b) => a.value > b.value ? a : b);
      bestServerStatName = playerName(best.key);
      bestServerStatCount = best.value;
    }

    // Best blocker
    String? bestBlockerName;
    int? bestBlockerCount;
    if (blocksByPlayer.isNotEmpty) {
      final best = blocksByPlayer.entries.reduce((a, b) => a.value > b.value ? a : b);
      bestBlockerName = playerName(best.key);
      bestBlockerCount = best.value;
    }

    // Best receiver
    String? bestReceiverName;
    int? bestReceiverCount;
    if (receptionsByPlayer.isNotEmpty) {
      final best = receptionsByPlayer.entries.reduce((a, b) => a.value > b.value ? a : b);
      bestReceiverName = playerName(best.key);
      bestReceiverCount = best.value;
    }

    // Statistics per action type
    final statistics = <TipoAccion, int>{};
    for (final e in events) {
      statistics[e.tipoAccion] = (statistics[e.tipoAccion] ?? 0) + 1;
    }

    // Set scores from VM
    final setScores = vm.setScores.map((e) => MapEntry(e.key, e.value)).toList();

    // Best service streak from rotation manager (consecutive points serving)
    String? bestServerName;
    int? bestStreak;
    if (_rotationManager.serviceHistory.isNotEmpty) {
      final best = _rotationManager.serviceHistory
          .reduce((a, b) => a.consecutivePoints > b.consecutivePoints ? a : b);
      bestServerName = _findPlayerName(best.playerNumber, vm) ?? '#${best.playerNumber}';
      bestStreak = best.consecutivePoints;
    }

    // Best rotation across entire match
    int? bestRotIdx;
    int? bestRotDiff;
    {
      final diffs = <int, int>{};
      for (final setState in _rotationManager.allSets) {
        for (final r in setState.history) {
          diffs.update(
            r.rotationIndex,
            (v) => v + r.pointsWon - r.pointsLost,
            ifAbsent: () => r.pointsWon - r.pointsLost,
          );
        }
      }
      if (diffs.isNotEmpty) {
        final best = diffs.entries.reduce((a, b) => a.value > b.value ? a : b);
        bestRotIdx = best.key + 1;
        bestRotDiff = best.value;
      }
    }

    return MatchEndRecord(
      matchId: matchId,
      localName: vm.nombreLocal,
      visitorName: vm.nombreVisitante,
      localSets: vm.setsLocal,
      visitorSets: vm.setsVisitante,
      durationSeconds: vm.duracionSegundos,
      winnerName: vm.setsLocal > vm.setsVisitante ? vm.nombreLocal : vm.nombreVisitante,
      mvpPlayerName: mvpName,
      mvpPoints: mvpPts,
      bestServerName: bestServerName,
      bestServerStreak: bestStreak,
      bestScorerName: bestScorerName,
      bestScorerPoints: bestScorerPts,
      bestBlockerName: bestBlockerName,
      bestBlockerCount: bestBlockerCount,
      bestReceiverName: bestReceiverName,
      bestReceiverCount: bestReceiverCount,
      bestRotationIndex: bestRotIdx,
      bestRotationDiff: bestRotDiff,
      startTime: _matchStartTime,
      endTime: DateTime.now(),
      setScores: setScores,
      statistics: statistics,
    );
  }

  Future<void> _showMatchEndDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MatchEndDialog(record: _matchEndRecord!),
    );

    if (!mounted) return;

    _liberoManager?.logs.add(LiberoLogEntry(
      message: 'MATCH: finalizado — ${_matchEndRecord!.winnerName} (${_matchEndRecord!.localSets}-${_matchEndRecord!.visitorSets})',
      level: LiberoLogLevel.success,
    ));

    switch (result) {
      case 'stats':
        break;
      case 'finalize':
        Navigator.of(context).pop();
        break;
    }
  }

  void _checkSetChange(PartidoViewModel vm) {
    final currentSet = vm.setActual;
    if (currentSet != _previousSet) {
      if (currentSet > 1) {
        final endedSet = _previousSet;
        // Capture final scores from setScores
        final scoreEntry = vm.setScores.length >= endedSet ? vm.setScores[endedSet - 1] : null;
        final finalLocal = scoreEntry?.key ?? 0;
        final finalVisitor = scoreEntry?.value ?? 0;

        _setEndEntries.add(TimelineEvent(
          id: _nextId(),
          time: DateTime.now(),
          type: TimelineEvent.typeSetEnd,
          set: endedSet,
          rotation: _rotationManager.rotationIndex,
          title: 'Fin SET $endedSet',
          metadata: {'score': '$finalLocal - $finalVisitor'},
        ));

        // Compute stats and show SetEndDialog before SetStartDialog
        final info = _computeSetEndInfo(endedSet, finalLocal, finalVisitor, vm);
        _showSetEndDialog(info, vm);
      }
      _previousSet = currentSet;
    }
  }

  Future<void> _showSetEndDialog(SetEndRecord info, PartidoViewModel vm) async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SetEndDialog(record: info),
    );

    if (!mounted) return;

    // Log
    _liberoManager?.logs.add(LiberoLogEntry(
      message: 'SET: finalizado — SET ${info.setNumber} (${info.localScore}-${info.visitorScore})',
      level: LiberoLogLevel.success,
    ));
    _liberoManager?.logs.add(LiberoLogEntry(
      message: 'SET: resumen generado',
      level: LiberoLogLevel.info,
    ));

    if (shouldContinue == true) {
      _showSetStartDialog(info.setNumber + 1, vm);
    }
    // If false, "Ver resumen" — close dialog but stay on screen
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
    _setStartTimes[setNumber] = DateTime.now();
  }

  void _handleZoneDragAccept(int fromZone, int toZone) {
    if (fromZone == toZone) return;
    LogService.instance.auto('🔵 Court — drag jugador: zona $fromZone → $toZone', source: 'MatchScreen');
    _rotationManager.swapZones(fromZone, toZone);
    if (_rotationManager.hasDuplicates()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Jugadores duplicados en la cancha'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      LogService.instance.auto('🔴 Error — duplicados tras swap $fromZone ↔ $toZone', source: 'MatchScreen');
    }
  }

  void _onRotate() {
    _rotationManager.rotate();
    _checkLiberoAutoZone();
  }

  void _checkLiberoAutoZone() {
    if (_liberoManager == null) return;
    final vm = context.read<PartidoViewModel>();
    _liberoManager!.checkAutoZone(
      currentSlots: _rotationManager.slots,
      setNumber: vm.setActual,
      rotationIndex: _rotationManager.rotationIndex,
      onSuggested: (outNum, inNum) {
        // Find player names
        String outName = '#$outNum';
        String inName = '#$inNum';
        try {
          final outP = vm.jugadores.firstWhere((p) => p.numero == outNum);
          outName = NameFormatter.playerMatchName(outP);
        } catch (_) {}
        try {
          final inP = vm.jugadores.firstWhere((p) => p.numero == inNum);
          inName = NameFormatter.playerMatchName(inP);
        } catch (_) {}

        _liberoManager?.performSwap(
          playerOutNumber: outNum,
          playerOutName: outName,
          playerInNumber: inNum,
          playerInName: inName,
          setNumber: vm.setActual,
          rotationIndex: _rotationManager.rotationIndex,
          isManual: false,
        );
      },
    );
  }

  Player? _playerForZone(int zoneNumber, PartidoViewModel vm) {
    final num = _rotationManager.courtState.zone(zoneNumber).athleteNumber;
    if (num == null) return null;
    try {
      return vm.jugadores.firstWhere((p) => p.numero == num);
    } catch (_) {
      return null;
    }
  }

  void _showPlayerActions(int zoneNumber, Player player, PartidoViewModel vm) {
    final name = NameFormatter.playerMatchName(player);

    // If player is a libero, show swap sheet
    if (_liberoManager?.config.isLibero(player) == true) {
      _showLiberoSwap(player, vm);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlayerActionSheet(
        player: player,
        onAction: (action) {
          final event = PlayerActionEvent(
            playerNumber: player.numero ?? 0,
            playerName: name,
            type: action,
            setNumber: vm.setActual,
            rotationIndex: _rotationManager.rotationIndex,
          );
          _actionEvents.add(event);
          vm.registrarAccionJugador(event);
          _lastActionType = action;
          _lastActionPlayer = name;
          _lastActionKey = ++_actionAnimCounter;
        },
        onReplace: () => _showPlayerReplace(zoneNumber, vm),
      ),
    );
  }

  void _showPlayerAssign(int zoneNumber, PartidoViewModel vm) {
    final available = vm.jugadores
        .where((p) => !_rotationManager.slots.whereType<int>().contains(p.numero))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay jugadores disponibles')),
      );
      return;
    }
    final csAssign = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: csAssign.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, color: csAssign.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Asignar jugador — Zona $zoneNumber',
                  style: TextStyle(
                    color: csAssign.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: csAssign.onSurface.withValues(alpha: 0.38)),
                  onPressed: () {
                    setState(() => _selectedZone = null);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: csAssign.onSurface.withValues(alpha: 0.12), height: 1),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: available.length,
                separatorBuilder: (_, __) => Divider(
                  color: csAssign.onSurface.withValues(alpha: 0.12), height: 1, indent: 48,
                ),
                itemBuilder: (_, i) {
                  final p = available[i];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: csAssign.primary.withValues(alpha: 0.3),
                      child: Text(
                        '${p.numero ?? '?'}',
                        style: TextStyle(
                          color: csAssign.onPrimary, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      NameFormatter.playerShortName(p),
                      style: TextStyle(color: csAssign.onSurface, fontSize: 14),
                    ),
                    subtitle: Text(
                      p.posicionLabel.toUpperCase(),
                      style: TextStyle(color: csAssign.onSurface.withValues(alpha: 0.38), fontSize: 11),
                    ),
                    onTap: () {
                      try {
                        _rotationManager.assignPlayerByZone(zoneNumber, p.numero ?? 0);
                        LogService.instance.auto('🔵 Court — jugador #${p.numero} asignado a zona $zoneNumber', source: 'MatchScreen');
                        LogService.instance.auto('🔵 Court — banca: ${_benchPlayers(vm).length} disponibles', source: 'MatchScreen');
                        LogService.instance.auto('🔵 Court — zona $zoneNumber ocupada', source: 'MatchScreen');
                      } catch (e) {
                        LogService.instance.auto('🔴 Error — asignar jugador a zona $zoneNumber: $e', source: 'MatchScreen');
                      }
                      setState(() => _selectedZone = null);
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _selectedZone = null);
    });
  }

  void _showPlayerReplace(int zoneNumber, PartidoViewModel vm) {
    final oldPlayer = _playerForZone(zoneNumber, vm);
    final bench = _benchPlayers(vm);
    if (bench.isEmpty) {
      LogService.instance.auto('🔴 Sustitución — no hay jugadores en banca', source: 'MatchScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay jugadores en banca')),
      );
      return;
    }
    final csRep = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: csRep.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sustituir — Zona $zoneNumber',
                  style: TextStyle(
                    color: csRep.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: csRep.onSurface.withValues(alpha: 0.38)),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: csRep.onSurface.withValues(alpha: 0.12), height: 1),
            const SizedBox(height: 8),
            if (oldPlayer != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: csRep.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: csRep.error.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, color: csRep.error, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Sale: #${oldPlayer.numero} ${NameFormatter.playerMatchName(oldPlayer)}',
                        style: TextStyle(color: csRep.error, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: bench.length,
                separatorBuilder: (_, __) => Divider(
                  color: csRep.onSurface.withValues(alpha: 0.12), height: 1, indent: 48,
                ),
                itemBuilder: (_, i) {
                  final p = bench[i];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: csRep.primary.withValues(alpha: 0.3),
                      child: Text(
                        '${p.numero ?? '?'}',
                        style: TextStyle(
                          color: csRep.onPrimary, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      NameFormatter.playerShortName(p),
                      style: TextStyle(color: csRep.onSurface, fontSize: 14),
                    ),
                    subtitle: Text(
                      p.posicionLabel.toUpperCase(),
                      style: TextStyle(color: csRep.onSurface.withValues(alpha: 0.38), fontSize: 11),
                    ),
                    onTap: () {
                      try {
                        _rotationManager.clearZone(zoneNumber);
                        _rotationManager.assignPlayerByZone(zoneNumber, p.numero ?? 0);
      LogService.instance.auto('🟡 Rotation — sustitución: #${p.numero} → zona $zoneNumber', source: 'MatchScreen');
                        LogService.instance.auto('🔵 Court — zona $zoneNumber reasignada', source: 'MatchScreen');
                        setState(() => _selectedZone = null);
                      } catch (e) {
                      LogService.instance.auto('🔴 Error — sustitución: $e', source: 'MatchScreen');
                      }
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _selectedZone = null);
    });
  }

  void _showLiberoSwap(Player libero, PartidoViewModel vm) {
    final courtPlayers = _courtPlayers(vm);
    final libName = NameFormatter.playerMatchName(libero);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LiberoSheet(
        libero: libero,
        courtPlayers: courtPlayers,
        onSwapIn: (playerOut) {
          _liberoManager?.performSwap(
            playerOutNumber: playerOut.numero ?? 0,
            playerOutName: NameFormatter.playerMatchName(playerOut),
            playerInNumber: libero.numero ?? 0,
            playerInName: libName,
            setNumber: vm.setActual,
            rotationIndex: _rotationManager.rotationIndex,
            isManual: true,
          );
        },
        onCancel: () {
          _liberoManager?.cancelSwap(
            setNumber: vm.setActual,
            rotationIndex: _rotationManager.rotationIndex,
          );
        },
      ),
    );
  }

  void _onZoneTap(int zoneNumber, PartidoViewModel vm) {
    setState(() => _selectedZone = zoneNumber);
    LogService.instance.auto('🔵 Court — zona seleccionada: $zoneNumber', source: 'MatchScreen');
    final player = _playerForZone(zoneNumber, vm);
    if (player != null) {
      _showPlayerActions(zoneNumber, player, vm);
    } else {
      _showPlayerAssign(zoneNumber, vm);
    }
  }

  void _showPlayerStats(Player player) {
    final playerActions = _actionEvents
        .where((a) => a.playerNumber == player.numero)
        .toList();
    final allPlayers = context.read<PartidoViewModel>().jugadores;
    final rankings = _computeRankings(allPlayers);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: PlayerStatsCard(
          player: player,
          actions: playerActions,
          rank: rankings.indexOf(player.numero ?? 0) + 1,
        ),
      ),
    );
  }

  List<int> _computeRankings(List<Player> allPlayers) {
    final scores = <int, int>{};
    for (final action in _actionEvents) {
      scores[action.playerNumber] =
          (scores[action.playerNumber] ?? 0) + action.type.value;
    }
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  void _togglePerspective() {
    setState(() {
      _perspective = _perspective == CourtPerspective.right
          ? CourtPerspective.left
          : CourtPerspective.right;
    });
  }

  int? _findCaptainNumber(PartidoViewModel vm) {
    try {
      return vm.jugadores.firstWhere((p) => p.esCapitan).numero;
    } catch (_) {
      return null;
    }
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
      playerOutName: NameFormatter.playerMatchName(playerOut),
      playerInName: NameFormatter.playerMatchName(benchPlayer),
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
            final csLoading = Theme.of(context).colorScheme;
            return Scaffold(
              backgroundColor: csLoading.surface,
              body: Center(
                child: CircularProgressIndicator(color: csLoading.primary),
              ),
            );
          }
          if (vm.error != null && vm.match == null) {
            final csError = Theme.of(context).colorScheme;
            return Scaffold(
              backgroundColor: csError.surface,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(vm.error!, style: TextStyle(color: csError.onSurface.withValues(alpha: 0.54))),
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
          _trackPoints(vm);

          if (!_initialAssignmentDone && !vm.isLoading && vm.match != null) {
            _initialAssignmentDone = true;
            final players = vm.jugadores;
            if (players.isNotEmpty) {
              final numbers = players
                  .where((p) => p.numero != null)
                  .take(6)
                  .map<int?>((p) => p.numero)
                  .toList();
              while (numbers.length < 6) {
                numbers.add(null);
              }
              _rotationManager.setSlots(numbers);
            }
          }

          if (vm.isFinalizado && !_matchEndShown && vm.match != null) {
            _matchEndShown = true;
            _persistRotationStats(vm.match!.id);
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              _matchEndRecord = await _computeMatchEndInfo(vm);
              if (mounted) _showMatchEndDialog();
            });
          }

          return Stack(
            children: [
              ListenableBuilder(
                listenable: Listenable.merge([
                  _rotationManager,
                  if (_liberoManager != null) _liberoManager!,
                ]),
                builder: (context, _) {
                  final cs = Theme.of(context).colorScheme;
                  final courtState = (_liberoManager != null
                          ? _rotationManager.courtStateWithLiberos(
                              (n) => _liberoManager!.isLibero(n))
                          : _rotationManager.courtState)
                      .withPerspective(_perspective);

                  return Scaffold(
                backgroundColor: cs.surface,
                endDrawer: PlayersDrawer(
                  benchPlayers: _benchPlayers(vm),
                  onSubstitute: (p) => _onSubstitute(p, vm),
                ),
                appBar: AppBar(
                  backgroundColor: cs.surfaceContainerHighest,
                  elevation: 0,
                  title: Text(
                    '${vm.nombreLocal} vs ${vm.nombreVisitante}',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: cs.primary,
                    labelColor: cs.onSurface,
                    unselectedLabelColor: cs.onSurface.withValues(alpha: 0.38),
                    labelStyle: TextStyle(
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
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.54),
                          size: 20,
                        ),
                        onPressed: vm.toggleEditMode,
                        tooltip: 'Editar',
                      ),
                    ),
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: Icon(Icons.people_outline, color: cs.onSurface.withValues(alpha: 0.54)),
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
              if (_lastActionType != null)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.35,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: PlayerActionAnim(
                      key: ValueKey('action_$_lastActionKey'),
                      action: _lastActionType!,
                      playerName: _lastActionPlayer ?? '',
                      child: const SizedBox.shrink(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _nextId() => 'evt_${DateTime.now().microsecondsSinceEpoch}_${++_eventIdCounter}';

  List<TimelineEvent> _buildTimelineEvents(PartidoViewModel vm) {
    final list = <TimelineEvent>[];

    list.add(TimelineEvent(
      id: _nextId(),
      time: _matchStartTime,
      type: TimelineEvent.typeMatchStarted,
      set: 1,
      rotation: 0,
      title: 'Partido iniciado',
      metadata: {'vs': '${vm.nombreLocal} vs ${vm.nombreVisitante}'},
    ));

    for (final s in _rotationManager.serviceHistory) {
      list.add(TimelineEvent(
        id: _nextId(),
        time: s.startTime,
        type: TimelineEvent.typeService,
        set: s.setNumber,
        rotation: _rotationManager.rotationIndex,
        playerId: s.playerNumber.toString(),
        title: '${s.consecutivePoints} puntos',
        metadata: {
          'playerNumber': '#${s.playerNumber}',
          'streak': '${s.consecutivePoints} puntos seguidos',
        },
      ));
    }

    for (final a in _actionEvents) {
      list.add(TimelineEvent(
        id: _nextId(),
        time: a.timestamp,
        type: TimelineEvent.typePlayerAction,
        set: a.setNumber,
        rotation: a.rotationIndex,
        playerId: a.playerNumber.toString(),
        playerName: a.playerName,
        title: '${a.type.icon} ${a.type.label}',
        metadata: {
          'value': a.type.value > 0 ? '+${a.type.value}' : '${a.type.value}',
        },
      ));
    }

    for (final setState in _rotationManager.allSets) {
      for (final snap in setState.history) {
        list.add(TimelineEvent(
          id: _nextId(),
          time: snap.timestamp,
          type: TimelineEvent.typeRotation,
          set: setState.setNumber,
          rotation: snap.rotationIndex,
          title: 'Rotación R${snap.rotationIndex + 1}',
          metadata: snap.serverNumber != null
              ? {'serving': '#${snap.serverNumber} al servicio'}
              : null,
        ));
      }
    }

    for (final sub in vm.substitutionHistory) {
      list.add(TimelineEvent(
        id: _nextId(),
        time: sub.timestamp,
        type: TimelineEvent.typeSubstitution,
        set: sub.setNumber,
        rotation: sub.rotationIndex,
        title: 'Sustitución',
        metadata: {
          'out': '${sub.playerOutName} (#${sub.playerOutNumber}) ↓',
          'in': '${sub.playerInName} (#${sub.playerInNumber}) ↑',
        },
      ));
    }

    if (_liberoManager != null) {
      for (final swap in _liberoManager!.history) {
        list.add(TimelineEvent(
          id: _nextId(),
          time: swap.timestamp,
          type: TimelineEvent.typeLiberoSwap,
          set: swap.setNumber,
          rotation: swap.rotationIndex,
          title: 'Cambio Líbero',
          playerName: swap.liberoName,
          playerId: swap.liberoPlayerNumber.toString(),
          metadata: {
            'swap': swap.associatedPlayerName != null
                ? '${swap.liberoName} ↔ ${swap.associatedPlayerName}'
                : '${swap.liberoName} (#${swap.liberoPlayerNumber})',
          },
        ));
      }
    }

    for (final t in vm.timeoutHistory) {
      list.add(TimelineEvent(
        id: _nextId(),
        time: t.inicio,
        type: TimelineEvent.typeTimeout,
        set: t.setNumero,
        rotation: 0,
        title: 'Tiempo muerto',
        metadata: {'team': t.esLocal ? vm.nombreLocal : vm.nombreVisitante},
      ));
    }

    list.addAll(_setEndEntries);

    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
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
            setActual: vm.setActual,
            setsTotales: vm.setsTotales,
            localName: vm.nombreLocal,
            visitorName: vm.nombreVisitante,
            onIncrementLocal: vm.isPartidoActivo ? () => vm.sumarPuntoLocal() : null,
            onIncrementVisitor: vm.isPartidoActivo ? () => vm.sumarPuntoVisitante() : null,
            onDecrementLocal: vm.isPartidoActivo ? () => vm.restarPuntoLocal() : null,
            onDecrementVisitor: vm.isPartidoActivo ? () => vm.restarPuntoVisitante() : null,
            localTimeoutsRemaining: vm.localTimeoutsRemaining,
            visitorTimeoutsRemaining: vm.visitorTimeoutsRemaining,
            currentRotation: _rotationManager.rotationIndex + 1,
            tiempoTranscurrido: vm.tiempoTranscurrido,
          ),
          _buildTimeoutRow(vm),
          CourtWidget(
            state: courtState,
            onZoneTap: (z) => _onZoneTap(z, vm),
            onZoneLongPress: (z) {
              final player = _playerForZone(z, vm);
              if (player != null) _showPlayerStats(player);
            },
            onZoneDragAccept: _handleZoneDragAccept,
            onTogglePerspective: _togglePerspective,
            selectedZone: _selectedZone,
            captainNumber: _findCaptainNumber(vm),
            players: vm.jugadores,
          ),
          _buildRotationInfoRow(context, vm),
          _buildServerioRow(),
          ServiceWidget(
            serverNumber: _rotationManager.currentServerNumber,
            serverName: _serverName(vm, _rotationManager.currentServerNumber),
            consecutivePoints: _rotationManager.consecutivePoints,
            rotationCount: _rotationManager.rotationIndex,
          ),
          _buildServiceHistoryButton(context, vm),
          _buildTimelineButton(context, vm),
          QuickStatsWidget(matchId: vm.match?.id ?? 0),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTimeoutRow(PartidoViewModel vm) {
    final csTR = Theme.of(context).colorScheme;
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
              color: csTR.onSurface.withValues(alpha: 0.05),
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

  void _openRotationHistory(PartidoViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RotationHistoryWidget(
        sets: _rotationManager.allSets,
      ),
    );
  }

  String? _serverName(PartidoViewModel vm, int? number) {
    if (number == null) return null;
    try {
      final player = vm.jugadores.firstWhere((p) => p.numero == number);
      return NameFormatter.playerMatchName(player);
    } catch (_) {
      return null;
    }
  }

  void _openServiceHistory(PartidoViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServiceHistorySheet(
        history: _rotationManager.serviceHistory,
        allPlayers: vm.jugadores,
        totalServices: _rotationManager.totalServices,
        bestStreak: _rotationManager.bestStreak,
        averagePointsPerServe: _rotationManager.averagePointsPerServe,
      ),
    );
  }

  Widget _buildRotationInfoRow(BuildContext context, PartidoViewModel vm) {
    final csRI = Theme.of(context).colorScheme;
    final currentRot = _rotationManager.rotationIndex + 1;
    final totalRot = _rotationManager.history.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: csRI.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rotate_right, size: 12, color: csRI.primary),
                const SizedBox(width: 4),
                Text(
                  'R$currentRot',
                  style: TextStyle(
                    color: csRI.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$totalRot rotac.',
            style: TextStyle(color: csRI.onSurface.withValues(alpha: 0.24), fontSize: 11),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _openRotationHistory(vm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: csRI.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 12, color: csRI.onSurface.withValues(alpha: 0.38)),
                  const SizedBox(width: 4),
                  Text(
                    'Historial',
                    style: TextStyle(
                      color: csRI.onSurface.withValues(alpha: 0.38),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineButton(BuildContext context, PartidoViewModel vm) {
    final csTB = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _openTimelineSheet(vm),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: csTB.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: csTB.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.timeline, size: 14, color: csTB.primary),
            const SizedBox(width: 8),
            Text(
              'Crónica completa',
              style: TextStyle(
                color: csTB.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 16, color: csTB.primary),
          ],
        ),
      ),
    );
  }

  void _openTimelineSheet(PartidoViewModel vm) {
    final events = _buildTimelineEvents(vm);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MatchTimelineSheet(events: events),
    );
  }

  Widget _buildServiceHistoryButton(BuildContext context, PartidoViewModel vm) {
    final csSH = Theme.of(context).colorScheme;
    final count = _rotationManager.serviceHistory.length;
    return GestureDetector(
      onTap: () => _openServiceHistory(vm),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: csSH.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: csSH.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.swap_vert, size: 14, color: csSH.onSurface.withValues(alpha: 0.38)),
            const SizedBox(width: 8),
            Text(
              'Historial de servicio',
              style: TextStyle(
                color: csSH.onSurface.withValues(alpha: 0.54),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$count servicio${count == 1 ? '' : 's'}',
              style: TextStyle(color: csSH.onSurface.withValues(alpha: 0.24), fontSize: 11),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 16, color: csSH.onSurface.withValues(alpha: 0.24)),
          ],
        ),
      ),
    );
  }

  Widget _buildServerioRow() {
    final csSR = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Rotación #${_rotationManager.rotationIndex + 1}',
              style: TextStyle(
                color: csSR.onSurface.withValues(alpha: 0.38),
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
                  color: csSR.primary.withValues(alpha: 0.2),
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
                backgroundColor: csSR.primary,
                foregroundColor: csSR.onPrimary,
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
          _onZoneTap(RotationManager.visualToZone[slot], vm),
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
    final csPN = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: csPN.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Número de jugador',
              style: TextStyle(color: csPN.onSurface, fontWeight: FontWeight.bold),
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
                      color: csPN.primary.withValues(alpha: 0.3),
                      border: Border.all(color: csPN.onSurface.withValues(alpha: 0.24)),
                    ),
                    child: Center(
                      child: Text(
                        '$num',
                        style: TextStyle(
                          color: csPN.onSurface,
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
