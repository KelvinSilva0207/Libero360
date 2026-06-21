import '../../estadisticas/data/models/models.dart';

enum MatchFormat { bestOf3, bestOf5 }

extension MatchFormatX on MatchFormat {
  int get totalSets {
    switch (this) {
      case MatchFormat.bestOf3:
        return 3;
      case MatchFormat.bestOf5:
        return 5;
    }
  }

  int get setsToWin => totalSets ~/ 2 + 1;
}

enum Categoria {
  u13(21, 2, 3, 30),
  u15(25, 2, 2, 30),
  u17(25, 2, 2, 30),
  u19(25, 2, 2, 30),
  libre(25, 2, 2, 30);

  final int puntosPorSet;
  final int diferenciaMinima;
  final int timeoutsPerSet;
  final int timeoutDurationSeconds;

  const Categoria(
    this.puntosPorSet,
    this.diferenciaMinima,
    this.timeoutsPerSet,
    this.timeoutDurationSeconds,
  );
}

List<bool> defaultServiceOrder(int setsTotales) =>
    List.generate(setsTotales, (i) => i.isEven);

class MatchConfig {
  String localName;
  String visitorName;
  int setsTotales;
  TipoPartido tipoPartido;
  String? lugar;
  String? competitionName;
  List<Player> selectedPlayers;
  MatchFormat formato;
  Categoria categoria;
  List<bool> serviceOrderPerSet;
  int timeoutsPerSet;
  int timeoutDurationSeconds;

  MatchConfig({
    this.localName = 'Local',
    this.visitorName = 'Visitante',
    this.setsTotales = 5,
    this.tipoPartido = TipoPartido.amistoso,
    this.lugar,
    this.competitionName,
    this.selectedPlayers = const [],
    this.formato = MatchFormat.bestOf5,
    this.categoria = Categoria.libre,
    List<bool>? serviceOrderPerSet,
    int? timeoutsPerSet,
    int? timeoutDurationSeconds,
  })  : serviceOrderPerSet =
            serviceOrderPerSet ?? defaultServiceOrder(setsTotales),
        timeoutsPerSet = timeoutsPerSet ?? Categoria.libre.timeoutsPerSet,
        timeoutDurationSeconds =
            timeoutDurationSeconds ?? Categoria.libre.timeoutDurationSeconds;
}
