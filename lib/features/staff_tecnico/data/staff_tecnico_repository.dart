import '../../estadisticas/data/local_db/database_service.dart';
import 'staff_tecnico_models.dart';

class StaffTecnicoRepository {
  final DatabaseService _db = DatabaseService.instance;

  Future<List<StaffMember>> getAllMembers({String? profileId}) async {
    await _db.initialize();
    if (profileId != null) return _db.getStaffByProfile(profileId);
    return _db.getAllStaffMembers();
  }

  Future<List<StaffInvitation>> getPendingInvitations({String? profileId}) async {
    await _db.initialize();
    if (profileId != null) return _db.getInvitationsByProfile(profileId);
    return _db.getAllStaffInvitations();
  }

  Future<List<StaffActivity>> getRecentActivity({String? profileId, int limit = 20}) async {
    await _db.initialize();
    if (profileId != null) return _db.getActivityByProfile(profileId, limit: limit);
    return _db.getAllStaffActivity(limit: limit);
  }

  Future<int> saveMember(StaffMember member) async {
    await _db.initialize();
    return _db.saveStaffMember(member);
  }

  Future<void> deleteMember(int id) async {
    await _db.initialize();
    await _db.deleteStaffMember(id);
  }

  Future<int> saveInvitation(StaffInvitation invitation) async {
    await _db.initialize();
    return _db.saveStaffInvitation(invitation);
  }

  Future<void> deleteInvitation(int id) async {
    await _db.initialize();
    await _db.deleteStaffInvitation(id);
  }

  Future<int> saveActivity(StaffActivity activity) async {
    await _db.initialize();
    return _db.saveStaffActivity(activity);
  }

  Future<int> getActiveCount({String? profileId}) async {
    await _db.initialize();
    if (profileId != null) return _db.countStaffByProfile(profileId);
    return _db.countActiveStaff();
  }

  Future<int> getPendingInvitationCount({String? profileId}) async {
    await _db.initialize();
    final all = await getPendingInvitations(profileId: profileId);
    return all.length;
  }
}
