import 'dart:async';
import '../models/models.dart';
import 'database_service.dart';
import '../../domain/services/stats_calculator.dart';

/// Servicio de streaming para actualizaciones en tiempo real
///
/// Usa polling en web (mock) y Isar.watch() en nativo
class StatsStreamService {
  final DatabaseService _db = DatabaseService.instance;
  
  // Streams para cada tipo de cambio
  Timer? _pollingTimer;
  
  // Controladores de stream
  final _eventStreamController = StreamController<List<StatEvent>>.broadcast();
  final _playerStatsController = StreamController<Map<int, PlayerStats>>.broadcast();
  final _matchController = StreamController<Match?>.broadcast();
  
  // Controlador para exportar PlayerStatsData
  final _playerStatsDataController = StreamController<PlayerStatsData>.broadcast();

  /// Stream de eventos del partido actual
  Stream<List<StatEvent>> get eventStream => _eventStreamController.stream;

  /// Stream de estadísticas por jugador
  Stream<Map<int, PlayerStats>> get playerStatsStream => _playerStatsController.stream;

  /// Stream del partido actual
  Stream<Match?> get matchStream => _matchController.stream;

  /// Stream de datos de estadísticas para UI
  Stream<PlayerStatsData> get playerStatsDataStream => _playerStatsDataController.stream;

  // Caché de eventos y jugadores
  List<StatEvent> _cachedEvents = [];
  Match? _cachedMatch;
  List<Player> _cachedJugadores = [];
  int? _currentMatchId;

  /// Inicia el streaming para un partido específico
  Future<void> startWatchingMatch(int matchId, List<Player> jugadores) async {
    _currentMatchId = matchId;
    _cachedJugadores = jugadores;
    
    // Cargar datos iniciales
    await _loadInitialData(matchId);
    
    // Iniciar polling para simular streaming en web
    _startPolling();
  }

  /// Detiene todos los watchers
  void stopWatching() {
    _pollingTimer?.cancel();
    _currentMatchId = null;
  }

  /// Carga datos iniciales
  Future<void> _loadInitialData(int matchId) async {
    _cachedMatch = await _db.getMatchById(matchId);
    _cachedEvents = await _db.getEventsByMatch(matchId);
    
    // Emitir datos iniciales
    _eventStreamController.add(List.from(_cachedEvents));
    _matchController.add(_cachedMatch);
    _notifyPlayerStats();
  }

  /// Inicia el polling para simular streaming
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (_currentMatchId == null) return;
      
      // Recargar eventos del partido actual
      final newEvents = await _db.getEventsByMatch(_currentMatchId!);
      
      // Verificar si hay cambios
      if (_hasEventsChanged(_cachedEvents, newEvents)) {
        _cachedEvents = newEvents;
        _eventStreamController.add(List.from(_cachedEvents));
        _notifyPlayerStats();
      }
      
      // Verificar cambios en el partido
      final match = await _db.getMatchById(_currentMatchId!);
      if (match != null && match != _cachedMatch) {
        _cachedMatch = match;
        _matchController.add(_cachedMatch);
      }
    });
  }

  /// Verifica si los eventos han cambiado
  bool _hasEventsChanged(List<StatEvent> oldEvents, List<StatEvent> newEvents) {
    if (oldEvents.length != newEvents.length) return true;
    
    for (int i = 0; i < oldEvents.length; i++) {
      if (oldEvents[i].id != newEvents[i].id ||
          oldEvents[i].timestamp != newEvents[i].timestamp) {
        return true;
      }
    }
    
    return false;
  }

  /// Notifica nuevas estadísticas a los listeners
  void _notifyPlayerStats() {
    // Calcular stats para cada jugador
    final statsMap = <int, PlayerStats>{};
    for (final jugador in _cachedJugadores) {
      final stats = StatsCalculator.calcularStats(_cachedEvents, jugador.id);
      statsMap[jugador.id] = stats;
    }
    
    _playerStatsController.add(statsMap);
    
    // Crear datos completos para UI
    final data = PlayerStatsData(
      statsMap: statsMap,
      jugadores: _cachedJugadores,
      eventos: List.from(_cachedEvents),
    );
    _playerStatsDataController.add(data);
  }

  /// Refresca manualmente las estadísticas (útil después de cambios)
  Future<void> refreshStats() async {
    if (_currentMatchId == null) return;
    _cachedEvents = await _db.getEventsByMatch(_currentMatchId!);
    _notifyPlayerStats();
  }

  /// Obtiene el stream actual de eventos
  List<StatEvent> get currentEvents => List.from(_cachedEvents);

  /// Obtiene las estadísticas actuales de un jugador
  PlayerStats? getPlayerStats(int playerId) {
    return StatsCalculator.calcularStats(_cachedEvents, playerId);
  }

  /// Libera recursos
  void dispose() {
    stopWatching();
    _eventStreamController.close();
    _playerStatsController.close();
    _matchController.close();
    _playerStatsDataController.close();
  }
}

/// Datos combinados de estadísticas para UI
class PlayerStatsData {
  final Map<int, PlayerStats> statsMap;
  final List<Player> jugadores;
  final List<StatEvent> eventos;

  PlayerStatsData({
    required this.statsMap,
    required this.jugadores,
    required this.eventos,
  });
}
