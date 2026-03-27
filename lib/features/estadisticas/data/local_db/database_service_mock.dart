import '../models/models.dart';

/// Servicio mock de base de datos para pruebas en web
/// 
/// Usa almacenamiento en memoria en lugar de Isar
/// para permitir pruebas en Flutter Web.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  // Almacenamiento en memoria
  final List<Player> _players = [];
  final List<Match> _matches = [];
  final List<StatEvent> _events = [];
  
  int _playerIdCounter = 1;
  int _matchIdCounter = 1;
  int _eventIdCounter = 1;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inicializa el servicio (simulado)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Agregar datos de ejemplo
    _seedData();
    
    _isInitialized = true;
  }

  /// Cierra la conexión (simulado)
  Future<void> close() async {
    _isInitialized = false;
  }

  /// Datos de ejemplo
  void _seedData() {
    // Jugadores de ejemplo
    _players.addAll([
      Player.create(nombre: 'Juan Pérez', numero: 10, posicion: Posicion.colocador),
      Player.create(nombre: 'Carlos López', numero: 12, posicion: Posicion.opuesto),
      Player.create(nombre: 'Miguel Santos', numero: 8, posicion: Posicion.central),
      Player.create(nombre: 'Andrés García', numero: 5, posicion: Posicion.receptor),
      Player.create(nombre: 'Pedro Ruiz', numero: 2, posicion: Posicion.libre),
    ]);
    
    for (var i = 0; i < _players.length; i++) {
      _players[i].id = _playerIdCounter++;
    }

    // Partido de ejemplo
    final match = Match.create(
      equipoLocal: 'Equipo Local',
      equipoVisitante: 'Equipo Visitante',
    );
    match.id = _matchIdCounter++;
    _matches.add(match);
  }

  // ==================== PLAYERS ====================
  
  Future<List<Player>> getAllPlayers() async {
    return List.from(_players);
  }

  Future<Player?> getPlayerById(int id) async {
    try {
      return _players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Player>> getPlayersByPosicion(Posicion posicion) async {
    return _players.where((p) => p.posicion == posicion).toList();
  }

  Future<List<Player>> searchPlayers(String query) async {
    final lowerQuery = query.toLowerCase();
    return _players.where((p) => 
      p.nombre.toLowerCase().contains(lowerQuery) ||
      p.numero.toString().contains(lowerQuery)
    ).toList();
  }

  Future<int> savePlayer(Player player) async {
    if (player.id == 0) {
      player.id = _playerIdCounter++;
      _players.add(player);
    } else {
      final index = _players.indexWhere((p) => p.id == player.id);
      if (index >= 0) {
        _players[index] = player;
      }
    }
    return player.id;
  }

  Future<bool> deletePlayer(int id) async {
    final index = _players.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _players.removeAt(index);
      return true;
    }
    return false;
  }

  // ==================== MATCHES ====================

  Future<List<Match>> getAllMatches() async {
    return List.from(_matches);
  }

  Future<List<Match>> getMatchesByEstado(EstadoPartido estado) async {
    return _matches.where((m) => m.estado == estado).toList();
  }

  Future<List<Match>> getMatchesEnProgreso() async {
    return _matches.where((m) => m.estado == EstadoPartido.enProgreso).toList();
  }

  Future<Match?> getMatchById(int id) async {
    try {
      return _matches.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Match?> getActiveMatch() async {
    try {
      return _matches.firstWhere((m) => m.estado == EstadoPartido.enProgreso);
    } catch (_) {
      return null;
    }
  }

  Future<List<Match>> getMatchesByState(EstadoPartido estado) async {
    return getMatchesByEstado(estado);
  }

  Future<int> saveMatch(Match match) async {
    if (match.id == 0) {
      match.id = _matchIdCounter++;
      _matches.add(match);
    } else {
      final index = _matches.indexWhere((m) => m.id == match.id);
      if (index >= 0) {
        _matches[index] = match;
      }
    }
    return match.id;
  }

  Future<bool> deleteMatch(int id) async {
    // Eliminar eventos asociados
    _events.removeWhere((e) => e.matchId == id);
    
    final index = _matches.indexWhere((m) => m.id == id);
    if (index >= 0) {
      _matches.removeAt(index);
      return true;
    }
    return false;
  }

  // ==================== STAT EVENTS ====================

  Future<List<StatEvent>> getAllEvents() async {
    return List.from(_events);
  }

  Future<List<StatEvent>> getEventsByMatch(int matchId) async {
    return _events.where((e) => e.matchId == matchId).toList();
  }

  Future<List<StatEvent>> getEventsByPlayer(int playerId) async {
    return _events.where((e) => e.playerId == playerId).toList();
  }

  Future<List<StatEvent>> getEventsByMatchAndPlayer(int matchId, int playerId) async {
    return _events.where((e) => e.matchId == matchId && e.playerId == playerId).toList();
  }

  Future<List<StatEvent>> getEventsByPlayerAndMatch(int playerId, int matchId) async {
    return getEventsByMatchAndPlayer(matchId, playerId);
  }

  // Alias para compatibilidad con repositorios
  Future<int> saveStatEvent(StatEvent event) async {
    return saveEvent(event);
  }

  Future<bool> deleteStatEvent(int id) async {
    return deleteEvent(id);
  }

  Future<int> saveEvent(StatEvent event) async {
    if (event.id == 0) {
      event.id = _eventIdCounter++;
      _events.add(event);
    } else {
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index >= 0) {
        _events[index] = event;
      }
    }
    return event.id;
  }

  Future<bool> deleteEvent(int id) async {
    final index = _events.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _events.removeAt(index);
      return true;
    }
    return false;
  }

  Future<int> deleteEventsByMatch(int matchId) async {
    final initialCount = _events.length;
    _events.removeWhere((e) => e.matchId == matchId);
    return initialCount - _events.length;
  }

  Future<int> getEventCountByMatch(int matchId) async {
    return _events.where((e) => e.matchId == matchId).length;
  }

  Future<int> countEventsByType(int matchId, TipoAccion tipo) async {
    return _events.where((e) => e.matchId == matchId && e.tipoAccion == tipo).length;
  }

  /// Propiedad mock para compatibilidad (siempre null en web)
  dynamic get isar => null;

  /// Método mock para compatibilidad (no hace nada en web)
  Stream<void> watchLazy() async* {
    // En web mock, no hay watch real
    yield* Stream.periodic(const Duration(seconds: 1)).map((_) {});
  }
}
