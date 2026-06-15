import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/estadisticas/data/models/player.dart';
import '../../features/estadisticas/data/local_db/database_service.dart';
import '../../core/models/athlete_status.dart';

class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  static FirebaseSyncService get instance => _instance;
  FirebaseSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _syncing = false;

  bool get isSyncing => _syncing;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Saves a player locally and syncs to Firestore.
  Future<void> saveAndSyncPlayer(Player player) async {
    final id = await DatabaseService.instance.savePlayer(player);
    player.id = id;
    await _syncPlayerToCloud(player);
  }

  /// Loads all players, preferring local data but syncing from cloud.
  Future<List<Player>> loadSyncedPlayers() async {
    await _syncFromCloud();
    return DatabaseService.instance.getPlayers();
  }

  /// Pushes a single player to Firestore under current user's UID.
  Future<void> _syncPlayerToCloud(Player player) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('players')
        .doc(player.id.toString())
        .set(_playerToMap(player));
  }

  /// Pulls all players from Firestore and merges into local DB.
  Future<void> _syncFromCloud() async {
    final uid = _uid;
    if (uid == null) return;

    _syncing = true;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('players')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final player = _mapToPlayer(data, int.tryParse(doc.id) ?? 0);
        final existing = await DatabaseService.instance.getPlayerById(player.id);
        if (existing == null) {
          await DatabaseService.instance.savePlayer(player);
        }
      }
    } finally {
      _syncing = false;
    }
  }

  /// Deletes a player locally and in Firestore.
  Future<void> deleteAndSyncPlayer(int playerId) async {
    await DatabaseService.instance.deletePlayer(playerId);
    final uid = _uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('players')
        .doc(playerId.toString())
        .delete();
  }

  Map<String, dynamic> _playerToMap(Player p) {
    return {
      'nombre': p.nombre,
      'numero': p.numero,
      'posicion': p.posicion.name,
      'esCapitan': p.esCapitan,
      'fotoUrl': p.fotoUrl ?? '',
      'atletaStatus': p.atletaStatus.name,
      'statusReason': p.statusReason ?? '',
      'statusStartDate': p.statusStartDate?.toIso8601String(),
      'statusEndDate': p.statusEndDate?.toIso8601String(),
    };
  }

  Player _mapToPlayer(Map<String, dynamic> data, int id) {
    return Player()
      ..id = id
      ..nombre = data['nombre'] as String? ?? ''
      ..numero = data['numero'] as int?
      ..posicion = Posicion.values.firstWhere(
        (e) => e.name == data['posicion'],
        orElse: () => Posicion.sinDefinir,
      )
      ..esCapitan = data['esCapitan'] as bool? ?? false
      ..fotoUrl = data['fotoUrl'] as String?
      ..atletaStatus = data['atletaStatus'] != null
          ? AthleteStatus.values.firstWhere(
              (e) => e.name == data['atletaStatus'],
              orElse: () => AthleteStatus.active,
            )
          : AthleteStatus.active
      ..statusReason = data['statusReason'] as String?
      ..statusStartDate = data['statusStartDate'] != null
          ? DateTime.tryParse(data['statusStartDate'] as String)
          : null
      ..statusEndDate = data['statusEndDate'] != null
          ? DateTime.tryParse(data['statusEndDate'] as String)
          : null;
  }
}
