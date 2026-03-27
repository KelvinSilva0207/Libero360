import '../../data/models/stat_event.dart';

/// Clase que contiene las estadísticas calculadas de un jugador
///
/// Almacena todos los conteos y métricas derivadas de las acciones
/// registradas durante un partido.
///
/// Optimizada para acceso rápido en tiempo real.
class PlayerStats {
  /// ID del jugador
  final int playerId;

  /// Total de acciones positivas (puntos ganados)
  final int puntosPositivos;

  /// Total de errores (puntos perdidos)
  final int errores;

  /// Efectividad del jugador (puntos - errores)
  final int efectividad;

  // ========== ATAQUE ==========
  /// Total de ataques intentados
  final int ataquesTotales;

  /// Ataques exitosos (que generaron punto)
  final int ataquesExitosos;

  /// Ataques fallidos (errores de ataque)
  final int ataquesFallidos;

  /// Porcentaje de efectividad en ataque
  final double efectividadAtaque;

  // ========== SAQUE ==========
  /// Total de saques intentados
  final int saquesTotales;

  /// Saques directos (aces)
  final int saquesDirectos;

  /// Saques fallidos
  final int saquesFallidos;

  /// Porcentaje de efectividad en saque
  final double efectividadSaque;

  // ========== BLOQUEO ==========
  /// Total de bloqueos intentados
  final int bloqueosTotales;

  /// Bloqueos exitosos (puntos de bloqueo)
  final int bloqueosExitosos;

  /// Errores de bloqueo
  final int bloqueosFallidos;

  /// Porcentaje de efectividad en bloqueo
  final double efectividadBloqueo;

  // ========== DEFENSA ==========
  /// Total de defensas intentadas
  final int defensasTotales;

  /// Defensas perfectas
  final int defensasPerfectas;

  /// Errores de defensa
  final int defensasFallidas;

  // ========== RECEPCIÓN ==========
  /// Total de recepciones
  final int recepcionesTotales;

  /// Recepciones perfectas
  final int recepcionesPerfectas;

  /// Errores de recepción
  final int recepcionesFallidas;

  // ========== COLOCACIÓN ==========
  /// Total de colocaciones
  final int colocacionesTotales;

  /// Colocaciones perfectas
  final int colocacionesPerfectas;

  /// Errores de colocación
  final int colocacionesFallidas;

  /// Número total de acciones
  final int totalAcciones;

  /// Constructor privado - usar factory methods
  const PlayerStats._({
    required this.playerId,
    required this.puntosPositivos,
    required this.errores,
    required this.efectividad,
    required this.ataquesTotales,
    required this.ataquesExitosos,
    required this.ataquesFallidos,
    required this.efectividadAtaque,
    required this.saquesTotales,
    required this.saquesDirectos,
    required this.saquesFallidos,
    required this.efectividadSaque,
    required this.bloqueosTotales,
    required this.bloqueosExitosos,
    required this.bloqueosFallidos,
    required this.efectividadBloqueo,
    required this.defensasTotales,
    required this.defensasPerfectas,
    required this.defensasFallidas,
    required this.recepcionesTotales,
    required this.recepcionesPerfectas,
    required this.recepcionesFallidas,
    required this.colocacionesTotales,
    required this.colocacionesPerfectas,
    required this.colocacionesFallidas,
    required this.totalAcciones,
  });

  /// Constructor vacío para初始化
  factory PlayerStats.empty(int playerId) => PlayerStats._(
    playerId: playerId,
    puntosPositivos: 0,
    errores: 0,
    efectividad: 0,
    ataquesTotales: 0,
    ataquesExitosos: 0,
    ataquesFallidos: 0,
    efectividadAtaque: 0.0,
    saquesTotales: 0,
    saquesDirectos: 0,
    saquesFallidos: 0,
    efectividadSaque: 0.0,
    bloqueosTotales: 0,
    bloqueosExitosos: 0,
    bloqueosFallidos: 0,
    efectividadBloqueo: 0.0,
    defensasTotales: 0,
    defensasPerfectas: 0,
    defensasFallidas: 0,
    recepcionesTotales: 0,
    recepcionesPerfectas: 0,
    recepcionesFallidas: 0,
    colocacionesTotales: 0,
    colocacionesPerfectas: 0,
    colocacionesFallidas: 0,
    totalAcciones: 0,
  );

