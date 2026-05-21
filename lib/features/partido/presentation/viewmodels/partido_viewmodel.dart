import 'package:flutter/foundation.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/repositories/repositories.dart';
import '../../../estadisticas/data/local_db/database_service.dart';

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

  Future<void> init() async {
    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      await DatabaseService.instance.initialize();

      _match = await _matchRepository.crearNuevoPartido(
        equipoLocal: 'Local',
        equipoVisitante: 'Visitante',
      );
      _match!.iniciar();
      await _matchRepository.guardar(_match!);

      _jugadores = List.generate(6, (i) {
        return Player.create(
          nombre: 'Jug ${i + 1}',
          cedula: '',
          fechaNacimiento: DateTime.now().subtract(const Duration(days: 365 * 20)),
          numero: i + 1,
          posicion: _posicionEnCancha(i),
          condicionFisica: 'Excelente',
        );
      });
      for (var j in _jugadores) {
        await DatabaseService.instance.savePlayer(j);
      }
      _jugadorSeleccionado = _jugadores[0];
    } catch (e) {
      _error = 'Error al iniciar partido: $e';
    } finally {
      _setLoading(false);
    }
  }

  Posicion _posicionEnCancha(int index) {
    switch (index) {
      case 0: return Posicion.opuesto;
      case 1: return Posicion.receptor;
      case 2: return Posicion.central;
      case 3: return Posicion.colocador;
      case 4: return Posicion.central;
      case 5: return Posicion.receptor;
      default: return Posicion.colocador;
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
    if (_match == null || !_match!.isActivo || _match!.puntosLocal <= 0) return;
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
    if (_match == null || !_match!.isActivo || _match!.puntosVisitante <= 0) return;
    try {
      _match!.puntosVisitante--;
      await _matchRepository.guardar(_match!);
      notifyListeners();
    } catch (e) {
      _error = 'Error: $e';
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
    final backRow = _jugadores.sublist(3, 6);
    final frontRow = _jugadores.sublist(0, 3);
    _jugadores = [
      backRow[2],
      ...frontRow,
      backRow[0],
      backRow[1],
    ];
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
