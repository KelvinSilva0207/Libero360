import '../../estadisticas/data/models/player.dart';
import '../../partido/data/match_event.dart' as me;

export '../../partido/data/match_event.dart' show EventType, EventTypeX;

class PlayerAssignment {
  final Player player;
  int? numeroOverride;
  int position;

  PlayerAssignment({
    required this.player,
    this.numeroOverride,
    required this.position,
  });

  int get effectiveNumber => numeroOverride ?? player.numero ?? 0;

  String get displayName {
    final first = player.firstNames.isNotEmpty
        ? player.firstNames.split(' ').first
        : player.nombre.split(' ').first;
    final lastInitial = player.lastNames.isNotEmpty
        ? '${player.lastNames[0]}.'
        : '';
    return '$first $lastInitial';
  }

  PlayerAssignment copyWith({
    Player? player,
    int? numeroOverride,
    int? position,
  }) {
    return PlayerAssignment(
      player: player ?? this.player,
      numeroOverride: numeroOverride ?? this.numeroOverride,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': player.id,
    'numeroOverride': numeroOverride,
    'position': position,
  };

  static PlayerAssignment? fromJson(Map<String, dynamic> json, List<Player> allPlayers) {
    final p = allPlayers.where((e) => e.id == json['playerId']).firstOrNull;
    if (p == null) return null;
    return PlayerAssignment(
      player: p,
      numeroOverride: json['numeroOverride'] as int?,
      position: json['position'] as int,
    );
  }
}

class RotationRecord {
  final int rotationNumber;
  final List<PlayerAssignment> lineup;
  final DateTime timestamp;
  final bool wonServe;

  RotationRecord({
    required this.rotationNumber,
    required this.lineup,
    required this.timestamp,
    this.wonServe = false,
  });
}

class PositionEvent {
  final int playerId;
  final int positionNumber;
  final me.EventType eventType;
  final DateTime timestamp;
  final int rotationNumber;

  PositionEvent({
    required this.playerId,
    required this.positionNumber,
    required this.eventType,
    required this.timestamp,
    required this.rotationNumber,
  });
}
