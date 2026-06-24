import 'package:flutter/foundation.dart';
import '../../data/staff_tecnico_models.dart';
import '../../data/staff_tecnico_repository.dart';

class StaffTecnicoViewModel extends ChangeNotifier {
  final StaffTecnicoRepository _repository = StaffTecnicoRepository();

  List<StaffMember> _members = [];
  List<StaffInvitation> _invitations = [];
  List<StaffActivity> _activities = [];
  bool _loading = true;
  String? _error;

  List<StaffMember> get members => _members;
  List<StaffInvitation> get invitations => _invitations;
  List<StaffActivity> get activities => _activities;
  bool get loading => _loading;
  String? get error => _error;

  int get activeCount => _members.where((m) => m.isActive).length;
  int get pendingInvitationCount => _invitations.where((i) => i.isPending).length;

  Future<void> load({String? profileId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getAllMembers(profileId: profileId),
        _repository.getPendingInvitations(profileId: profileId),
        _repository.getRecentActivity(profileId: profileId),
      ]);
      _members = results[0] as List<StaffMember>;
      _invitations = results[1] as List<StaffInvitation>;
      _activities = results[2] as List<StaffActivity>;
      _loading = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }

  Future<bool> addMember(StaffMember member) async {
    try {
      await _repository.saveMember(member);
      await _logActivity(
        ActivityType.staffAdded,
        '👤 ${member.nombre} agregado como ${member.role.displayName}',
        member.nombre,
      );
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMember(StaffMember member) async {
    try {
      await _repository.deleteMember(member.id);
      await _logActivity(
        ActivityType.staffRemoved,
        '🚫 ${member.nombre} eliminado del staff',
        member.nombre,
      );
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendInvitation(StaffInvitation invitation) async {
    try {
      await _repository.saveInvitation(invitation);
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelInvitation(StaffInvitation invitation) async {
    try {
      await _repository.deleteInvitation(invitation.id);
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _logActivity(ActivityType type, String message, String createdBy) async {
    try {
      await _repository.saveActivity(StaffActivity(
        type: type,
        message: message,
        createdBy: createdBy,
      ));
    } catch (_) {}
  }
}
