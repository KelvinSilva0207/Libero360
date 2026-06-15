import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/estadisticas/data/models/player.dart';
import '../../features/estadisticas/data/models/season.dart';
import '../../features/estadisticas/data/models/match.dart';
import '../../features/estadisticas/data/models/stat_event.dart';
import '../../features/estadisticas/data/models/attendance_record.dart';
import '../../features/estadisticas/data/local_db/database_service.dart';
import '../models/athlete_status.dart';
import '../config.dart';

class ClubDataService {
  static final ClubDataService instance = ClubDataService._internal();
  ClubDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<String?> get clubId async {
    if (!AppConfig.useFirebase) return null;
    try {
      final snap = await _firestore
          .collectionGroup('members')
          .where('userId', isEqualTo: _uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.reference.parent.parent?.id;
    } catch (_) {
      return null;
    }
  }

  /// Save a player under the current club or fallback to local DB.
  Future<int> savePlayer(Player player) async {
    final localId = await DatabaseService.instance.savePlayer(player);
    if (localId > 0) player.id = localId;

    if (!AppConfig.useFirebase) return localId;

    final cid = await clubId;
    if (cid == null) return localId;

    await _firestore
        .collection('clubs')
        .doc(cid)
        .collection('athletes')
        .doc(localId.toString())
        .set(_playerToMap(player));

    return localId;
  }

  /// Load all players from the current club or local DB.
  Future<List<Player>> getPlayers() async {
    if (!AppConfig.useFirebase) return DatabaseService.instance.getPlayers();

    final cid = await clubId;
    if (cid == null) return DatabaseService.instance.getPlayers();

    try {
      final snap = await _firestore
          .collection('clubs')
          .doc(cid)
          .collection('athletes')
          .get();

      final cloud = snap.docs
          .map((d) => _mapToPlayer(d.id, d.data()))
          .toList();

      for (final p in cloud) {
        await DatabaseService.instance.savePlayer(p);
      }

      return cloud;
    } catch (_) {
      return DatabaseService.instance.getPlayers();
    }
  }

  /// Delete a player from both local DB and cloud (under club).
  Future<void> deletePlayer(int playerId) async {
    await DatabaseService.instance.deletePlayer(playerId);

    if (!AppConfig.useFirebase) return;
    final cid = await clubId;
    if (cid == null) return;

    await _firestore
        .collection('clubs')
        .doc(cid)
        .collection('athletes')
        .doc(playerId.toString())
        .delete();
  }

  /// Stream players from the current club in real-time.
  Stream<List<Player>> streamPlayers() {
    if (!AppConfig.useFirebase) return const Stream.empty();

    return _firestore
        .collectionGroup('athletes')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _mapToPlayer(d.id, d.data())).toList());
  }

  /// Save a match under the current club.
  Future<void> saveMatch(Match match) async {
    if (!AppConfig.useFirebase) {
      await DatabaseService.instance.saveMatch(match);
      return;
    }

    final cid = await clubId;
    if (cid == null) {
      await DatabaseService.instance.saveMatch(match);
      return;
    }

    final data = {
      'id': match.id,
      'fecha': match.fecha.toIso8601String(),
      'equipoLocal': match.equipoLocal,
      'equipoVisitante': match.equipoVisitante,
      'puntosLocal': match.puntosLocal,
      'puntosVisitante': match.puntosVisitante,
      'setsLocal': match.setsLocal,
      'setsVisitante': match.setsVisitante,
      'setActual': match.setActual,
      'estado': match.estado.name,
      'turnoLocal': match.turnoLocal,
      'velocidadAnimacion': match.velocidadAnimacion,
      'createdAt': match.createdAt.toIso8601String(),
      'tipoPartido': match.tipoPartido.name,
      'setsTotales': match.setsTotales,
      'resultadoFinal': match.resultadoFinal,
      'lugar': match.lugar,
      'seasonId': match.seasonId,
      'duracionSegundos': match.duracionSegundos,
    };

    await _firestore
        .collection('clubs')
        .doc(cid)
        .collection('matches')
        .doc(match.id > 0 ? match.id.toString() : null)
        .set(data);
  }

  Map<String, dynamic> _playerToMap(Player p) => {
        'nombre': p.nombre,
        'firstNames': p.firstNames,
        'lastNames': p.lastNames,
        'displayName': p.displayName,
        'cedula': p.cedula,
        'fechaNacimiento': p.fechaNacimiento.toIso8601String(),
        'numero': p.numero,
        'posicion': p.posicion.name,
        'esCapitan': p.esCapitan,
        'fotoUrl': p.fotoUrl ?? '',
        'estadoSalud': p.estadoSalud.name,
        'condicionFisica': p.condicionFisica,
        'atletaStatus': p.atletaStatus.name,
        'statusReason': p.statusReason ?? '',
        'statusStartDate': p.statusStartDate?.toIso8601String(),
        'statusEndDate': p.statusEndDate?.toIso8601String(),
      };

  Player _mapToPlayer(String id, Map<String, dynamic> data) {
    return Player()
      ..id = int.tryParse(id) ?? 0
      ..nombre = data['nombre'] as String? ?? ''
      ..firstNames = data['firstNames'] as String? ?? ''
      ..lastNames = data['lastNames'] as String? ?? ''
      ..displayName = data['displayName'] as String? ?? ''
      ..cedula = data['cedula'] as String? ?? ''
      ..fechaNacimiento = data['fechaNacimiento'] != null
          ? DateTime.parse(data['fechaNacimiento'] as String)
          : DateTime.now()
      ..numero = data['numero'] as int?
      ..posicion = Posicion.values.firstWhere(
          (e) => e.name == data['posicion'],
          orElse: () => Posicion.sinDefinir)
      ..esCapitan = data['esCapitan'] as bool? ?? false
      ..fotoUrl = data['fotoUrl'] as String?
      ..estadoSalud = data['estadoSalud'] != null
          ? EstadoSalud.values.firstWhere(
              (e) => e.name == data['estadoSalud'],
              orElse: () => EstadoSalud.disponible)
          : EstadoSalud.disponible
      ..atletaStatus = data['atletaStatus'] != null
          ? AthleteStatus.values.firstWhere(
              (e) => e.name == data['atletaStatus'],
              orElse: () => AthleteStatus.active)
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
