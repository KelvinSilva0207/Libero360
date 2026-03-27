import 'package:flutter/material.dart';

import '../../data/local_db/stats_stream_service.dart';
import '../../data/models/models.dart';
import '../widgets/live_stats_widget.dart';
import '../widgets/stat_recorder_widget.dart';

/// Pantalla de Dashboard de Estadísticas en Vivo
///
/// Muestra un resumen completo del partido con:
///
/// - Marcador en tiempo real
/// - Lista de jugadores con estadísticas
/// - Puntos, errores y efectividad
/// - Actualización automática via streams
///
/// Diseño: Dashboard moderno con tema oscuro
class LiveStatsDashboardScreen extends StatefulWidget {
  /// Partido a mostrar
  final Match match;
  
  /// Jugadores del equipo local
  final List<Player> jugadoresLocal;
  
  /// Jugadores del equipo visitante
  final List<Player> jugadoresVisitante;

  const LiveStatsDashboardScreen({
    super.key,
    required this.match,
    required this.jugadoresLocal,
    required this.jugadoresVisitante,
  });

  @override
  State<LiveStatsDashboardScreen> createState() => _LiveStatsDashboardScreenState();
}

class _LiveStatsDashboardScreenState extends State<LiveStatsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StatsStreamService _streamService = StatsStreamService();

  // Colores del tema
  static const Color _primaryDark = Color(0xFF002B5B);
  static const Color _primaryLight = Color(0xFF0081CF);
  static const Color _accentOrange = Color(0xFFFF8C00);
  static const Color _backgroundDark = Color(0xFF0D1117);
  static const Color _surfaceDark = Color(0xFF161B22);
  static const Color _cardDark = Color(0xFF21262D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Combinar jugadores de ambos equipos
    final todosJugadores = [...widget.jugadoresLocal, ...widget.jugadoresVisitante];
    _streamService.startWatchingMatch(widget.match.id, todosJugadores);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _streamService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildScoreBoard(),
            _buildTabs(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, _surfaceDark],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'DASHBOARD EN VIVO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Estadísticas actualizadas en tiempo real',
                  style: TextStyle(
                    color: _primaryLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Indicador de streaming
          StreamBuilder<List<StatEvent>>(
            stream: _streamService.eventStream,
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE ($count)',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardDark, _surfaceDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryLight.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: _primaryDark.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Set actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _accentOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'SET ${widget.match.setActual}',
              style: TextStyle(
                color: _accentOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Marcador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamScore(
                widget.match.equipoLocal,
                widget.match.puntosLocal,
                widget.match.setsLocal,
                true,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: _primaryLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildTeamScore(
                widget.match.equipoVisitante,
                widget.match.puntosVisitante,
                widget.match.setsVisitante,
                false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Indicador de turno
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_volleyball,
                color: widget.match.turnoLocal ? _accentOrange : _primaryLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Turno: ${widget.match.turnoLocal ? widget.match.equipoLocal : widget.match.equipoVisitante}',
                style: TextStyle(
                  color: widget.match.turnoLocal ? _accentOrange : _primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String nombre, int puntos, int sets, bool esLocal) {
    return Expanded(
      child: Column(
        children: [
          Text(
            nombre,
            style: TextStyle(
              color: esLocal ? _accentOrange : _primaryLight,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '$puntos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            '$sets sets',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _primaryDark,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 18, color: _accentOrange),
                const SizedBox(width: 8),
                Text(widget.match.equipoLocal),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 18, color: _primaryLight),
                const SizedBox(width: 8),
                Text(widget.match.equipoVisitante),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Equipo Local
        _buildTeamStats(widget.jugadoresLocal, true),
        // Equipo Visitante
        _buildTeamStats(widget.jugadoresVisitante, false),
      ],
    );
  }

  Widget _buildTeamStats(List<Player> jugadores, bool esLocal) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Resumen del equipo
          _buildTeamSummary(esLocal),
          const SizedBox(height: 16),
          // Lista de jugadores
          Expanded(
            child: LiveStatsWidget(
              matchId: widget.match.id,
              jugadores: jugadores,
              streamService: _streamService,
            ),
          ),
          const SizedBox(height: 16),
          // Widget de registro
          StatRecorderWidget(
            matchId: widget.match.id,
            jugadores: jugadores,
            esEquipoLocal: esLocal,
            onEventRegistered: (evento) {
              // Feedback ya manejado por el widget
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSummary(bool esLocal) {
    return StreamBuilder<List<StatEvent>>(
      stream: _streamService.eventStream,
      builder: (context, snapshot) {
        final eventos = snapshot.data ?? [];
        final eventosEquipo = eventos.where((e) => e.esEquipoLocal == esLocal).toList();
        
        int puntos = 0;
        int errores = 0;
        int ataques = 0;
        int saques = 0;
        int bloqueos = 0;
        
        for (final e in eventosEquipo) {
          if (e.isPuntoGanado) puntos++;
          if (e.isPuntoPerdido) errores++;
          switch (e.tipoAccion) {
            case TipoAccion.ataque:
              ataques++;
            case TipoAccion.saque:
              saques++;
            case TipoAccion.bloqueo:
              bloqueos++;
            default:
              break;
          }
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: esLocal
                  ? [_accentOrange.withOpacity(0.2), _cardDark]
                  : [_primaryLight.withOpacity(0.2), _cardDark],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: esLocal ? _accentOrange : _primaryLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('PUNTOS', '$puntos', Colors.green),
              _buildSummaryItem('ERRORES', '$errores', Colors.red),
              _buildSummaryItem('ATAQUES', '$ataques', Colors.orange),
              _buildSummaryItem('SAQUES', '$saques', Colors.blue),
              _buildSummaryItem('BLOQUEOS', '$bloqueos', Colors.purple),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
