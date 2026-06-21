import 'package:flutter/foundation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../../partido/presentation/controllers/match_controller.dart';
import '../../../partido/data/match_config.dart';

class PlayByPlayViewModel extends ChangeNotifier {
  final MatchController _controller;
  final StatEventRepository _statEventRepository = StatEventRepository();

  List<StatEvent> _eventos = [];
  List<Player> _jugadoresLocal = [];
  List<Player> _jugadoresVisitante = [];
  Player? _jugadorSeleccionado;
  bool _esEquipoLocal = true;
  String? _ownError;

  PlayByPlayViewModel(this._controller) {
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    notifyListeners();
  }

  // ============================================================
  // GETTERS DELEGADOS A MATCHCONTROLLER
  // ============================================================

  Match? get partidoActual => _controller.match;
  bool get isLoading => _controller.isLoading;
  String? get error => _ownError ?? _controller.error;
  bool get hayPartidoActivo => _controller.isPartidoActivo;
  String get marcador => _controller.match?.marcador ?? '0 - 0';
  String get resultadoSets => _controller.match?.resultadoSets ?? '0 - 0';
  int get setActual => _controller.setActual;
  EstadoPartido get estadoPartido => _controller.estado;

  // ============================================================
  // GETTERS PROPIOS
  // ============================================================

  List<StatEvent> get eventos => _eventos;
  List<Player> get jugadoresLocal => _jugadoresLocal;
  List<Player> get jugadoresVisitante => _jugadoresVisitante;
  Player? get jugadorSeleccionado => _jugadorSeleccionado;
  bool get esEquipoLocal => _esEquipoLocal;

  // ============================================================
  // MÉTODOS DE PARTIDO (DELEGADOS A MATCHCONTROLLER)
  // ============================================================

  Future<void> iniciarNuevoPartido({
    required String equipoLocal,
    required String equipoVisitante,
  }) async {
    _clearError();
    final success = await _controller.init(MatchConfig(
      localName: equipoLocal,
      visitorName: equipoVisitante,
    ));
    if (!success) {
      _setError(_controller.error ?? 'No se pudo iniciar el partido');
      return;
    }
    _eventos = [];
  }

  Future<void> cargarPartido(int matchId) async {
    _clearError();
    await _controller.loadMatch(matchId);
    if (_controller.match != null) {
      _eventos = await _statEventRepository.obtenerEventosDelPartido(matchId);
    }
  }

  Future<void> agregarPuntoLocal() async {
    await _controller.sumarPuntoLocal();
  }

  Future<void> agregarPuntoVisitante() async {
    await _controller.sumarPuntoVisitante();
  }

  Future<void> pausarPartido() async {
    await _controller.pausarReanudar();
  }

  Future<void> reanudarPartido() async {
    await _controller.pausarReanudar();
  }

  Future<void> finalizarPartido() async {
    await _controller.finalizarPartido();
  }

  // ============================================================
  // MÉTODOS DE JUGADORES
  // ============================================================

  void seleccionarJugador(Player jugador) {
    _jugadorSeleccionado = jugador;
    notifyListeners();
  }

  void cambiarEquipo(bool esLocal) {
    _esEquipoLocal = esLocal;
    _jugadorSeleccionado = null;
    notifyListeners();
  }

  void setJugadoresLocal(List<Player> jugadores) {
    _jugadoresLocal = jugadores;
    notifyListeners();
  }

  void setJugadoresVisitante(List<Player> jugadores) {
    _jugadoresVisitante = jugadores;
    notifyListeners();
  }

  // ============================================================
  // MÉTODOS DE REGISTRO DE ACCIONES
  // ============================================================

  Future<void> registrarAtaque({required bool esPositivo}) async {
    if (_controller.match == null || _jugadorSeleccionado == null) return;

    _clearError();

    try {
      await _statEventRepository.registrarAtaque(
        playerId: _jugadorSeleccionado!.id,
        matchId: _controller.match!.id,
        esPositivo: esPositivo,
        esEquipoLocal: _esEquipoLocal,
      );

      if (esPositivo) {
        if (_esEquipoLocal) {
          await _controller.sumarPuntoLocal();
        } else {
          await _controller.sumarPuntoVisitante();
        }
      }

      await _actualizarEventos();
    } catch (e) {
      _setError('Error al registrar ataque: $e');
    }
  }

