class Partido {
  final String id; // Puede ser un código como "PART-001" o generado por Firebase
  final String rival;
  final DateTime fecha;
  final String tipoPartido; // Amistoso, Liga, Torneo
  final int setsTotales;    // 3 o 5
  final String resultadoFinal; // Ej: "3-1"
  final String lugar;       // Gimnasio o Cancha específica
  final String observaciones;

  Partido({
    required this.id,
    required this.rival,
    required this.fecha,
    required this.tipoPartido,
    required this.setsTotales,
    this.resultadoFinal = "0-0",
    required this.lugar,
    this.observaciones = "",
  });

  // Para guardar en la nube
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rival': rival,
      'fecha': fecha,
      'tipo_partido': tipoPartido,
      'sets_totales': setsTotales,
      'resultado_final': resultadoFinal,
      'lugar': lugar,
      'observaciones': observaciones,
    };
  }
}