import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sembast/sembast.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/abstract_data_service.dart';
import '../../../../core/services/category_service.dart';
import '../models/models.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../partido/data/match_event.dart';
import 'package:intl/intl.dart';
import '../../../profiles/data/profile_model.dart';
import '../../../statistics/data/rotation_stats_model.dart';
import '../../../statistics/data/statistics_models.dart';
import '../../../staff_tecnico/data/staff_tecnico_models.dart';

class DatabaseService extends AbstractDataService {
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
  final _userStore = intMapStoreFactory.store('users');
  final _sessionStore = intMapStoreFactory.store('_session');
  final _seasonStore = intMapStoreFactory.store('seasons');
  final _matchEventStore = intMapStoreFactory.store('match_events');
  final _profileStore = intMapStoreFactory.store('profiles');
  final _profileMetaStore = intMapStoreFactory.store('profiles_meta');
  final _rotationStatsStore = intMapStoreFactory.store('rotation_stats');
  final _monthlyAwardStore = intMapStoreFactory.store('monthly_awards');
  final _staffStore = intMapStoreFactory.store('staff_members');
  final _staffInvitationStore = intMapStoreFactory.store('staff_invitations');
  final _staffActivityStore = intMapStoreFactory.store('staff_activities');
  final _medicalLeaveStore = intMapStoreFactory.store('medical_leaves');
  final _categoryStore = intMapStoreFactory.store('categories');

