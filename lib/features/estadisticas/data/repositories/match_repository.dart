import '../local_db/database_service.dart';
import '../models/models.dart';

/// Repositorio para gestionar operaciones de Partido
///
/// Proporciona una capa de abstracción sobre el acceso a datos de partidos,
/// facilitando la manipulación de entidades Match y sus relaciones.
///
/// Ejemplo de uso:
/// ```dart
/// final repo = MatchRepository();
/// await repo.crearNuevoPartido('Equipo A', 'Equipo B');
/// final partidoActivo = await repo.obtenerPartidoActivo();
/// ```
class MatchRepository {
  /// Acceso al servicio de base de datos
  DatabaseService get _db => DatabaseService.instance;

  // ============================================================
  // OPERACIONES CRUD BÁSICAS
  // ============================================================

  /// Obtiene todos los partidos ordenados por fecha
  Future<List<Match>> obtenerTodos() async {
    return await _db.getAllMatches();
  }

  /// Busca un partido por su ID
  Future<Match?> obtenerPorId(int id) async {
    return await _db.getMatchById(id);
  }

  /// Obtiene partidos filtrados por estado
  Future<List<Match>> obtenerPorEstado(EstadoPartido estado) async {
    return await _db.getMatchesByState(estado);
  }

  /// Guarda un partido (crea o actualiza)
  Future<int> guardar(Match match) async {
    return await _db.saveMatch(match);
  }

  /// Elimina un partido y todos sus eventos asociados
  Future<bool> eliminar(int id) async {
    return await _db.deleteMatch(id);
  }

  // ============================================================
  // OPERACIONES DE PARTIDO
  // ============================================================

  /// Crea un nuevo partido
  ///
  /// [equipoLocal] - Nombre del equipo local
  /// [equipoVisitante] - Nombre del equipo visitante
  /// [fecha] - Fecha y hora del partido (opcional, por defecto ahora)
  Future<Match> crearNuevoPartido({
    required String equipoLocal,
    required String equipoVisitante,
    DateTime? fecha,
    TipoPartido tipoPartido = TipoPartido.amistoso,
    int setsTotales = 5,
    String? lugar,
  }) async {
    final match = Match.create(
      equipoLocal: equipoLocal,
      equipoVisitante: equipoVisitante,
      fecha: fecha,
      tipoPartido: tipoPartido,
      setsTotales: setsTotales,
      lugar: lugar,
    );
    
    final id = await _db.saveMatch(match);
    match.id = id;
    
    return match;
  }

  /// Obtiene el partido activo actual
  ///
  /// Retorna null si no hay ningún partido en progreso
  Future<Match?> obtenerPartidoActivo() async {
    return await _db.getActiveMatch();
  }

  /// Inicia un partido que estaba en estado "noIniciado"
  Future<Match?> iniciarPartido(int id) async {
    final match = await _db.getMatchById(id);
    if (match != null && match.estado == EstadoPartido.noIniciado) {
      match.iniciar();
      await _db.saveMatch(match);
    }
    return match;
  }

  /// Pausa el partido en progreso
  Future<Match?> pausarPartido(int id) async {
    final match = await _db.getMatchById(id);
    if (match != null && match.estado == EstadoPartido.enProgreso) {
      match.pausar();
      await _db.saveMatch(match);
    }
    return match;
  }

  /// Reanuda un partido pausado
  Future<Match?> reanudarPartido(int id) async {
    final match = await _db.getMatchById(id);
    if (match != null && match.estado == EstadoPartido.pausado) {
      match.reanudar();
      await _db.saveMatch(match);
    }
    return match;
  }

  /// Finaliza un partido manualmente
  Future<Match?> finalizarPartido(int id) async {
    final match = await _db.getMatchById(id);
    if (match != null && match.estado != EstadoPartido.finalizado) {
      match.finalizar();
      await _db.saveMatch(match);
    }
    return match;
  }

  // ============================================================
  // OPERACIONES DE PUNTUACIÓN
  // ============================================================

  /// Agrega un punto al equipo local
  /// Retorna true si el set o partido terminó
  Future<Match?> agregarPuntoLocal(int matchId) async {
    final match = await _db.getMatchById(matchId);
    if (match != null && match.isActivo) {
      match.agregarPuntoLocal();
      await _db.saveMatch(match);
    }
    return match;
  }

