class AttendanceRecord {
  static const String sessionManana = 'manana';
  static const String sessionTarde = 'tarde';
  static const String mananaLabel = 'Mañana';
  static const String tardeLabel = 'Tarde';

  int id = 0;
  int playerId = 0;
  String? profileId;
  String? clubId;
  DateTime fecha = DateTime.now();
  bool asistio = false;
  String observaciones = '';
  String? session;
  DateTime? savedAt;

  AttendanceRecord();

  factory AttendanceRecord.create({
    required int playerId,
    required DateTime fecha,
    bool asistio = false,
    String observaciones = '',
    String? session,
    DateTime? savedAt,
  }) {
    return AttendanceRecord()
      ..playerId = playerId
      ..fecha = fecha
      ..asistio = asistio
      ..observaciones = observaciones
      ..session = session
      ..savedAt = savedAt;
  }

  String get sessionKey => session ?? sessionManana;

  String get sessionLabel =>
      sessionKey == sessionTarde ? tardeLabel : mananaLabel;

  @override
  String toString() =>
      'AttendanceRecord(id: $id, playerId: $playerId, fecha: $fecha, session: $sessionKey, asistio: $asistio)';
}
