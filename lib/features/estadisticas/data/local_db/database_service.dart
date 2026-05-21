import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  Database? _db;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final _playerStore = intMapStoreFactory.store('players');
  final _matchStore = intMapStoreFactory.store('matches');
  final _eventStore = intMapStoreFactory.store('events');
  final _attendanceStore = intMapStoreFactory.store('attendance');

  Future<void> initialize() async {
    if (_isInitialized) return;
    _db = await databaseFactoryWeb.openDatabase('libero360.db');
    _isInitialized = true;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _isInitialized = false;
  }

  Database get _database {
    if (_db == null) throw StateError('Database not initialized. Call initialize() first.');
    return _db!;
  }

  // ==================== PLAYERS ====================

  Future<List<Player>> getAllPlayers() async {
    final snapshots = await _playerStore.find(_database);
    return snapshots.map((e) => _playerFromMap(e.value)..id = e.key).toList();
  }

  Future<Player?> getPlayerById(int id) async {
    final record = await _playerStore.record(id).get(_database);
    if (record == null) return null;
    return _playerFromMap(record)..id = id;
  }

  Future<List<Player>> searchPlayers(String query) async {
    final all = await getAllPlayers();
    final lower = query.toLowerCase();
    return all.where((p) =>
      p.nombre.toLowerCase().contains(lower) ||
      p.numero.toString().contains(lower)
    ).toList();
  }

  Future<int> savePlayer(Player player) async {
    final map = _playerToMap(player);
    if (player.id == 0) {
      return await _playerStore.add(_database, map);
    } else {
      await _playerStore.record(player.id).put(_database, map);
      return player.id;
    }
  }

  Future<bool> deletePlayer(int id) async {
    await _playerStore.record(id).delete(_database);
    return true;
  }

  Future<List<Player>> getPlayersByPosicion(Posicion posicion) async {
    final all = await getAllPlayers();
    return all.where((p) => p.posicion == posicion).toList();
  }

  // ==================== MATCHES ====================

  Future<List<Match>> getAllMatches() async {
    final snapshots = await _matchStore.find(
      _database,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)]),
    );
    return snapshots.map((e) => _matchFromMap(e.value)..id = e.key).toList();
  }

  Future<Match?> getMatchById(int id) async {
    final record = await _matchStore.record(id).get(_database);
    if (record == null) return null;
    return _matchFromMap(record)..id = id;
  }

  Future<Match?> getActiveMatch() async {
    final snapshots = await _matchStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('estado', EstadoPartido.enProgreso.index),
      ),
    );
    if (snapshots.isEmpty) return null;
    final e = snapshots.first;
    return _matchFromMap(e.value)..id = e.key;
  }

  Future<List<Match>> getMatchesByState(EstadoPartido estado) async {
    final snapshots = await _matchStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('estado', estado.index),
        sortOrders: [SortOrder('createdAt', false)],
      ),
    );
    return snapshots.map((e) => _matchFromMap(e.value)..id = e.key).toList();
  }

  Future<int> saveMatch(Match match) async {
    final map = _matchToMap(match);
    if (match.id == 0) {
      return await _matchStore.add(_database, map);
    } else {
      await _matchStore.record(match.id).put(_database, map);
      return match.id;
    }
  }

  Future<bool> deleteMatch(int id) async {
    await _eventStore.delete(_database, finder: Finder(filter: Filter.equals('matchId', id)));
    await _matchStore.record(id).delete(_database);
    return true;
  }

  // ==================== STAT EVENTS ====================

  Future<List<StatEvent>> getAllEvents() async {
    final snapshots = await _eventStore.find(_database);
    return snapshots.map((e) => _eventFromMap(e.value)..id = e.key).toList();
  }

  Future<List<StatEvent>> getEventsByMatch(int matchId) async {
    final snapshots = await _eventStore.find(
      _database,
      finder: Finder(filter: Filter.equals('matchId', matchId)),
    );
    return snapshots.map((e) => _eventFromMap(e.value)..id = e.key).toList();
  }

  Future<List<StatEvent>> getEventsByPlayer(int playerId) async {
    final snapshots = await _eventStore.find(
      _database,
      finder: Finder(filter: Filter.equals('playerId', playerId)),
    );
    return snapshots.map((e) => _eventFromMap(e.value)..id = e.key).toList();
  }

  Future<List<StatEvent>> getEventsByPlayerAndMatch(int playerId, int matchId) async {
    return getEventsByMatchAndPlayer(matchId, playerId);
  }

  Future<List<StatEvent>> getEventsByMatchAndPlayer(int matchId, int playerId) async {
    final snapshots = await _eventStore.find(
      _database,
      finder: Finder(filter: Filter.and([
        Filter.equals('matchId', matchId),
        Filter.equals('playerId', playerId),
      ])),
    );
    return snapshots.map((e) => _eventFromMap(e.value)..id = e.key).toList();
  }

  Future<int> saveStatEvent(StatEvent event) async {
    final map = _eventToMap(event);
    if (event.id == 0) {
      return await _eventStore.add(_database, map);
    } else {
      await _eventStore.record(event.id).put(_database, map);
      return event.id;
    }
  }

  Future<bool> deleteStatEvent(int id) async {
    await _eventStore.record(id).delete(_database);
    return true;
  }

  Future<int> deleteEventsByMatch(int matchId) async {
    final deleted = await _eventStore.delete(
      _database,
      finder: Finder(filter: Filter.equals('matchId', matchId)),
    );
    return deleted;
  }

  Future<int> getEventCountByMatch(int matchId) async {
    final events = await getEventsByMatch(matchId);
    return events.length;
  }

  Future<int> countEventsByType(int matchId, TipoAccion tipo) async {
    final snapshots = await _eventStore.count(
      _database,
      filter: Filter.and([
        Filter.equals('matchId', matchId),
        Filter.equals('tipoAccion', tipo.index),
      ]),
    );
    return snapshots;
  }

  // ==================== ATTENDANCE ====================

  Future<List<AttendanceRecord>> getAllAttendanceRecords() async {
    final snapshots = await _attendanceStore.find(_database);
    return snapshots.map((e) => _attendanceFromMap(e.value)..id = e.key).toList();
  }

  Future<List<AttendanceRecord>> getAttendanceByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snapshots = await _attendanceStore.find(
      _database,
      finder: Finder(filter: Filter.and([
        Filter.greaterThanOrEquals('fecha', start.millisecondsSinceEpoch),
        Filter.lessThan('fecha', end.millisecondsSinceEpoch),
      ])),
    );
    return snapshots.map((e) => _attendanceFromMap(e.value)..id = e.key).toList();
  }

  Future<List<AttendanceRecord>> getAttendanceByPlayer(int playerId) async {
    final snapshots = await _attendanceStore.find(
      _database,
      finder: Finder(filter: Filter.equals('playerId', playerId)),
    );
    return snapshots.map((e) => _attendanceFromMap(e.value)..id = e.key).toList();
  }

  Future<int> saveAttendanceRecord(AttendanceRecord record) async {
    final map = _attendanceToMap(record);
    if (record.id == 0) {
      return await _attendanceStore.add(_database, map);
    } else {
      await _attendanceStore.record(record.id).put(_database, map);
      return record.id;
    }
  }

  // ==================== SERIALIZATION ====================

  Map<String, dynamic> _playerToMap(Player p) => {
    'nombre': p.nombre,
    'cedula': p.cedula,
    'fechaNacimiento': p.fechaNacimiento.millisecondsSinceEpoch,
    'numero': p.numero,
    'posicion': p.posicion.index,
    'esCapitan': p.esCapitan ? 1 : 0,
    'fotoUrl': p.fotoUrl ?? '',
    'estadoSalud': p.estadoSalud.index,
    'condicionFisica': p.condicionFisica,
    'createdAt': p.createdAt.millisecondsSinceEpoch,
  };

  Player _playerFromMap(Map<String, dynamic> map) => Player()
    ..nombre = map['nombre'] as String? ?? ''
    ..cedula = map['cedula'] as String? ?? ''
    ..fechaNacimiento = DateTime.fromMillisecondsSinceEpoch(map['fechaNacimiento'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..numero = map['numero'] as int? ?? 0
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
  };

  Match _matchFromMap(Map<String, dynamic> map) => Match()
    ..fecha = DateTime.fromMillisecondsSinceEpoch(map['fecha'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..equipoLocal = map['equipoLocal'] as String? ?? ''
    ..equipoVisitante = map['equipoVisitante'] as String? ?? ''
    ..puntosLocal = map['puntosLocal'] as int? ?? 0
    ..puntosVisitante = map['puntosVisitante'] as int? ?? 0
    ..setsLocal = map['setsLocal'] as int? ?? 0
    ..setsVisitante = map['setsVisitante'] as int? ?? 0
    ..setActual = map['setActual'] as int? ?? 1
    ..estado = EstadoPartido.values[map['estado'] as int? ?? 0]
    ..turnoLocal = (map['turnoLocal'] as int? ?? 1) == 1
    ..velocidadAnimacion = map['velocidadAnimacion'] as int? ?? 1000
    ..createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..tipoPartido = TipoPartido.values[map['tipoPartido'] as int? ?? 0]
    ..setsTotales = map['setsTotales'] as int? ?? 5
    ..resultadoFinal = (map['resultadoFinal'] as String?)?.isNotEmpty == true ? map['resultadoFinal'] as String? : null
    ..lugar = (map['lugar'] as String?)?.isNotEmpty == true ? map['lugar'] as String? : null;

  Map<String, dynamic> _attendanceToMap(AttendanceRecord r) => {
    'playerId': r.playerId,
    'fecha': r.fecha.millisecondsSinceEpoch,
    'asistio': r.asistio ? 1 : 0,
    'observaciones': r.observaciones,
  };

  AttendanceRecord _attendanceFromMap(Map<String, dynamic> map) => AttendanceRecord()
    ..playerId = map['playerId'] as int? ?? 0
    ..fecha = DateTime.fromMillisecondsSinceEpoch(map['fecha'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..asistio = (map['asistio'] as int? ?? 0) == 1
    ..observaciones = map['observaciones'] as String? ?? '';

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

  StatEvent _eventFromMap(Map<String, dynamic> map) => StatEvent()
    ..tipoAccion = TipoAccion.values[map['tipoAccion'] as int? ?? 0]
    ..resultado = ResultadoAccion.values[map['resultado'] as int? ?? 0]
    ..timestamp = DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..setNumero = map['setNumero'] as int? ?? 1
    ..puntoLocal = map['puntoLocal'] as int? ?? 0
    ..puntoVisitante = map['puntoVisitante'] as int? ?? 0
    ..esEquipoLocal = (map['esEquipoLocal'] as int? ?? 1) == 1
    ..zona = ZonaCancha.values[map['zona'] as int? ?? 0]
    ..descripcion = map['descripcion'] as String?
    ..playerId = map['playerId'] as int? ?? 0
    ..matchId = map['matchId'] as int? ?? 0
    ..createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch);
}