  /// Agrega un punto al equipo visitante
  /// Retorna true si el set o partido terminó
  Future<Match?> agregarPuntoVisitante(int matchId) async {
    final match = await _db.getMatchById(matchId);
    if (match != null && match.isActivo) {
      match.agregarPuntoVisitante();
      await _db.saveMatch(match);
    }
    return match;
  }

  /// Cambia el turno de saque
  Future<Match?> cambiarTurno(int matchId) async {
    final match = await _db.getMatchById(matchId);
    if (match != null) {
      match.turnoLocal = !match.turnoLocal;
      await _db.saveMatch(match);
    }
    return match;
  }

  /// Quita el último punto (undo)
  Future<Match?> quitarUltimoPunto(int matchId) async {
    final match = await _db.getMatchById(matchId);
    if (match != null && match.isActivo) {
      // Lógica simple: reducir el último punto marcado
      // En una implementación real, se guardaría el historial
      if (match.puntosLocal > 0) {
        match.puntosLocal--;
      } else if (match.puntosVisitante > 0) {
        match.puntosVisitante--;
      }
      await _db.saveMatch(match);
    }
    return match;
  }

  // ============================================================
  // CONSULTAS ESPECÍFICAS
  // ============================================================

  /// Obtiene el historial de partidos entre dos equipos
  Future<List<Match>> obtenerHistorialEntreEquipos(
    String equipo1,
    String equipo2,
  ) async {
    final todos = await _db.getAllMatches();
    return todos.where((m) =>
      (m.equipoLocal == equipo1 && m.equipoVisitante == equipo2) ||
      (m.equipoLocal == equipo2 && m.equipoVisitante == equipo1)
    ).toList();
  }

  /// Obtiene los últimos N partidos jugados
  Future<List<Match>> obtenerUltimosPartidos(int cantidad) async {
    final todos = await _db.getAllMatches();
    return todos.take(cantidad).toList();
  }

  /// Obtiene partidos jugados en un rango de fechas
  Future<List<Match>> obtenerPartidosPorRangoFechas(
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    final todos = await _db.getAllMatches();
    return todos.where((m) =>
      m.fecha.isAfter(fechaInicio) && m.fecha.isBefore(fechaFin)
    ).toList();
  }

  /// Obtiene estadísticas resumidas de un partido
  Future<Map<String, dynamic>> obtenerResumen(int matchId) async {
    final match = await _db.getMatchById(matchId);
    if (match == null) {
      return {};
    }

    final eventos = await _db.getEventsByMatch(matchId);
    
    // Contadores por equipo
    int puntosLocal = 0;
    int puntosVisitante = 0;
    int ataquesLocal = 0;
    int ataquesVisitante = 0;
    int saquesLocal = 0;
    int saquesVisitante = 0;
    int bloqueosLocal = 0;
    int bloqueosVisitante = 0;

    for (final evento in eventos) {
      if (evento.esEquipoLocal) {
        switch (evento.tipoAccion) {
          case TipoAccion.ataque:
            ataquesLocal++;
          case TipoAccion.saque:
            saquesLocal++;
          case TipoAccion.bloqueo:
            bloqueosLocal++;
          case TipoAccion.defensa:
          case TipoAccion.recepcion:
          case TipoAccion.colocacion:
          case TipoAccion.errorContrario:
            // No se cuenta para estadísticas específicas
            break;
        }
        if (evento.isPuntoGanado) puntosLocal++;
      } else {
        switch (evento.tipoAccion) {
          case TipoAccion.ataque:
            ataquesVisitante++;
          case TipoAccion.saque:
            saquesVisitante++;
          case TipoAccion.bloqueo:
            bloqueosVisitante++;
          case TipoAccion.defensa:
          case TipoAccion.recepcion:
          case TipoAccion.colocacion:
          case TipoAccion.errorContrario:
            // No se cuenta para estadísticas específicas
            break;
        }
        if (evento.isPuntoGanado) puntosVisitante++;
      }
    }

    return {
      'match': match,
      'puntosLocal': puntosLocal,
      'puntosVisitante': puntosVisitante,
      'ataquesLocal': ataquesLocal,
      'ataquesVisitante': ataquesVisitante,
      'saquesLocal': saquesLocal,
      'saquesVisitante': saquesVisitante,
      'bloqueosLocal': bloqueosLocal,
      'bloqueosVisitante': bloqueosVisitante,
      'totalEventos': eventos.length,
    };
  }
}