  Future<void> initialize() async {
    if (_isInitialized) return;
    final path = await databasePath;
    _db = await databaseFactory.openDatabase(path);
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

  Future<List<Player>> getAllPlayers({bool includeDeleted = true}) async {
    final snapshots = await _playerStore.find(
      _database,
      finder: Finder(sortOrders: [SortOrder('numero')]),
    );
    var players = snapshots.map((e) => _playerFromMap(e.value)..id = e.key).toList();
    if (!includeDeleted) {
      players = players.where((p) => !p.isDeleted).toList();
    }
    return players;
  }

  Future<Player?> getPlayerById(int id) async {
    final record = await _playerStore.record(id).get(_database);
    if (record == null) return null;
    return _playerFromMap(record)..id = id;
  }

  Future<Player?> getPlayer(int id) async {
    return getPlayerById(id);
  }

  Future<List<Player>> getActivePlayers() async {
    return getAllPlayers(includeDeleted: false);
  }

  Future<List<Player>> getDeletedPlayers() async {
    final snapshots = await _playerStore.find(_database);
    return snapshots
        .map((e) => _playerFromMap(e.value)..id = e.key)
        .where((p) => p.isDeleted)
        .toList();
  }

  Future<List<Player>> searchPlayers(String query) async {
    final all = await getAllPlayers(includeDeleted: false);
    final lower = query.toLowerCase();
    return all.where((p) =>
      p.displayName.toLowerCase().contains(lower) ||
      p.nombre.toLowerCase().contains(lower) ||
      (p.numero?.toString() ?? '').contains(lower) ||
      p.cedula.replaceAll('.', '').contains(lower)
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
    final snapshots = await _playerStore.find(
      _database,
      finder: Finder(filter: Filter.equals('posicion', posicion.index)),
    );
    return snapshots.map((e) => _playerFromMap(e.value)..id = e.key).toList();
  }

  Future<int> getPlayerCount() async {
    return await _playerStore.count(_database);
  }

  Future<List<Player>> getPlayers() async {
    return getAllPlayers();
  }

  // ==================== SEASONS ====================

  Future<List<Season>> getAllSeasons() async {
    final snapshots = await _seasonStore.find(
      _database,
      finder: Finder(sortOrders: [SortOrder('year', false)]),
    );
    return snapshots.map((e) => _seasonFromMap(e.value)..id = e.key).toList();
  }

  Future<Season?> getSeasonById(int id) async {
    final record = await _seasonStore.record(id).get(_database);
    if (record == null) return null;
    return _seasonFromMap(record)..id = id;
  }

  Future<int> saveSeason(Season season) async {
    final map = _seasonToMap(season);
    if (season.id == 0) {
      return await _seasonStore.add(_database, map);
    } else {
      await _seasonStore.record(season.id).put(_database, map);
      return season.id;
    }
  }

  Future<bool> deleteSeason(int id) async {
    await _matchStore.delete(
      _database,
      finder: Finder(filter: Filter.equals('seasonId', id)),
    );
    await _seasonStore.record(id).delete(_database);
    return true;
  }

  Future<Season?> getActiveSeason() async {
    final snapshots = await _seasonStore.find(
      _database,
      finder: Finder(filter: Filter.equals('isActive', 1)),
    );
    if (snapshots.isEmpty) return null;
    final e = snapshots.first;
    return _seasonFromMap(e.value)..id = e.key;
  }

  Future<void> setActiveSeason(int id) async {
    final all = await _seasonStore.find(_database);
    for (final record in all) {
      await _seasonStore.record(record.key).put(_database, {
        ...record.value,
        'isActive': record.key == id ? 1 : 0,
      });
    }
  }

  Future<List<Match>> getMatchesBySeason(int seasonId) async {
    final snapshots = await _matchStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('seasonId', seasonId),
        sortOrders: [SortOrder('createdAt', false)],
      ),
    );
    return snapshots.map((e) => _matchFromMap(e.value)..id = e.key).toList();
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

  Future<int> getMatchCount() async {
    return await _matchStore.count(_database);
  }

  // ==================== STREAMS (REACTIVE) ====================

  Stream<List<Player>> watchAllPlayers({bool includeDeleted = false}) {
    return _playerStore.query().onSnapshots(_database).map(
      (snapshots) => snapshots
          .map((e) => _playerFromMap(e.value)..id = e.key)
          .where((p) => includeDeleted || !p.isDeleted)
          .toList(),
    );
  }

  Stream<List<Match>> watchMatchesByState(EstadoPartido estado) {
    return _matchStore.query(
      finder: Finder(
        filter: Filter.equals('estado', estado.index),
        sortOrders: [SortOrder('createdAt', false)],
      ),
    ).onSnapshots(_database).map(
      (snapshots) => snapshots.map((e) => _matchFromMap(e.value)..id = e.key).toList(),
    );
  }

  // ==================== STAT EVENTS (OPTIMIZED) ====================

  Future<List<StatEvent>> getAllEvents() async {
    final snapshots = await _eventStore.find(_database);
    return snapshots.map((e) => _eventFromMap(e.value)..id = e.key).toList();
  }

  Future<List<StatEvent>> getEventsByMatch(int matchId) async {
    final snapshots = await _eventStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('matchId', matchId),
        sortOrders: [SortOrder('timestamp')],
      ),
    );
    return snapshots.map((e) => _eventFromMap(e.value)..id = e.key).toList();
  }

  Future<List<StatEvent>> getEventsByPlayer(int playerId) async {
    final snapshots = await _eventStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('playerId', playerId),
        sortOrders: [SortOrder('timestamp', false)],
      ),
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

  Future<List<StatEvent>> getEventsByMatchAndType(int matchId, TipoAccion tipo) async {
    final snapshots = await _eventStore.find(
      _database,
      finder: Finder(filter: Filter.and([
        Filter.equals('matchId', matchId),
        Filter.equals('tipoAccion', tipo.index),
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
    return await _eventStore.delete(
      _database,
      finder: Finder(filter: Filter.equals('matchId', matchId)),
    );
  }

  Future<int> countEventsByType(int matchId, TipoAccion tipo) async {
    return await _eventStore.count(
      _database,
      filter: Filter.and([
        Filter.equals('matchId', matchId),
        Filter.equals('tipoAccion', tipo.index),
      ]),
    );
  }

  Future<Map<TipoAccion, int>> countAllEventTypes(int matchId) async {
    final events = await getEventsByMatch(matchId);
    final counts = <TipoAccion, int>{};
    for (final event in events) {
      counts[event.tipoAccion] = (counts[event.tipoAccion] ?? 0) + 1;
    }
    return counts;
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
      finder: Finder(
        filter: Filter.equals('playerId', playerId),
        sortOrders: [SortOrder('fecha', false)],
      ),
    );
    return snapshots.map((e) => _attendanceFromMap(e.value)..id = e.key).toList();
  }

  Future<List<AttendanceRecord>> getAttendanceByPlayerAndDateRange(
    int playerId, DateTime start, DateTime end,
  ) async {
    final snapshots = await _attendanceStore.find(
      _database,
      finder: Finder(filter: Filter.and([
        Filter.equals('playerId', playerId),
        Filter.greaterThanOrEquals('fecha', start.millisecondsSinceEpoch),
        Filter.lessThan('fecha', end.millisecondsSinceEpoch),
      ])),
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

  // ==================== MATCH EVENTS ====================

  Future<List<MatchEvent>> getMatchEvents(int matchId) async {
    final snapshots = await _matchEventStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('matchId', matchId),
        sortOrders: [SortOrder('fecha')],
      ),
    );
    return snapshots.map((e) => _matchEventFromMap(e.value)..id = e.key).toList();
  }

  Future<List<MatchEvent>> getAllMatchEvents() async {
    final snapshots = await _matchEventStore.find(_database);
    return snapshots.map((e) => _matchEventFromMap(e.value)..id = e.key).toList();
  }

  Future<int> saveMatchEvent(MatchEvent event) async {
    final map = _matchEventToMap(event);
    if (event.id == 0) {
      return await _matchEventStore.add(_database, map);
    } else {
      await _matchEventStore.record(event.id).put(_database, map);
      return event.id;
    }
  }

  // ==================== ROTATION STATS ====================

  Future<void> saveRotationStatsRecords(List<RotationStatsRecord> records) async {
    await _rotationStatsStore.delete(_database);
    for (final r in records) {
      await _rotationStatsStore.add(_database, _rotationStatsToMap(r));
    }
  }

  Future<List<RotationStatsRecord>> getAllRotationStatsRecords() async {
    final snapshots = await _rotationStatsStore.find(_database);
    return snapshots.map((e) => _rotationStatsFromMap(e.value)..id = e.key).toList();
  }

  Future<void> deleteRotationStatsByMatch(int matchId) async {
    await _rotationStatsStore.delete(
      _database,
      finder: Finder(filter: Filter.equals('matchId', matchId)),
    );
  }

  Map<String, dynamic> _rotationStatsToMap(RotationStatsRecord r) => {
    'matchId': r.matchId,
    'setNumber': r.setNumber,
    'rotationIndex': r.rotationIndex,
    'pointsWon': r.pointsWon,
    'pointsLost': r.pointsLost,
    'serverPlayerNumber': r.serverPlayerNumber,
    'playerSlots': r.playerSlots,
  };

  RotationStatsRecord _rotationStatsFromMap(Map<String, dynamic> map) => RotationStatsRecord(
    matchId: map['matchId'] as int? ?? 0,
    setNumber: map['setNumber'] as int? ?? 1,
    rotationIndex: map['rotationIndex'] as int? ?? 0,
    pointsWon: map['pointsWon'] as int? ?? 0,
    pointsLost: map['pointsLost'] as int? ?? 0,
    serverPlayerNumber: map['serverPlayerNumber'] as int? ?? 0,
    playerSlots: (map['playerSlots'] as List?)?.cast<int>() ?? [],
  );

  // ==================== MONTHLY AWARDS ====================

  Future<List<AthleteMonthlyAward>> getAllMonthlyAwards() async {
    final snapshots = await _monthlyAwardStore.find(
      _database,
      finder: Finder(sortOrders: [
        SortOrder('year', false),
        SortOrder('month', false),
        SortOrder('rank'),
      ]),
    );
    return snapshots.map((e) => _monthlyAwardFromMap(e.value)..id = e.key).toList();
  }

  Future<List<AthleteMonthlyAward>> getMonthlyAwardsByYearMonth(int year, int month) async {
    final snapshots = await _monthlyAwardStore.find(
      _database,
      finder: Finder(filter: Filter.and([
        Filter.equals('year', year),
        Filter.equals('month', month),
      ])),
    );
    return snapshots.map((e) => _monthlyAwardFromMap(e.value)..id = e.key).toList();
  }

  Future<int> saveMonthlyAward(AthleteMonthlyAward award) async {
    final map = _monthlyAwardToMap(award);
    if (award.id == 0) {
      return await _monthlyAwardStore.add(_database, map);
    } else {
      await _monthlyAwardStore.record(award.id).put(_database, map);
      return award.id;
    }
  }

  Future<bool> deleteMonthlyAward(int id) async {
    await _monthlyAwardStore.record(id).delete(_database);
    return true;
  }

  Map<String, dynamic> _monthlyAwardToMap(AthleteMonthlyAward a) => {
    'playerId': a.playerId,
    'year': a.year,
    'month': a.month,
    'score': a.score,
    'rank': a.rank,
    'awardedAt': a.awardedAt.millisecondsSinceEpoch,
    'profileId': a.profileId,
    'clubId': a.clubId,
  };

  AthleteMonthlyAward _monthlyAwardFromMap(Map<String, dynamic> map) => AthleteMonthlyAward(
    playerId: map['playerId'] as int? ?? 0,
    year: map['year'] as int? ?? DateTime.now().year,
    month: map['month'] as int? ?? DateTime.now().month,
    score: (map['score'] as num?)?.toDouble() ?? 0,
    rank: map['rank'] as int? ?? 1,
    awardedAt: DateTime.fromMillisecondsSinceEpoch(map['awardedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    profileId: map['profileId'] as String?,
    clubId: map['clubId'] as String?,
  );

  // ==================== STAFF ====================

  Future<List<StaffMember>> getAllStaffMembers() async {
    final snapshots = await _staffStore.find(
      _database,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)]),
    );
    return snapshots.map((e) => _staffFromMap(e.value)..id = e.key).toList();
  }

  Future<int> saveStaffMember(StaffMember member) async {
    final map = _staffToMap(member);
    if (member.id == 0) {
      return await _staffStore.add(_database, map);
    } else {
      await _staffStore.record(member.id).put(_database, map);
      return member.id;
    }
  }

  Future<bool> deleteStaffMember(int id) async {
    await _staffStore.record(id).delete(_database);
    return true;
  }

  Future<int> countActiveStaff() async {
    final all = await getAllStaffMembers();
    return all.where((m) => m.isActive).length;
  }

  Future<List<StaffMember>> getStaffByProfile(String profileId) async {
    final snapshots = await _staffStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('profileId', profileId),
        sortOrders: [SortOrder('createdAt', false)],
      ),
    );
    return snapshots.map((e) => _staffFromMap(e.value)..id = e.key).toList();
  }

  Future<int> countStaffByProfile(String profileId) async {
    final all = await getStaffByProfile(profileId);
    return all.where((m) => m.isActive).length;
  }

  Future<List<StaffInvitation>> getAllStaffInvitations() async {
    final snapshots = await _staffInvitationStore.find(
      _database,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)]),
    );
    return snapshots.map((e) => _invitationFromMap(e.value)..id = e.key).toList();
  }

  Future<int> saveStaffInvitation(StaffInvitation invitation) async {
    final map = _invitationToMap(invitation);
    if (invitation.id == 0) {
      return await _staffInvitationStore.add(_database, map);
    } else {
      await _staffInvitationStore.record(invitation.id).put(_database, map);
      return invitation.id;
    }
  }

  Future<bool> deleteStaffInvitation(int id) async {
    await _staffInvitationStore.record(id).delete(_database);
    return true;
  }

  Future<List<StaffInvitation>> getInvitationsByProfile(String profileId) async {
    final snapshots = await _staffInvitationStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('profileId', profileId),
        sortOrders: [SortOrder('createdAt', false)],
      ),
    );
    return snapshots.map((e) => _invitationFromMap(e.value)..id = e.key).toList();
  }

  Future<List<StaffActivity>> getAllStaffActivity({int limit = 20}) async {
    final snapshots = await _staffActivityStore.find(
      _database,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)], limit: limit),
    );
    return snapshots.map((e) => _activityFromMap(e.value)..id = e.key).toList();
  }

  Future<int> saveStaffActivity(StaffActivity activity) async {
    final map = _activityToMap(activity);
    if (activity.id == 0) {
      return await _staffActivityStore.add(_database, map);
    } else {
      await _staffActivityStore.record(activity.id).put(_database, map);
      return activity.id;
    }
  }

  Future<List<StaffActivity>> getActivityByProfile(String profileId, {int limit = 20}) async {
    final snapshots = await _staffActivityStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('profileId', profileId),
        sortOrders: [SortOrder('createdAt', false)],
        limit: limit,
      ),
    );
    return snapshots.map((e) => _activityFromMap(e.value)..id = e.key).toList();
  }

  Map<String, dynamic> _staffToMap(StaffMember m) => {
    'nombre': m.nombre,
    'correo': m.correo,
    'fotoUrl': m.fotoUrl ?? '',
    'role': m.role.index,
    'status': m.status.index,
    'profileId': m.profileId,
    'clubId': m.clubId,
    'createdAt': m.createdAt.millisecondsSinceEpoch,
    'createdBy': m.createdBy ?? '',
  };

  StaffMember _staffFromMap(Map<String, dynamic> map) => StaffMember(
    nombre: map['nombre'] as String? ?? '',
    correo: map['correo'] as String? ?? '',
    fotoUrl: (map['fotoUrl'] as String?)?.isNotEmpty == true ? map['fotoUrl'] as String? : null,
    role: StaffRole.values[map['role'] as int? ?? 1],
    status: StaffStatus.values[map['status'] as int? ?? 0],
    profileId: map['profileId'] as String?,
    clubId: map['clubId'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    createdBy: (map['createdBy'] as String?)?.isNotEmpty == true ? map['createdBy'] as String? : null,
  );

  Map<String, dynamic> _invitationToMap(StaffInvitation i) => {
    'email': i.email,
    'role': i.role.index,
    'status': i.status,
    'createdAt': i.createdAt.millisecondsSinceEpoch,
    'createdBy': i.createdBy ?? '',
    'profileId': i.profileId,
    'clubId': i.clubId,
  };

  StaffInvitation _invitationFromMap(Map<String, dynamic> map) => StaffInvitation(
    email: map['email'] as String? ?? '',
    role: StaffRole.values[map['role'] as int? ?? 1],
    status: map['status'] as String? ?? 'pending',
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    createdBy: (map['createdBy'] as String?)?.isNotEmpty == true ? map['createdBy'] as String? : null,
    profileId: map['profileId'] as String?,
    clubId: map['clubId'] as String?,
  );

  Map<String, dynamic> _activityToMap(StaffActivity a) => {
    'type': a.type.index,
    'message': a.message,
    'createdBy': a.createdBy,
    'createdAt': a.createdAt.millisecondsSinceEpoch,
    'profileId': a.profileId,
    'clubId': a.clubId,
  };

  StaffActivity _activityFromMap(Map<String, dynamic> map) => StaffActivity(
    type: ActivityType.values[map['type'] as int? ?? 0],
    message: map['message'] as String? ?? '',
    createdBy: map['createdBy'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    profileId: map['profileId'] as String?,
    clubId: map['clubId'] as String?,
  );

  // ==================== PROFILES ====================

  Future<List<ProfileModel>> getAllProfiles() async {
    final snapshots = await _profileStore.find(_database);
    return snapshots.map((e) => ProfileModel.fromJson(e.value)).toList();
  }

  Future<void> addProfile(ProfileModel profile) async {
    await _profileStore.add(_database, profile.toJson());
  }

  Future<void> updateProfile(ProfileModel profile) async {
    final records = await _profileStore.find(
      _database,
      finder: Finder(filter: Filter.equals('id', profile.id)),
    );
    for (final r in records) {
      await _profileStore.record(r.key).update(_database, profile.toJson());
    }
  }

  Future<void> deleteProfile(String id) async {
    await _profileStore.delete(
      _database,
      finder: Finder(filter: Filter.equals('id', id)),
    );
  }

  Future<String?> getActiveProfileId() async {
    final records = await _profileMetaStore.find(
      _database,
      finder: Finder(filter: Filter.equals('key', 'activeProfileId')),
    );
    if (records.isEmpty) return null;
    return records.first.value['value'] as String?;
  }

  Future<void> setActiveProfileId(String? id) async {
    await _profileMetaStore.delete(
      _database,
      finder: Finder(filter: Filter.equals('key', 'activeProfileId')),
    );
    if (id != null) {
      await _profileMetaStore.add(_database, {'key': 'activeProfileId', 'value': id});
    }
  }

  // ==================== MULTI-PROFILE QUERIES ====================

  Future<List<Player>> getPlayersByProfile(String? profileId) async {
    if (profileId == null) return getAllPlayers();
    final snapshots = await _playerStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('profileId', profileId),
        sortOrders: [SortOrder('numero')],
      ),
    );
    return snapshots.map((e) => _playerFromMap(e.value)..id = e.key).toList();
  }

  Future<List<Match>> getMatchesByProfile(String? profileId) async {
    if (profileId == null) return getAllMatches();
    final snapshots = await _matchStore.find(
      _database,
      finder: Finder(
        filter: Filter.equals('profileId', profileId),
        sortOrders: [SortOrder('createdAt', false)],
      ),
    );
    return snapshots.map((e) => _matchFromMap(e.value)..id = e.key).toList();
  }

  Future<List<AttendanceRecord>> getAttendanceByProfile(String? profileId) async {
    if (profileId == null) return getAllAttendanceRecords();
    final snapshots = await _attendanceStore.find(
      _database,
      finder: Finder(filter: Filter.equals('profileId', profileId)),
    );
    return snapshots.map((e) => _attendanceFromMap(e.value)..id = e.key).toList();
  }

  Future<List<StatEvent>> getStatsByProfile(String? profileId) async {
    if (profileId == null) return getAllEvents();
    final snapshots = await _eventStore.find(
      _database,
      finder: Finder(filter: Filter.equals('profileId', profileId)),
    );
    return snapshots.map((e) => _eventFromMap(e.value)..id = e.key).toList();
  }

  // ==================== ORPHAN HELPERS ====================

  Future<Map<String, int>> countOrphanRecords() async {
    final orphans = <String, int>{};
    orphans['players'] = await _playerStore.count(_database, filter: Filter.equals('profileId', null));
    orphans['matches'] = await _matchStore.count(_database, filter: Filter.equals('profileId', null));
    orphans['attendance'] = await _attendanceStore.count(_database, filter: Filter.equals('profileId', null));
    orphans['events'] = await _eventStore.count(_database, filter: Filter.equals('profileId', null));
    orphans['matchEvents'] = await _matchEventStore.count(_database, filter: Filter.equals('profileId', null));
    return orphans;
  }

  Future<void> assignOrphansToProfile(String profileId, String clubId) async {
    for (final store in [_playerStore, _matchStore, _attendanceStore, _eventStore, _matchEventStore]) {
      final records = await store.find(
        _database,
        finder: Finder(filter: Filter.equals('profileId', null)),
      );
      for (final r in records) {
        await store.record(r.key).put(_database, {
          ...r.value,
          'profileId': profileId,
          'clubId': clubId,
        });
      }
    }
  }

  // ==================== ATTENDANCE ALIAS ====================

  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    return getAllAttendanceRecords();
  }

  // ==================== USERS ====================

  Future<List<AppUser>> getAllUsers() async {
    final snapshots = await _userStore.find(_database);
    return snapshots.map((e) => _userFromMap(e.value)..id = e.key).toList();
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final snapshots = await _userStore.find(
      _database,
      finder: Finder(filter: Filter.equals('email', email)),
    );
    if (snapshots.isEmpty) return null;
    final e = snapshots.first;
    return _userFromMap(e.value)..id = e.key;
  }

  Future<AppUser?> getUserById(int id) async {
    final record = await _userStore.record(id).get(_database);
    if (record == null) return null;
    return _userFromMap(record)..id = id;
  }

  Future<int> saveUser(AppUser user) async {
    final map = _userToMap(user);
    if (user.id == 0) {
      return await _userStore.add(_database, map);
    } else {
      await _userStore.record(user.id).put(_database, map);
      return user.id;
    }
  }

  Future<bool> deleteUser(int id) async {
    await _userStore.record(id).delete(_database);
    return true;
  }

  // ==================== SESSION ====================

  Future<void> saveSessionUserId(int userId) async {
    await _sessionStore.record(0).put(_database, {'userId': userId});
  }

  Future<int?> getSessionUserId() async {
    final record = await _sessionStore.record(0).get(_database);
    if (record == null) return null;
    return record['userId'] as int?;
  }

  Future<void> clearSession() async {
    await _sessionStore.record(0).delete(_database);
  }

  // ==================== BACKUP & RESTORE ====================

  Future<String?> exportToJson({String? appVersion, String? devicePlatform}) async {
    final _appVersion = appVersion ?? '1.0.0';
    final _devicePlatform = devicePlatform ?? 'unknown';
    final now = DateTime.now();

    // Integrity-verified data collection
    List<Map<String, dynamic>> players;
    try {
      players = (await getAllPlayers()).map(_playerToMap).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> matches;
    try {
      matches = (await getAllMatches()).map(_matchToMap).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> events;
    try {
      events = (await getAllEvents()).map(_eventToMap).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> attendance;
    try {
      attendance = (await getAllAttendanceRecords()).map(_attendanceToMap).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> matchEvents;
    try {
      matchEvents = (await getAllMatchEvents()).map(_matchEventToMap).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> profiles;
    try {
      profiles = (await getAllProfiles()).map((p) => p.toJson()).toList();
    } catch (_) { return null; }

    String? activeProfileId;
    try {
      activeProfileId = await getActiveProfileId();
    } catch (_) { return null; }

    List<Map<String, dynamic>> users;
    try {
      users = (await getAllUsers()).map(_userToMap).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> seasons;
    try {
      seasons = (await getAllSeasons()).map(_seasonToMap).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> rotationStats;
    try {
      rotationStats = (await getAllRotationStatsRecords()).map(_rotationStatsToMap).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> monthlyAwards;
    try {
      monthlyAwards = (await getAllMonthlyAwards()).map(_monthlyAwardToMap).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> medicalLeaves;
    try {
      medicalLeaves = (await _medicalLeaveStore.find(_database)).map((e) => e.value).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> staff;
    try {
      staff = (await _staffStore.find(_database)).map((e) => e.value).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> staffInvitations;
    try {
      staffInvitations = (await _staffInvitationStore.find(_database)).map((e) => e.value).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> staffActivities;
    try {
      staffActivities = (await _staffActivityStore.find(_database)).map((e) => e.value).toList();
    } catch (_) { return null; }

    List<Map<String, dynamic>> categories;
    try {
      categories = (await _categoryStore.find(_database)).map((e) => e.value).toList();
    } catch (_) { return null; }

    // Build data map without checksum
    final data = {
      'version': '2.0.0',
      'appVersion': _appVersion,
      'schemaVersion': '2.0.0',
      'createdAt': now.toIso8601String(),
      'devicePlatform': _devicePlatform,
      'databaseVersion': '1.0.0',
      'totalPlayers': players.length,
      'totalMatches': matches.length,
      'totalEvents': events.length,
      'totalAttendance': attendance.length,
      'totalMatchEvents': matchEvents.length,
      'totalProfiles': profiles.length,
      'totalUsers': users.length,
      'totalSeasons': seasons.length,
      'totalRotationStats': rotationStats.length,
      'totalMonthlyAwards': monthlyAwards.length,
      'totalMedicalLeaves': medicalLeaves.length,
      'totalStaff': staff.length,
      'totalStaffInvitations': staffInvitations.length,
      'totalStaffActivities': staffActivities.length,
      'totalCategories': categories.length,
      'players': players,
      'matches': matches,
      'events': events,
      'attendance': attendance,
      'matchEvents': matchEvents,
      'profiles': profiles,
      'profilesMeta': {'activeProfileId': activeProfileId},
      'users': users,
      'seasons': seasons,
      'rotationStats': rotationStats,
      'monthlyAwards': monthlyAwards,
      'medicalLeaves': medicalLeaves,
      'staffMembers': staff,
      'staffInvitations': staffInvitations,
      'staffActivities': staffActivities,
      'categories': categories,
    };

    final preChecksumJson = const JsonEncoder.withIndent('  ').convert(data);
    final checksum = sha256.convert(utf8.encode(preChecksumJson)).toString();
    data['checksum'] = checksum;

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      await clearAllData();

      for (final p in (data['players'] as List? ?? [])) {
        await _playerStore.add(_database, p as Map<String, dynamic>);
      }
      for (final m in (data['matches'] as List? ?? [])) {
        await _matchStore.add(_database, m as Map<String, dynamic>);
      }
      for (final e in (data['events'] as List? ?? [])) {
        await _eventStore.add(_database, e as Map<String, dynamic>);
      }
      for (final a in (data['attendance'] as List? ?? [])) {
        await _attendanceStore.add(_database, a as Map<String, dynamic>);
      }
      for (final p in (data['profiles'] as List? ?? [])) {
        await _profileStore.add(_database, p as Map<String, dynamic>);
      }
      final meta = data['profilesMeta'] as Map<String, dynamic>?;
      if (meta != null && meta['activeProfileId'] != null) {
        await setActiveProfileId(meta['activeProfileId'] as String);
      }
      for (final u in (data['users'] as List? ?? [])) {
        await _userStore.add(_database, u as Map<String, dynamic>);
      }
      for (final s in (data['seasons'] as List? ?? [])) {
        await _seasonStore.add(_database, s as Map<String, dynamic>);
      }
      for (final me in (data['matchEvents'] as List? ?? [])) {
        await _matchEventStore.add(_database, me as Map<String, dynamic>);
      }
      for (final rs in (data['rotationStats'] as List? ?? [])) {
        await _rotationStatsStore.add(_database, rs as Map<String, dynamic>);
      }
      for (final ma in (data['monthlyAwards'] as List? ?? [])) {
        await _monthlyAwardStore.add(_database, ma as Map<String, dynamic>);
      }
      for (final ml in (data['medicalLeaves'] as List? ?? [])) {
        await _medicalLeaveStore.add(_database, ml as Map<String, dynamic>);
      }
      for (final sm in (data['staffMembers'] as List? ?? [])) {
        await _staffStore.add(_database, sm as Map<String, dynamic>);
      }
      for (final si in (data['staffInvitations'] as List? ?? [])) {
        await _staffInvitationStore.add(_database, si as Map<String, dynamic>);
      }
      for (final sa in (data['staffActivities'] as List? ?? [])) {
        await _staffActivityStore.add(_database, sa as Map<String, dynamic>);
      }
      for (final c in (data['categories'] as List? ?? [])) {
        await _categoryStore.add(_database, c as Map<String, dynamic>);
      }
      await CategoryService.instance.reload();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> generateMatchReport(int matchId) async {
    final match = await getMatchById(matchId);
    if (match == null) return 'Partido no encontrado';

    final events = await getEventsByMatch(matchId);
    final players = await getAllPlayers();
    final playerMap = {for (final p in players) p.id: p};

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final buf = StringBuffer();
    buf.writeln('=== LIBERO360 - REPORTE DE PARTIDO ===\n');
    buf.writeln('Fecha: ${dateFormat.format(match.fecha)}');
    buf.writeln('${match.equipoLocal} vs ${match.equipoVisitante}');
    buf.writeln('Resultado: ${match.puntosLocal} - ${match.puntosVisitante}');
    buf.writeln('Sets: ${match.setsLocal} - ${match.setsVisitante}');
    buf.writeln('Estado: ${match.estado.name}\n');

    buf.writeln('--- ESTADÍSTICAS POR JUGADORA ---');
    for (final event in events) {
      final player = playerMap[event.playerId];
      final name = player?.nombre ?? 'Jugadora #${event.playerId}';
      buf.writeln('$name | ${event.tipoAccion.name} | Set ${event.setNumero} | ${event.resultado.name}');
    }

    buf.writeln('\n--- RESUMEN ---');
    final counts = await countAllEventTypes(matchId);
    counts.forEach((tipo, count) {
      buf.writeln('${tipo.name}: $count');
    });

    return buf.toString();
  }

  // ==================== CLEANUP ====================

  Future<void> clearAllData() async {
    await _playerStore.delete(_database);
    await _matchStore.delete(_database);
    await _eventStore.delete(_database);
    await _attendanceStore.delete(_database);
    await _userStore.delete(_database);
    await _sessionStore.delete(_database);
    await _seasonStore.delete(_database);
    await _matchEventStore.delete(_database);
    await _profileStore.delete(_database);
    await _profileMetaStore.delete(_database);
    await _rotationStatsStore.delete(_database);
    await _monthlyAwardStore.delete(_database);
    await _medicalLeaveStore.delete(_database);
    await _staffStore.delete(_database);
    await _staffInvitationStore.delete(_database);
    await _staffActivityStore.delete(_database);
    await _categoryStore.delete(_database);
  }

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
    'profileId': p.profileId,
    'clubId': p.clubId,
    'createdAt': p.createdAt.millisecondsSinceEpoch,
    'sexo': p.sexo.index,
    'altura': p.altura,
    'tipoSangre': p.tipoSangre.index,
    'manoDominante': p.manoDominante.index,
    'posicionSecundaria': p.posicionSecundaria.index,
    'fechaIngreso': p.fechaIngreso.millisecondsSinceEpoch,
    'atletaStatus': p.atletaStatus.index,
    'statusReason': p.statusReason ?? '',
    'statusStartDate': p.statusStartDate?.millisecondsSinceEpoch,
    'statusEndDate': p.statusEndDate?.millisecondsSinceEpoch,
    'isDeleted': p.isDeleted ? 1 : 0,
    'deletedAt': p.deletedAt?.millisecondsSinceEpoch,
    'deletedBy': p.deletedBy ?? '',
    'deletionReason': p.deletionReason ?? '',
  };

  Player _playerFromMap(Map<String, dynamic> map) => Player()
    ..nombre = map['nombre'] as String? ?? ''
    ..firstNames = map['firstNames'] as String? ?? (map['nombre'] as String? ?? '')
    ..lastNames = map['lastNames'] as String? ?? ''
    ..displayName = map['displayName'] as String? ?? (map['nombre'] as String? ?? '')
    ..cedula = map['cedula'] as String? ?? ''
    ..fechaNacimiento = DateTime.fromMillisecondsSinceEpoch(map['fechaNacimiento'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..numero = map['numero'] as int?
    ..posicion = Posicion.values[map['posicion'] as int? ?? 0]
    ..esCapitan = (map['esCapitan'] as int? ?? 0) == 1
    ..fotoUrl = (map['fotoUrl'] as String?)?.isNotEmpty == true ? map['fotoUrl'] as String? : null
    ..estadoSalud = EstadoSalud.values[map['estadoSalud'] as int? ?? 0]
    ..condicionFisica = map['condicionFisica'] as String? ?? 'Excelente'
    ..profileId = map['profileId'] as String?
    ..clubId = map['clubId'] as String?
    ..createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..sexo = Sexo.values[map['sexo'] as int? ?? 0]
    ..altura = (map['altura'] as num?)?.toDouble() ?? 0
    ..tipoSangre = TipoSangre.values[map['tipoSangre'] as int? ?? 3]
    ..manoDominante = ManoDominante.values[map['manoDominante'] as int? ?? 0]
    ..posicionSecundaria = Posicion.values[map['posicionSecundaria'] as int? ?? 5]
    ..fechaIngreso = DateTime.fromMillisecondsSinceEpoch(map['fechaIngreso'] as int? ?? map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..atletaStatus = AthleteStatus.values[map['atletaStatus'] as int? ?? 0]
    ..statusReason = (map['statusReason'] as String?)?.isNotEmpty == true ? map['statusReason'] as String? : null
    ..statusStartDate = map['statusStartDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['statusStartDate'] as int) : null
    ..statusEndDate = map['statusEndDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['statusEndDate'] as int) : null
    ..isDeleted = (map['isDeleted'] as int? ?? 0) == 1
    ..deletedAt = map['deletedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deletedAt'] as int) : null
    ..deletedBy = (map['deletedBy'] as String?)?.isNotEmpty == true ? map['deletedBy'] as String? : null
    ..deletionReason = (map['deletionReason'] as String?)?.isNotEmpty == true ? map['deletionReason'] as String? : null;

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
    'puntosParaGanarSet': m.puntosParaGanarSet,
    'puntosDiferenciaSet': m.puntosDiferenciaSet,
    'ultimoPuntoFueLocal': m.ultimoPuntoFueLocal ? 1 : 0,
    'resultadoFinal': m.resultadoFinal ?? '',
    'lugar': m.lugar ?? '',
    'competitionName': m.competitionName ?? '',
    'seasonId': m.seasonId ?? 0,
    'profileId': m.profileId,
    'clubId': m.clubId,
    'duracionSegundos': m.duracionSegundos,
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
    ..puntosParaGanarSet = map['puntosParaGanarSet'] as int? ?? 25
    ..puntosDiferenciaSet = map['puntosDiferenciaSet'] as int? ?? 2
    ..ultimoPuntoFueLocal = (map['ultimoPuntoFueLocal'] as int? ?? 1) == 1
    ..resultadoFinal = (map['resultadoFinal'] as String?)?.isNotEmpty == true ? map['resultadoFinal'] as String? : null
    ..lugar = (map['lugar'] as String?)?.isNotEmpty == true ? map['lugar'] as String? : null
    ..competitionName = (map['competitionName'] as String?)?.isNotEmpty == true ? map['competitionName'] as String? : null
    ..seasonId = map['seasonId'] as int? ?? 0
    ..profileId = map['profileId'] as String?
    ..clubId = map['clubId'] as String?
    ..duracionSegundos = map['duracionSegundos'] as int? ?? 0;

  Map<String, dynamic> _attendanceToMap(AttendanceRecord r) => {
    'playerId': r.playerId,
    'profileId': r.profileId,
    'clubId': r.clubId,
    'fecha': r.fecha.millisecondsSinceEpoch,
    'asistio': r.asistio ? 1 : 0,
    'observaciones': r.observaciones,
  };

  AttendanceRecord _attendanceFromMap(Map<String, dynamic> map) => AttendanceRecord()
    ..playerId = map['playerId'] as int? ?? 0
    ..profileId = map['profileId'] as String?
    ..clubId = map['clubId'] as String?
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
    'profileId': e.profileId,
    'clubId': e.clubId,
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
    ..profileId = map['profileId'] as String?
    ..clubId = map['clubId'] as String?
    ..createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch);

  Map<String, dynamic> _userToMap(AppUser u) => {
    'nombre': u.nombre,
    'email': u.email,
    'password': u.password,
    'fechaRegistro': u.fechaRegistro.millisecondsSinceEpoch,
  };

  AppUser _userFromMap(Map<String, dynamic> map) => AppUser(
    nombre: map['nombre'] as String? ?? '',
    email: map['email'] as String? ?? '',
    password: map['password'] as String? ?? '',
    fechaRegistro: DateTime.fromMillisecondsSinceEpoch(map['fechaRegistro'] as int? ?? DateTime.now().millisecondsSinceEpoch),
  );

  Map<String, dynamic> _seasonToMap(Season s) => {
    'name': s.name,
    'year': s.year,
    'isActive': s.isActive ? 1 : 0,
    'startDate': s.startDate.millisecondsSinceEpoch,
    'endDate': s.endDate?.millisecondsSinceEpoch,
    'createdAt': s.createdAt.millisecondsSinceEpoch,
  };

  Map<String, dynamic> _matchEventToMap(MatchEvent e) => {
    'athleteId': e.athleteId,
    'matchId': e.matchId,
    'profileId': e.profileId,
    'clubId': e.clubId,
    'fecha': e.fecha.millisecondsSinceEpoch,
    'setNumero': e.setNumero,
    'eventType': e.eventType.index,
    'tipoPartido': e.tipoPartido,
    'competenciaNombre': e.competenciaNombre ?? '',
    'rotacion': e.rotacion,
  };

  MatchEvent _matchEventFromMap(Map<String, dynamic> map) => MatchEvent()
    ..athleteId = map['athleteId'] as int? ?? 0
    ..matchId = map['matchId'] as int? ?? 0
    ..profileId = map['profileId'] as String?
    ..clubId = map['clubId'] as String?
    ..fecha = DateTime.fromMillisecondsSinceEpoch(map['fecha'] as int? ?? DateTime.now().millisecondsSinceEpoch)
    ..setNumero = map['setNumero'] as int? ?? 1
    ..eventType = EventType.values[map['eventType'] as int? ?? 1]
    ..tipoPartido = map['tipoPartido'] as String? ?? ''
    ..competenciaNombre = (map['competenciaNombre'] as String?)?.isNotEmpty == true ? map['competenciaNombre'] as String? : null
    ..rotacion = map['rotacion'] as int? ?? 0;

  Season _seasonFromMap(Map<String, dynamic> map) => Season(
    name: map['name'] as String? ?? '',
    year: map['year'] as int? ?? DateTime.now().year,
    isActive: (map['isActive'] as int? ?? 0) == 1,
    startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    endDate: map['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int) : null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
  );
}
