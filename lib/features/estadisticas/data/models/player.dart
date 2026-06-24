import '../../../../core/models/athlete_status.dart';
import '../../../../core/utils/category_calculator.dart';

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

enum Sexo {
  masculino,
  femenino,
}

enum TipoSangre {
  aPositivo,
  aNegativo,
  bPositivo,
  bNegativo,
  abPositivo,
  abNegativo,
  oPositivo,
  oNegativo,
}

enum ManoDominante {
  derecha,
  izquierda,
  ambidiestro,
}

class Player {
  int id = 0;
  String nombre = '';
  String firstNames = '';
  String lastNames = '';
  String displayName = '';
  String cedula = '';
  DateTime fechaNacimiento = DateTime.now();
  int? numero;
  Posicion posicion = Posicion.sinDefinir;
  bool esCapitan = false;
  String? fotoUrl;
  EstadoSalud estadoSalud = EstadoSalud.disponible;
  String condicionFisica = 'Excelente';
  DateTime createdAt = DateTime.now();
  String? profileId;
  String? clubId;

  // AthleteStatus fields
  AthleteStatus atletaStatus = AthleteStatus.active;
  String? statusReason;
  DateTime? statusStartDate;
  DateTime? statusEndDate;
  RestriccionDeportiva restriccion = const RestriccionDeportiva();

  // Athlete 3.0 fields
  Sexo sexo = Sexo.masculino;
  double altura = 0;
  TipoSangre tipoSangre = TipoSangre.oPositivo;
  ManoDominante manoDominante = ManoDominante.derecha;
  Posicion posicionSecundaria = Posicion.sinDefinir;
  DateTime fechaIngreso = DateTime.now();

  // Soft delete fields
  bool isDeleted = false;
  DateTime? deletedAt;
  String? deletedBy;
  String? deletionReason;

  Player();

  factory Player.create({
    String? nombre,
    String? firstNames,
    String? lastNames,
    required String cedula,
    required DateTime fechaNacimiento,
    int? numero,
    Posicion posicion = Posicion.sinDefinir,
    bool esCapitan = false,
    String? fotoUrl,
    EstadoSalud estadoSalud = EstadoSalud.disponible,
    String condicionFisica = 'Excelente',
    Sexo sexo = Sexo.masculino,
    double altura = 0,
    TipoSangre tipoSangre = TipoSangre.oPositivo,
    ManoDominante manoDominante = ManoDominante.derecha,
    Posicion posicionSecundaria = Posicion.sinDefinir,
    DateTime? fechaIngreso,
  }) {
    final fn = firstNames ?? nombre ?? '';
    final ln = lastNames ?? '';
    return Player()
      ..firstNames = fn
      ..lastNames = ln
      ..displayName = '$fn $ln'.trim()
      ..nombre = nombre ?? '$fn $ln'.trim()
      ..cedula = cedula
      ..fechaNacimiento = fechaNacimiento
      ..numero = numero
      ..posicion = posicion
      ..esCapitan = esCapitan
      ..fotoUrl = fotoUrl
      ..estadoSalud = estadoSalud
      ..condicionFisica = condicionFisica
      ..sexo = sexo
      ..altura = altura
      ..tipoSangre = tipoSangre
      ..manoDominante = manoDominante
      ..posicionSecundaria = posicionSecundaria
      ..fechaIngreso = fechaIngreso ?? DateTime.now()
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

  String get categoria {
    return CategoryCalculator.calculate(edad);
  }

  String get sexoLabel {
    switch (sexo) {
      case Sexo.masculino: return 'Masculino';
      case Sexo.femenino: return 'Femenino';
    }
  }

  String get tipoSangreLabel {
    switch (tipoSangre) {
      case TipoSangre.aPositivo: return 'A+';
      case TipoSangre.aNegativo: return 'A-';
      case TipoSangre.bPositivo: return 'B+';
      case TipoSangre.bNegativo: return 'B-';
      case TipoSangre.abPositivo: return 'AB+';
      case TipoSangre.abNegativo: return 'AB-';
      case TipoSangre.oPositivo: return 'O+';
      case TipoSangre.oNegativo: return 'O-';
    }
  }

  String get manoDominanteLabel {
    switch (manoDominante) {
      case ManoDominante.derecha: return 'Derecha';
      case ManoDominante.izquierda: return 'Izquierda';
      case ManoDominante.ambidiestro: return 'Ambidiestro';
    }
  }

  @override
  String toString() => 'Player(id: $id, nombre: $nombre, #${numero ?? 0}, ${posicionLabel})';
}
