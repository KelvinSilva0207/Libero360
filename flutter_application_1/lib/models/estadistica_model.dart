class Estadistica {
  final String idAtleta;  // Relación con el Atleta (Cédula)
  final String idPartido; // Relación con el Partido
  final int setNumero;    // 1, 2, 3, 4 o 5
  final String tipoAccion; // Ataque, Saque, Bloqueo, Defensa, Recepción
  final bool esPunto;      // true si fue punto positivo, false si fue error

  Estadistica({
    required this.idAtleta,
    required this.idPartido,
    required this.setNumero,
    required this.tipoAccion,
    required this.esPunto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_atleta': idAtleta,
      'id_partido': idPartido,
      'set_numero': setNumero,
      'tipo_accion': tipoAccion,
      'es_punto': esPunto,
    };
  }
}