class Asistencia {
  final String idAtleta; // Relación con Cédula del Atleta
  final DateTime fecha;
  final bool asistio;
  final String observaciones;

  Asistencia({
    required this.idAtleta,
    required this.fecha,
    required this.asistio,
    this.observaciones = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'id_atleta': idAtleta,
      'fecha': fecha,
      'asistio': asistio,
      'observaciones': observaciones,
    };
  }
}