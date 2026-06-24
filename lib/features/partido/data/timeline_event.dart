class TimelineEvent {
  final String id;
  final DateTime time;
  final String type;
  final String title;
  final String? playerId;
  final String? playerName;
  final int set;
  final int rotation;
  final Map<String, dynamic>? metadata;

  const TimelineEvent({
    required this.id,
    required this.time,
    required this.type,
    required this.title,
    this.playerId,
    this.playerName,
    this.set = 1,
    this.rotation = 0,
    this.metadata,
  });

  // type constants
  static const typeMatchStarted = 'match_started';
  static const typeService = 'service';
  static const typeRotation = 'rotation';
  static const typeSubstitution = 'substitution';
  static const typeLiberoSwap = 'libero_swap';
  static const typePlayerAction = 'player_action';
  static const typeTimeout = 'timeout';
  static const typeSetEnd = 'set_end';
  static const typeMatchEnd = 'match_end';
}