  /// Efectividad general del jugador (%)
  double get porcentajeEfectividad {
    if (totalAcciones == 0) return 0.0;
    return (efectividad / totalAcciones) * 100;
  }

  @override
  String toString() => 'PlayerStats(playerId: $playerId, '
      'ataques: $ataquesExitosos/$ataquesTotales, '
      'saques: $saquesDirectos/$saquesTotales, '
      'efectividad: ${porcentajeEfectividad.toStringAsFixed(1)}%)';
}

/// Servicio de cálculo de estadísticas
///
/// Proporciona funciones estáticas optimizadas para calcular
/// estadísticas de jugadores a partir de eventos de un partido.
class StatsCalculator {
  /// Calcula las estadísticas de un jugador a partir de sus eventos
  ///
  /// [eventos] - Lista de StatEvent del jugador
  /// [playerId] - ID del jugador
  ///
  /// Retorna un objeto [PlayerStats] con todas las métricas calculadas.
  ///
  /// Optimizado para tiempo real: usa un solo recorrido de la lista
  static PlayerStats calcularStats(List<StatEvent> eventos, int playerId) {
    // Contadores
    int puntosPositivos = 0;
    int errores = 0;

    int ataquesTotales = 0;
    int ataquesExitosos = 0;

    int saquesTotales = 0;
    int saquesDirectos = 0;
    int saquesFallidos = 0;

    int bloqueosTotales = 0;
    int bloqueosExitosos = 0;

    int defensasTotales = 0;
    int defensasPerfectas = 0;
    int defensasFallidas = 0;

    int recepcionesTotales = 0;
    int recepcionesPerfectas = 0;
    int recepcionesFallidas = 0;

    int colocacionesTotales = 0;
    int colocacionesPerfectas = 0;
    int colocacionesFallidas = 0;

    // Un solo recorrido - O(n) donde n = número de eventos
    for (final evento in eventos) {
      // Solo procesamos eventos del jugador especificado
      if (evento.playerId != playerId) continue;

      switch (evento.tipoAccion) {
        case TipoAccion.ataque:
          ataquesTotales++;
          if (evento.isPuntoGanado) {
            ataquesExitosos++;
            puntosPositivos++;
          } else if (evento.isPuntoPerdido) {
            errores++;
          }
          break;

        case TipoAccion.saque:
          saquesTotales++;
          if (evento.isPuntoGanado) {
            saquesDirectos++;
            puntosPositivos++;
          } else if (evento.isPuntoPerdido) {
            saquesFallidos++;
            errores++;
          }
          break;

        case TipoAccion.bloqueo:
          bloqueosTotales++;
          if (evento.isPuntoGanado) {
            bloqueosExitosos++;
            puntosPositivos++;
          } else if (evento.isPuntoPerdido) {
            errores++;
          }
          break;

        case TipoAccion.defensa:
          defensasTotales++;
          // Las defensas pueden ser perfectas o fallidas
          if (evento.resultado == ResultadoAccion.neutral) {
            defensasPerfectas++; // Continuó la jugada
          } else if (evento.isPuntoPerdido) {
            defensasFallidas++;
            errores++;
          }
          break;

        case TipoAccion.recepcion:
          recepcionesTotales++;
          if (evento.isPuntoGanado) {
            recepcionesPerfectas++;
            puntosPositivos++;
          } else if (evento.isPuntoPerdido) {
            recepcionesFallidas++;
            errores++;
          }
          break;

        case TipoAccion.colocacion:
          colocacionesTotales++;
          if (evento.isPuntoGanado) {
            colocacionesPerfectas++;
            puntosPositivos++;
          } else if (evento.isPuntoPerdido) {
            colocacionesFallidas++;
            errores++;
          }
          break;

        case TipoAccion.errorContrario:
          // No cuenta para estadísticas del jugador
          break;
      }
    }

    // Calcular efectividad
    final efectividad = puntosPositivos - errores;
    final totalAcciones = ataquesTotales + saquesTotales + bloqueosTotales;

    // Calcular porcentajes
    final efectividadAtaque = ataquesTotales > 0
        ? (ataquesExitosos / ataquesTotales) * 100
        : 0.0;

    final efectividadSaque = saquesTotales > 0
        ? (saquesDirectos / saquesTotales) * 100
        : 0.0;

    final efectividadBloqueo = bloqueosTotales > 0
        ? (bloqueosExitosos / bloqueosTotales) * 100
        : 0.0;

    return PlayerStats._(
      playerId: playerId,
      puntosPositivos: puntosPositivos,
      errores: errores,
      efectividad: efectividad,
      ataquesTotales: ataquesTotales,
      ataquesExitosos: ataquesExitosos,
      ataquesFallidos: ataquesTotales - ataquesExitosos,
      efectividadAtaque: efectividadAtaque,
      saquesTotales: saquesTotales,
      saquesDirectos: saquesDirectos,
      saquesFallidos: saquesFallidos,
      efectividadSaque: efectividadSaque,
      bloqueosTotales: bloqueosTotales,
      bloqueosExitosos: bloqueosExitosos,
      bloqueosFallidos: bloqueosTotales - bloqueosExitosos,
      efectividadBloqueo: efectividadBloqueo,
      defensasTotales: defensasTotales,
      defensasPerfectas: defensasPerfectas,
      defensasFallidas: defensasFallidas,
      recepcionesTotales: recepcionesTotales,
      recepcionesPerfectas: recepcionesPerfectas,
      recepcionesFallidas: recepcionesFallidas,
      colocacionesTotales: colocacionesTotales,
      colocacionesPerfectas: colocacionesPerfectas,
      colocacionesFallidas: colocacionesFallidas,
      totalAcciones: totalAcciones,
    );
  }

