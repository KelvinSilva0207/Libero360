import '../local_db/database_service.dart';
import '../models/models.dart';

/// Repositorio para gestionar operaciones de Eventos de Estadística
///
/// Proporciona una capa de abstracción sobre el acceso a datos de eventos
/// de estadísticas, facilitando el registro y consulta de acciones
/// durante los partidos.
///
/// Ejemplo de uso:
/// ```dart
/// final repo = StatEventRepository();
/// await repo.registrarAtaque(playerId: 1, matchId: 1, esPositivo: true);
/// final eventos = await repo.obtenerEventosDelPartido(1);
/// ```
class StatEventRepository {
  /// Acceso al servicio de base de datos
  DatabaseService get _db => DatabaseService.instance;

  // ============================================================
  // OPERACIONES CRUD BÁSICAS
  // ============================================================

  /// Obtiene todos los eventos de un partido ordenados por timestamp
  Future<List<StatEvent>> obtenerEventosDelPartido(int matchId) async {
    return await _db.getEventsByMatch(matchId);
  }

  /// Obtiene todos los eventos de un jugador
  Future<List<StatEvent>> obtenerEventosDelJugador(int playerId) async {
    return await _db.getEventsByPlayer(playerId);
  }

  /// Obtiene eventos de un jugador en un partido específico
  Future<List<StatEvent>> obtenerEventosDeJugadorEnPartido(
    int playerId,
    int matchId,
  ) async {
    return await _db.getEventsByPlayerAndMatch(playerId, matchId);
  }

  /// Guarda un evento de estadística
  Future<int> guardar(StatEvent event) async {
    return await _db.saveStatEvent(event);
  }

  /// Elimina un evento
  Future<bool> eliminar(int id) async {
    return await _db.deleteStatEvent(id);
  }

  // ============================================================
  // MÉTODOS DE REGISTRO RÁPIDO
  // ============================================================

  /// Registra un evento de ataque
  ///
  /// [playerId] - ID del jugador que realizó el ataque
  /// [matchId] - ID del partido
  /// [esPositivo] - true si el ataque fue exitoso (punto ganado)
  /// [esEquipoLocal] - true si el equipo es el local
  Future<StatEvent> registrarAtaque({
    required int playerId,
    required int matchId,
    required bool esPositivo,
    required bool esEquipoLocal,
    ZonaCancha zona = ZonaCancha.ataque,
  }) async {
    final match = await _db.getMatchById(matchId);
    if (match == null) {
      throw Exception('Partido no encontrado: $matchId');
    }

    final evento = StatEvent.create(
      tipoAccion: TipoAccion.ataque,
      resultado: esPositivo ? ResultadoAccion.positivo : ResultadoAccion.negativo,
      setNumero: match.setActual,
      puntoLocal: match.puntosLocal,
      puntoVisitante: match.puntosVisitante,
      esEquipoLocal: esEquipoLocal,
      zona: zona,
      playerId: playerId,
      matchId: matchId,
      profileId: match.profileId,
      clubId: match.clubId,
    );

    await _db.saveStatEvent(evento);
    return evento;
  }

  /// Registra un evento de saque
  Future<StatEvent> registrarSaque({
    required int playerId,
    required int matchId,
    required bool esPositivo,
    required bool esEquipoLocal,
  }) async {
    final match = await _db.getMatchById(matchId);
    if (match == null) {
      throw Exception('Partido no encontrado: $matchId');
    }

    final evento = StatEvent.create(
      tipoAccion: TipoAccion.saque,
      resultado: esPositivo ? ResultadoAccion.positivo : ResultadoAccion.negativo,
      setNumero: match.setActual,
      puntoLocal: match.puntosLocal,
      puntoVisitante: match.puntosVisitante,
      esEquipoLocal: esEquipoLocal,
      zona: ZonaCancha.saque,
      playerId: playerId,
      matchId: matchId,
      profileId: match.profileId,
      clubId: match.clubId,
    );

    await _db.saveStatEvent(evento);
    return evento;
  }

  /// Registra un evento de bloqueo
  Future<StatEvent> registrarBloqueo({
    required int playerId,
    required int matchId,
    required bool esPositivo,
    required bool esEquipoLocal,
  }) async {
    final match = await _db.getMatchById(matchId);
    if (match == null) {
      throw Exception('Partido no encontrado: $matchId');
    }

    final evento = StatEvent.create(
      tipoAccion: TipoAccion.bloqueo,
      resultado: esPositivo ? ResultadoAccion.positivo : ResultadoAccion.negativo,
      setNumero: match.setActual,
      puntoLocal: match.puntosLocal,
      puntoVisitante: match.puntosVisitante,
      esEquipoLocal: esEquipoLocal,
      zona: ZonaCancha.central,
      playerId: playerId,
      matchId: matchId,
      profileId: match.profileId,
      clubId: match.clubId,
    );

    await _db.saveStatEvent(evento);
    return evento;
  }

