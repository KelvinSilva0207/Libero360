class TimeoutRecord {
  final int matchId;
  final int setNumero;
  final DateTime inicio;
  final DateTime? fin;
  final int? duracionSegundos;
  final bool esLocal;

  TimeoutRecord({
    required this.matchId,
    required this.setNumero,
    required this.inicio,
    this.fin,
    this.duracionSegundos,
    required this.esLocal,
  });
}
