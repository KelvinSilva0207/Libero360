class Institucion {
  final int id; // Incremental
  final String nombre;
  final String direccion;

  Institucion({
    required this.id,
    required this.nombre,
    required this.direccion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
    };
  }
}