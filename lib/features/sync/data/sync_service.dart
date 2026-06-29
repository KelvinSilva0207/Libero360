import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config.dart';
import '../../estadisticas/data/local_db/database_service.dart';
import '../../estadisticas/data/models/models.dart';
import '../../profiles/data/profile_model.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _db = DatabaseService.instance;

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
  // PROFILES
  // ============================================================

  Future<void> uploadProfiles() async {
    if (!AppConfig.useFirebase) return;
    final uid = _uid;
    if (uid == null) {
      print('🔴 SYNC: usuario no autenticado');
      return;
    }
    print('🔵 SYNC: subiendo perfiles');
    final profiles = await _db.getAllProfiles();
    for (final profile in profiles) {
      try {
        await _userProfileRef(profile.id).set(profile.toJson());
        if (profile.clubId.isNotEmpty) {
          await _clubProfileDocRef(profile.clubId, profile.id).set(profile.toJson());
        }
      } catch (e) {
        print('🔴 SYNC: error subiendo perfil ${profile.id}: $e');
      }
    }
    print('🟢 SYNC: perfiles subidos (${profiles.length})');
  }

  Future<List<ProfileModel>> downloadProfiles() async {
    if (!AppConfig.useFirebase) return [];
    final uid = _uid;
    if (uid == null) return [];
    print('🔵 SYNC: descargando perfiles');
    final List<ProfileModel> downloaded = [];
    try {
      final snap = await _firestore.collection('users').doc(uid).collection('profiles').get();
      for (final doc in snap.docs) {
        final profile = ProfileModel.fromJson(doc.data());
        downloaded.add(profile);
        await _db.addProfile(profile);
      }
    } catch (e) {
      print('🔴 SYNC: error descargando perfiles: $e');
    }
    print('🟢 SYNC: perfiles descargados (${downloaded.length})');
    return downloaded;
  }

  // ============================================================
  // PLAYERS
  // ============================================================

  Future<void> uploadPlayers(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    print('🔵 SYNC: subiendo atletas (perfil $profileId)');
    final players = await _db.getPlayersByProfile(profileId);
    final ref = _clubAthletesRef(clubId, profileId);
    for (final player in players) {
      try {
        await ref.doc(player.id.toString()).set(_playerToMap(player));
      } catch (e) {
        print('🔴 SYNC: error subiendo atleta ${player.id}: $e');
      }
    }
    print('🟢 SYNC: atletas subidos (${players.length})');
  }

  Future<void> downloadPlayers(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    print('🔵 SYNC: descargando atletas (perfil $profileId)');
    try {
      final snap = await _clubAthletesRef(clubId, profileId).get();
      for (final doc in snap.docs) {
        final player = _mapToPlayer(doc.id, doc.data() as Map<String, dynamic>);
        await _db.savePlayer(player);
      }
      print('🟢 SYNC: atletas descargados (${snap.docs.length})');
    } catch (e) {
      print('🔴 SYNC: error descargando atletas: $e');
    }
  }

  // ============================================================
  // MATCHES
  // ============================================================

  Future<void> uploadMatches(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    print('🔵 SYNC: subiendo partidos (perfil $profileId)');
    final matches = await _db.getMatchesByProfile(profileId);
    final ref = _clubMatchesRef(clubId, profileId);
    for (final match in matches) {
      try {
        await ref.doc(match.id.toString()).set(_matchToMap(match));
      } catch (e) {
        print('🔴 SYNC: error subiendo partido ${match.id}: $e');
      }
    }
    print('🟢 SYNC: partidos subidos (${matches.length})');
  }

  Future<void> downloadMatches(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    print('🔵 SYNC: descargando partidos (perfil $profileId)');
    try {
      final snap = await _clubMatchesRef(clubId, profileId).get();
      for (final doc in snap.docs) {
        final match = _mapToMatch(doc.id, doc.data() as Map<String, dynamic>);
        await _db.saveMatch(match);
      }
      print('🟢 SYNC: partidos descargados (${snap.docs.length})');
    } catch (e) {
      print('🔴 SYNC: error descargando partidos: $e');
    }
  }

  // ============================================================
  // ATTENDANCE
  // ============================================================

  Future<void> uploadAttendance(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    print('🔵 SYNC: subiendo asistencias (perfil $profileId)');
    final records = await _db.getAttendanceByProfile(profileId);
    final ref = _clubAttendanceRef(clubId, profileId);
    for (final record in records) {
      try {
        await ref.doc(record.id.toString()).set(_attendanceToMap(record));
      } catch (e) {
        print('🔴 SYNC: error subiendo asistencia ${record.id}: $e');
      }
    }
    print('🟢 SYNC: asistencias subidas (${records.length})');
  }

  Future<void> downloadAttendance(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    print('🔵 SYNC: descargando asistencias (perfil $profileId)');
    try {
      final snap = await _clubAttendanceRef(clubId, profileId).get();
      for (final doc in snap.docs) {
        final record = _mapToAttendance(doc.id, doc.data() as Map<String, dynamic>);
        await _db.saveAttendanceRecord(record);
      }
      print('🟢 SYNC: asistencias descargadas (${snap.docs.length})');
    } catch (e) {
      print('🔴 SYNC: error descargando asistencias: $e');
    }
  }

  // ============================================================
  // STATS (StatEvent)
  // ============================================================

  Future<void> uploadStats(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    print('🔵 SYNC: subiendo estadísticas (perfil $profileId)');
    final events = await _db.getStatsByProfile(profileId);
    final ref = _clubStatsRef(clubId, profileId);
    for (final event in events) {
      try {
        await ref.doc(event.id.toString()).set(_statEventToMap(event));
      } catch (e) {
        print('🔴 SYNC: error subiendo estadística ${event.id}: $e');
      }
    }
    print('🟢 SYNC: estadísticas subidas (${events.length})');
  }

  Future<void> downloadStats(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    print('🔵 SYNC: descargando estadísticas (perfil $profileId)');
    try {
      final snap = await _clubStatsRef(clubId, profileId).get();
      for (final doc in snap.docs) {
        final event = _mapToStatEvent(doc.id, doc.data() as Map<String, dynamic>);
        await _db.saveStatEvent(event);
      }
      print('🟢 SYNC: estadísticas descargadas (${snap.docs.length})');
    } catch (e) {
      print('🔴 SYNC: error descargando estadísticas: $e');
    }
  }

  // ============================================================
  // SYNC ALL
  // ============================================================

  Future<void> syncAll(String profileId, String clubId) async {
    if (!AppConfig.useFirebase) return;
    print('🔵 SYNC: iniciando sincronización (perfil $profileId)');
    try {
      await uploadProfiles();
      await uploadPlayers(profileId, clubId);
      await uploadMatches(profileId, clubId);
      await uploadAttendance(profileId, clubId);
      await uploadStats(profileId, clubId);
      print('🟢 SYNC: sincronización completada');
    } catch (e) {
      print('🔴 SYNC: error en sincronización: $e');
      rethrow;
    }
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
