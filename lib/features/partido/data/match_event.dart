enum EventType {
  winnerPoint,
  regularPoint,
  error,
}

extension EventTypeX on EventType {
  String get label {
    switch (this) {
      case EventType.winnerPoint: return 'Punto ganador';
      case EventType.regularPoint: return 'Punto regular';
      case EventType.error: return 'Error';
    }
  }

  String get emoji {
    switch (this) {
      case EventType.winnerPoint: return '🔥';
      case EventType.regularPoint: return '✔';
      case EventType.error: return '✖';
    }
  }
}

class MatchEvent {
  int id = 0;
  int athleteId = 0;
  int matchId = 0;
  DateTime fecha = DateTime.now();
  int setNumero = 1;
  EventType eventType = EventType.regularPoint;
  String tipoPartido = '';
  String? competenciaNombre;
  int rotacion = 0;

  MatchEvent();

  factory MatchEvent.create({
    required int athleteId,
    required int matchId,
    required int setNumero,
    required EventType eventType,
    required String tipoPartido,
    String? competenciaNombre,
    int rotacion = 0,
  }) {
    return MatchEvent()
      ..athleteId = athleteId
      ..matchId = matchId
      ..fecha = DateTime.now()
      ..setNumero = setNumero
      ..eventType = eventType
      ..tipoPartido = tipoPartido
      ..competenciaNombre = competenciaNombre
      ..rotacion = rotacion;
  }

  @override
  String toString() => 'MatchEvent(id: $id, athlete: $athleteId, type: $eventType, set: $setNumero)';
}
