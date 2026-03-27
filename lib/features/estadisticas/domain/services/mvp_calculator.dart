import '../services/stats_calculator.dart';

/// Resultado del cálculo de MVP
class MvpResult {
  /// Jugador MVP
  final int playerId;
  
  /// Efectividad del MVP (puntos - errores)
  final int efectividad;
  
  /// Lista de jugadores empatados (si hay empate)
  final List<int>? empates;
  
  /// Si hay empate, contiene el desempate usado
  final String? criterioDesempate;

  const MvpResult({
    required this.playerId,
    required this.efectividad,
    this.empates,
    this.criterioDesempate,
  });

  bool get hayEmpate => empates != null && empates!.isNotEmpty;

  @override
  String toString() => 'MvpResult(playerId: $playerId, efectividad: $efectividad, empates: $empates)';
}

/// Servicio para calcular el MVP del partido
///
/// Implementa reglas de desempate:
/// 1. Mayor efectividad (puntos - errores)
/// 2. Desempate 1: Mayor cantidad de acciones totales
/// 3. Desempate 2: Mayor porcentaje de efectividad
class MvpCalculator {
  /// Calcula el MVP del partido
  ///
  /// [statsMap] - Mapa de playerId -> PlayerStats
  ///
  /// Retorna un [MvpResult] con el jugador MVP
  static MvpResult calcularMVP(Map<int, PlayerStats> statsMap) {
    if (statsMap.isEmpty) {
      throw ArgumentError('No hay estadísticas para calcular MVP');
    }

    // Encontrar la máxima efectividad
    int maxEfectividad = -999999;
    final candidatos = <int>[];

    for (final entry in statsMap.entries) {
      final stats = entry.value;
      final efectividad = stats.efectividad;

      if (efectividad > maxEfectividad) {
        maxEfectividad = efectividad;
        candidatos.clear();
        candidatos.add(entry.key);
      } else if (efectividad == maxEfectividad) {
        candidatos.add(entry.key);
      }
    }

    // Si hay un solo candidato, es el MVP
    if (candidatos.length == 1) {
      return MvpResult(
        playerId: candidatos.first,
        efectividad: maxEfectividad,
      );
    }

    // Desempate por cantidad de acciones totales
    int maxAcciones = -999999;
    final candidatosDesempate1 = <int>[];

    for (final playerId in candidatos) {
      final stats = statsMap[playerId]!;
      final acciones = stats.totalAcciones;

      if (acciones > maxAcciones) {
        maxAcciones = acciones;
        candidatosDesempate1.clear();
        candidatosDesempate1.add(playerId);
      } else if (acciones == maxAcciones) {
        candidatosDesempate1.add(playerId);
      }
    }

    // Si hay un solo candidato después del primer desempate
    if (candidatosDesempate1.length == 1) {
      return MvpResult(
        playerId: candidatosDesempate1.first,
        efectividad: maxEfectividad,
        empates: candidatos,
        criterioDesempate: 'Mayor cantidad de acciones ($maxAcciones)',
      );
    }

    // Segundo desempate: mayor porcentaje de efectividad
    double maxPorcentaje = -999999.0;
    int? mvpFinal;

    for (final playerId in candidatosDesempate1) {
      final stats = statsMap[playerId]!;
      final porcentaje = stats.porcentajeEfectividad;

      if (porcentaje > maxPorcentaje) {
        maxPorcentaje = porcentaje;
        mvpFinal = playerId;
      }
    }

    return MvpResult(
      playerId: mvpFinal ?? candidatosDesempate1.first,
      efectividad: maxEfectividad,
      empates: candidatos,
      criterioDesempate: 'Mayor porcentaje de efectividad (${maxPorcentaje.toStringAsFixed(1)}%)',
    );
  }

  /// Calcula el MVP del partido por equipo
  ///
  /// [statsMap] - Mapa de playerId -> PlayerStats
  /// [jugadoresEquipo] - Lista de IDs de jugadores del equipo
  ///
  /// Retorna un [MvpResult] con el jugador MVP del equipo
  static MvpResult calcularMVPEquipo(
    Map<int, PlayerStats> statsMap,
    List<int> jugadoresEquipo,
  ) {
    // Filtrar solo jugadores del equipo
    final statsEquipo = <int, PlayerStats>{};
    
    for (final playerId in jugadoresEquipo) {
      if (statsMap.containsKey(playerId)) {
        statsEquipo[playerId] = statsMap[playerId]!;
      }
    }

    if (statsEquipo.isEmpty) {
      throw ArgumentError('No hay estadísticas para calcular MVP del equipo');
    }

    return calcularMVP(statsEquipo);
  }

  /// Obtiene el ranking de jugadores por efectividad
  ///
  /// Retorna lista ordenada de playerIds (mejor primero)
  static List<int> obtenerRanking(Map<int, PlayerStats> statsMap) {
    final ranking = statsMap.entries.toList();
    
    // Ordenar por efectividad descendente, luego por acciones totales
    ranking.sort((a, b) {
      final diff = b.value.efectividad.compareTo(a.value.efectividad);
      if (diff != 0) return diff;
      return b.value.totalAcciones.compareTo(a.value.totalAcciones);
    });

    return ranking.map((e) => e.key).toList();
  }

  /// Calcula estadísticas del equipo
  ///
  /// [statsMap] - Mapa de playerId -> PlayerStats
  /// [jugadoresEquipo] - Lista de IDs de jugadores del equipo
  static TeamStats calcularStatsEquipo(
    Map<int, PlayerStats> statsMap,
    List<int> jugadoresEquipo,
  ) {
    int puntosTotales = 0;
    int erroresTotales = 0;
    int accionesTotales = 0;

    for (final playerId in jugadoresEquipo) {
      final stats = statsMap[playerId];
      if (stats != null) {
        puntosTotales += stats.puntosPositivos;
        erroresTotales += stats.errores;
        accionesTotales += stats.totalAcciones;
      }
    }

    return TeamStats(
      puntosTotales: puntosTotales,
      erroresTotales: erroresTotales,
      efectividadTotal: puntosTotales - erroresTotales,
      accionesTotales: accionesTotales,
      porcentajeEfectividad: accionesTotales > 0
          ? ((puntosTotales - erroresTotales) / accionesTotales) * 100
          : 0.0,
    );
  }
}

/// Estadísticas agregadas de un equipo
class TeamStats {
  final int puntosTotales;
  final int erroresTotales;
  final int efectividadTotal;
  final int accionesTotales;
  final double porcentajeEfectividad;

  const TeamStats({
    required this.puntosTotales,
    required this.erroresTotales,
    required this.efectividadTotal,
    required this.accionesTotales,
    required this.porcentajeEfectividad,
  });

  @override
  String toString() {
    return 'TeamStats(puntos: $puntosTotales, errores: $erroresTotales, '
        'efectividad: $efectividadTotal, acciones: $accionesTotales, '
        'porcentaje: ${porcentajeEfectividad.toStringAsFixed(1)}%)';
  }
}
