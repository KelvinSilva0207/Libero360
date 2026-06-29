import 'package:flutter/material.dart';

import '../../data/local_db/stats_stream_service.dart';
import '../../data/models/models.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../domain/services/stats_calculator.dart';

/// Widget que muestra estadísticas en vivo de los jugadores
///
/// Usa StreamBuilder para escuchar cambios en tiempo real desde Isar
/// y actualiza la UI automáticamente cuando hay nuevos eventos.
///
/// Diseño: Fondo oscuro con acentos azul (#002B5B, #0081CF) y naranja (#FF8C00)
class LiveStatsWidget extends StatefulWidget {
  /// ID del partido a observar
  final int matchId;
  
  /// Jugadores del equipo
  final List<Player> jugadores;
  
  /// Servicio de streaming
  final StatsStreamService streamService;

  const LiveStatsWidget({
    super.key,
    required this.matchId,
    required this.jugadores,
    required this.streamService,
  });

  @override
  State<LiveStatsWidget> createState() => _LiveStatsWidgetState();
}

class _LiveStatsWidgetState extends State<LiveStatsWidget> {
  // Colores del tema
  static const Color _primaryDark = Color(0xFF002B5B);
  static const Color _primaryLight = Color(0xFF0081CF);
  static const Color _accentOrange = Color(0xFFFF8C00);
  static const Color _backgroundDark = Color(0xFF1A1A2E);
  static const Color _surfaceDark = Color(0xFF16213E);
  static const Color _cardDark = Color(0xFF0F3460);

  @override
  void initState() {
    super.initState();
    // Iniciar streaming con jugadores
    widget.streamService.startWatchingMatch(widget.matchId, widget.jugadores);
  }

  @override
  void dispose() {
    widget.streamService.stopWatching();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _backgroundDark,
            _surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<Map<int, PlayerStats>>(
              stream: widget.streamService.playerStatsStream,
              initialData: _calculateInitialStats(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }
                
                final statsMap = snapshot.data ?? {};
                
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.jugadores.length,
                  itemBuilder: (context, index) {
                    final jugador = widget.jugadores[index];
                    final stats = statsMap[jugador.id];
                    
                    return _buildPlayerStatsCard(jugador, stats);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<int, PlayerStats> _calculateInitialStats() {
    final stats = <int, PlayerStats>{};
    final events = widget.streamService.currentEvents;
    
    for (final jugador in widget.jugadores) {
      final playerEvents = events.where((e) => e.playerId == jugador.id).toList();
      if (playerEvents.isNotEmpty) {
        stats[jugador.id] = widget.streamService.getPlayerStats(jugador.id)!;
      }
    }
    
    return stats;
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryDark.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            color: _accentOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTADÍSTICAS EN VIVO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Actualización automática',
                  style: TextStyle(
                    color: _primaryLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Indicador de conexión
          StreamBuilder<List<StatEvent>>(
            stream: widget.streamService.eventStream,
            builder: (context, snapshot) {
              final hasData = snapshot.hasData && (snapshot.data?.isNotEmpty ?? false);
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasData ? Colors.green : Colors.grey,
                  boxShadow: hasData
                      ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsCard(Player jugador, PlayerStats? stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primaryLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header del jugador
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _accentOrange,
                radius: 18,
                child: Text(
                  '${jugador.numero}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NameFormatter.playerDisplayName(jugador),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _getPosicionCompleta(jugador.posicion),
                      style: TextStyle(
                        color: _primaryLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Efectividad general
              if (stats != null)
                _buildEffectivenessBadge(stats.porcentajeEfectividad),
            ],
          ),
          const SizedBox(height: 12),
          // Estadísticas detalladas
          if (stats != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'ATAQUES',
                    '${stats.ataquesExitosos}/${stats.ataquesTotales}',
                    stats.efectividadAtaque,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    'SAQUES',
                    '${stats.saquesDirectos}/${stats.saquesTotales}',
                    stats.efectividadSaque,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    'BLOQUEOS',
                    '${stats.bloqueosExitosos}/${stats.bloqueosTotales}',
                    stats.efectividadBloqueo,
                    _accentOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Barra de puntos
            Row(
              children: [
                _buildPointsBar(
                  'Puntos',
                  stats.puntosPositivos,
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _buildPointsBar(
                  'Errores',
                  stats.errores,
                  Colors.red,
                ),
                const SizedBox(width: 8),
                _buildPointsBar(
                  'Efectividad',
                  stats.efectividad,
                  stats.efectividad >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ] else
            _buildNoStats(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectivenessBadge(double percentage) {
    final color = percentage >= 30 
        ? Colors.green 
        : (percentage >= 0 ? Colors.orange : Colors.red);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '${percentage.toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPointsBar(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value >= 0 ? Icons.add_circle : Icons.remove_circle,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '$label: $value',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            color: Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Sin estadísticas aún',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar estadísticas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getPosicionCompleta(Posicion posicion) {
    switch (posicion) {
      case Posicion.colocador: return 'Colocador';
      case Posicion.opuesto: return 'Opuesto';
      case Posicion.central: return 'Central';
      case Posicion.receptor: return 'Receptor';
      case Posicion.libre: return 'Líbero';
      case Posicion.sinDefinir: return 'Sin definir';
    }
  }
}

/// Extensión para calcular porcentaje de efectividad
extension PlayerStatsExtension on PlayerStats {
  double get porcentajeEfectividad {
    if (totalAcciones == 0) return 0.0;
    return (efectividad / totalAcciones) * 100;
  }
}