  /// Registra un evento de defensa
  Future<StatEvent> registrarDefensa({
    required int playerId,
    required int matchId,
    required bool esEquipoLocal,
    String? descripcion,
  }) async {
    final match = await _db.getMatchById(matchId);
    if (match == null) {
      throw Exception('Partido no encontrado: $matchId');
    }

    final evento = StatEvent.create(
      tipoAccion: TipoAccion.defensa,
      resultado: ResultadoAccion.neutral,
      setNumero: match.setActual,
      puntoLocal: match.puntosLocal,
      puntoVisitante: match.puntosVisitante,
      esEquipoLocal: esEquipoLocal,
      zona: ZonaCancha.defensa,
      playerId: playerId,
      matchId: matchId,
      descripcion: descripcion,
      profileId: match.profileId,
      clubId: match.clubId,
    );

    await _db.saveStatEvent(evento);
    return evento;
  }

  /// Registra un error del equipo contrario
  Future<StatEvent> registrarErrorContrario({
    required int matchId,
    required bool esEquipoLocal,
  }) async {
    final match = await _db.getMatchById(matchId);
    if (match == null) {
      throw Exception('Partido no encontrado: $matchId');
    }

    final evento = StatEvent.create(
      tipoAccion: TipoAccion.errorContrario,
      resultado: ResultadoAccion.positivo,
      setNumero: match.setActual,
      puntoLocal: match.puntosLocal,
      puntoVisitante: match.puntosVisitante,
      esEquipoLocal: !esEquipoLocal,
      zona: ZonaCancha.central,
      playerId: 0,
      matchId: matchId,
      descripcion: 'Error del equipo contrario',
      profileId: match.profileId,
      clubId: match.clubId,
    );

    await _db.saveStatEvent(evento);
    return evento;
  }

  // ============================================================
  // CONSULTAS ESTADÍSTICAS
  // ============================================================

  /// Obtiene estadísticas de un jugador en un partido
  Future<Map<String, int>> obtenerEstadisticasJugadorPartido(
    int playerId,
    int matchId,
  ) async {
    final eventos = await _db.getEventsByPlayerAndMatch(playerId, matchId);
    
    int ataquesTotales = 0;
    int ataquesExitosos = 0;
    int saquesTotales = 0;
    int saquesExitosos = 0;
    int bloqueosTotales = 0;
    int bloqueosExitosos = 0;
    int defensasTotales = 0;

    for (final evento in eventos) {
      switch (evento.tipoAccion) {
        case TipoAccion.ataque:
          ataquesTotales++;
          if (evento.isPuntoGanado) ataquesExitosos++;
          break;
        case TipoAccion.saque:
          saquesTotales++;
          if (evento.isPuntoGanado) saquesExitosos++;
          break;
        case TipoAccion.bloqueo:
          bloqueosTotales++;
          if (evento.isPuntoGanado) bloqueosExitosos++;
          break;
        case TipoAccion.defensa:
          defensasTotales++;
          break;
        case TipoAccion.recepcion:
        case TipoAccion.colocacion:
        case TipoAccion.errorContrario:
          // No se cuenta para estadísticas específicas
          break;
      }
    }

    return {
      'ataques_totales': ataquesTotales,
      'ataques_exitosos': ataquesExitosos,
      'saques_totales': saquesTotales,
      'saques_exitosos': saquesExitosos,
      'bloqueos_totales': bloqueosTotales,
      'bloqueos_exitosos': bloqueosExitosos,
      'defensas_totales': defensasTotales,
    };
  }

  /// Calcula el porcentaje de efectividad de un jugador
  Future<double> calcularEfectividadJugador(int playerId, int matchId) async {
    final eventos = await _db.getEventsByPlayerAndMatch(playerId, matchId);
    
    int accionesPositivas = 0;
    int accionesTotales = 0;

    for (final evento in eventos) {
      if (evento.tipoAccion != TipoAccion.defensa &&
          evento.tipoAccion != TipoAccion.colocacion &&
          evento.tipoAccion != TipoAccion.recepcion) {
        accionesTotales++;
        if (evento.isPuntoGanado) accionesPositivas++;
      }
    }

    if (accionesTotales == 0) return 0.0;
    return (accionesPositivas / accionesTotales) * 100;
  }

  /// Obtiene el último evento de un partido
  Future<StatEvent?> obtenerUltimoEvento(int matchId) async {
    final eventos = await _db.getEventsByMatch(matchId);
    if (eventos.isEmpty) return null;
    return eventos.last;
  }

  /// Obtiene los eventos de un set específico
  Future<List<StatEvent>> obtenerEventosDelSet(
    int matchId,
    int setNumero,
  ) async {
    final eventos = await _db.getEventsByMatch(matchId);
    return eventos.where((e) => e.setNumero == setNumero).toList();
  }

  /// Cuenta eventos por tipo en un partido
  Future<int> contarEventosPorTipo(int matchId, TipoAccion tipo) async {
    return await _db.countEventsByType(matchId, tipo);
  }

  /// Obtiene el timeline de eventos para play-by-play
  Future<List<Map<String, dynamic>>> obtenerTimeline(int matchId) async {
    final eventos = await _db.getEventsByMatch(matchId);
    final match = await _db.getMatchById(matchId);
    
    if (match == null) return [];

    final result = <Map<String, dynamic>>[];
    for (final e in eventos) {
      final player = e.playerId > 0 ? await _db.getPlayerById(e.playerId) : null;
      result.add({
        'evento': e,
        'jugador': player,
        'marcador': e.marcadorEnAccion,
        'set': e.setNumero,
        'descripcion': e.descripcionAccion,
      });
    }
    return result;
  }
}
