import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config.dart';
import '../../../core/services/log_service.dart';
import '../../estadisticas/data/local_db/database_service.dart';
import '../../estadisticas/data/models/models.dart';
import '../../profiles/data/profile_model.dart';
import 'pending_sync_operation.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _db = DatabaseService.instance;
  bool _isProcessingQueue = false;
  static const int _maxRetries = 5;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ============================================================
  // PATH HELPERS
  // ============================================================

  DocumentReference _userProfileRef(String profileId) =>
      _firestore.doc('users/$_uid/profiles/$profileId');

  DocumentReference _clubProfileDocRef(String clubId, String profileId) =>
      _firestore.doc('clubs/$clubId/profiles/$profileId');

  CollectionReference _clubAthletesRef(String clubId, String profileId) =>
      _clubProfileDocRef(clubId, profileId).collection('athletes');

  CollectionReference _clubMatchesRef(String clubId, String profileId) =>
      _clubProfileDocRef(clubId, profileId).collection('matches');

  CollectionReference _clubAttendanceRef(String clubId, String profileId) =>
      _clubProfileDocRef(clubId, profileId).collection('attendance');

  CollectionReference _clubStatsRef(String clubId, String profileId) =>
      _clubProfileDocRef(clubId, profileId).collection('stats');

  // ============================================================
  // QUEUE ENQUEUE HELPERS
  // ============================================================

  Future<void> enqueueUpload(String collection, String documentId,
      {Map<String, dynamic>? data}) async {
    if (!AppConfig.useFirebase) return;
    final op = PendingSyncOperation(
      type: SyncOperationType.upload,
      collection: collection,
      documentId: documentId,
      data: data,
    );
    await _db.addSyncOperation(op);
    LogService.instance.auto(
      '🔵 SYNC-QUEUE: enqueued $collection/$documentId',
      source: 'SyncService',
    );
    _processQueue();
  }

  Future<void> enqueueDelete(String collection, String documentId) async {
    if (!AppConfig.useFirebase) return;
    final op = PendingSyncOperation(
      type: SyncOperationType.delete,
      collection: collection,
      documentId: documentId,
    );
    await _db.addSyncOperation(op);
    LogService.instance.auto(
      '🔵 SYNC-QUEUE: enqueued DELETE $collection/$documentId',
      source: 'SyncService',
    );
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      final ops = await _db.getPendingSyncOperations();
      for (final op in ops) {
        if (op.retryCount >= _maxRetries) {
          LogService.instance.auto(
            '🔴 SYNC-QUEUE: max retries reached for ${op.collection}/${op.documentId}: ${op.errorMessage}',
            source: 'SyncService',
          );
          await _db.removeSyncOperation(op.id);
          continue;
        }
        try {
          await _executeOperation(op);
          await _db.removeSyncOperation(op.id);
          LogService.instance.auto(
            '🟢 SYNC-QUEUE: completed ${op.collection}/${op.documentId}',
            source: 'SyncService',
          );
        } catch (e) {
          final backoff = Duration(seconds: (op.retryCount + 1) * 2);
          LogService.instance.auto(
            '🟠 SYNC-QUEUE: retry ${op.retryCount + 1}/$_maxRetries ${op.collection}/${op.documentId}: $e (backoff ${backoff.inSeconds}s)',
            source: 'SyncService',
          );
          final updated = op.copyWith(
            retryCount: op.retryCount + 1,
            errorMessage: e.toString(),
          );
          // Remove and re-add to update (Sembast intMapStore)
          await _db.removeSyncOperation(op.id);
          await _db.addSyncOperation(updated);
          await Future.delayed(backoff);
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _executeOperation(PendingSyncOperation op) async {
    switch (op.collection) {
      case 'matches':
        if (op.type == SyncOperationType.upload) {
          final match = await _db.getMatchById(int.tryParse(op.documentId) ?? 0);
          if (match != null) {
            final ref = _findMatchRef(match);
            await _setWithConflictCheck(ref, _matchToMap(match));
          }
        }
        break;
      case 'athletes':
        if (op.type == SyncOperationType.upload) {
          final player = await _db.getPlayer(int.tryParse(op.documentId) ?? 0);
          if (player != null) {
            final ref = _findPlayerRef(player);
            await _setWithConflictCheck(ref, _playerToMap(player));
          }
        }
        break;
      case 'attendance':
        if (op.type == SyncOperationType.upload && op.data != null) {
          final ref = _findAttendanceRef(op.data!);
          await _setWithConflictCheck(ref, op.data!);
        }
        break;
      case 'stats':
        if (op.type == SyncOperationType.upload && op.data != null) {
          final ref = _findStatsRef(op.data!);
          await _setWithConflictCheck(ref, op.data!);
        }
        break;
      case 'profiles':
        if (op.type == SyncOperationType.upload && op.data != null) {
          await _userProfileRef(op.documentId).set(op.data!);
        }
        break;
    }
  }

  DocumentReference _findMatchRef(Match m) {
    final clubId = m.clubId ?? '';
    final profileId = m.profileId ?? '';
    if (clubId.isNotEmpty && profileId.isNotEmpty) {
      return _clubMatchesRef(clubId, profileId).doc(m.id.toString());
    }
    return _firestore.collection('orphan_matches').doc(m.id.toString());
  }

  DocumentReference _findPlayerRef(Player p) {
    final clubId = p.clubId ?? '';
    final profileId = p.profileId ?? '';
    if (clubId.isNotEmpty && profileId.isNotEmpty) {
      return _clubAthletesRef(clubId, profileId).doc(p.id.toString());
    }
    return _firestore.collection('orphan_players').doc(p.id.toString());
  }

  DocumentReference _findAttendanceRef(Map<String, dynamic> data) {
    final clubId = data['clubId'] as String? ?? '';
    final profileId = data['profileId'] as String? ?? '';
    final docId = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    if (clubId.isNotEmpty && profileId.isNotEmpty) {
      return _clubAttendanceRef(clubId, profileId).doc(docId);
    }
    return _firestore.collection('orphan_attendance').doc(docId);
  }

  DocumentReference _findStatsRef(Map<String, dynamic> data) {
    final clubId = data['clubId'] as String? ?? '';
    final profileId = data['profileId'] as String? ?? '';
    final docId = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    if (clubId.isNotEmpty && profileId.isNotEmpty) {
      return _clubStatsRef(clubId, profileId).doc(docId);
    }
    return _firestore.collection('orphan_stats').doc(docId);
  }

  Future<void> _setWithConflictCheck(DocumentReference ref, Map<String, dynamic> newData) async {
    try {
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        await ref.set(newData);
        return;
      }
      final existing = snapshot.data() as Map<String, dynamic>;
      final localUpdated = newData['updatedAt'] as String?;
      final remoteUpdated = existing['updatedAt'] as String?;
      if (localUpdated != null && remoteUpdated != null) {
        if (DateTime.parse(localUpdated).isAfter(DateTime.parse(remoteUpdated))) {
          await ref.set(newData);
          LogService.instance.auto('🟡 SYNC: conflict resolved — local newer for $ref', source: 'SyncService');
        } else {
          LogService.instance.auto('🟠 SYNC: conflict resolved — remote newer for $ref, skipping', source: 'SyncService');
        }
      } else {
        await ref.set(newData);
      }
    } catch (e) {
      LogService.instance.auto('🔴 SYNC: conflict check failed for $ref: $e', source: 'SyncService');
      rethrow;
    }
  }

  // ============================================================
  // DIRECT UPLOAD (legacy)
  // ============================================================

  Future<void> uploadProfiles() async {
    if (!AppConfig.useFirebase) return;
    final uid = _uid;
    if (uid == null) return;
    LogService.instance.auto('🔵 SYNC: subiendo perfiles', source: 'SyncService');
    final profiles = await _db.getAllProfiles();
    for (final profile in profiles) {
      try {
        await _userProfileRef(profile.id).set(profile.toJson());
        if (profile.clubId.isNotEmpty) {
          await _clubProfileDocRef(profile.clubId, profile.id).set(profile.toJson());
        }
      } catch (e) {
        LogService.instance.auto('🔴 SYNC: error subiendo perfil ${profile.id}: $e', source: 'SyncService');
      }
    }
    LogService.instance.auto('🟢 SYNC: perfiles subidos (${profiles.length})', source: 'SyncService');
  }

  Future<List<ProfileModel>> downloadProfiles() async {
    if (!AppConfig.useFirebase) return [];
    final uid = _uid;
    if (uid == null) return [];
    LogService.instance.auto('🔵 SYNC: descargando perfiles', source: 'SyncService');
    final List<ProfileModel> downloaded = [];
    try {
      final snap = await _firestore.collection('users').doc(uid).collection('profiles').get();
      for (final doc in snap.docs) {
        final profile = ProfileModel.fromJson(doc.data());
        downloaded.add(profile);
        await _db.addProfile(profile);
      }
    } catch (e) {
      LogService.instance.auto('🔴 SYNC: error descargando perfiles: $e', source: 'SyncService');
    }
    LogService.instance.auto('🟢 SYNC: perfiles descargados (${downloaded.length})', source: 'SyncService');
    return downloaded;
  }

  Future<void> uploadPlayers(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    LogService.instance.auto('🔵 SYNC: subiendo atletas (perfil $profileId)', source: 'SyncService');
    final players = await _db.getPlayersByProfile(profileId);
    final ref = _clubAthletesRef(clubId, profileId);
    for (final player in players) {
      try {
        await _setWithConflictCheck(ref.doc(player.id.toString()), _playerToMap(player));
      } catch (e) {
        LogService.instance.auto('🔴 SYNC: error subiendo atleta ${player.id}: $e', source: 'SyncService');
      }
    }
    LogService.instance.auto('🟢 SYNC: atletas subidos (${players.length})', source: 'SyncService');
  }

  Future<void> downloadPlayers(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    LogService.instance.auto('🔵 SYNC: descargando atletas (perfil $profileId)', source: 'SyncService');
    try {
      final snap = await _clubAthletesRef(clubId, profileId).get();
      for (final doc in snap.docs) {
        final player = _mapToPlayer(doc.id, doc.data() as Map<String, dynamic>);
        await _db.savePlayer(player);
      }
      LogService.instance.auto('🟢 SYNC: atletas descargados (${snap.docs.length})', source: 'SyncService');
    } catch (e) {
      LogService.instance.auto('🔴 SYNC: error descargando atletas: $e', source: 'SyncService');
    }
  }

  Future<void> uploadMatches(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    LogService.instance.auto('🔵 SYNC: subiendo partidos (perfil $profileId)', source: 'SyncService');
    final matches = await _db.getMatchesByProfile(profileId);
    final ref = _clubMatchesRef(clubId, profileId);
    for (final match in matches) {
      try {
        await _setWithConflictCheck(ref.doc(match.id.toString()), _matchToMap(match));
      } catch (e) {
        LogService.instance.auto('🔴 SYNC: error subiendo partido ${match.id}: $e', source: 'SyncService');
      }
    }
    LogService.instance.auto('🟢 SYNC: partidos subidos (${matches.length})', source: 'SyncService');
  }

  Future<void> downloadMatches(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    LogService.instance.auto('🔵 SYNC: descargando partidos (perfil $profileId)', source: 'SyncService');
    try {
      final snap = await _clubMatchesRef(clubId, profileId).get();
      for (final doc in snap.docs) {
        final match = _mapToMatch(doc.id, doc.data() as Map<String, dynamic>);
        await _db.saveMatch(match);
      }
      LogService.instance.auto('🟢 SYNC: partidos descargados (${snap.docs.length})', source: 'SyncService');
    } catch (e) {
      LogService.instance.auto('🔴 SYNC: error descargando partidos: $e', source: 'SyncService');
    }
  }

  Future<void> uploadAttendance(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    LogService.instance.auto('🔵 SYNC: subiendo asistencias (perfil $profileId)', source: 'SyncService');
    final records = await _db.getAttendanceByProfile(profileId);
    final ref = _clubAttendanceRef(clubId, profileId);
    for (final record in records) {
      try {
        await _setWithConflictCheck(ref.doc(record.id.toString()), _attendanceToMap(record));
      } catch (e) {
        LogService.instance.auto('🔴 SYNC: error subiendo asistencia ${record.id}: $e', source: 'SyncService');
      }
    }
    LogService.instance.auto('🟢 SYNC: asistencias subidas (${records.length})', source: 'SyncService');
  }

  Future<void> downloadAttendance(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    LogService.instance.auto('🔵 SYNC: descargando asistencias (perfil $profileId)', source: 'SyncService');
    try {
      final snap = await _clubAttendanceRef(clubId, profileId).get();
      for (final doc in snap.docs) {
        final record = _mapToAttendance(doc.id, doc.data() as Map<String, dynamic>);
        await _db.saveAttendanceRecord(record);
      }
      LogService.instance.auto('🟢 SYNC: asistencias descargadas (${snap.docs.length})', source: 'SyncService');
    } catch (e) {
      LogService.instance.auto('🔴 SYNC: error descargando asistencias: $e', source: 'SyncService');
    }
  }

  Future<void> uploadStats(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    LogService.instance.auto('🔵 SYNC: subiendo estadísticas (perfil $profileId)', source: 'SyncService');
    final events = await _db.getStatsByProfile(profileId);
    final ref = _clubStatsRef(clubId, profileId);
    for (final event in events) {
      try {
        await _setWithConflictCheck(ref.doc(event.id.toString()), _statEventToMap(event));
      } catch (e) {
        LogService.instance.auto('🔴 SYNC: error subiendo estadística ${event.id}: $e', source: 'SyncService');
      }
    }
    LogService.instance.auto('🟢 SYNC: estadísticas subidas (${events.length})', source: 'SyncService');
  }

  Future<void> downloadStats(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    LogService.instance.auto('🔵 SYNC: descargando estadísticas (perfil $profileId)', source: 'SyncService');
    try {
      final snap = await _clubStatsRef(clubId, profileId).get();
      for (final doc in snap.docs) {
        final event = _mapToStatEvent(doc.id, doc.data() as Map<String, dynamic>);
        await _db.saveStatEvent(event);
      }
      LogService.instance.auto('🟢 SYNC: estadísticas descargadas (${snap.docs.length})', source: 'SyncService');
    } catch (e) {
      LogService.instance.auto('🔴 SYNC: error descargando estadísticas: $e', source: 'SyncService');
    }
  }

  Future<void> syncAll(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    LogService.instance.auto('🔵 SYNC: iniciando sincronización (perfil $profileId)', source: 'SyncService');
    try {
      await uploadProfiles();
      await uploadPlayers(profileId, clubId);
      await uploadMatches(profileId, clubId);
      await uploadAttendance(profileId, clubId);
      await uploadStats(profileId, clubId);
      // Process any remaining queue items
      await _processQueue();
      LogService.instance.auto('🟢 SYNC: sincronización completada', source: 'SyncService');
    } catch (e) {
      LogService.instance.auto('🔴 SYNC: error en sincronización: $e', source: 'SyncService');
      rethrow;
    }
  }

  Future<int> getPendingCount() async {
    if (!AppConfig.useFirebase) return 0;
    return await _db.getSyncQueueCount();
  }

  Future<void> clearQueue() async {
    await _db.clearSyncQueue();
  }

  // ============================================================
  // SERIALIZATION — PLAYER
  // ============================================================

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
        'profileId': p.profileId,
        'clubId': p.clubId,
        'createdAt': p.createdAt.toIso8601String(),
        'atletaStatus': p.atletaStatus.name,
        'statusReason': p.statusReason ?? '',
        'statusStartDate': p.statusStartDate?.toIso8601String(),
        'statusEndDate': p.statusEndDate?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

  Player _mapToPlayer(String id, Map<String, dynamic> data) => Player()
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
    ..condicionFisica = data['condicionFisica'] as String? ?? 'Excelente'
    ..profileId = data['profileId'] as String?
    ..clubId = data['clubId'] as String?
    ..createdAt = data['createdAt'] != null
        ? DateTime.parse(data['createdAt'] as String)
        : DateTime.now()
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

  // ============================================================
  // SERIALIZATION — MATCH
  // ============================================================

  Map<String, dynamic> _matchToMap(Match m) => {
        'fecha': m.fecha.toIso8601String(),
        'equipoLocal': m.equipoLocal,
        'equipoVisitante': m.equipoVisitante,
        'puntosLocal': m.puntosLocal,
        'puntosVisitante': m.puntosVisitante,
        'setsLocal': m.setsLocal,
        'setsVisitante': m.setsVisitante,
        'setActual': m.setActual,
        'estado': m.estado.name,
        'turnoLocal': m.turnoLocal,
        'velocidadAnimacion': m.velocidadAnimacion,
        'createdAt': m.createdAt.toIso8601String(),
        'tipoPartido': m.tipoPartido.name,
        'setsTotales': m.setsTotales,
        'puntosParaGanarSet': m.puntosParaGanarSet,
        'puntosDiferenciaSet': m.puntosDiferenciaSet,
        'resultadoFinal': m.resultadoFinal,
        'lugar': m.lugar,
        'competitionName': m.competitionName,
        'seasonId': m.seasonId,
        'profileId': m.profileId,
        'clubId': m.clubId,
        'duracionSegundos': m.duracionSegundos,
        'ultimoPuntoFueLocal': m.ultimoPuntoFueLocal,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  Match _mapToMatch(String id, Map<String, dynamic> data) => Match()
    ..id = int.tryParse(id) ?? 0
    ..fecha = data['fecha'] != null
        ? DateTime.parse(data['fecha'] as String)
        : DateTime.now()
    ..equipoLocal = data['equipoLocal'] as String? ?? ''
    ..equipoVisitante = data['equipoVisitante'] as String? ?? ''
    ..puntosLocal = data['puntosLocal'] as int? ?? 0
    ..puntosVisitante = data['puntosVisitante'] as int? ?? 0
    ..setsLocal = data['setsLocal'] as int? ?? 0
    ..setsVisitante = data['setsVisitante'] as int? ?? 0
    ..setActual = data['setActual'] as int? ?? 1
    ..estado = EstadoPartido.values.firstWhere(
        (e) => e.name == data['estado'],
        orElse: () => EstadoPartido.noIniciado)
    ..turnoLocal = data['turnoLocal'] as bool? ?? true
    ..velocidadAnimacion = data['velocidadAnimacion'] as int? ?? 1000
    ..createdAt = data['createdAt'] != null
        ? DateTime.parse(data['createdAt'] as String)
        : DateTime.now()
    ..tipoPartido = TipoPartido.values.firstWhere(
        (e) => e.name == data['tipoPartido'],
        orElse: () => TipoPartido.amistoso)
    ..setsTotales = data['setsTotales'] as int? ?? 5
    ..puntosParaGanarSet = data['puntosParaGanarSet'] as int? ?? 25
    ..puntosDiferenciaSet = data['puntosDiferenciaSet'] as int? ?? 2
    ..resultadoFinal = data['resultadoFinal'] as String?
    ..lugar = data['lugar'] as String?
    ..competitionName = data['competitionName'] as String?
    ..seasonId = data['seasonId'] as int?
    ..profileId = data['profileId'] as String?
    ..clubId = data['clubId'] as String?
    ..duracionSegundos = data['duracionSegundos'] as int? ?? 0
    ..ultimoPuntoFueLocal = data['ultimoPuntoFueLocal'] as bool? ?? true;

  // ============================================================
  // SERIALIZATION — ATTENDANCE
  // ============================================================

  Map<String, dynamic> _attendanceToMap(AttendanceRecord r) => {
        'playerId': r.playerId,
        'profileId': r.profileId,
        'clubId': r.clubId,
        'fecha': r.fecha.toIso8601String(),
        'asistio': r.asistio,
        'observaciones': r.observaciones,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  AttendanceRecord _mapToAttendance(String id, Map<String, dynamic> data) =>
      AttendanceRecord()
        ..id = int.tryParse(id) ?? 0
        ..playerId = data['playerId'] as int? ?? 0
        ..profileId = data['profileId'] as String?
        ..clubId = data['clubId'] as String?
        ..fecha = data['fecha'] != null
            ? DateTime.parse(data['fecha'] as String)
            : DateTime.now()
        ..asistio = data['asistio'] as bool? ?? false
        ..observaciones = data['observaciones'] as String? ?? '';

  // ============================================================
  // SERIALIZATION — STAT EVENT
  // ============================================================

  Map<String, dynamic> _statEventToMap(StatEvent e) => {
        'tipoAccion': e.tipoAccion.name,
        'resultado': e.resultado.name,
        'timestamp': e.timestamp.toIso8601String(),
        'setNumero': e.setNumero,
        'puntoLocal': e.puntoLocal,
        'puntoVisitante': e.puntoVisitante,
        'esEquipoLocal': e.esEquipoLocal,
        'zona': e.zona.name,
        'descripcion': e.descripcion,
        'playerId': e.playerId,
        'matchId': e.matchId,
        'profileId': e.profileId,
        'clubId': e.clubId,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

  StatEvent _mapToStatEvent(String id, Map<String, dynamic> data) =>
      StatEvent()
        ..id = int.tryParse(id) ?? 0
        ..tipoAccion = TipoAccion.values.firstWhere(
            (e) => e.name == data['tipoAccion'],
            orElse: () => TipoAccion.ataque)
        ..resultado = ResultadoAccion.values.firstWhere(
            (e) => e.name == data['resultado'],
            orElse: () => ResultadoAccion.neutral)
        ..timestamp = data['timestamp'] != null
            ? DateTime.parse(data['timestamp'] as String)
            : DateTime.now()
        ..setNumero = data['setNumero'] as int? ?? 1
        ..puntoLocal = data['puntoLocal'] as int? ?? 0
        ..puntoVisitante = data['puntoVisitante'] as int? ?? 0
        ..esEquipoLocal = data['esEquipoLocal'] as bool? ?? true
        ..zona = ZonaCancha.values.firstWhere(
            (e) => e.name == data['zona'],
            orElse: () => ZonaCancha.ninguna)
        ..descripcion = data['descripcion'] as String?
        ..playerId = data['playerId'] as int? ?? 0
        ..matchId = data['matchId'] as int? ?? 0
        ..profileId = data['profileId'] as String?
        ..clubId = data['clubId'] as String?
        ..createdAt = data['createdAt'] != null
            ? DateTime.parse(data['createdAt'] as String)
            : DateTime.now();
}
