import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/club_data_service.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/player.dart';
import '../../../estadisticas/data/models/match.dart';
import '../../../estadisticas/data/models/season.dart';
import '../../../estadisticas/data/models/stat_event.dart';
import '../../../estadisticas/data/models/attendance_record.dart';
import '../../../partido/data/match_event.dart';
import '../../data/team_models.dart';
import '../../data/club_service.dart';
import '../../data/invitation_service.dart';
import '../../data/permission_service.dart';

class ClubViewModel extends ChangeNotifier {
  final ClubService _clubService = ClubService.instance;
  final InvitationService _invitationService = InvitationService.instance;
  final PermissionService _permissionService = PermissionService.instance;
  final ClubDataService _dataService = ClubDataService.instance;

  Club? _currentClub;
  List<Club> _myClubs = [];
  List<ClubMember> _members = [];
  List<ClubInvitation> _invitations = [];
  List<Player> _athletes = [];
  List<Match> _clubMatches = [];
  List<StatEvent> _statEvents = [];
  List<MatchEvent> _matchEvents = [];
  List<AttendanceRecord> _attendanceRecords = [];
  List<Season> _seasons = [];
  bool _loading = true;
  String? _error;
  String? _profileId;
  StreamSubscription? _clubSub;
  StreamSubscription? _membersSub;
  StreamSubscription? _myClubsSub;
  StreamSubscription? _invitationsSub;
  StreamSubscription? _athletesSub;
  StreamSubscription? _matchesSub;
  StreamSubscription? _statEventsSub;
  StreamSubscription? _matchEventsSub;
  StreamSubscription? _attendanceSub;
  StreamSubscription? _seasonsSub;

  Club? get currentClub => _currentClub;
  List<Club> get myClubs => _myClubs;
  List<ClubMember> get members => _members;
  List<ClubInvitation> get invitations => _invitations;
  List<Player> get athletes => _athletes;
  List<Match> get clubMatches => _clubMatches;
  List<StatEvent> get statEvents => _statEvents;
  List<MatchEvent> get matchEvents => _matchEvents;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  List<Season> get seasons => _seasons;
  bool get loading => _loading;
  String? get error => _error;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  ClubRole? get myRole {
    if (_currentClub == null || uid == null) return null;
    return _members.cast<ClubMember?>().firstWhere(
      (m) => m!.userId == uid,
      orElse: () => null,
    )?.role;
  }

  bool get isOwner => myRole == ClubRole.owner;
  bool get isEntrenador =>
      myRole == ClubRole.owner || myRole == ClubRole.entrenador;

  void init() {
    _loading = true;
    notifyListeners();
    _listenMyClubs();
  }

  void _listenMyClubs() {
    _myClubsSub?.cancel();
    _myClubsSub = _clubService.myClubsStream().listen((clubs) {
      _myClubs = clubs;
      if (_currentClub == null && clubs.isNotEmpty) {
        setCurrentClub(clubs.first.id);
      } else if (_currentClub != null &&
          !clubs.any((c) => c.id == _currentClub!.id)) {
        _currentClub = null;
        _members = [];
        notifyListeners();
      } else {
        _loading = false;
        notifyListeners();
      }
    });
  }

  void setCurrentClub(String clubId) {
    _clubSub?.cancel();
    _membersSub?.cancel();
    _invitationsSub?.cancel();
    _cancelDataStreams();

    _clubSub = _clubService.clubStream(clubId).listen((club) {
      if (club != null) {
        _currentClub = club;
        _loading = false;
        notifyListeners();
        _initDataStreams();
      }
    });

    _membersSub = _clubService.membersStream(clubId).listen((members) {
      _members = members;
      notifyListeners();
    });

    _invitationsSub = _invitationService.myInvitationsStream().listen((inv) {
      _invitations = inv;
      notifyListeners();
    });
  }

  Future<void> setProfileFilter(String? profileId) async {
    if (_profileId == profileId) return;
    _profileId = profileId;
    final db = DatabaseService.instance;
    _athletes = await db.getPlayersByProfile(profileId);
    _clubMatches = await db.getMatchesByProfile(profileId);
    _statEvents = await db.getStatsByProfile(profileId);
    _attendanceRecords = await db.getAttendanceByProfile(profileId);
    notifyListeners();
  }

