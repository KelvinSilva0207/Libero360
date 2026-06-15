import 'team_models.dart';
import 'club_service.dart';

class PermissionService {
  static final PermissionService instance = PermissionService._internal();
  PermissionService._internal();

  bool canInviteMembers(ClubRole role) => role == ClubRole.owner;
  bool canRemoveMembers(ClubRole role) => role == ClubRole.owner;
  bool canDeleteClub(ClubRole role) => role == ClubRole.owner;
  bool canTransferOwnership(ClubRole role) => role == ClubRole.owner;
  bool canChangeSettings(ClubRole role) => role == ClubRole.owner;

  bool canCreateEditAthletes(ClubRole role) =>
      role == ClubRole.owner || role == ClubRole.entrenador;
  bool canDeleteAthletes(ClubRole role) => role == ClubRole.owner;

  bool canCreateEditMatches(ClubRole role) =>
      role == ClubRole.owner || role == ClubRole.entrenador;
  bool canDeleteMatches(ClubRole role) => role == ClubRole.owner;

  bool canTakeAttendance(ClubRole role) =>
      role == ClubRole.owner || role == ClubRole.entrenador || role == ClubRole.asistente;

  bool canViewStats(ClubRole role) => true;

  bool canRecordMatchEvents(ClubRole role) =>
      role == ClubRole.owner || role == ClubRole.entrenador || role == ClubRole.asistente;

  Future<ClubRole?> getRole(String clubId, String userId) async {
    final member = await ClubService.instance.getMemberRole(clubId, userId);
    return member;
  }
}
