import '../../estadisticas/data/models/stat_event.dart';

enum ActionType {
  ataque('Ataque', '⚔', 3),
  bloqueo('Bloqueo', '🧱', 4),
  servicio('Servicio', '🏐', 4),
  defensa('Defensa', '🛡', 2),
  recepcion('Recepción', '🙌', 2),
  neutra('Neutra', '➖', 1),
  error('Error', '❌', -2);

  final String label;
  final String icon;
  final int value;

  const ActionType(this.label, this.icon, this.value);

  TipoAccion get tipoAccion {
    return switch (this) {
      ActionType.ataque => TipoAccion.ataque,
      ActionType.bloqueo => TipoAccion.bloqueo,
      ActionType.servicio => TipoAccion.saque,
      ActionType.defensa => TipoAccion.defensa,
      ActionType.recepcion => TipoAccion.recepcion,
      ActionType.neutra => TipoAccion.colocacion,
      ActionType.error => TipoAccion.ataque,
    };
  }

  ResultadoAccion get resultado {
    return switch (this) {
      ActionType.error => ResultadoAccion.negativo,
      ActionType.neutra => ResultadoAccion.neutral,
      _ => ResultadoAccion.positivo,
    };
  }
}

class PlayerActionEvent {
  final int playerNumber;
  final String playerName;
  final ActionType type;
  final int setNumber;
  final int rotationIndex;
  final DateTime timestamp;

  PlayerActionEvent({
    required this.playerNumber,
    required this.playerName,
    required this.type,
    required this.setNumber,
    required this.rotationIndex,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
