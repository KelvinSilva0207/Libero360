import '../../features/estadisticas/data/models/player.dart';
import '../../features/estadisticas/data/models/match.dart';
import '../../features/estadisticas/data/models/stat_event.dart';
import '../../features/estadisticas/data/models/attendance_record.dart';
import '../../features/estadisticas/data/models/season.dart';
import '../../features/auth/data/models/user_model.dart';

abstract class AbstractDataService {
  // Players
  Future<List<Player>> getAllPlayers();
  Future<Player?> getPlayerById(int id);
  Future<List<Player>> searchPlayers(String query);
  Future<int> savePlayer(Player player);
  Future<bool> deletePlayer(int id);
  Future<List<Player>> getPlayersByPosicion(Posicion posicion);
  Future<int> getPlayerCount();

  // Seasons
  Future<List<Season>> getAllSeasons();
  Future<Season?> getSeasonById(int id);
  Future<int> saveSeason(Season season);
  Future<bool> deleteSeason(int id);
  Future<Season?> getActiveSeason();
  Future<void> setActiveSeason(int id);
  Future<List<Match>> getMatchesBySeason(int seasonId);

  // Matches
  Future<List<Match>> getAllMatches();
  Future<Match?> getMatchById(int id);
  Future<Match?> getActiveMatch();
  Future<List<Match>> getMatchesByState(EstadoPartido estado);
  Future<int> saveMatch(Match match);
  Future<bool> deleteMatch(int id);
  Future<int> getMatchCount();

  // Stat Events
  Future<List<StatEvent>> getAllEvents();
  Future<List<StatEvent>> getEventsByMatch(int matchId);
  Future<List<StatEvent>> getEventsByPlayer(int playerId);
  Future<List<StatEvent>> getEventsByPlayerAndMatch(int playerId, int matchId);
  Future<List<StatEvent>> getEventsByMatchAndPlayer(int matchId, int playerId);
  Future<List<StatEvent>> getEventsByMatchAndType(int matchId, TipoAccion tipo);
  Future<int> saveStatEvent(StatEvent event);
  Future<bool> deleteStatEvent(int id);
  Future<int> deleteEventsByMatch(int matchId);
  Future<int> countEventsByType(int matchId, TipoAccion tipo);
  Future<Map<TipoAccion, int>> countAllEventTypes(int matchId);

  // Attendance
  Future<List<AttendanceRecord>> getAllAttendanceRecords();
  Future<List<AttendanceRecord>> getAttendanceByDate(DateTime date);
  Future<List<AttendanceRecord>> getAttendanceByPlayer(int playerId);
  Future<List<AttendanceRecord>> getAttendanceByPlayerAndDateRange(int playerId, DateTime start, DateTime end);
  Future<int> saveAttendanceRecord(AttendanceRecord record);

  // Users
  Future<List<AppUser>> getAllUsers();
  Future<AppUser?> getUserByEmail(String email);
  Future<AppUser?> getUserById(int id);
  Future<int> saveUser(AppUser user);
  Future<bool> deleteUser(int id);

  // Session
  Future<void> saveSessionUserId(int userId);
  Future<int?> getSessionUserId();
  Future<void> clearSession();

  // Backup & Restore
  Future<String?> exportToJson({String? appVersion, String? devicePlatform});
  Future<bool> importFromJson(String jsonString);

  // Lifecycle
  Future<void> initialize();
  Future<void> close();
}
