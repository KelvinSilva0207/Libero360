import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../../../core/services/log_service.dart';
import '../../../notifications/data/notification_service.dart';
import '../../../notifications/data/notification_models.dart' show NotificationType;
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/repositories/repositories.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../data/match_config.dart';
import '../../data/match_event.dart';
import '../../data/substitution_record.dart';
import '../../data/timeout_event.dart';
import '../../data/timeout_service.dart';

enum TimeoutState { idle, running, finished }

class MatchController extends ChangeNotifier {
  final MatchRepository _matchRepository = MatchRepository();

  Match? _match;
  bool _isLoading = false;
  String? _error;
  List<MapEntry<int, int>> _setScores = [];

  int _puntosPorSet = 25;
  int _setsPorPartido = 5;
  int _tiempoPorSet = 0;
  int _timeoutsPerSet = 2;
  int _timeoutDurationSeconds = 30;
  Categoria _categoria = Categoria.libre;

  List<Player> _jugadores = [];
  List<Player> _jugadoresVisitante = [];
  int _rotacionLocal = 0;
  int _rotacionVisitante = 0;
  bool _isLocalServing = true;

  // Timeout
  final TimeoutService _timeoutService = TimeoutService();
  TimeoutState _timeoutState = TimeoutState.idle;
  bool _activeTimeoutIsLocal = true;
  int _timeoutCountdown = 0;
  int _localTimeoutsUsed = 0;
  int _visitorTimeoutsUsed = 0;
  List<TimeoutRecord> _timeoutHistory = [];
  Timer? _timeoutTimer;

  // Substitution & Edit Mode
  bool _editMode = false;
  List<SubstitutionRecord> _substitutionHistory = [];

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
  int get timeoutsPerSet => _timeoutsPerSet;
  int get timeoutDurationSeconds => _timeoutDurationSeconds;
  Categoria get categoria => _categoria;
  List<Player> get jugadores => _jugadores;
  List<Player> get jugadoresVisitante => _jugadoresVisitante;
  int get rotacionLocal => _rotacionLocal;
  int get rotacionVisitante => _rotacionVisitante;
  bool get isLocalServing => _isLocalServing;

  // Timeout
  TimeoutState get timeoutState => _timeoutState;
  bool get activeTimeoutIsLocal => _activeTimeoutIsLocal;
  int get timeoutCountdown => _timeoutCountdown;
  int get localTimeoutsUsed => _localTimeoutsUsed;
  int get visitorTimeoutsUsed => _visitorTimeoutsUsed;
  int get localTimeoutsRemaining => _timeoutsPerSet - _localTimeoutsUsed;
  int get visitorTimeoutsRemaining => _timeoutsPerSet - _visitorTimeoutsUsed;
  List<TimeoutRecord> get timeoutHistory => UnmodifiableListView(_timeoutHistory);
  List<SubstitutionRecord> get substitutionHistory =>
      UnmodifiableListView(_substitutionHistory);

  // Edit mode
  bool get editMode => _editMode;
  void toggleEditMode() {
    _editMode = !_editMode;
    notifyListeners();
  }

  // Timer
  Timer? _timer;
  int _duracionSegundos = 0;
  int get duracionSegundos => _duracionSegundos;
  int get duracionSegundosMatch => _duracionSegundos;

