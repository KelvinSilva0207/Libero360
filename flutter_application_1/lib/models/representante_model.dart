class Representante {
  final String id; // Cédula
  final String nombres;
  final String apellidos;
  final String sexo;
  final String celular;
  final String tlfHabitacion;
  final String email;

  Representante({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.sexo,
    required this.celular,
    required this.tlfHabitacion,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'sexo': sexo,
      'celular': celular,
      'tlf_habitacion': tlfHabitacion,
      'email': email,
    };
  }
}