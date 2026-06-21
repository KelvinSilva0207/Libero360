class AttendanceRecord {
  int id = 0;
  int playerId = 0;
  String? profileId;
  String? clubId;
  DateTime fecha = DateTime.now();
  bool asistio = false;
  String observaciones = '';

  AttendanceRecord();

  factory AttendanceRecord.create({
    required int playerId,
    required DateTime fecha,
    bool asistio = false,
    String observaciones = '',
  }) {
    return AttendanceRecord()
      ..playerId = playerId
      ..fecha = fecha
      ..asistio = asistio
      ..observaciones = observaciones;
  }

  @override
  String toString() => 'AttendanceRecord(id: $id, playerId: $playerId, fecha: $fecha, asistio: $asistio)';
}
