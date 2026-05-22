class AppUser {
  int id = 0;
  String nombre = '';
  String email = '';
  String password = '';
  DateTime fechaRegistro = DateTime.now();

  AppUser({
    this.id = 0,
    required this.nombre,
    required this.email,
    required this.password,
    DateTime? fechaRegistro,
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();
}
