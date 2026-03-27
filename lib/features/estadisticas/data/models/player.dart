/// Enum para las posiciones de voleibol
enum Posicion {
  colocador,
  opuesto,
  central,
  receptor,
  libre,
}

/// Modelo de Jugador para estadísticas de voleibol
class Player {
  int id = 0;
  String nombre = '';
  int numero = 0;
  Posicion posicion = Posicion.colocador;
  DateTime createdAt = DateTime.now();

  Player();

  factory Player.create({
    required String nombre,
    required int numero,
    required Posicion posicion,
  }) {
    return Player()
      ..nombre = nombre
      ..numero = numero
      ..posicion = posicion
      ..createdAt = DateTime.now();
  }

  void update({
    String? nombre,
    int? numero,
    Posicion? posicion,
  }) {
    if (nombre != null) this.nombre = nombre;
    if (numero != null) this.numero = numero;
    if (posicion != null) this.posicion = posicion;
  }

  @override
  String toString() => 'Player(id: $id, nombre: $nombre, numero: $numero, posicion: $posicion)';
}
