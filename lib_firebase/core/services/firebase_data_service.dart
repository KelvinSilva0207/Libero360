import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../lib/core/services/abstract_data_service.dart';
import '../../../features/estadisticas/data/models/models.dart';
import '../../../features/estadisticas/data/local_db/database_service.dart';
import '../../../features/auth/data/models/user_model.dart';

class FirebaseDataService extends AbstractDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _local = DatabaseService.instance;

  // ==================== SYNC HELPERS ====================

  Future<void> _syncLocalToFirestore() async {
    final players = await _local.getAllPlayers();
    for (final p in players) {
      await _firestore.collection('players').doc(p.id.toString()).set(_playerToMap(p));
    }
  }

  Future<void> _syncFirestoreToLocal() async {
    final snap = await _firestore.collection('players').get();
    for (final doc in snap.docs) {
      final id = int.tryParse(doc.id) ?? 0;
      if (id > 0) {
        final p = _playerFromMap(doc.data());
        p.id = id;
        await _local.savePlayer(p);
      }
    }
  }

  // ==================== LIFECYCLE ====================

  @override
  Future<void> initialize() async {
    await _local.initialize();
    try {
      await _syncFirestoreToLocal();
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    try {
      await _syncLocalToFirestore();
    } catch (_) {}
    await _local.close();
  }

  // All read operations use local DB (faster)
  // All write operations write to both local DB and Firestore

  @override
  Future<List<Player>> getAllPlayers() => _local.getAllPlayers();

  @override
  Future<Player?> getPlayerById(int id) => _local.getPlayerById(id);

  @override
  Future<List<Player>> searchPlayers(String query) => _local.searchPlayers(query);

  @override
  Future<int> savePlayer(Player player) async {
    final id = await _local.savePlayer(player);
    try {
      player.id = id;
      await _firestore.collection('players').doc(id.toString()).set(_playerToMap(player));
    } catch (_) {}
    return id;
  }

  @override
  Future<bool> deletePlayer(int id) async {
    final ok = await _local.deletePlayer(id);
    try {
      await _firestore.collection('players').doc(id.toString()).delete();
    } catch (_) {}
    return ok;
  }

  @override
  Future<List<Player>> getPlayersByPosicion(Posicion posicion) => _local.getPlayersByPosicion(posicion);

  @override
  Future<int> getPlayerCount() => _local.getPlayerCount();

  // Seasons
  @override
  Future<List<Season>> getAllSeasons() => _local.getAllSeasons();

  @override
  Future<Season?> getSeasonById(int id) => _local.getSeasonById(id);

  @override
  Future<int> saveSeason(Season season) async {
    final id = await _local.saveSeason(season);
    try {
      season.id = id;
      await _firestore.collection('seasons').doc(id.toString()).set(_seasonToMap(season));
    } catch (_) {}
    return id;
  }

  @override
  Future<bool> deleteSeason(int id) async {
    final ok = await _local.deleteSeason(id);
    try {
      await _firestore.collection('seasons').doc(id.toString()).delete();
    } catch (_) {}
    return ok;
  }

  @override
  Future<Season?> getActiveSeason() => _local.getActiveSeason();

  @override
  Future<void> setActiveSeason(int id) => _local.setActiveSeason(id);

  @override
  Future<List<Match>> getMatchesBySeason(int seasonId) => _local.getMatchesBySeason(seasonId);

  // Matches
  @override
  Future<List<Match>> getAllMatches() => _local.getAllMatches();

  @override
  Future<Match?> getMatchById(int id) => _local.getMatchById(id);

  @override
  Future<Match?> getActiveMatch() => _local.getActiveMatch();

  @override
  Future<List<Match>> getMatchesByState(EstadoPartido estado) => _local.getMatchesByState(estado);

  @override
  Future<int> saveMatch(Match match) async {
    final id = await _local.saveMatch(match);
    try {
      match.id = id;
      await _firestore.collection('matches').doc(id.toString()).set(_matchToMap(match));
    } catch (_) {}
    return id;
  }

  @override
  Future<bool> deleteMatch(int id) async {
    final ok = await _local.deleteMatch(id);
    try {
      await _firestore.collection('matches').doc(id.toString()).delete();
    } catch (_) {}
    return ok;
  }

  @override
  Future<int> getMatchCount() => _local.getMatchCount();

  // Stat Events
  @override
  Future<List<StatEvent>> getAllEvents() => _local.getAllEvents();

  @override
  Future<List<StatEvent>> getEventsByMatch(int matchId) => _local.getEventsByMatch(matchId);

  @override
  Future<List<StatEvent>> getEventsByPlayer(int playerId) => _local.getEventsByPlayer(playerId);

  @override
  Future<List<StatEvent>> getEventsByPlayerAndMatch(int playerId, int matchId) => _local.getEventsByPlayerAndMatch(playerId, matchId);

  @override
  Future<List<StatEvent>> getEventsByMatchAndPlayer(int matchId, int playerId) => _local.getEventsByMatchAndPlayer(matchId, playerId);

  @override
  Future<List<StatEvent>> getEventsByMatchAndType(int matchId, TipoAccion tipo) => _local.getEventsByMatchAndType(matchId, tipo);

  @override
  Future<int> saveStatEvent(StatEvent event) async {
    final id = await _local.saveStatEvent(event);
    try {
      event.id = id;
      await _firestore.collection('events').doc(id.toString()).set(_eventToMap(event));
    } catch (_) {}
    return id;
  }

  @override
  Future<bool> deleteStatEvent(int id) async {
    final ok = await _local.deleteStatEvent(id);
    try {
      await _firestore.collection('events').doc(id.toString()).delete();
    } catch (_) {}
    return ok;
  }

  @override
  Future<int> deleteEventsByMatch(int matchId) => _local.deleteEventsByMatch(matchId);

  @override
  Future<int> countEventsByType(int matchId, TipoAccion tipo) => _local.countEventsByType(matchId, tipo);

  @override
  Future<Map<TipoAccion, int>> countAllEventTypes(int matchId) => _local.countAllEventTypes(matchId);

  // Attendance
  @override
  Future<List<AttendanceRecord>> getAllAttendanceRecords() => _local.getAllAttendanceRecords();

  @override
  Future<List<AttendanceRecord>> getAttendanceByDate(DateTime date) => _local.getAttendanceByDate(date);

  @override
  Future<List<AttendanceRecord>> getAttendanceByPlayer(int playerId) => _local.getAttendanceByPlayer(playerId);

  @override
  Future<List<AttendanceRecord>> getAttendanceByPlayerAndDateRange(int playerId, DateTime start, DateTime end) => _local.getAttendanceByPlayerAndDateRange(playerId, start, end);

  @override
  Future<int> saveAttendanceRecord(AttendanceRecord record) async {
    final id = await _local.saveAttendanceRecord(record);
    try {
      record.id = id;
      await _firestore.collection('attendance').doc(id.toString()).set(_attendanceToMap(record));
    } catch (_) {}
    return id;
  }

  // Users
  @override
  Future<List<AppUser>> getAllUsers() => _local.getAllUsers();

  @override
  Future<AppUser?> getUserByEmail(String email) => _local.getUserByEmail(email);

  @override
  Future<AppUser?> getUserById(int id) => _local.getUserById(id);

  @override
  Future<int> saveUser(AppUser user) async {
    final id = await _local.saveUser(user);
    try {
      user.id = id;
      await _firestore.collection('users').doc(id.toString()).set(_userToMap(user));
    } catch (_) {}
    return id;
  }

  @override
  Future<bool> deleteUser(int id) async {
    final ok = await _local.deleteUser(id);
    try {
      await _firestore.collection('users').doc(id.toString()).delete();
    } catch (_) {}
    return ok;
  }

  // Session
  @override
  Future<void> saveSessionUserId(int userId) => _local.saveSessionUserId(userId);

  @override
  Future<int?> getSessionUserId() => _local.getSessionUserId();

  @override
  Future<void> clearSession() => _local.clearSession();

  // Backup & Restore
  @override
  Future<String> exportToJson() => _local.exportToJson();

  @override
  Future<bool> importFromJson(String jsonString) => _local.importFromJson(jsonString);

  // ==================== SERIALIZATION ====================

  Map<String, dynamic> _playerToMap(Player p) => {
    'nombre': p.nombre,
    'firstNames': p.firstNames,
    'lastNames': p.lastNames,
    'displayName': p.displayName,
    'cedula': p.cedula,
    'fechaNacimiento': p.fechaNacimiento.millisecondsSinceEpoch,
    'numero': p.numero ?? 0,
    'posicion': p.posicion.index,
    'esCapitan': p.esCapitan ? 1 : 0,
    'fotoUrl': p.fotoUrl ?? '',
    'estadoSalud': p.estadoSalud.index,
    'condicionFisica': p.condicionFisica,
    'createdAt': p.createdAt.millisecondsSinceEpoch,
  };

  Player _playerFromMap(Map<String, dynamic> map) => Player()
    ..nombre = map['nombre'] as String? ?? ''
    ..firstNames = map['firstNames'] as String? ?? ''
    ..lastNames = map['lastNames'] as String? ?? ''
    ..displayName = map['displayName'] as String? ?? ''
    ..cedula = map['cedula'] as String? ?? ''
    ..fechaNacimiento = DateTime.fromMillisecondsSinceEpoch(map['fechaNacimiento'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..numero = map['numero'] as int?
    ..posicion = Posicion.values[map['posicion'] as int? ?? 0]
    ..esCapitan = (map['esCapitan'] as int? ?? 0) == 1
    ..fotoUrl = (map['fotoUrl'] as String?)?.isNotEmpty == true ? map['fotoUrl'] as String? : null
    ..estadoSalud = EstadoSalud.values[map['estadoSalud'] as int? ?? 0]
    ..condicionFisica = map['condicionFisica'] as String? ?? 'Excelente'
    ..createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch);

  Map<String, dynamic> _matchToMap(Match m) => {
    'fecha': m.fecha.millisecondsSinceEpoch,
    'equipoLocal': m.equipoLocal,
    'equipoVisitante': m.equipoVisitante,
    'puntosLocal': m.puntosLocal,
    'puntosVisitante': m.puntosVisitante,
    'setsLocal': m.setsLocal,
    'setsVisitante': m.setsVisitante,
    'setActual': m.setActual,
    'estado': m.estado.index,
    'turnoLocal': m.turnoLocal ? 1 : 0,
    'velocidadAnimacion': m.velocidadAnimacion,
    'createdAt': m.createdAt.millisecondsSinceEpoch,
    'tipoPartido': m.tipoPartido.index,
    'setsTotales': m.setsTotales,
    'resultadoFinal': m.resultadoFinal ?? '',
    'lugar': m.lugar ?? '',
    'seasonId': m.seasonId ?? 0,
    'duracionSegundos': m.duracionSegundos,
  };

  Map<String, dynamic> _eventToMap(StatEvent e) => {
    'tipoAccion': e.tipoAccion.index,
    'resultado': e.resultado.index,
    'timestamp': e.timestamp.millisecondsSinceEpoch,
    'setNumero': e.setNumero,
    'puntoLocal': e.puntoLocal,
    'puntoVisitante': e.puntoVisitante,
    'esEquipoLocal': e.esEquipoLocal ? 1 : 0,
    'zona': e.zona.index,
    'descripcion': e.descripcion ?? '',
    'playerId': e.playerId,
    'matchId': e.matchId,
    'createdAt': e.createdAt.millisecondsSinceEpoch,
  };

  Map<String, dynamic> _attendanceToMap(AttendanceRecord r) => {
    'playerId': r.playerId,
    'fecha': r.fecha.millisecondsSinceEpoch,
    'asistio': r.asistio ? 1 : 0,
    'observaciones': r.observaciones,
  };

  Map<String, dynamic> _userToMap(AppUser u) => {
    'nombre': u.nombre,
    'email': u.email,
    'password': u.password,
    'fechaRegistro': u.fechaRegistro.millisecondsSinceEpoch,
  };

  Map<String, dynamic> _seasonToMap(Season s) => {
    'name': s.name,
    'year': s.year,
    'isActive': s.isActive ? 1 : 0,
    'startDate': s.startDate.millisecondsSinceEpoch,
    'endDate': s.endDate?.millisecondsSinceEpoch,
    'createdAt': s.createdAt.millisecondsSinceEpoch,
  };
}
