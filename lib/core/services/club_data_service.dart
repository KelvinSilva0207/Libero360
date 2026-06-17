import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/estadisticas/data/models/player.dart';
import '../../features/estadisticas/data/models/season.dart';
import '../../features/estadisticas/data/models/match.dart';
import '../../features/estadisticas/data/models/stat_event.dart';
import '../../features/estadisticas/data/models/attendance_record.dart';
import '../../features/estadisticas/data/local_db/database_service.dart';
import '../../features/partido/data/match_event.dart';
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

  Future<String?> get _cid => clubId;

  DocumentReference? _clubRef(String? cid) =>
      cid != null ? _firestore.collection('clubs').doc(cid) : null;

  // ==================== ATHLETES ====================

  Future<int> savePlayer(Player player) async {
    final localId = await DatabaseService.instance.savePlayer(player);
    if (localId > 0) player.id = localId;

    final cid = await _cid;
    if (cid == null || !AppConfig.useFirebase) return localId;

    await _clubRef(cid)!
        .collection('athletes')
        .doc(localId.toString())
        .set(_playerToMap(player));
    return localId;
  }

  Future<List<Player>> getPlayers() async {
    if (!AppConfig.useFirebase) return DatabaseService.instance.getPlayers();
    final cid = await _cid;
    if (cid == null) return DatabaseService.instance.getPlayers();
    try {
      final snap = await _clubRef(cid)!.collection('athletes').get();
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

  Future<void> deletePlayer(int playerId) async {
    await DatabaseService.instance.deletePlayer(playerId);
    final cid = await _cid;
    if (cid == null || !AppConfig.useFirebase) return;
    await _clubRef(cid)!.collection('athletes').doc(playerId.toString()).delete();
  }

  Stream<List<Player>> streamPlayers() {
    if (!AppConfig.useFirebase) {
      return DatabaseService.instance.watchAllPlayers();
    }
    return _firestore
        .collectionGroup('athletes')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _mapToPlayer(d.id, d.data())).toList());
  }

  // ==================== MATCHES ====================

  Future<List<Match>> getMatches() async {
    if (!AppConfig.useFirebase) return DatabaseService.instance.getAllMatches();
    final cid = await _cid;
    if (cid == null) return DatabaseService.instance.getAllMatches();
    try {
      final snap = await _clubRef(cid)!.collection('matches').get();
      final cloud = snap.docs
          .map((d) => _mapToMatch(d.id, d.data()))
          .toList();
      return cloud;
    } catch (_) {
      return DatabaseService.instance.getAllMatches();
    }
  }

  Stream<List<Match>> streamMatches() {
    if (!AppConfig.useFirebase) return const Stream.empty();
    return _firestore
        .collectionGroup('matches')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _mapToMatch(d.id, d.data())).toList());
  }

  Future<void> saveMatch(Match match) async {
    await DatabaseService.instance.saveMatch(match);
    final cid = await _cid;
    if (cid == null || !AppConfig.useFirebase) return;
    await _clubRef(cid)!
        .collection('matches')
        .doc(match.id.toString())
        .set(_matchToMap(match));
  }

  Future<void> deleteMatch(int matchId) async {
    await DatabaseService.instance.deleteMatch(matchId);
    final cid = await _cid;
    if (cid == null || !AppConfig.useFirebase) return;
    await _clubRef(cid)!.collection('matches').doc(matchId.toString()).delete();
  }

  // ==================== STAT EVENTS ====================

  Future<int> saveStatEvent(StatEvent event) async {
    final localId = await DatabaseService.instance.saveStatEvent(event);
    if (localId > 0) event.id = localId;
    final cid = await _cid;
    if (cid == null || !AppConfig.useFirebase) return localId;
    await _clubRef(cid)!
        .collection('statEvents')
        .doc(localId.toString())
        .set(_statEventToMap(event));
    return localId;
  }

  Future<void> deleteStatEvent(int eventId) async {
    await DatabaseService.instance.deleteStatEvent(eventId);
    final cid = await _cid;
    if (cid == null || !AppConfig.useFirebase) return;
    await _clubRef(cid)!.collection('statEvents').doc(eventId.toString()).delete();
  }

  Stream<List<StatEvent>> streamStatEvents() {
    if (!AppConfig.useFirebase) return const Stream.empty();
    return _firestore
        .collectionGroup('statEvents')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _mapToStatEvent(d.id, d.data())).toList());
  }

  // ==================== MATCH EVENTS (Court points) ====================

  Future<int> saveMatchEvent(MatchEvent event) async {
    final localId = await DatabaseService.instance.saveMatchEvent(event);
    if (localId > 0) event.id = localId;
    final cid = await _cid;
    if (cid == null || !AppConfig.useFirebase) return localId;
    await _clubRef(cid)!
        .collection('matchEvents')
        .doc(localId.toString())
        .set(_matchEventToMap(event));
    return localId;
  }

  Stream<List<MatchEvent>> streamMatchEvents() {
    if (!AppConfig.useFirebase) return const Stream.empty();
    return _firestore
        .collectionGroup('matchEvents')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _mapToMatchEvent(d.id, d.data())).toList());
  }

  // ==================== ATTENDANCE ====================

  Future<int> saveAttendance(AttendanceRecord record) async {
    final localId = await DatabaseService.instance.saveAttendanceRecord(record);
    if (localId > 0) record.id = localId;
    final cid = await _cid;
    if (cid == null || !AppConfig.useFirebase) return localId;
    await _clubRef(cid)!
        .collection('attendance')
        .doc(localId.toString())
        .set(_attendanceToMap(record));
    return localId;
  }

  Future<void> deleteAttendance(int recordId) async {
    final cid = await _cid;
    if (cid == null || !AppConfig.useFirebase) return;
    await _clubRef(cid)!.collection('attendance').doc(recordId.toString()).delete();
  }

  Stream<List<AttendanceRecord>> streamAttendance() {
    if (!AppConfig.useFirebase) return const Stream.empty();
    return _firestore
        .collectionGroup('attendance')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _mapToAttendance(d.id, d.data())).toList());
  }

  // ==================== SEASONS ====================

  Future<int> saveSeason(Season season) async {
    final cid = await _cid;
    if (cid == null || !AppConfig.useFirebase) return 0;
    final docId = season.id > 0 ? season.id.toString() : _firestore.collection('clubs').doc().id;
    if (season.id == 0) season.id = int.tryParse(docId) ?? docId.hashCode;
    await _clubRef(cid)!
        .collection('seasons')
        .doc(docId)
        .set(_seasonToMap(season));
    return season.id;
  }

  Stream<List<Season>> streamSeasons() {
    if (!AppConfig.useFirebase) return const Stream.empty();
    return _firestore
        .collectionGroup('seasons')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => _mapToSeason(d.id, d.data())).toList());
  }

  // ==================== TO MAP ====================

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
        'duracionSegundos': m.duracionSegundos,
        'ultimoPuntoFueLocal': m.ultimoPuntoFueLocal,
      };

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
        'createdAt': e.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _matchEventToMap(MatchEvent e) => {
        'athleteId': e.athleteId,
        'matchId': e.matchId,
        'fecha': e.fecha.toIso8601String(),
        'setNumero': e.setNumero,
        'eventType': e.eventType.name,
        'tipoPartido': e.tipoPartido,
        'competenciaNombre': e.competenciaNombre,
        'rotacion': e.rotacion,
      };

  Map<String, dynamic> _attendanceToMap(AttendanceRecord r) => {
        'playerId': r.playerId,
        'fecha': r.fecha.toIso8601String(),
        'asistio': r.asistio,
        'observaciones': r.observaciones,
      };

  Map<String, dynamic> _seasonToMap(Season s) => {
        'name': s.name,
        'year': s.year,
        'isActive': s.isActive,
        'startDate': s.startDate.toIso8601String(),
        'endDate': s.endDate?.toIso8601String(),
        'createdAt': s.createdAt.toIso8601String(),
      };

  // ==================== FROM MAP ====================

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

  Match _mapToMatch(String id, Map<String, dynamic> data) {
    return Match()
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
      ..duracionSegundos = data['duracionSegundos'] as int? ?? 0
      ..ultimoPuntoFueLocal = data['ultimoPuntoFueLocal'] as bool? ?? true;
  }

  StatEvent _mapToStatEvent(String id, Map<String, dynamic> data) {
    return StatEvent()
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
      ..createdAt = data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now();
  }

  MatchEvent _mapToMatchEvent(String id, Map<String, dynamic> data) {
    return MatchEvent()
      ..id = int.tryParse(id) ?? 0
      ..athleteId = data['athleteId'] as int? ?? 0
      ..matchId = data['matchId'] as int? ?? 0
      ..fecha = data['fecha'] != null
          ? DateTime.parse(data['fecha'] as String)
          : DateTime.now()
      ..setNumero = data['setNumero'] as int? ?? 1
      ..eventType = EventType.values.firstWhere(
          (e) => e.name == data['eventType'],
          orElse: () => EventType.regularPoint)
      ..tipoPartido = data['tipoPartido'] as String? ?? ''
      ..competenciaNombre = data['competenciaNombre'] as String?
      ..rotacion = data['rotacion'] as int? ?? 0;
  }

  AttendanceRecord _mapToAttendance(String id, Map<String, dynamic> data) {
    return AttendanceRecord()
      ..id = int.tryParse(id) ?? 0
      ..playerId = data['playerId'] as int? ?? 0
      ..fecha = data['fecha'] != null
          ? DateTime.parse(data['fecha'] as String)
          : DateTime.now()
      ..asistio = data['asistio'] as bool? ?? false
      ..observaciones = data['observaciones'] as String? ?? '';
  }

  Season _mapToSeason(String id, Map<String, dynamic> data) {
    return Season(
      name: data['name'] as String? ?? '',
      year: data['year'] as int? ?? DateTime.now().year,
      isActive: data['isActive'] as bool? ?? false,
      startDate: data['startDate'] != null
          ? DateTime.parse(data['startDate'] as String)
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? DateTime.tryParse(data['endDate'] as String)
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : null,
    )..id = int.tryParse(id) ?? 0;
  }
}
