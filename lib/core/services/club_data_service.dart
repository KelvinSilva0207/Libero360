import '../../features/estadisticas/data/models/player.dart';
import '../../features/estadisticas/data/models/season.dart';
import '../../features/estadisticas/data/models/match.dart';
import '../../features/estadisticas/data/models/stat_event.dart';
import '../../features/estadisticas/data/models/attendance_record.dart';
import '../../features/estadisticas/data/local_db/database_service.dart';
import '../../features/partido/data/match_event.dart';
import 'log_service.dart';

class ClubDataService {
  static final ClubDataService instance = ClubDataService._internal();
  ClubDataService._internal();

  final DatabaseService _db = DatabaseService.instance;
  final LogService _log = LogService.instance;

  // ==================== ATHLETES ====================

  Future<int> savePlayer(Player player) async {
    final id = await _db.savePlayer(player);
    await _log.auto('🟢 Atleta guardado local: ${player.displayName} (ID: $id)', source: 'ClubDataService');
    return id;
  }

  Future<List<Player>> getPlayers() async {
    return _db.getAllPlayers();
  }

  Future<void> deletePlayer(int playerId) async {
    await _db.deletePlayer(playerId);
    await _log.auto('🟡 Atleta eliminado local (ID: $playerId)', source: 'ClubDataService');
  }

  Stream<List<Player>> streamPlayers() {
    return _db.watchAllPlayers();
  }

  // ==================== MATCHES ====================

  Future<List<Match>> getMatches() async {
    return _db.getAllMatches();
  }

  Stream<List<Match>> streamMatches() {
    return _db.watchAllMatches();
  }

  Future<void> saveMatch(Match match) async {
    final id = await _db.saveMatch(match);
    await _log.auto('🟢 Partido guardado local (ID: $id)', source: 'ClubDataService');
  }

  Future<void> deleteMatch(int matchId) async {
    await _db.deleteMatch(matchId);
    await _log.auto('🟡 Partido eliminado local (ID: $matchId)', source: 'ClubDataService');
  }

  // ==================== STAT EVENTS ====================

  Future<int> saveStatEvent(StatEvent event) async {
    final id = await _db.saveStatEvent(event);
    await _log.auto('🟢 Evento estadístico guardado local (ID: $id)', source: 'ClubDataService');
    return id;
  }

  Future<void> deleteStatEvent(int eventId) async {
    await _db.deleteStatEvent(eventId);
    await _log.auto('🟡 Evento estadístico eliminado local (ID: $eventId)', source: 'ClubDataService');
  }

  Stream<List<StatEvent>> streamStatEvents() {
    return _db.watchAllEvents();
  }

  // ==================== MATCH EVENTS ====================

  Future<int> saveMatchEvent(MatchEvent event) async {
    final id = await _db.saveMatchEvent(event);
    await _log.auto('🟢 Evento de partido guardado local (ID: $id)', source: 'ClubDataService');
    return id;
  }

  Stream<List<MatchEvent>> streamMatchEvents() {
    return _db.watchAllMatchEvents();
  }

  // ==================== ATTENDANCE ====================

  Future<int> saveAttendance(AttendanceRecord record) async {
    final id = await _db.saveAttendanceRecord(record);
    await _log.auto('🟢 Asistencia guardada local (ID: $id)', source: 'ClubDataService');
    return id;
  }

  Future<void> deleteAttendance(int recordId) async {
    await _db.deleteAttendance(recordId);
    await _log.auto('🟡 Asistencia eliminada local (ID: $recordId)', source: 'ClubDataService');
  }

  Stream<List<AttendanceRecord>> streamAttendance() {
    return _db.watchAllAttendance();
  }

  // ==================== SEASONS ====================

  Future<int> saveSeason(Season season) async {
    final id = await _db.saveSeason(season);
    await _log.auto('🟢 Temporada guardada local: ${season.name}', source: 'ClubDataService');
    return id;
  }

  Stream<List<Season>> streamSeasons() {
    return _db.watchAllSeasons();
  }
}
