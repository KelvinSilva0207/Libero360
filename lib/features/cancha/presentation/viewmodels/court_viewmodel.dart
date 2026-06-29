import 'package:flutter/foundation.dart';
import '../../data/court_models.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/player.dart';
import '../../../partido/data/match_event.dart';
import '../../../partido/data/court_state.dart';

class CourtViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Player> _allPlayers = [];
  List<PlayerAssignment?> _positions = List.filled(6, null);
  int _rotationCount = 0;
  bool _isServing = true;
  List<RotationRecord> _history = [];
  int? _selectedPositionIndex;
  List<PositionEvent> _events = [];

  bool _isLoading = false;
  String? _error;
  String? _profileId;

  List<Player> get allPlayers => _allPlayers;
  List<PlayerAssignment?> get positions => _positions;
  int get rotationCount => _rotationCount;
  bool get isServing => _isServing;
  List<RotationRecord> get history => _history;
  int? get selectedPositionIndex => _selectedPositionIndex;
  List<PositionEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isLineupSet => _positions.where((p) => p != null).length == 6;

  int get serverIndex => _findPositionIndex(1);

  PlayerAssignment? get serverPlayer {
    final idx = serverIndex;
    if (idx < 0 || idx >= _positions.length) return null;
    return _positions[idx];
  }

  int _findPositionIndex(int positionNumber) {
    for (int i = 0; i < _positions.length; i++) {
      if (_positions[i]?.position == positionNumber) return i;
    }
    return -1;
  }

  Future<void> init({String? profileId}) async {
    _profileId = profileId;
    _isLoading = true;
    notifyListeners();
    try {
      await _db.initialize();
      _allPlayers = await _db.getPlayersByProfile(profileId);
      _error = null;
    } catch (e) {
      _error = 'Error al cargar: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  void setProfileFilter(String? profileId) {
    if (_profileId == profileId) return;
    init(profileId: profileId);
  }

  void assignPlayerDirect(Player player, int index) {
    if (index < 0 || index >= 6) return;
    _positions[index] = PlayerAssignment(
      player: player,
      position: index + 1,
    );
    notifyListeners();
  }

  void selectPlayerForPosition(int positionIndex) {
    _selectedPositionIndex = positionIndex;
    notifyListeners();
  }

  void clearSelectedPosition() {
    _selectedPositionIndex = null;
    notifyListeners();
  }

  void assignPlayer(Player player) {
    final idx = _selectedPositionIndex;
    if (idx == null || idx < 0 || idx >= 6) return;
    _positions[idx] = PlayerAssignment(
      player: player,
      position: idx + 1,
    );
    _selectedPositionIndex = null;
    notifyListeners();
  }

  void removePlayerFromPosition(int index) {
    if (index < 0 || index >= _positions.length) return;
    _positions[index] = null;
    notifyListeners();
  }

  void editNumber(int index, int number) {
    if (index < 0 || index >= _positions.length) return;
    final current = _positions[index];
    if (current == null) return;
    _positions[index] = current.copyWith(numeroOverride: number);
    notifyListeners();
  }

  void rotate() {
    if (!isLineupSet) return;

    final oldLineup = List<PlayerAssignment?>.from(_positions);

    _history.add(RotationRecord(
      rotationNumber: _rotationCount,
      lineup: oldLineup.whereType<PlayerAssignment>().toList(),
      timestamp: DateTime.now(),
      wonServe: true,
    ));

    final newPositions = List<PlayerAssignment?>.filled(6, null);
    for (int i = 0; i < 6; i++) {
      final fromIdx = (i + 1) % 6;
      final current = _positions[fromIdx];
      if (current != null) {
        newPositions[i] = current.copyWith(position: i + 1);
      } else {
        newPositions[i] = null;
      }
    }
    _positions = newPositions;
    _rotationCount++;
    notifyListeners();
  }

  Future<void> recordEvent(int playerId, EventType type) async {
    final idx = _positions.indexWhere((p) => p?.player.id == playerId);
    if (idx < 0) return;

    final posNum = idx + 1;

    _events.add(PositionEvent(
      playerId: playerId,
      positionNumber: posNum,
      eventType: type,
      timestamp: DateTime.now(),
      rotationNumber: _rotationCount,
    ));

    try {
      final event = MatchEvent.create(
        athleteId: playerId,
        matchId: 0,
        setNumero: 1,
        eventType: type,
        tipoPartido: 'practica',
        competenciaNombre: 'Cancha de práctica',
        rotacion: _rotationCount,
        profileId: _profileId,
      );
      await _db.saveMatchEvent(event);
    } catch (_) {}

    notifyListeners();
  }

  List<Player> get unassignedPlayers {
    final assignedIds = _positions
        .whereType<PlayerAssignment>()
        .map((p) => p.player.id)
        .toSet();
    return _allPlayers.where((p) => !assignedIds.contains(p.id)).toList();
  }

  CourtState toCourtState() {
    const visualToZone = [4, 3, 2, 5, 6, 1];
    final zones = List.generate(6, (i) {
      final zoneNum = visualToZone[i];
      final assignment = _positions[i];
      return CourtZone(
        zoneNumber: zoneNum,
        athleteNumber: assignment?.effectiveNumber,
        isLibero: assignment?.player.posicion.index == 4,
        isServing: zoneNum == 1 && _isServing,
      );
    });
    return CourtState(zones: zones);
  }

  void resetLineup() {
    _positions = List.filled(6, null);
    _rotationCount = 0;
    _isServing = true;
    _history = [];
    _selectedPositionIndex = null;
    notifyListeners();
  }
}