  String get tiempoTranscurrido {
    final h = _duracionSegundos ~/ 3600;
    final m = (_duracionSegundos % 3600) ~/ 60;
    final s = _duracionSegundos % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get totalPuntosLocal =>
      _setScores.fold(0, (sum, e) => sum + e.key);
  int get totalPuntosVisitante =>
      _setScores.fold(0, (sum, e) => sum + e.value);

  Future<void> loadMatch(int id) async {
    _setLoading(true);
    _error = null;
    try {
      _match = await _matchRepository.obtenerPorId(id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar partido: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> init([MatchConfig? config]) async {
    _setLoading(true);
    _error = null;

    try {
      await DatabaseService.instance.initialize();

      _setsPorPartido = config?.setsTotales ?? 5;
      _puntosPorSet = config?.categoria.puntosPorSet ?? 25;
      _timeoutsPerSet = config?.timeoutsPerSet ?? 2;
      _timeoutDurationSeconds = config?.timeoutDurationSeconds ?? 30;
      _categoria = config?.categoria ?? Categoria.libre;

      _jugadores = config?.selectedPlayers != null
          ? List.from(config!.selectedPlayers)
          : [];

      final serviceStartsLocal = (config != null &&
              config.serviceOrderPerSet.isNotEmpty)
          ? config.serviceOrderPerSet[0]
          : true;

      _match = await _matchRepository.crearNuevoPartido(
        equipoLocal: config?.localName ?? 'Local',
        equipoVisitante: config?.visitorName ?? 'Visitante',
        setsTotales: _setsPorPartido,
        tipoPartido: config?.tipoPartido ?? TipoPartido.amistoso,
        puntosParaGanarSet: _puntosPorSet,
      );

      _match!.iniciar();
      await _matchRepository.guardar(_match!);
      _setScores = List.generate(_setsPorPartido, (_) => const MapEntry(0, 0));
      _rotacionLocal = 0;
      _rotacionVisitante = 0;
      _isLocalServing = serviceStartsLocal;
      _iniciarTimer();
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

      await _registrarEvento(athleteId: 0, esLocal: true);

      if (!_isLocalServing) {
        _rotacionLocal = (_rotacionLocal + 1) % 6;
        _isLocalServing = true;
      }

      if (_match!.setActual > oldSet) {
        _resetSetTimeouts();
        await _guardarDuracion();
        if (!_match!.isFinalizado) {
          await _matchRepository.pausarPartido(_match!.id);
        } else {
          _detenerTimer();
        }
      }

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

      await _registrarEvento(athleteId: 0, esLocal: false);

      if (_isLocalServing) {
        _rotacionVisitante = (_rotacionVisitante + 1) % 6;
        _isLocalServing = false;
      }

      if (_match!.setActual > oldSet) {
        _resetSetTimeouts();
        await _guardarDuracion();
        if (!_match!.isFinalizado) {
          await _matchRepository.pausarPartido(_match!.id);
        } else {
          _detenerTimer();
        }
      }

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

  void rotarLocal() {
    _rotacionLocal = (_rotacionLocal + 1) % 6;
    notifyListeners();
  }

  void rotarVisitante() {
    _rotacionVisitante = (_rotacionVisitante + 1) % 6;
    notifyListeners();
  }

  void cambiarServicio() {
    if (_match?.isFinalizado == true) return;
    _isLocalServing = !_isLocalServing;
    if (!_isLocalServing) {
      _rotacionVisitante = (_rotacionVisitante + 1) % 6;
    } else {
      _rotacionLocal = (_rotacionLocal + 1) % 6;
    }
    notifyListeners();
  }

  Future<void> actualizarNumeroJugador(int posIndex, int numero) async {
    if (posIndex < 0 || posIndex >= _jugadores.length) return;
    _jugadores[posIndex].numero = numero;
    try {
      await DatabaseService.instance.savePlayer(_jugadores[posIndex]);
    } catch (_) {}
    notifyListeners();
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

  // ========== TIMEOUT ==========

  void startTimeout(bool isLocal) {
    if (_match == null || !_match!.isActivo) return;
    if (_timeoutState != TimeoutState.idle) return;
    if (isLocal && _localTimeoutsUsed >= _timeoutsPerSet) return;
    if (!isLocal && _visitorTimeoutsUsed >= _timeoutsPerSet) return;

    _timeoutState = TimeoutState.running;
    _activeTimeoutIsLocal = isLocal;
    _timeoutCountdown = _timeoutDurationSeconds;

    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timeoutCountdown--;
      if (_timeoutCountdown <= 3 && _timeoutCountdown > 0) {
        _timeoutService.vibrateShort();
      }
      if (_timeoutCountdown <= 0) {
        _finishTimeout();
      }
      notifyListeners();
    });

    notifyListeners();
  }

  void cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _resetTimeoutState();
  }

  void dismissTimeoutResult() {
    if (_timeoutState == TimeoutState.finished) {
      _resetTimeoutState();
    }
  }

  void _resetTimeoutState() {
    _timeoutState = TimeoutState.idle;
    _timeoutCountdown = 0;
    notifyListeners();
  }

  void _finishTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _timeoutService.vibrateLong();

    final now = DateTime.now();
    final inicio = now.subtract(Duration(seconds: _timeoutDurationSeconds));
    final record = TimeoutRecord(
      matchId: _match!.id,
      setNumero: _match!.setActual,
      inicio: inicio,
      fin: now,
      duracionSegundos: _timeoutDurationSeconds,
      esLocal: _activeTimeoutIsLocal,
    );
    _timeoutHistory = [..._timeoutHistory, record];

    if (_activeTimeoutIsLocal) {
      _localTimeoutsUsed++;
    } else {
      _visitorTimeoutsUsed++;
    }

    _timeoutState = TimeoutState.finished;
    notifyListeners();
  }

  void _resetSetTimeouts() {
    _localTimeoutsUsed = 0;
    _visitorTimeoutsUsed = 0;
  }

  // ========== SUBSTITUTION ==========

  void addSubstitution({
    required int playerOutNumber,
    required int playerInNumber,
    required String playerOutName,
    required String playerInName,
    required int setNumber,
    required int rotationIndex,
  }) {
    _substitutionHistory = [
      ..._substitutionHistory,
      SubstitutionRecord(
        playerOutNumber: playerOutNumber,
        playerInNumber: playerInNumber,
        playerOutName: playerOutName,
        playerInName: playerInName,
        timestamp: DateTime.now(),
        setNumber: setNumber,
        rotationIndex: rotationIndex,
      ),
    ];
    notifyListeners();
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

  Future<void> cambiarSet(int nuevoSet) async {
    if (_match == null || _match!.isFinalizado) return;
    if (nuevoSet < 1 || nuevoSet > _setsPorPartido) return;
    if (nuevoSet == _match!.setActual) return;

    try {
      final currentIdx = _match!.setActual - 1;
      while (_setScores.length <= currentIdx) {
        _setScores.add(const MapEntry(0, 0));
      }
      _setScores[currentIdx] = MapEntry(_match!.puntosLocal, _match!.puntosVisitante);

      _match!.setActual = nuevoSet;
      final newIdx = nuevoSet - 1;
      if (newIdx < _setScores.length) {
        _match!.puntosLocal = _setScores[newIdx].key;
        _match!.puntosVisitante = _setScores[newIdx].value;
      } else {
        _match!.puntosLocal = 0;
        _match!.puntosVisitante = 0;
      }

      if (_match!.isActivo) {
        _match!.pausar();
      }

      _resetSetTimeouts();
      await _matchRepository.guardar(_match!);
      notifyListeners();
    } catch (e) {
      _error = 'Error al cambiar set: $e';
      notifyListeners();
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
    int? timeoutsPerSet,
    int? timeoutDurationSeconds,
  }) {
    if (puntosPorSet != null) _puntosPorSet = puntosPorSet;
    if (setsPorPartido != null) _setsPorPartido = setsPorPartido;
    if (tiempoPorSet != null) _tiempoPorSet = tiempoPorSet;
    if (timeoutsPerSet != null) _timeoutsPerSet = timeoutsPerSet;
    if (timeoutDurationSeconds != null) _timeoutDurationSeconds = timeoutDurationSeconds;
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
      _detenerTimer();
      await _guardarDuracion();
      _match = await _matchRepository.finalizarPartido(_match!.id);
      final isWin = _match!.setsLocal > _match!.setsVisitante;
      final result = isWin ? 'Victoria' : 'Derrota';
      LogService.instance.event('Partido finalizado: ${_match!.equipoLocal} vs ${_match!.equipoVisitante} — $result ${_match!.setsLocal}-${_match!.setsVisitante}', source: 'MatchController');
      NotificationService.instance.createNotification(
        type: NotificationType.matchResultSaved,
        title: 'Resultado guardado',
        message: '${_match!.equipoLocal} ${_match!.setsLocal}-${_match!.setsVisitante} ${_match!.equipoVisitante}',
        relatedMatchId: _match!.id.toString(),
      );
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  // ========== TIMER ==========

  void _iniciarTimer() {
    _detenerTimer();
    _duracionSegundos = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_match?.isActivo == true) {
        _duracionSegundos++;
        notifyListeners();
      }
    });
  }

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> eliminarPartido() async {
    if (_match == null) return;
    try {
      _detenerTimer();
      await _matchRepository.eliminar(_match!.id);
      _match = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> _guardarDuracion() async {
    if (_match == null) return;
    _match!.duracionSegundos = _duracionSegundos;
    await _matchRepository.guardar(_match!);
  }

  Future<void> _registrarEvento({required int athleteId, required bool esLocal}) async {
    if (_match == null) return;
    try {
      final event = MatchEvent.create(
        athleteId: athleteId,
        matchId: _match!.id,
        setNumero: _match!.setActual,
        eventType: EventType.regularPoint,
        tipoPartido: _match!.tipoPartido.name,
        rotacion: esLocal ? _rotacionLocal : _rotacionVisitante,
      );
      await DatabaseService.instance.saveMatchEvent(event);
    } catch (_) {}
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
