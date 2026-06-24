import '../../estadisticas/data/local_db/database_service.dart';
import '../../estadisticas/data/models/models.dart';

class AthleteRepository {
  final DatabaseService _db = DatabaseService.instance;

  Future<List<Player>> getActive({String? profileId}) async {
    await _db.initialize();
    if (profileId != null) {
      return _db.getPlayersByProfile(profileId);
    }
    return _db.getActivePlayers();
  }

  Future<List<Player>> getDeleted() async {
    await _db.initialize();
    return _db.getDeletedPlayers();
  }

  Future<List<Player>> search(String query, {String? profileId}) async {
    await _db.initialize();
    final all = profileId != null
        ? await _db.getPlayersByProfile(profileId)
        : await _db.getActivePlayers();
    final lower = query.toLowerCase();
    return all.where((p) =>
      p.displayName.toLowerCase().contains(lower) ||
      (p.numero?.toString() ?? '').contains(lower) ||
      p.cedula.replaceAll('.', '').contains(lower)
    ).toList();
  }

  Future<Player?> getById(int id) async {
    await _db.initialize();
    return _db.getPlayerById(id);
  }

  Future<int> save(Player player) async {
    await _db.initialize();
    return _db.savePlayer(player);
  }

  Future<void> softDelete(int id, {String? deletedBy, String? reason}) async {
    final player = await getById(id);
    if (player == null) return;
    player.isDeleted = true;
    player.deletedAt = DateTime.now();
    player.deletedBy = deletedBy;
    player.deletionReason = reason;
    await _db.savePlayer(player);
  }

  Future<void> restore(int id) async {
    final player = await getById(id);
    if (player == null) return;
    player.isDeleted = false;
    player.deletedAt = null;
    await _db.savePlayer(player);
  }

  Future<void> permanentDelete(int id) async {
    await _db.initialize();
    await _db.deletePlayer(id);
  }
}
