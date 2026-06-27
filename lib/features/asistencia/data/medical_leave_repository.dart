import 'package:sembast/sembast.dart';
import '../../../core/database/database_provider.dart';
import 'medical_leave_model.dart';

class MedicalLeaveRepository {
  static final MedicalLeaveRepository instance = MedicalLeaveRepository._internal();
  MedicalLeaveRepository._internal();

  final StoreRef<int, Map<String, dynamic>> _store = intMapStoreFactory.store('medical_leaves');

  Database? _db;
  bool _initialized = false;

  Future<Database> get _database async {
    if (!_initialized) {
      final path = await databasePath;
      _db = await databaseFactory.openDatabase(path);
      _initialized = true;
    }
    return _db!;
  }

  Future<List<MedicalLeave>> getAll() async {
    final db = await _database;
    final snapshots = await _store.find(
      db,
      finder: Finder(sortOrders: [SortOrder('startDate', false)]),
    );
    return snapshots.map((e) => _fromMap(e.value)..id = e.key).toList();
  }

  Future<List<MedicalLeave>> getActive() async {
    final db = await _database;
    final snapshots = await _store.find(
      db,
      finder: Finder(
        filter: Filter.equals('status', MedicalLeaveStatus.active.index),
        sortOrders: [SortOrder('startDate', false)],
      ),
    );
    return snapshots.map((e) => _fromMap(e.value)..id = e.key).toList();
  }

  Future<List<MedicalLeave>> getByPlayer(int playerId) async {
    final db = await _database;
    final snapshots = await _store.find(
      db,
      finder: Finder(
        filter: Filter.equals('playerId', playerId),
        sortOrders: [SortOrder('startDate', false)],
      ),
    );
    return snapshots.map((e) => _fromMap(e.value)..id = e.key).toList();
  }

  Future<int> save(MedicalLeave leave) async {
    final db = await _database;
    final map = _toMap(leave);
    if (leave.id == 0) {
      return await _store.add(db, map);
    } else {
      await _store.record(leave.id).put(db, map);
      return leave.id;
    }
  }

  Future<bool> delete(int id) async {
    final db = await _database;
    await _store.record(id).delete(db);
    return true;
  }

  Future<bool> hasActiveLeave(int playerId) async {
    final leaves = await getByPlayer(playerId);
    return leaves.any((l) => l.isActive);
  }

  Map<String, dynamic> _toMap(MedicalLeave l) => {
    'playerId': l.playerId,
    'reason': l.reason,
    'startDate': l.startDate.millisecondsSinceEpoch,
    'endDate': l.endDate?.millisecondsSinceEpoch,
    'notes': l.notes,
    'createdAt': l.createdAt.millisecondsSinceEpoch,
    'createdBy': l.createdBy,
    'status': l.status.index,
  };

  MedicalLeave _fromMap(Map<String, dynamic> map) => MedicalLeave(
    playerId: map['playerId'] as int? ?? 0,
    reason: map['reason'] as String? ?? '',
    startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    endDate: map['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int) : null,
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    createdBy: map['createdBy'] as String? ?? '',
    status: MedicalLeaveStatus.values[map['status'] as int? ?? 0],
  );
}
