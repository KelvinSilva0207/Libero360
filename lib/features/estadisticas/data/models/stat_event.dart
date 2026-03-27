/// Enum para los tipos de acciones en voleibol
enum TipoAccion {
  ataque,
  saque,
  bloqueo,
  defensa,
  recepcion,
  colocacion,
  errorContrario,
}

/// Enum para el resultado de la acción
enum ResultadoAccion {
  positivo,
  negativo,
  neutral,
}

/// Enum para la zona de la cancha
enum ZonaCancha {
  ataque,
  defensa,
  red,
  ninguna,
  saque,
  central,
}

/// Modelo de Evento de Estadística
class StatEvent {
  int id = 0;
  TipoAccion tipoAccion = TipoAccion.ataque;
  ResultadoAccion resultado = ResultadoAccion.neutral;
  DateTime timestamp = DateTime.now();
  int setNumero = 1;
  int puntoLocal = 0;
  int puntoVisitante = 0;
  bool esEquipoLocal = true;
  ZonaCancha zona = ZonaCancha.ninguna;
  String? descripcion;
  int playerId = 0;
  int matchId = 0;
  DateTime createdAt = DateTime.now();

  StatEvent();

  factory StatEvent.create({
    required TipoAccion tipoAccion,
    required ResultadoAccion resultado,
    required int setNumero,
    required int puntoLocal,
    required int puntoVisitante,
    required bool esEquipoLocal,
    required ZonaCancha zona,
    required int playerId,
    required int matchId,
    String? descripcion,
  }) {
    return StatEvent()
      ..tipoAccion = tipoAccion
      ..resultado = resultado
      ..timestamp = DateTime.now()
      ..setNumero = setNumero
      ..puntoLocal = puntoLocal
      ..puntoVisitante = puntoVisitante
      ..esEquipoLocal = esEquipoLocal
      ..zona = zona
      ..playerId = playerId
      ..matchId = matchId
      ..descripcion = descripcion
      ..createdAt = DateTime.now();
  }

  bool get isPuntoGanado => resultado == ResultadoAccion.positivo;
  bool get isPuntoPerdido => resultado == ResultadoAccion.negativo;
  bool get isNeutral => resultado == ResultadoAccion.neutral;

  /// Getter para el marcador en el momento de la acción
  String get marcadorEnAccion => '$puntoLocal - $puntoVisitante';
  
  /// Getter para descripción de la acción
  String get descripcionAccion {
    final tipoStr = tipoAccion.toString().split('.').last;
    final resultadoStr = resultado.toString().split('.').last;
    return '${tipoStr.toUpperCase()}: $resultadoStr';
  }

  @override
  String toString() => 'StatEvent(id: $id, tipo: $tipoAccion, resultado: $resultado, playerId: $playerId)';
}
