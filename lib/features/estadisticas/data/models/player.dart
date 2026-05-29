enum Posicion {
  colocador,
  opuesto,
  central,
  receptor,
  libre,
  sinDefinir,
}

enum EstadoSalud {
  disponible,
  lesionado,
  enDuda,
}

class Player {
  int id = 0;
  String nombre = '';
  String cedula = '';
  DateTime fechaNacimiento = DateTime.now();
  int numero = 0;
  Posicion posicion = Posicion.sinDefinir;
  bool esCapitan = false;
  String? fotoUrl;
  EstadoSalud estadoSalud = EstadoSalud.disponible;
  String condicionFisica = 'Excelente';
  DateTime createdAt = DateTime.now();

  Player();

  factory Player.create({
    required String nombre,
    required String cedula,
    required DateTime fechaNacimiento,
    required int numero,
    Posicion posicion = Posicion.sinDefinir,
    bool esCapitan = false,
    String? fotoUrl,
    EstadoSalud estadoSalud = EstadoSalud.disponible,
    String condicionFisica = 'Excelente',
  }) {
    return Player()
      ..nombre = nombre
      ..cedula = cedula
      ..fechaNacimiento = fechaNacimiento
      ..numero = numero
      ..posicion = posicion
      ..esCapitan = esCapitan
      ..fotoUrl = fotoUrl
      ..estadoSalud = estadoSalud
      ..condicionFisica = condicionFisica
      ..createdAt = DateTime.now();
  }

  int get edad {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  String get posicionLabel {
    switch (posicion) {
      case Posicion.colocador: return 'Armador';
      case Posicion.opuesto: return 'Opuesto';
      case Posicion.central: return 'Central';
      case Posicion.receptor: return 'Punta';
      case Posicion.libre: return 'Líbero';
      case Posicion.sinDefinir: return 'Sin definir';
    }
  }

  String get estadoSaludLabel {
    switch (estadoSalud) {
      case EstadoSalud.disponible: return 'Disponible';
      case EstadoSalud.lesionado: return 'Lesionado';
      case EstadoSalud.enDuda: return 'En duda';
    }
  }

  @override
  String toString() => 'Player(id: $id, nombre: $nombre, #$numero, ${posicionLabel})';
}
