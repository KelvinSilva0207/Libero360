import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/match_config.dart';
import '../../data/player_action.dart';
import '../../data/substitution_record.dart';
import '../../data/timeout_event.dart';
import '../controllers/match_controller.dart';

class PartidoViewModel extends ChangeNotifier {
  final MatchController _controller;

  PartidoViewModel(this._controller) {
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    notifyListeners();
  }

  // ========== DELEGATED GETTERS ==========

  Match? get match => _controller.match;
  bool get isLoading => _controller.isLoading;
  String? get error => _controller.error;
  bool get isPartidoActivo => _controller.isPartidoActivo;

  int get puntosLocal => _controller.puntosLocal;
  int get puntosVisitante => _controller.puntosVisitante;
  int get setsLocal => _controller.setsLocal;
  int get setsVisitante => _controller.setsVisitante;
  int get setActual => _controller.setActual;
  String get nombreLocal => _controller.nombreLocal;
  String get nombreVisitante => _controller.nombreVisitante;
  EstadoPartido get estado => _controller.estado;
  bool get isFinalizado => _controller.isFinalizado;

  List<MapEntry<int, int>> get setScores => UnmodifiableListView(_controller.setScores);
  int get puntosPorSet => _controller.puntosPorSet;
  int get setsPorPartido => _controller.setsPorPartido;
  int get timeoutsPerSet => _controller.timeoutsPerSet;
  int get timeoutDurationSeconds => _controller.timeoutDurationSeconds;
  Categoria get categoria => _controller.categoria;
  List<Player> get jugadores => _controller.jugadores;
  List<Player> get jugadoresVisitante => _controller.jugadoresVisitante;
  int get rotacionLocal => _controller.rotacionLocal;
  int get rotacionVisitante => _controller.rotacionVisitante;
  bool get isLocalServing => _controller.isLocalServing;

  // Timeout
  TimeoutState get timeoutState => _controller.timeoutState;
  bool get activeTimeoutIsLocal => _controller.activeTimeoutIsLocal;
  int get timeoutCountdown => _controller.timeoutCountdown;
  int get localTimeoutsUsed => _controller.localTimeoutsUsed;
  int get visitorTimeoutsUsed => _controller.visitorTimeoutsUsed;
  int get localTimeoutsRemaining => _controller.localTimeoutsRemaining;
  int get visitorTimeoutsRemaining => _controller.visitorTimeoutsRemaining;
  List<TimeoutRecord> get timeoutHistory => _controller.timeoutHistory;

  // Substitution & Edit Mode
  bool get editMode => _controller.editMode;
  List<SubstitutionRecord> get substitutionHistory =>
      _controller.substitutionHistory;

  int get duracionSegundos => _controller.duracionSegundos;
  int get duracionSegundosMatch => _controller.duracionSegundosMatch;
  String get tiempoTranscurrido => _controller.tiempoTranscurrido;

  int get totalPuntosLocal => _controller.totalPuntosLocal;
  int get totalPuntosVisitante => _controller.totalPuntosVisitante;

  // ========== DELEGATED METHODS ==========

  Future<void> init([MatchConfig? config]) async {
    await _controller.init(config);
    notifyListeners();
  }

  Future<void> sumarPuntoLocal() => _controller.sumarPuntoLocal();

  Future<void> sumarPuntoVisitante() => _controller.sumarPuntoVisitante();

  Future<void> restarPuntoLocal() => _controller.restarPuntoLocal();

  Future<void> restarPuntoVisitante() => _controller.restarPuntoVisitante();

  void rotarLocal() => _controller.rotarLocal();

  void rotarVisitante() => _controller.rotarVisitante();

  void cambiarServicio() => _controller.cambiarServicio();

  Future<void> actualizarNumeroJugador(int posIndex, int numero) =>
      _controller.actualizarNumeroJugador(posIndex, numero);

  Future<void> undoLastPoint() => _controller.undoLastPoint();

  Future<void> cambiarSet(int nuevoSet) => _controller.cambiarSet(nuevoSet);

  void actualizarNombreLocal(String nombre) => _controller.actualizarNombreLocal(nombre);

  void actualizarNombreVisitante(String nombre) => _controller.actualizarNombreVisitante(nombre);

  void actualizarConfiguracion({int? puntosPorSet, int? setsPorPartido, int? timeoutsPerSet, int? timeoutDurationSeconds}) =>
      _controller.actualizarConfiguracion(
        puntosPorSet: puntosPorSet,
        setsPorPartido: setsPorPartido,
        timeoutsPerSet: timeoutsPerSet,
        timeoutDurationSeconds: timeoutDurationSeconds,
      );

  void startTimeout(bool isLocal) => _controller.startTimeout(isLocal);
  void cancelTimeout() => _controller.cancelTimeout();
  void dismissTimeoutResult() => _controller.dismissTimeoutResult();

  void toggleEditMode() => _controller.toggleEditMode();

  void addSubstitution({
    required int playerOutNumber,
    required int playerInNumber,
    required String playerOutName,
    required String playerInName,
    required int setNumber,
    required int rotationIndex,
  }) =>
      _controller.addSubstitution(
        playerOutNumber: playerOutNumber,
        playerInNumber: playerInNumber,
        playerOutName: playerOutName,
        playerInName: playerInName,
        setNumber: setNumber,
        rotationIndex: rotationIndex,
      );

  Future<void> pausarReanudar() => _controller.pausarReanudar();

  Future<void> finalizarPartido() => _controller.finalizarPartido();

  Future<void> eliminarPartido() => _controller.eliminarPartido();

  Future<void> registrarAccionJugador(PlayerActionEvent action, {bool esLocal = true}) =>
      _controller.registrarAccionJugador(action, esLocal: esLocal);

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    super.dispose();
  }
}
