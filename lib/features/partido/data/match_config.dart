import '../../estadisticas/data/models/models.dart';

class MatchConfig {
  String localName;
  String visitorName;
  int setsTotales;
  TipoPartido tipoPartido;
  String? lugar;
  String? competitionName;
  List<Player> selectedPlayers;

  MatchConfig({
    this.localName = 'Local',
    this.visitorName = 'Visitante',
    this.setsTotales = 5,
    this.tipoPartido = TipoPartido.amistoso,
    this.lugar,
    this.competitionName,
    this.selectedPlayers = const [],
  });
}
