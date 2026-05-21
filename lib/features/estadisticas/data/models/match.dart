enum EstadoPartido {
  noIniciado,
  enProgreso,
  pausado,
  finalizado,
}

enum TipoPartido {
  amistoso,
  liga,
  torneo,
}

class Match {
  int id = 0;
  DateTime fecha = DateTime.now();
  String equipoLocal = '';
  String equipoVisitante = '';
  int puntosLocal = 0;
  int puntosVisitante = 0;
  int setsLocal = 0;
  int setsVisitante = 0;
  int setActual = 1;
  EstadoPartido estado = EstadoPartido.noIniciado;
  bool turnoLocal = true;
  int velocidadAnimacion = 1000;
  DateTime createdAt = DateTime.now();

  // Nuevos campos del schema
  TipoPartido tipoPartido = TipoPartido.amistoso;
  int setsTotales = 5;
  String? resultadoFinal;
  String? lugar;

  Match();

  factory Match.create({
    required String equipoLocal,
    required String equipoVisitante,
    DateTime? fecha,
    TipoPartido tipoPartido = TipoPartido.amistoso,
    int setsTotales = 5,
    String? lugar,
  }) {
    return Match()
      ..fecha = fecha ?? DateTime.now()
      ..equipoLocal = equipoLocal
      ..equipoVisitante = equipoVisitante
      ..tipoPartido = tipoPartido
      ..setsTotales = setsTotales
      ..lugar = lugar
      ..puntosLocal = 0
      ..puntosVisitante = 0
      ..setsLocal = 0
      ..setsVisitante = 0
      ..setActual = 1
      ..estado = EstadoPartido.noIniciado
      ..turnoLocal = true
      ..velocidadAnimacion = 1000
      ..createdAt = DateTime.now();
  }

  String get rival => equipoVisitante;
  String get marcador => '$puntosLocal - $puntosVisitante';
  String get resultadoSets => '$setsLocal - $setsVisitante';
  bool get isFinalizado => estado == EstadoPartido.finalizado;
  bool get isActivo => estado == EstadoPartido.enProgreso;

  String get tipoPartidoLabel {
    switch (tipoPartido) {
      case TipoPartido.amistoso: return 'Amistoso';
      case TipoPartido.liga: return 'Liga';
      case TipoPartido.torneo: return 'Torneo';
    }
  }

  void agregarPuntoLocal() {
    puntosLocal++;
    _verificarCambioSet();
  }

  void agregarPuntoVisitante() {
    puntosVisitante++;
    _verificarCambioSet();
  }

  void _verificarCambioSet() {
    const puntosParaGanar = 25;
    const puntosDiferencia = 2;

    if (puntosLocal >= puntosParaGanar || puntosVisitante >= puntosParaGanar) {
      if ((puntosLocal - puntosVisitante).abs() >= puntosDiferencia) {
        if (puntosLocal > puntosVisitante) {
          setsLocal++;
        } else {
          setsVisitante++;
        }
        setActual++;
        puntosLocal = 0;
        puntosVisitante = 0;

        if (setsLocal == 3 || setsVisitante == 3) {
          estado = EstadoPartido.finalizado;
          resultadoFinal = resultadoSets;
        }
      }
    }
  }

  void iniciar() {
    estado = EstadoPartido.enProgreso;
  }

  void pausar() {
    estado = EstadoPartido.pausado;
  }

  void reanudar() {
    estado = EstadoPartido.enProgreso;
  }

  void finalizar() {
    estado = EstadoPartido.finalizado;
    resultadoFinal = resultadoSets;
  }

  void cambiarTurno() {
    turnoLocal = !turnoLocal;
  }

  @override
  String toString() => 'Match(id: $id, $equipoLocal vs $equipoVisitante, $marcador)';
}
