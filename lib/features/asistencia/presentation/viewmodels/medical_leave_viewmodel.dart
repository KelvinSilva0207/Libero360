import 'package:flutter/foundation.dart';
import '../../data/medical_leave_model.dart';
import '../../data/medical_leave_repository.dart';
import '../../../../core/services/log_service.dart';
import '../../../notifications/data/notification_service.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../../core/utils/name_formatter.dart';

class MedicalLeaveViewModel extends ChangeNotifier {
  final MedicalLeaveRepository _repository = MedicalLeaveRepository.instance;
  final LogService _log = LogService.instance;
  final NotificationService _notif = NotificationService.instance;
  final DatabaseService _db = DatabaseService.instance;

  List<MedicalLeave> _allLeaves = [];
  List<MedicalLeave> _activeLeaves = [];
  bool _loading = false;

  List<MedicalLeave> get allLeaves => _allLeaves;
  List<MedicalLeave> get activeLeaves => _activeLeaves;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _allLeaves = await _repository.getAll();
      _activeLeaves = await _repository.getActive();
      _checkExpiringSoon();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> _checkExpiringSoon() async {
    try {
      final expiring = _activeLeaves.where((l) => l.isExpiringSoon).toList();
      for (final l in expiring) {
        final player = await _db.getPlayerById(l.playerId);
        final name = player != null ? NameFormatter.playerDisplayName(player) : 'Atleta';
        final daysLeft = l.endDate != null ? l.endDate!.difference(DateTime.now()).inDays : 3;
        await _notif.notifyRestExpiringSoon(name, daysLeft);
        await _log.auto('Reposo próximo a vencer: $name ($daysLeft días)', source: 'MedicalLeaveViewModel');
      }
    } catch (_) {}
  }

  Future<int> registerLeave(MedicalLeave leave) async {
    final id = await _repository.save(leave);
    final player = await _db.getPlayerById(leave.playerId);
    final name = player != null ? NameFormatter.playerDisplayName(player) : 'Atleta';
    await _log.event('Reposo registrado: $name - ${leave.reason}', source: 'MedicalLeaveViewModel');
    await load();
    return id;
  }

  Future<void> finishLeave(int id) async {
    final leaves = _allLeaves.where((l) => l.id == id);
    for (final l in leaves) {
      final updated = MedicalLeave(
        playerId: l.playerId,
        reason: l.reason,
        startDate: l.startDate,
        endDate: l.endDate,
        notes: l.notes,
        createdAt: l.createdAt,
        createdBy: l.createdBy,
        status: MedicalLeaveStatus.finished,
      )..id = l.id;
      await _repository.save(updated);
    }
    await load();
  }

  Future<void> cancelLeave(int id) async {
    final leaves = _allLeaves.where((l) => l.id == id);
    for (final l in leaves) {
      final updated = MedicalLeave(
        playerId: l.playerId,
        reason: l.reason,
        startDate: l.startDate,
        endDate: l.endDate,
        notes: l.notes,
        createdAt: l.createdAt,
        createdBy: l.createdBy,
        status: MedicalLeaveStatus.cancelled,
      )..id = l.id;
      await _repository.save(updated);
    }
    await load();
  }

  Future<bool> hasActiveLeave(int playerId) async {
    return _repository.hasActiveLeave(playerId);
  }

  List<MedicalLeave> getLeavesByPlayer(int playerId) {
    return _allLeaves.where((l) => l.playerId == playerId).toList();
  }

  List<MedicalLeave> getExpiringSoon() {
    return _activeLeaves.where((l) => l.isExpiringSoon).toList();
  }
}
