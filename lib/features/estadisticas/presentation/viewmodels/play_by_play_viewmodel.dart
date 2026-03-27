import 'package:flutter/foundation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

/// ViewModel para la pantalla de Play-by-Play en tiempo real
///
/// Gestiona el estado del partido y las acciones en tiempo real,
/// siguiendo el patrón MVVM.
///
/// Uso con Provider:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => PlayByPlayViewModel(),
/// )
/// ```
class PlayByPlayViewModel extends ChangeNotifier {
  // ============================================================
  // REPOSITORIOS
  // ============================================================
  
  final MatchRepository _matchRepository = MatchRepository();
  final StatEventRepository _statEventRepository = StatEventRepository();

  // ============================================================
  // ESTADO DEL PARTIDO
  // ============================================================
  
  Match? _partidoActual;
  List<StatEvent> _eventos = [];
  List<Player> _jugadoresLocal = [];
  List<Player> _jugadoresVisitante = [];
  Player? _jugadorSeleccionado;
  bool _esEquipoLocal = true;
  bool _isLoading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  /// Partido actualmente seleccionado
  Match? get partidoActual => _partidoActual;

  /// Lista de eventos del partido
  List<StatEvent> get eventos => _eventos;

  /// Jugadores del equipo local
  List<Player> get jugadoresLocal => _jugadoresLocal;

  /// Jugadores del equipo visitante
  List<Player> get jugadoresVisitante => _jugadoresVisitante;

  /// Jugador actualmente seleccionado
  Player? get jugadorSeleccionado => _jugadorSeleccionado;

  /// Indica si el equipo activo es el local
  bool get esEquipoLocal => _esEquipoLocal;

  /// Bandera de carga
  bool get isLoading => _isLoading;

  /// Último error ocurrido
  String? get error => _error;

  /// Indica si hay un partido activo
  bool get hayPartidoActivo => _partidoActual != null && _partidoActual!.isActivo;

  /// Marcador formateado
  String get marcador => _partidoActual?.marcador ?? '0 - 0';

  /// Sets ganados formateados
  String get resultadoSets => _partidoActual?.resultadoSets ?? '0 - 0';

  /// Set actual
  int get setActual => _partidoActual?.setActual ?? 1;

  /// Estado del partido
  EstadoPartido get estadoPartido => _partidoActual?.estado ?? EstadoPartido.noIniciado;

  // ============================================================
  // MÉTODOS DE PARTIDO
  // ============================================================

