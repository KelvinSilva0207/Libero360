import 'package:flutter/foundation.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/repositories/repositories.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../data/match_config.dart';

class PartidoViewModel extends ChangeNotifier {
  final MatchRepository _matchRepository = MatchRepository();
  final StatEventRepository _statEventRepository = StatEventRepository();

  Match? _match;
  List<Player> _jugadores = [];
  Player? _jugadorSeleccionado;
  int _teamSeleccionado = 0;
  bool _isLoading = false;
  String? _error;

  Match? get match => _match;
  List<Player> get jugadores => _jugadores;
  Player? get jugadorSeleccionado => _jugadorSeleccionado;
  int get teamSeleccionado => _teamSeleccionado;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPartidoActivo => _match?.isActivo ?? false;

  String get marcador => _match?.marcador ?? '0 - 0';
  int get puntosLocal => _match?.puntosLocal ?? 0;
  int get puntosVisitante => _match?.puntosVisitante ?? 0;
  int get setsLocal => _match?.setsLocal ?? 0;
  int get setsVisitante => _match?.setsVisitante ?? 0;
  int get setActual => _match?.setActual ?? 1;
  String get nombreLocal => _match?.equipoLocal ?? 'Local';
  String get nombreVisitante => _match?.equipoVisitante ?? 'Visitante';
  EstadoPartido get estado => _match?.estado ?? EstadoPartido.noIniciado;

  Future<void> init([MatchConfig? config]) async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      await DatabaseService.instance.initialize();

      final configLocalName = config?.localName ?? 'Local';
      final configVisitorName = config?.visitorName ?? 'Visitante';
      final configSetsTotales = config?.setsTotales ?? 5;
      final configTipoPartido = config?.tipoPartido ?? TipoPartido.amistoso;

      _match = await _matchRepository.crearNuevoPartido(
        equipoLocal: configLocalName,
        equipoVisitante: configVisitorName,
        setsTotales: configSetsTotales,
        tipoPartido: configTipoPartido,
      );

      if (config != null && config.selectedPlayers.isNotEmpty) {
        _jugadores = List.from(config.selectedPlayers);
      } else {
        _jugadores = [
          Player.create(nombre: 'Jug 4', numero: 4, posicion: Posicion.receptor, cedula: '', fechaNacimiento: DateTime.now().subtract(const Duration(days: 365 * 20)), condicionFisica: 'Excelente'),
          Player.create(nombre: 'Jug 3', numero: 3, posicion: Posicion.central, cedula: '', fechaNacimiento: DateTime.now().subtract(const Duration(days: 365 * 20)), condicionFisica: 'Excelente'),
          Player.create(nombre: 'Jug 2', numero: 2, posicion: Posicion.opuesto, cedula: '', fechaNacimiento: DateTime.now().subtract(const Duration(days: 365 * 20)), condicionFisica: 'Excelente'),
          Player.create(nombre: 'Jug 5', numero: 5, posicion: Posicion.receptor, cedula: '', fechaNacimiento: DateTime.now().subtract(const Duration(days: 365 * 20)), condicionFisica: 'Excelente'),
          Player.create(nombre: 'Jug 6', numero: 6, posicion: Posicion.central, cedula: '', fechaNacimiento: DateTime.now().subtract(const Duration(days: 365 * 20)), condicionFisica: 'Excelente'),
          Player.create(nombre: 'Jug 1', numero: 1, posicion: Posicion.colocador, cedula: '', fechaNacimiento: DateTime.now().subtract(const Duration(days: 365 * 20)), condicionFisica: 'Excelente'),
        ];
      }
      _ordenarJugadoresEnCancha();

