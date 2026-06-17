import '../../../estadisticas/data/models/stat_event.dart';
import '../match_event.dart';

class MatchEventMapper {
  /// Convierte [MatchEvent] → [StatEvent].
  ///
  /// MatchEvent solo conoce `EventType` (winnerPoint, regularPoint, error)
  /// sin distinguir entre ataque/saque/bloqueo. Se mapea a `TipoAccion.ataque`
  /// como valor por defecto (el punto regular más común).
  ///
  /// `puntoLocal`, `puntoVisitante`, `esEquipoLocal`, `zona` no existen en
  /// MatchEvent → se asignan valores por defecto.
  static StatEvent toStatEvent(MatchEvent source) {
    final (TipoAccion tipo, ResultadoAccion resultado) = _matchEventTypeToStat(
      source.eventType,
    );

    return StatEvent.create(
      tipoAccion: tipo,
      resultado: resultado,
      setNumero: source.setNumero,
      puntoLocal: 0,
      puntoVisitante: 0,
      esEquipoLocal: false,
      zona: ZonaCancha.ninguna,
      playerId: source.athleteId,
      matchId: source.matchId,
      descripcion: _buildDescripcion(source),
    );
  }

  /// Convierte [StatEvent] → [MatchEvent].
  ///
  /// `tipoPartido`, `competenciaNombre`, `rotacion` no existen en StatEvent
  /// → se asignan valores por defecto.
  static MatchEvent toMatchEvent(StatEvent source) {
    return MatchEvent.create(
      athleteId: source.playerId,
      matchId: source.matchId,
      setNumero: source.setNumero,
      eventType: _statResultToEventType(source.resultado),
      tipoPartido: '',
      competenciaNombre: null,
      rotacion: 0,
    );
  }

  // ============================================================
  // HELPERS DE CONVERSIÓN
  // ============================================================

  /// Mapea [EventType] → ([TipoAccion], [ResultadoAccion]).
  ///
  /// | MatchEvent EventType | StatEvent TipoAccion    | Resultado |
  /// |----------------------|-------------------------|-----------|
  /// | winnerPoint          | ataque                  | positivo  |
  /// | regularPoint         | ataque                  | positivo  |
  /// | error                | errorContrario          | negativo  |
  static (TipoAccion, ResultadoAccion) _matchEventTypeToStat(EventType e) {
    return switch (e) {
      EventType.winnerPoint => (TipoAccion.ataque, ResultadoAccion.positivo),
      EventType.regularPoint => (TipoAccion.ataque, ResultadoAccion.positivo),
      EventType.error => (TipoAccion.errorContrario, ResultadoAccion.negativo),
    };
  }

  /// Mapea [ResultadoAccion] → [EventType].
  ///
  /// | StatEvent Resultado | MatchEvent EventType |
  /// |---------------------|----------------------|
  /// | positivo            | winnerPoint          |
  /// | negativo            | error                |
  /// | neutral             | regularPoint         |
  static EventType _statResultToEventType(ResultadoAccion r) {
    return switch (r) {
      ResultadoAccion.positivo => EventType.winnerPoint,
      ResultadoAccion.negativo => EventType.error,
      ResultadoAccion.neutral => EventType.regularPoint,
    };
  }

  /// Construye una descripción legible a partir de campos de MatchEvent.
  static String _buildDescripcion(MatchEvent e) {
    final typeLabel = e.eventType.label;
    return '${e.tipoPartido.isEmpty ? "Partido" : e.tipoPartido}: $typeLabel';
  }
}
