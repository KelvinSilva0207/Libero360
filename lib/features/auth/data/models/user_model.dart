class AppUser {
  final String id;
  final String nombre;
  final String email;
  final String password;
  final DateTime fechaRegistro;

  AppUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.password,
    DateTime? fechaRegistro,
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();
}
