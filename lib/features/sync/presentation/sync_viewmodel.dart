import 'package:flutter/foundation.dart';
import '../data/sync_service.dart';

enum SyncState { idle, syncing, completed, error }

class SyncViewModel extends ChangeNotifier {
  final SyncService _service = SyncService.instance;

  SyncState _state = SyncState.idle;
  String? _error;
  String _currentOperation = '';
  int _progress = 0;
  final int _totalSteps = 5;
  DateTime? _lastSyncDate;

  SyncState get state => _state;
  String? get error => _error;
  String get currentOperation => _currentOperation;
  int get progress => _progress;
  int get totalSteps => _totalSteps;
  bool get isSyncing => _state == SyncState.syncing;
  DateTime? get lastSyncDate => _lastSyncDate;

  String? get lastSyncDateFormatted {
    if (_lastSyncDate == null) return null;
    final d = _lastSyncDate!.day.toString().padLeft(2, '0');
    final m = _lastSyncDate!.month.toString().padLeft(2, '0');
    final y = _lastSyncDate!.year.toString();
    final h = _lastSyncDate!.hour.toString().padLeft(2, '0');
    final min = _lastSyncDate!.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Future<void> syncAll(String profileId, String clubId) async {
    _state = SyncState.syncing;
    _error = null;
    _progress = 0;
    _currentOperation = 'Subiendo perfiles...';
    notifyListeners();

    try {
      await _service.uploadProfiles();
      _progress = 1;
      _currentOperation = 'Subiendo atletas...';
      notifyListeners();

      await _service.uploadPlayers(profileId, clubId);
      _progress = 2;
      _currentOperation = 'Subiendo partidos...';
      notifyListeners();

      await _service.uploadMatches(profileId, clubId);
      _progress = 3;
      _currentOperation = 'Subiendo asistencias...';
      notifyListeners();

      await _service.uploadAttendance(profileId, clubId);
      _progress = 4;
      _currentOperation = 'Subiendo estadísticas...';
      notifyListeners();

      await _service.uploadStats(profileId, clubId);
      _progress = 5;
      _lastSyncDate = DateTime.now();
      _currentOperation = 'Sincronización completada';
      _state = SyncState.completed;
    } catch (e) {
      _error = e.toString();
      _state = SyncState.error;
    }
    notifyListeners();
  }

  Future<void> uploadAll(String profileId, String clubId) async {
    await syncAll(profileId, clubId);
  }

  Future<void> downloadAll(String profileId, String clubId) async {
    _state = SyncState.syncing;
    _error = null;
    _progress = 0;
    _currentOperation = 'Descargando perfiles...';
    notifyListeners();

    try {
      await _service.downloadProfiles();
      _progress = 1;
      _currentOperation = 'Descargando atletas...';
      notifyListeners();

      await _service.downloadPlayers(profileId, clubId);
      _progress = 2;
      _currentOperation = 'Descargando partidos...';
      notifyListeners();

      await _service.downloadMatches(profileId, clubId);
      _progress = 3;
      _currentOperation = 'Descargando asistencias...';
      notifyListeners();

      await _service.downloadAttendance(profileId, clubId);
      _progress = 4;
      _currentOperation = 'Descargando estadísticas...';
      notifyListeners();

      await _service.downloadStats(profileId, clubId);
      _progress = 5;
      _lastSyncDate = DateTime.now();
      _currentOperation = 'Descarga completada';
      _state = SyncState.completed;
    } catch (e) {
      _error = e.toString();
      _state = SyncState.error;
    }
    notifyListeners();
  }

  void reset() {
    _state = SyncState.idle;
    _error = null;
    _currentOperation = '';
    _progress = 0;
    notifyListeners();
  }
}
