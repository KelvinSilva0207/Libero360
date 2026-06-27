import 'package:sembast/sembast.dart';
import '../database/database_provider.dart';

enum LogLevel { auto, system, event, error }

class LogEntry {
  final int? id;
  final LogLevel level;
  final String message;
  final String? source;
  final DateTime createdAt;

  LogEntry({this.id, required this.level, required this.message, this.source, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'level': level.name,
        'message': message,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LogEntry.fromMap(Map<String, dynamic> map, {int? id}) => LogEntry(
        id: id,
        level: LogLevel.values.firstWhere((l) => l.name == map['level'], orElse: () => LogLevel.system),
        message: map['message'] as String? ?? '',
        source: map['source'] as String?,
        createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      );

  String get icon => switch (level) {
        LogLevel.auto => '🟢',
        LogLevel.system => '🔵',
        LogLevel.event => '🟡',
        LogLevel.error => '🔴',
      };
}

class LogService {
  static final LogService instance = LogService._internal();
  LogService._internal();

  Database? _db;
  final _store = intMapStoreFactory.store('logs');
  final List<LogEntry> _memoryBuffer = [];
  static const int _maxMemory = 200;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = await databasePath;
    _db = await databaseFactory.openDatabase(path);
    return _db!;
  }

  Future<void> log(LogLevel level, String message, {String? source}) async {
    final entry = LogEntry(level: level, message: message, source: source);
    _memoryBuffer.add(entry);
    if (_memoryBuffer.length > _maxMemory) _memoryBuffer.removeAt(0);
    try {
      final db = await _database;
      await _store.add(db, entry.toMap());
    } catch (_) {}
  }

  Future<void> auto(String message, {String? source}) => log(LogLevel.auto, message, source: source);
  Future<void> system(String message, {String? source}) => log(LogLevel.system, message, source: source);
  Future<void> event(String message, {String? source}) => log(LogLevel.event, message, source: source);
  Future<void> error(String message, {String? source}) => log(LogLevel.error, message, source: source);

  Future<List<LogEntry>> getAll({int limit = 100, LogLevel? level}) async {
    try {
      final db = await _database;
      final finder = Finder(
        sortOrders: [SortOrder('createdAt', false)],
        limit: limit,
      );
      final snapshots = await _store.find(db, finder: finder);
      return snapshots.map((e) => LogEntry.fromMap(e.value, id: e.key)).toList();
    } catch (_) {
      return _memoryBuffer.reversed.take(limit).toList();
    }
  }

  Future<void> clear() async {
    try {
      final db = await _database;
      await _store.delete(db);
    } catch (_) {}
  }
}