  Future<void> registrarSaque({required bool esPositivo}) async {
    if (_controller.match == null || _jugadorSeleccionado == null) return;

    _clearError();

    try {
      await _statEventRepository.registrarSaque(
        playerId: _jugadorSeleccionado!.id,
        matchId: _controller.match!.id,
        esPositivo: esPositivo,
        esEquipoLocal: _esEquipoLocal,
      );

      if (esPositivo) {
        if (_esEquipoLocal) {
          await _controller.sumarPuntoLocal();
        } else {
          await _controller.sumarPuntoVisitante();
        }
      }

      await _actualizarEventos();
    } catch (e) {
      _setError('Error al registrar saque: $e');
    }
  }

  Future<void> registrarBloqueo({required bool esPositivo}) async {
    if (_controller.match == null || _jugadorSeleccionado == null) return;

    _clearError();

    try {
      await _statEventRepository.registrarBloqueo(
        playerId: _jugadorSeleccionado!.id,
        matchId: _controller.match!.id,
        esPositivo: esPositivo,
        esEquipoLocal: _esEquipoLocal,
      );

      if (esPositivo) {
        if (_esEquipoLocal) {
          await _controller.sumarPuntoLocal();
        } else {
          await _controller.sumarPuntoVisitante();
        }
      }

      await _actualizarEventos();
    } catch (e) {
      _setError('Error al registrar bloqueo: $e');
    }
  }

  Future<void> registrarDefensa() async {
    if (_controller.match == null || _jugadorSeleccionado == null) return;

    _clearError();

    try {
      await _statEventRepository.registrarDefensa(
        playerId: _jugadorSeleccionado!.id,
        matchId: _controller.match!.id,
        esEquipoLocal: _esEquipoLocal,
      );

      await _actualizarEventos();
    } catch (e) {
      _setError('Error al registrar defensa: $e');
    }
  }

  Future<void> registrarErrorContrario() async {
    if (_controller.match == null) return;

    _clearError();

    try {
      await _statEventRepository.registrarErrorContrario(
        matchId: _controller.match!.id,
        esEquipoLocal: _esEquipoLocal,
      );

      if (_esEquipoLocal) {
        await _controller.sumarPuntoVisitante();
      } else {
        await _controller.sumarPuntoLocal();
      }

      await _actualizarEventos();
    } catch (e) {
      _setError('Error al registrar error: $e');
    }
  }

  // ============================================================
  // MÉTODOS DE CONSULTA
  // ============================================================

  Future<Map<String, int>> obtenerEstadisticasJugador() async {
    if (_controller.match == null || _jugadorSeleccionado == null) {
      return {};
    }

    return await _statEventRepository.obtenerEstadisticasJugadorPartido(
      _jugadorSeleccionado!.id,
      _controller.match!.id,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerTimeline() async {
    if (_controller.match == null) return [];

    return await _statEventRepository.obtenerTimeline(_controller.match!.id);
  }

  Future<Map<String, dynamic>> obtenerResumen() async {
    if (_controller.match == null) return {};

    return await MatchRepository().obtenerResumen(_controller.match!.id);
  }

  // ============================================================
  // MÉTODOS PRIVADOS DE UTILIDAD
  // ============================================================

  Future<void> _actualizarEventos() async {
    if (_controller.match == null) return;

    _eventos = await _statEventRepository.obtenerEventosDelPartido(
      _controller.match!.id,
    );
    notifyListeners();
  }

  void _setError(String message) {
    _ownError = message;
    notifyListeners();
  }

  void _clearError() {
    _ownError = null;
  }

  void clear() {
    _eventos = [];
    _jugadoresLocal = [];
    _jugadoresVisitante = [];
    _jugadorSeleccionado = null;
    _esEquipoLocal = true;
    _ownError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    super.dispose();
  }
}
