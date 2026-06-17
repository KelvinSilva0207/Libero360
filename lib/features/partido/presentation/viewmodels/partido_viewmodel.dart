import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/match_config.dart';
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
  int get tiempoPorSet => _controller.tiempoPorSet;
  List<Player> get jugadores => _controller.jugadores;
  List<Player> get jugadoresVisitante => _controller.jugadoresVisitante;
  int get rotacionLocal => _controller.rotacionLocal;
  int get rotacionVisitante => _controller.rotacionVisitante;
  bool get isLocalServing => _controller.isLocalServing;

  int get duracionSegundos => _controller.duracionSegundos;
  int get duracionSegundosMatch => _controller.duracionSegundosMatch;
  String get tiempoTranscurrido => _controller.tiempoTranscurrido;

  int get totalPuntosLocal => _controller.totalPuntosLocal;
  int get totalPuntosVisitante => _controller.totalPuntosVisitante;

  // ========== DELEGATED METHODS ==========

  Future<void> init([MatchConfig? config]) => _controller.init(config);

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

  void actualizarConfiguracion({int? puntosPorSet, int? setsPorPartido, int? tiempoPorSet}) =>
      _controller.actualizarConfiguracion(
        puntosPorSet: puntosPorSet,
        setsPorPartido: setsPorPartido,
        tiempoPorSet: tiempoPorSet,
      );

  Future<void> pausarReanudar() => _controller.pausarReanudar();

  Future<void> finalizarPartido() => _controller.finalizarPartido();

  Future<void> eliminarPartido() => _controller.eliminarPartido();

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    super.dispose();
  }
}