      _match!.iniciar();
      await _matchRepository.guardar(_match!);
      _jugadorSeleccionado = _jugadores.isNotEmpty ? _jugadores[0] : null;
    } catch (e) {
      _error = 'Error al iniciar partido: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _ordenarJugadoresEnCancha() {
    if (_jugadores.length < 6) return;
    final cancha = _jugadores.take(6).toList()..sort((a, b) => a.numero.compareTo(b.numero));
    final banca = _jugadores.skip(6).toList();
    _jugadores = [
      cancha[3], cancha[2], cancha[1],  // Z4, Z3, Z2 (frente)
      cancha[4], cancha[5], cancha[0],  // Z5, Z6, Z1 (fondo)
      ...banca,
    ];
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

  void actualizarNumeroJugador(int index, int numero) {
    if (index < 0 || index >= _jugadores.length) return;
    _jugadores[index].numero = numero;
    notifyListeners();
  }

  void seleccionarJugador(Player j) {
    if (_jugadorSeleccionado?.id == j.id) return;
    _jugadorSeleccionado = j;
    notifyListeners();
  }

  void seleccionarTeam(int index) {
    if (_teamSeleccionado == index) return;
    _teamSeleccionado = index;
    notifyListeners();
  }

  void setJugadores(List<Player> nuevos) {
    _jugadores = List.from(nuevos);
    _ordenarJugadoresEnCancha();
    if (_jugadorSeleccionado != null && !_jugadores.any((j) => j.id == _jugadorSeleccionado!.id)) {
      _jugadorSeleccionado = _jugadores.isNotEmpty ? _jugadores[0] : null;
    }
    notifyListeners();
  }

  Future<void> registrarAccion(TipoAccion tipo, {bool positivo = true}) async {
    if (_match == null || _jugadorSeleccionado == null) return;

    try {
      switch (tipo) {
        case TipoAccion.ataque:
          await _statEventRepository.registrarAtaque(
            playerId: _jugadorSeleccionado!.id,
            matchId: _match!.id,
            esPositivo: positivo,
            esEquipoLocal: _teamSeleccionado == 0,
          );
        case TipoAccion.saque:
          await _statEventRepository.registrarSaque(
            playerId: _jugadorSeleccionado!.id,
            matchId: _match!.id,
            esPositivo: positivo,
            esEquipoLocal: _teamSeleccionado == 0,
          );
        case TipoAccion.bloqueo:
          await _statEventRepository.registrarBloqueo(
            playerId: _jugadorSeleccionado!.id,
            matchId: _match!.id,
            esPositivo: positivo,
            esEquipoLocal: _teamSeleccionado == 0,
          );
        case TipoAccion.defensa:
          await _statEventRepository.registrarDefensa(
            playerId: _jugadorSeleccionado!.id,
            matchId: _match!.id,
            esEquipoLocal: _teamSeleccionado == 0,
          );
          return;
        default:
          return;
      }

      if (positivo) {
        if (_teamSeleccionado == 0) {
          await _matchRepository.agregarPuntoLocal(_match!.id);
        } else {
          await _matchRepository.agregarPuntoVisitante(_match!.id);
        }
      }
      _match = await _matchRepository.obtenerPorId(_match!.id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al registrar: $e';
      notifyListeners();
    }
  }

  Future<void> registrarErrorContrario() async {
    if (_match == null) return;
    try {
      await _statEventRepository.registrarErrorContrario(
        matchId: _match!.id,
        esEquipoLocal: _teamSeleccionado == 0,
      );
      if (_teamSeleccionado == 0) {
        await _matchRepository.agregarPuntoLocal(_match!.id);
      } else {
        await _matchRepository.agregarPuntoVisitante(_match!.id);
      }
      _match = await _matchRepository.obtenerPorId(_match!.id);
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> sumarPuntoLocal() async {
    if (_match == null || !_match!.isActivo) return;
    try {
      _match = await _matchRepository.agregarPuntoLocal(_match!.id);
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> sumarPuntoVisitante() async {
    if (_match == null || !_match!.isActivo) return;
    try {
      _match = await _matchRepository.agregarPuntoVisitante(_match!.id);
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> restarPuntoLocal() async {
    if (_match == null || !_match!.isActivo || (_match!.puntosLocal <= 0)) return;
    try {
      _match!.puntosLocal--;
      await _matchRepository.guardar(_match!);
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> restarPuntoVisitante() async {
    if (_match == null || !_match!.isActivo || (_match!.puntosVisitante <= 0)) return;
    try {
      _match!.puntosVisitante--;
      await _matchRepository.guardar(_match!);
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> undoLastPoint() async {
    if (_match == null || !_match!.isActivo) return;
    try {
      final eventos = await _statEventRepository.obtenerEventosDelPartido(_match!.id);
      final ultimoEvento = eventos.isNotEmpty ? eventos.last : null;

      if (ultimoEvento != null) {
        await _statEventRepository.eliminar(ultimoEvento.id);
        final fueLocal = ultimoEvento.esEquipoLocal;
        if (ultimoEvento.isPuntoGanado || ultimoEvento.tipoAccion == TipoAccion.errorContrario) {
          if (fueLocal && _match!.puntosLocal > 0) {
            _match!.puntosLocal--;
          } else if (!fueLocal && _match!.puntosVisitante > 0) {
            _match!.puntosVisitante--;
          }
        }
      } else {
        if (_match!.puntosLocal > 0) {
          _match!.puntosLocal--;
        } else if (_match!.puntosVisitante > 0) {
          _match!.puntosVisitante--;
        }
      }
      await _matchRepository.guardar(_match!);
      notifyListeners();
    } catch (e) {
      _error = 'Error al deshacer: $e';
      notifyListeners();
    }
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

  void rotarJugadores() {
    if (_jugadores.length < 6) return;
    final original = List<Player>.from(_jugadores);
    // Rotación horaria correcta del voleibol:
    // Z5→Z4(3→0), Z4→Z3(0→1), Z3→Z2(1→2),
    // Z6→Z5(4→3), Z1→Z6(5→4), Z2→Z1(2→5)
    _jugadores = [
      original[3],
      original[0],
      original[1],
      original[4],
      original[5],
      original[2],
    ];
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