  /// Calcula estadísticas de múltiples jugadores eficientemente
  ///
  /// [eventosPorJugador] - Mapa de playerId -> lista de eventos
  ///
  /// Retorna un mapa de playerId -> PlayerStats
  static Map<int, PlayerStats> calcularStatsMultiples(
    Map<int, List<StatEvent>> eventosPorJugador,
  ) {
    final resultado = <int, PlayerStats>{};

    for (final entry in eventosPorJugador.entries) {
      resultado[entry.key] = calcularStats(entry.value, entry.key);
    }

    return resultado;
  }

  /// Obtiene el conteo por tipo de acción
  ///
  /// Retorna un mapa de TipoAccion -> cantidad
  static Map<TipoAccion, int> contarPorTipo(List<StatEvent> eventos) {
    final conteo = <TipoAccion, int>{};

    for (final evento in eventos) {
      conteo[evento.tipoAccion] = (conteo[evento.tipoAccion] ?? 0) + 1;
    }

    return conteo;
  }

  /// Calcula estadísticas de un equipo completo
  ///
  /// Suma las estadísticas de todos los jugadores
  static Map<String, int> calcularStatsEquipo(List<StatEvent> eventos) {
    int puntosLocal = 0;
    int puntosVisitante = 0;
    int ataquesLocal = 0;
    int ataquesVisitante = 0;
    int saquesLocal = 0;
    int saquesVisitante = 0;
    int bloqueosLocal = 0;
    int bloqueosVisitante = 0;

    for (final evento in eventos) {
      if (evento.esEquipoLocal) {
        puntosLocal++;
        switch (evento.tipoAccion) {
          case TipoAccion.ataque:
            ataquesLocal++;
          case TipoAccion.saque:
            saquesLocal++;
          case TipoAccion.bloqueo:
            bloqueosLocal++;
          default:
            break;
        }
      } else {
        puntosVisitante++;
        switch (evento.tipoAccion) {
          case TipoAccion.ataque:
            ataquesVisitante++;
          case TipoAccion.saque:
            saquesVisitante++;
          case TipoAccion.bloqueo:
            bloqueosVisitante++;
          default:
            break;
        }
      }
    }

    return {
      'puntosLocal': puntosLocal,
      'puntosVisitante': puntosVisitante,
      'ataquesLocal': ataquesLocal,
      'ataquesVisitante': ataquesVisitante,
      'saquesLocal': saquesLocal,
      'saquesVisitante': saquesVisitante,
      'bloqueosLocal': bloqueosLocal,
      'bloqueosVisitante': bloqueosVisitante,
    };
  }

  /// Filtra eventos por set
  static List<StatEvent> filtrarPorSet(List<StatEvent> eventos, int setNumero) {
    return eventos.where((e) => e.setNumero == setNumero).toList();
  }

  /// Obtiene eventos recientes (últimos n)
  static List<StatEvent> eventosRecientes(List<StatEvent> eventos, int cantidad) {
    if (eventos.length <= cantidad) return eventos;
    return eventos.sublist(eventos.length - cantidad);
  }
}