  void _initDataStreams() {
    _athletesSub = _dataService.streamPlayers().listen((list) {
      _athletes = _profileId != null ? list.where((p) => p.profileId == _profileId).toList() : list;
      notifyListeners();
    });
    _matchesSub = _dataService.streamMatches().listen((list) {
      _clubMatches = _profileId != null ? list.where((m) => m.profileId == _profileId).toList() : list;
      notifyListeners();
    });
    _statEventsSub = _dataService.streamStatEvents().listen((list) {
      _statEvents = _profileId != null ? list.where((e) => e.profileId == _profileId).toList() : list;
      notifyListeners();
    });
    _matchEventsSub = _dataService.streamMatchEvents().listen((list) {
      _matchEvents = _profileId != null ? list.where((e) => e.profileId == _profileId).toList() : list;
      notifyListeners();
    });
    _attendanceSub = _dataService.streamAttendance().listen((list) {
      _attendanceRecords = _profileId != null ? list.where((r) => r.profileId == _profileId).toList() : list;
      notifyListeners();
    });
    _seasonsSub = _dataService.streamSeasons().listen((list) {
      _seasons = list;
      notifyListeners();
    });
  }

  void _cancelDataStreams() {
    _athletesSub?.cancel();
    _matchesSub?.cancel();
    _statEventsSub?.cancel();
    _matchEventsSub?.cancel();
    _attendanceSub?.cancel();
    _seasonsSub?.cancel();
  }

  Future<String?> createClub(String name) async {
    try {
      final id = await _clubService.createClub(name);
      setCurrentClub(id);
      return null;
    } catch (e) {
      return 'Error al crear el club';
    }
  }

  Future<String?> inviteMember({
    required String email,
    required ClubRole role,
  }) async {
    if (_currentClub == null) return 'No hay club seleccionado';
    return _invitationService.sendInvitation(
      clubId: _currentClub!.id,
      clubName: _currentClub!.name,
      inviteeEmail: email,
      role: role,
    );
  }

  Future<String?> acceptInvitation(ClubInvitation invitation) async {
    try {
      await _invitationService.acceptInvitation(invitation);
      return null;
    } catch (e) {
      return 'Error al aceptar invitación';
    }
  }

  Future<String?> rejectInvitation(ClubInvitation invitation) async {
    try {
      await _invitationService.rejectInvitation(invitation);
      return null;
    } catch (e) {
      return 'Error al rechazar invitación';
    }
  }

  Future<String?> removeMember(String memberId) async {
    if (_currentClub == null) return 'No hay club seleccionado';
    try {
      await _clubService.removeMember(_currentClub!.id, memberId);
      return null;
    } catch (e) {
      return 'Error al eliminar miembro';
    }
  }

  Future<String?> updateMemberRole(String memberId, ClubRole newRole) async {
    if (_currentClub == null) return 'No hay club seleccionado';
    try {
      await _clubService.updateMemberRole(_currentClub!.id, memberId, newRole);
      return null;
    } catch (e) {
      return 'Error al actualizar rol';
    }
  }

  Future<String?> transferOwnership(String newOwnerId) async {
    if (_currentClub == null) return 'No hay club seleccionado';
    try {
      await _clubService.transferOwnership(_currentClub!.id, newOwnerId);
      return null;
    } catch (e) {
      return 'Error al transferir propiedad';
    }
  }

  Future<String?> deleteClub() async {
    if (_currentClub == null) return 'No hay club seleccionado';
    try {
      await _clubService.deleteClub(_currentClub!.id);
      _currentClub = null;
      _members = [];
      notifyListeners();
      return null;
    } catch (e) {
      return 'Error al eliminar club';
    }
  }

  bool canInvite() =>
      _permissionService.canInviteMembers(myRole ?? ClubRole.asistente);
  bool canRemoveMembers() =>
      _permissionService.canRemoveMembers(myRole ?? ClubRole.asistente);
  bool canCreateEditAthletes() =>
      _permissionService.canCreateEditAthletes(myRole ?? ClubRole.asistente);
  bool canDeleteAthletes() =>
      _permissionService.canDeleteAthletes(myRole ?? ClubRole.asistente);
  bool canCreateEditMatches() =>
      _permissionService.canCreateEditMatches(myRole ?? ClubRole.asistente);
  bool canTakeAttendance() =>
      _permissionService.canTakeAttendance(myRole ?? ClubRole.asistente);
  bool canRecordMatchEvents() =>
      _permissionService.canRecordMatchEvents(myRole ?? ClubRole.asistente);

  @override
  void dispose() {
    _clubSub?.cancel();
    _membersSub?.cancel();
    _myClubsSub?.cancel();
    _invitationsSub?.cancel();
    _cancelDataStreams();
    super.dispose();
  }
}
