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

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'firstNames': firstNames,
    'lastNames': lastNames,
    'displayName': displayName,
    'cedula': cedula,
    'fechaNacimiento': fechaNacimiento.millisecondsSinceEpoch,
    'numero': numero ?? 0,
    'posicion': posicion.index,
    'esCapitan': esCapitan ? 1 : 0,
    'fotoUrl': fotoUrl ?? '',
    'estadoSalud': estadoSalud.index,
    'condicionFisica': condicionFisica,
    'profileId': profileId,
    'clubId': clubId,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'sexo': sexo.index,
    'altura': altura,
    'tipoSangre': tipoSangre.index,
    'manoDominante': manoDominante.index,
    'posicionSecundaria': posicionSecundaria.index,
    'fechaIngreso': fechaIngreso.millisecondsSinceEpoch,
    'atletaStatus': atletaStatus.index,
    'statusReason': statusReason ?? '',
    'statusStartDate': statusStartDate?.millisecondsSinceEpoch,
    'statusEndDate': statusEndDate?.millisecondsSinceEpoch,
    'isDeleted': isDeleted ? 1 : 0,
    'deletedAt': deletedAt?.millisecondsSinceEpoch,
    'deletedBy': deletedBy ?? '',
    'deletionReason': deletionReason ?? '',
  };

  factory Player.fromMap(Map<String, dynamic> map) => Player()
    ..id = (map['id'] as int? ?? 0)
    ..nombre = map['nombre'] as String? ?? ''
    ..firstNames = map['firstNames'] as String? ?? (map['nombre'] as String? ?? '')
    ..lastNames = map['lastNames'] as String? ?? ''
    ..displayName = map['displayName'] as String? ?? (map['nombre'] as String? ?? '')
    ..cedula = map['cedula'] as String? ?? ''
    ..fechaNacimiento = DateTime.fromMillisecondsSinceEpoch(map['fechaNacimiento'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..numero = map['numero'] as int?
    ..posicion = Posicion.values[map['posicion'] as int? ?? 0]
    ..esCapitan = (map['esCapitan'] as int? ?? 0) == 1
    ..fotoUrl = (map['fotoUrl'] as String?)?.isNotEmpty == true ? map['fotoUrl'] as String? : null
    ..estadoSalud = EstadoSalud.values[map['estadoSalud'] as int? ?? 0]
    ..condicionFisica = map['condicionFisica'] as String? ?? 'Excelente'
    ..profileId = map['profileId'] as String?
    ..clubId = map['clubId'] as String?
    ..createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..sexo = Sexo.values[map['sexo'] as int? ?? 0]
    ..altura = (map['altura'] as num?)?.toDouble() ?? 0
    ..tipoSangre = TipoSangre.values[map['tipoSangre'] as int? ?? 3]
    ..manoDominante = ManoDominante.values[map['manoDominante'] as int? ?? 0]
    ..posicionSecundaria = Posicion.values[map['posicionSecundaria'] as int? ?? 5]
    ..fechaIngreso = DateTime.fromMillisecondsSinceEpoch(map['fechaIngreso'] as int? ?? map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..atletaStatus = AthleteStatus.values[map['atletaStatus'] as int? ?? 0]
    ..statusReason = (map['statusReason'] as String?)?.isNotEmpty == true ? map['statusReason'] as String? : null
    ..statusStartDate = map['statusStartDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['statusStartDate'] as int) : null
    ..statusEndDate = map['statusEndDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['statusEndDate'] as int) : null
    ..isDeleted = (map['isDeleted'] as int? ?? 0) == 1
    ..deletedAt = map['deletedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deletedAt'] as int) : null
    ..deletedBy = (map['deletedBy'] as String?)?.isNotEmpty == true ? map['deletedBy'] as String? : null
    ..deletionReason = (map['deletionReason'] as String?)?.isNotEmpty == true ? map['deletionReason'] as String? : null;

  Player copyWith({
    int? id,
    String? nombre,
    String? firstNames,
    String? lastNames,
    String? displayName,
    String? cedula,
    DateTime? fechaNacimiento,
    int? numero,
    Posicion? posicion,
    bool? esCapitan,
    String? fotoUrl,
    EstadoSalud? estadoSalud,
    String? condicionFisica,
    DateTime? createdAt,
    String? profileId,
    String? clubId,
    AthleteStatus? atletaStatus,
    String? statusReason,
    DateTime? statusStartDate,
    DateTime? statusEndDate,
    RestriccionDeportiva? restriccion,
    Sexo? sexo,
    double? altura,
    TipoSangre? tipoSangre,
    ManoDominante? manoDominante,
    Posicion? posicionSecundaria,
    DateTime? fechaIngreso,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,
    String? deletionReason,
  }) {
    return Player()
      ..id = id ?? this.id
      ..nombre = nombre ?? this.nombre
      ..firstNames = firstNames ?? this.firstNames
      ..lastNames = lastNames ?? this.lastNames
      ..displayName = displayName ?? this.displayName
      ..cedula = cedula ?? this.cedula
      ..fechaNacimiento = fechaNacimiento ?? this.fechaNacimiento
      ..numero = numero ?? this.numero
      ..posicion = posicion ?? this.posicion
      ..esCapitan = esCapitan ?? this.esCapitan
      ..fotoUrl = fotoUrl ?? this.fotoUrl
      ..estadoSalud = estadoSalud ?? this.estadoSalud
      ..condicionFisica = condicionFisica ?? this.condicionFisica
      ..createdAt = createdAt ?? this.createdAt
      ..profileId = profileId ?? this.profileId
      ..clubId = clubId ?? this.clubId
      ..atletaStatus = atletaStatus ?? this.atletaStatus
      ..statusReason = statusReason ?? this.statusReason
      ..statusStartDate = statusStartDate ?? this.statusStartDate
      ..statusEndDate = statusEndDate ?? this.statusEndDate
      ..restriccion = restriccion ?? this.restriccion
      ..sexo = sexo ?? this.sexo
      ..altura = altura ?? this.altura
      ..tipoSangre = tipoSangre ?? this.tipoSangre
      ..manoDominante = manoDominante ?? this.manoDominante
      ..posicionSecundaria = posicionSecundaria ?? this.posicionSecundaria
      ..fechaIngreso = fechaIngreso ?? this.fechaIngreso
      ..isDeleted = isDeleted ?? this.isDeleted
      ..deletedAt = deletedAt ?? this.deletedAt
      ..deletedBy = deletedBy ?? this.deletedBy
      ..deletionReason = deletionReason ?? this.deletionReason;
  }

  @override
  String toString() => 'Player(id: $id, nombre: $nombre, #${numero ?? 0}, $posicionLabel)';
}
