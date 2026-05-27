import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/repositories/repositories.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../data/match_config.dart';

class PartidoViewModel extends ChangeNotifier {
  final MatchRepository _matchRepository = MatchRepository();

  Match? _match;
  bool _isLoading = false;
  String? _error;
  List<MapEntry<int, int>> _setScores = [];

  int _puntosPorSet = 25;
  int _setsPorPartido = 5;
  int _tiempoPorSet = 0;

  Match? get match => _match;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPartidoActivo => _match?.isActivo ?? false;

  int get puntosLocal => _match?.puntosLocal ?? 0;
  int get puntosVisitante => _match?.puntosVisitante ?? 0;
  int get setsLocal => _match?.setsLocal ?? 0;
  int get setsVisitante => _match?.setsVisitante ?? 0;
  int get setActual => _match?.setActual ?? 1;
  String get nombreLocal => _match?.equipoLocal ?? 'Local';
  String get nombreVisitante => _match?.equipoVisitante ?? 'Visitante';
  EstadoPartido get estado => _match?.estado ?? EstadoPartido.noIniciado;
  bool get isFinalizado => _match?.isFinalizado ?? false;

  List<MapEntry<int, int>> get setScores => UnmodifiableListView(_setScores);
  int get puntosPorSet => _puntosPorSet;
  int get setsPorPartido => _setsPorPartido;
  int get tiempoPorSet => _tiempoPorSet;

  int get totalPuntosLocal =>
      _setScores.fold(0, (sum, e) => sum + e.key);
  int get totalPuntosVisitante =>
      _setScores.fold(0, (sum, e) => sum + e.value);

  Future<void> init([MatchConfig? config]) async {
    _setLoading(true);
    _error = null;

    try {
      await DatabaseService.instance.initialize();

      _setsPorPartido = config?.setsTotales ?? 5;

      _match = await _matchRepository.crearNuevoPartido(
        equipoLocal: config?.localName ?? 'Local',
        equipoVisitante: config?.visitorName ?? 'Visitante',
        setsTotales: _setsPorPartido,
        tipoPartido: config?.tipoPartido ?? TipoPartido.amistoso,
      );

      _match!.iniciar();
      await _matchRepository.guardar(_match!);
      _setScores = List.generate(_setsPorPartido, (_) => const MapEntry(0, 0));
    } catch (e) {
      _error = 'Error al iniciar partido: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sumarPuntoLocal() async {
    if (_match == null || !_match!.isActivo) return;
    try {
      final oldSet = _match!.setActual;
      final oldLocal = _match!.puntosLocal;
      final oldVisitor = _match!.puntosVisitante;

      _match = await _matchRepository.agregarPuntoLocal(_match!.id);
      _actualizarSetScores(
        oldSet: oldSet,
        oldLocalPts: oldLocal,
        oldVisitorPts: oldVisitor,
        localScored: true,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> sumarPuntoVisitante() async {
    if (_match == null || !_match!.isActivo) return;
    try {
      final oldSet = _match!.setActual;
      final oldLocal = _match!.puntosLocal;
      final oldVisitor = _match!.puntosVisitante;

      _match = await _matchRepository.agregarPuntoVisitante(_match!.id);
      _actualizarSetScores(
        oldSet: oldSet,
        oldLocalPts: oldLocal,
        oldVisitorPts: oldVisitor,
        localScored: false,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> restarPuntoLocal() async {
    if (_match == null || !_match!.isActivo || _match!.puntosLocal <= 0) return;
    try {
      final setIdx = _match!.setActual - 1;
      _match!.puntosLocal--;
      await _matchRepository.guardar(_match!);
      if (setIdx < _setScores.length) {
        _setScores[setIdx] = MapEntry(
          _match!.puntosLocal,
          _match!.puntosVisitante,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> restarPuntoVisitante() async {
    if (_match == null || !_match!.isActivo || _match!.puntosVisitante <= 0) {
      return;
    }
    try {
      final setIdx = _match!.setActual - 1;
      _match!.puntosVisitante--;
      await _matchRepository.guardar(_match!);
      if (setIdx < _setScores.length) {
        _setScores[setIdx] = MapEntry(
          _match!.puntosLocal,
          _match!.puntosVisitante,
        );
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> undoLastPoint() async {
    if (_match == null || !_match!.isActivo) return;
    try {
      final oldSet = _match!.setActual;
      if (_match!.puntosLocal > 0) {
        _match = await _matchRepository.quitarUltimoPunto(_match!.id);
      } else if (_match!.puntosVisitante > 0) {
        _match = await _matchRepository.quitarUltimoPunto(_match!.id);
      }
      if (_match!.setActual == oldSet) {
        final idx = _match!.setActual - 1;
        if (idx < _setScores.length) {
          _setScores[idx] = MapEntry(
            _match!.puntosLocal,
            _match!.puntosVisitante,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error al deshacer: $e';
      notifyListeners();
    }
  }

  void _actualizarSetScores({
    required int oldSet,
    required int oldLocalPts,
    required int oldVisitorPts,
    required bool localScored,
  }) {
    final currentSet = _match!.setActual;
    while (_setScores.length < currentSet) {
      _setScores.add(const MapEntry(0, 0));
    }

    if (currentSet > oldSet) {
      _setScores[oldSet - 1] = MapEntry(
        localScored ? oldLocalPts + 1 : oldLocalPts,
        localScored ? oldVisitorPts : oldVisitorPts + 1,
      );
      if (currentSet - 1 < _setScores.length) {
        _setScores[currentSet - 1] = const MapEntry(0, 0);
      }
    } else {
      _setScores[currentSet - 1] = MapEntry(
        _match!.puntosLocal,
        _match!.puntosVisitante,
      );
    }
  }

  void actualizarNombreLocal(String nombre) {
    if (_match == null) return;
    _match!.equipoLocal = nombre;
    notifyListeners();
  }

  void actualizarNombreVisitante(String nombre) {
    if (_match == null) return;
    _match!.equipoVisitante = nombre;
    notifyListeners();
  }

  void actualizarConfiguracion({
    int? puntosPorSet,
    int? setsPorPartido,
    int? tiempoPorSet,
  }) {
    if (puntosPorSet != null) _puntosPorSet = puntosPorSet;
    if (setsPorPartido != null) _setsPorPartido = setsPorPartido;
    if (tiempoPorSet != null) _tiempoPorSet = tiempoPorSet;
    notifyListeners();
  }

  Future<void> pausarReanudar() async {
    if (_match == null) return;
    try {
      if (_match!.isActivo) {
        _match = await _matchRepository.pausarPartido(_match!.id);
      } else if (_match!.estado == EstadoPartido.pausado) {
        _match = await _matchRepository.reanudarPartido(_match!.id);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> finalizarPartido() async {
    if (_match == null) return;
    try {
      _match = await _matchRepository.finalizarPartido(_match!.id);
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