  /// Inicializa un nuevo partido
  ///
  /// [equipoLocal] - Nombre del equipo local
  /// [equipoVisitante] - Nombre del equipo visitante
  Future<void> iniciarNuevoPartido({
    required String equipoLocal,
    required String equipoVisitante,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _partidoActual = await _matchRepository.crearNuevoPartido(
        equipoLocal: equipoLocal,
        equipoVisitante: equipoVisitante,
      );
      
      _partidoActual!.iniciar();
      await _matchRepository.guardar(_partidoActual!);
      
      _eventos = [];
      notifyListeners();
    } catch (e) {
      _setError('Error al iniciar partido: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carga un partido existente
  Future<void> cargarPartido(int matchId) async {
    _setLoading(true);
    _clearError();

    try {
      _partidoActual = await _matchRepository.obtenerPorId(matchId);
      if (_partidoActual != null) {
        _eventos = await _statEventRepository.obtenerEventosDelPartido(matchId);
      }
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar partido: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Agrega un punto al equipo local
  Future<void> agregarPuntoLocal() async {
    if (_partidoActual == null || !_partidoActual!.isActivo) return;

    _setLoading(true);
    _clearError();

    try {
      _partidoActual = await _matchRepository.agregarPuntoLocal(_partidoActual!.id);
      notifyListeners();
    } catch (e) {
      _setError('Error al agregar punto: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Agrega un punto al equipo visitante
  Future<void> agregarPuntoVisitante() async {
    if (_partidoActual == null || !_partidoActual!.isActivo) return;

    _setLoading(true);
    _clearError();

    try {
      _partidoActual = await _matchRepository.agregarPuntoVisitante(_partidoActual!.id);
      notifyListeners();
    } catch (e) {
      _setError('Error al agregar punto: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Pausa el partido
  Future<void> pausarPartido() async {
    if (_partidoActual == null) return;

    _setLoading(true);
    _clearError();

    try {
      _partidoActual = await _matchRepository.pausarPartido(_partidoActual!.id);
      notifyListeners();
    } catch (e) {
      _setError('Error al pausar: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Reanuda el partido
  Future<void> reanudarPartido() async {
    if (_partidoActual == null) return;

    _setLoading(true);
    _clearError();

    try {
      _partidoActual = await _matchRepository.reanudarPartido(_partidoActual!.id);
      notifyListeners();
    } catch (e) {
      _setError('Error al reanudar: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Finaliza el partido
  Future<void> finalizarPartido() async {
    if (_partidoActual == null) return;

    _setLoading(true);
    _clearError();

    try {
      _partidoActual = await _matchRepository.finalizarPartido(_partidoActual!.id);
      notifyListeners();
    } catch (e) {
      _setError('Error al finalizar: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // MÉTODOS DE JUGADORES
  // ============================================================

  /// Selecciona un jugador
  void seleccionarJugador(Player jugador) {
    _jugadorSeleccionado = jugador;
    notifyListeners();
  }

  /// Cambia el equipo activo
  void cambiarEquipo(bool esLocal) {
    _esEquipoLocal = esLocal;
    _jugadorSeleccionado = null;
    notifyListeners();
  }

  /// Configura los jugadores del equipo local
  void setJugadoresLocal(List<Player> jugadores) {
    _jugadoresLocal = jugadores;
    notifyListeners();
  }

  /// Configura los jugadores del equipo visitante
  void setJugadoresVisitante(List<Player> jugadores) {
    _jugadoresVisitante = jugadores;
    notifyListeners();
  }

  // ============================================================
  // MÉTODOS DE REGISTRO DE ACCIONES
  // ============================================================

  /// Registra un ataque
  Future<void> registrarAtaque({required bool esPositivo}) async {
    if (_partidoActual == null || _jugadorSeleccionado == null) return;

    _clearError();

    try {
      await _statEventRepository.registrarAtaque(
        playerId: _jugadorSeleccionado!.id,
        matchId: _partidoActual!.id,
        esPositivo: esPositivo,
        esEquipoLocal: _esEquipoLocal,
      );
      
      // Agregar punto si fue positivo
      if (esPositivo) {
        if (_esEquipoLocal) {
          await agregarPuntoLocal();
        } else {
          await agregarPuntoVisitante();
        }
      }
      
      await _actualizarEventos();
    } catch (e) {
      _setError('Error al registrar ataque: $e');
    }
  }

  /// Registra un saque
  Future<void> registrarSaque({required bool esPositivo}) async {
    if (_partidoActual == null || _jugadorSeleccionado == null) return;

    _clearError();

    try {
      await _statEventRepository.registrarSaque(
        playerId: _jugadorSeleccionado!.id,
        matchId: _partidoActual!.id,
        esPositivo: esPositivo,
        esEquipoLocal: _esEquipoLocal,
      );
      
      if (esPositivo) {
        if (_esEquipoLocal) {
          await agregarPuntoLocal();
        } else {
          await agregarPuntoVisitante();
        }
      }
      
      await _actualizarEventos();
    } catch (e) {
      _setError('Error al registrar saque: $e');
    }
  }

  /// Registra un bloqueo
  Future<void> registrarBloqueo({required bool esPositivo}) async {
    if (_partidoActual == null || _jugadorSeleccionado == null) return;

    _clearError();

    try {
      await _statEventRepository.registrarBloqueo(
        playerId: _jugadorSeleccionado!.id,
        matchId: _partidoActual!.id,
        esPositivo: esPositivo,
        esEquipoLocal: _esEquipoLocal,
      );
      
      if (esPositivo) {
        if (_esEquipoLocal) {
          await agregarPuntoLocal();
        } else {
          await agregarPuntoVisitante();
        }
      }
      
      await _actualizarEventos();
    } catch (e) {
      _setError('Error al registrar bloqueo: $e');
    }
  }

  /// Registra una defensa
  Future<void> registrarDefensa() async {
    if (_partidoActual == null || _jugadorSeleccionado == null) return;

    _clearError();

    try {
      await _statEventRepository.registrarDefensa(
        playerId: _jugadorSeleccionado!.id,
        matchId: _partidoActual!.id,
        esEquipoLocal: _esEquipoLocal,
      );
      
      await _actualizarEventos();
    } catch (e) {
      _setError('Error al registrar defensa: $e');
    }
  }

  /// Registra un error del equipo contrario
  Future<void> registrarErrorContrario() async {
    if (_partidoActual == null) return;

    _clearError();

    try {
      await _statEventRepository.registrarErrorContrario(
        matchId: _partidoActual!.id,
        esEquipoLocal: _esEquipoLocal,
      );
      
      // El punto va para el equipo que no es el actual
      if (_esEquipoLocal) {
        await agregarPuntoVisitante();
      } else {
        await agregarPuntoLocal();
      }
      
      await _actualizarEventos();
    } catch (e) {
      _setError('Error al registrar error: $e');
    }
  }

  // ============================================================
  // MÉTODOS DE CONSULTA
  // ============================================================

  /// Obtiene estadísticas del jugador seleccionado
  Future<Map<String, int>> obtenerEstadisticasJugador() async {
    if (_partidoActual == null || _jugadorSeleccionado == null) {
      return {};
    }
    
    return await _statEventRepository.obtenerEstadisticasJugadorPartido(
      _jugadorSeleccionado!.id,
      _partidoActual!.id,
    );
  }

  /// Obtiene el timeline de eventos
  Future<List<Map<String, dynamic>>> obtenerTimeline() async {
    if (_partidoActual == null) return [];
    
    return await _statEventRepository.obtenerTimeline(_partidoActual!.id);
  }

  /// Obtiene el resumen del partido
  Future<Map<String, dynamic>> obtenerResumen() async {
    if (_partidoActual == null) return {};
    
    return await _matchRepository.obtenerResumen(_partidoActual!.id);
  }

  // ============================================================
  // MÉTODOS PRIVADOS DE UTILIDAD
  // ============================================================

  /// Actualiza la lista de eventos desde la base de datos
  Future<void> _actualizarEventos() async {
    if (_partidoActual == null) return;
    
    _eventos = await _statEventRepository.obtenerEventosDelPartido(
      _partidoActual!.id,
    );
    notifyListeners();
  }

  /// Establece el estado de carga
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Establece un error
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  /// Limpia el error actual
  void _clearError() {
    _error = null;
  }

  /// Limpia todo el estado
  void clear() {
    _partidoActual = null;
    _eventos = [];
    _jugadoresLocal = [];
    _jugadoresVisitante = [];
    _jugadorSeleccionado = null;
    _esEquipoLocal = true;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Limpiar recursos si es necesario
    super.dispose();
  }
}
