import 'package:flutter/foundation.dart';
import '../../../../core/services/log_service.dart';
import 'court_state.dart';

class RotationManager extends ChangeNotifier {
  int _currentSet = 1;
  final Map<int, SetRotationState> _sets = {};

  RotationManager() {
    _sets[1] = SetRotationState(setNumber: 1);
  }

  SetRotationState get currentSet => _sets[_currentSet]!;
  int get currentSetNumber => _currentSet;
  int get rotationIndex => currentSet.rotationIndex;
  List<int?> get slots => currentSet.currentSlots;
  List<int?> get initialSlots => currentSet.initialSlots;
  List<RotationSnapshot> get history => currentSet.history;
  RotationStats get stats => currentSet.stats;

  List<SetRotationState> get allSets => _sets.entries
      .map((e) => e.value)
      .toList()
    ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

  static const visualToZone = [4, 3, 2, 5, 6, 1];
  static const zoneToVisual = [null, 5, 2, 1, 0, 3, 4];

  // ========== VALIDATION ==========

  Set<int?> get assignedNumbers => slots.where((s) => s != null).toSet();

  bool hasDuplicates() {
    final nums = slots.where((s) => s != null).toList();
    return nums.toSet().length != nums.length;
  }

  bool isComplete() => slots.where((s) => s != null).length == 6;

  int occupiedCount() => slots.where((s) => s != null).length;

  bool isZoneOccupied(int zoneNumber) {
    final vi = zoneToVisual[zoneNumber];
    if (vi == null) return false;
    return slots[vi] != null;
  }

  int? playerInZone(int zoneNumber) {
    final vi = zoneToVisual[zoneNumber];
    if (vi == null || vi >= slots.length) return null;
    return slots[vi];
  }

  // ========== SWAP ==========

  void swapZones(int zoneA, int zoneB) {
    final viA = zoneToVisual[zoneA];
    final viB = zoneToVisual[zoneB];
    if (viA == null || viB == null) return;
    if (viA >= slots.length || viB >= slots.length) return;

    final temp = slots[viA];
    slots[viA] = slots[viB];
    slots[viB] = temp;

    LogService.instance.auto('🔵 Rotación — swap zonas $zoneA ↔ $zoneB (jugadores ${slots[viA]} ↔ ${slots[viB]})', source: 'RotationManager');
    notifyListeners();
  }

  void clearZone(int zoneNumber) {
    final vi = zoneToVisual[zoneNumber];
    if (vi == null || vi >= slots.length) return;
    slots[vi] = null;
    LogService.instance.auto('🟡 Rotación — zona $zoneNumber liberada', source: 'RotationManager');
    notifyListeners();
  }

  // ========== ASSIGN ==========

  void assignPlayerByZone(int zoneNumber, int playerNumber) {
    final visualIdx = zoneToVisual[zoneNumber];
    if (visualIdx != null) {
      assignPlayer(visualIdx, playerNumber);
    }
  }

  void assignPlayer(int slotIndex, int playerNumber) {
    currentSet.currentSlots[slotIndex] = playerNumber;
    if (currentSet.initialSlots.every((s) => s == null)) {
      currentSet.initialSlots[slotIndex] = playerNumber;
    }
    LogService.instance.auto('🟢 Rotación — jugador #$playerNumber asignado a zona ${visualToZone[slotIndex]}', source: 'RotationManager');
    notifyListeners();
  }

  // ========== ROTATION ==========

  final List<ServiceRecord> serviceHistory = [];
  int _consecutivePoints = 0;
  ServiceRecord? _currentService;

  int get consecutivePoints => _consecutivePoints;

  int? get currentServerNumber => currentSet.currentSlots[5];

  int get totalServices => serviceHistory.length;
  int get bestStreak =>
      serviceHistory.isEmpty
          ? 0
          : serviceHistory.map((r) => r.consecutivePoints).reduce(
              (a, b) => a > b ? a : b,
            );
  double get averagePointsPerServe =>
      serviceHistory.isEmpty
          ? 0
          : serviceHistory.fold(0, (sum, r) => sum + r.consecutivePoints) /
              serviceHistory.length;

  void rotate() {
    if (!isComplete()) {
      LogService.instance.auto('🔴 Rotación — mínimo 6 jugadores requeridos (actual: ${occupiedCount()})', source: 'RotationManager');
      return;
    }
    if (hasDuplicates()) {
      LogService.instance.auto('🔴 Rotación — jugadores duplicados detectados', source: 'RotationManager');
      return;
    }
    _closeCurrentService();
    final newSlots = RotationEngine.rotate(slots);
    currentSet.rotationIndex = (currentSet.rotationIndex + 1) % 6;
    currentSet.currentSlots = newSlots;
    _startNewService();
    notifyListeners();
    currentSet.history.add(RotationSnapshot(
      rotationIndex: currentSet.rotationIndex,
      slots: List.from(newSlots),
      serverNumber: currentSet.currentSlots[5],
      fromInitialRotation: currentSet.rotationIndex,
    ));
    LogService.instance.auto('🔵 Rotación — ejecutada (índice ${currentSet.rotationIndex})', source: 'RotationManager');
  }

  void recordPointForCurrentRotation({required bool localScored}) {
    final hist = currentSet.history;
    if (hist.isNotEmpty) {
      final snap = hist.last;
      if (localScored) {
        snap.pointsWon++;
      } else {
        snap.pointsLost++;
      }
    }
    recordPoint(localScored: localScored, wasServing: true);
  }

  void recordPoint({required bool localScored, required bool wasServing}) {
    if (wasServing && localScored) {
      stats.recordPoint(true);
      _consecutivePoints++;
      if (_currentService != null) _currentService!.consecutivePoints = _consecutivePoints;
    } else if (wasServing && !localScored) {
      stats.recordPoint(false);
      _consecutivePoints = 0;
    } else if (!wasServing && localScored) {
      stats.recordPoint(true);
    }
  }

  void _startNewService() {
    final serverNum = currentSet.currentSlots[5];
    if (serverNum != null) {
      _consecutivePoints = 0;
      _currentService = ServiceRecord(
        setNumber: _currentSet,
        playerNumber: serverNum,
        startTime: DateTime.now(),
      );
    }
  }

  void _closeCurrentService() {
    if (_currentService != null) {
      _currentService!.endTime = DateTime.now();
      serviceHistory.add(_currentService!);
      _currentService = null;
    }
  }

  void prepareNewSet(int setNumber) {
    if (_sets.containsKey(setNumber)) {
      _currentSet = setNumber;
      notifyListeners();
      return;
    }
    final previous = _sets[_currentSet];
    _currentSet = setNumber;
    if (previous != null) {
      _sets[setNumber] = SetRotationState.fromPrevious(setNumber, previous);
    } else {
      _sets[setNumber] = SetRotationState(setNumber: setNumber);
    }
    notifyListeners();
  }

  void usePreviousRotation() {
    final prev = _sets[_currentSet - 1];
    if (prev != null) {
      currentSet.initialSlots = List.from(prev.currentSlots);
      currentSet.currentSlots = List.from(prev.currentSlots);
      currentSet.rotationIndex = 0;
      currentSet.usedPrevious = true;
      notifyListeners();
    }
  }

  void setSlots(List<int?> newSlots, {bool asInitial = true}) {
    if (asInitial) {
      currentSet.initialSlots = List.from(newSlots);
    }
    currentSet.currentSlots = List.from(newSlots);
    currentSet.rotationIndex = 0;
    if (newSlots.any((s) => s != null)) {
      currentSet.history.add(RotationSnapshot(
        rotationIndex: 0,
        slots: List.from(newSlots),
        serverNumber: newSlots[5],
        fromInitialRotation: 0,
      ));
    }
    notifyListeners();
  }

  CourtState courtStateWithLiberos(bool Function(int) isLibero) {
    final zones = List.generate(6, (i) {
      final zoneNum = visualToZone[i];
      final athleteNum = currentSet.currentSlots[i];
      return CourtZone(
        zoneNumber: zoneNum,
        athleteNumber: athleteNum,
        isLibero: athleteNum != null && isLibero(athleteNum),
        isServing: zoneNum == 1,
      );
    });
    return CourtState(zones: zones);
  }

  CourtState get courtState {
    return courtStateWithLiberos((_) => false);
  }
}

class RotationEngine {
  static List<int?> rotate(List<int?> slots) {
    return [
      slots[3],
      slots[0],
      slots[1],
      slots[4],
      slots[5],
      slots[2],
    ];
  }
}

class SetRotationState {
  final int setNumber;
  int rotationIndex;
  bool usedPrevious;
  late List<int?> initialSlots;
  late List<int?> currentSlots;
  final List<RotationSnapshot> history;
  final RotationStats stats;

  SetRotationState({
    required this.setNumber,
    this.rotationIndex = 0,
    this.usedPrevious = false,
    List<int?>? initialSlots,
    List<int?>? currentSlots,
  })  : initialSlots = initialSlots ?? List.filled(6, null),
        currentSlots = currentSlots ?? List.filled(6, null),
        history = [],
        stats = RotationStats();

  SetRotationState.fromPrevious(int setNumber, SetRotationState previous)
      : setNumber = setNumber,
        rotationIndex = 0,
        usedPrevious = false,
        initialSlots = List.from(previous.currentSlots),
        currentSlots = List.from(previous.currentSlots),
        history = [],
        stats = RotationStats();

  bool get hasInitialFormation =>
      initialSlots.any((s) => s != null) ||
      (initialSlots.every((s) => s == null) && setNumber == 1);

  int occupiedCount() => currentSlots.where((s) => s != null).length;
  bool isComplete() => currentSlots.where((s) => s != null).length == 6;
}

class RotationSnapshot {
  final int rotationIndex;
  final int fromInitialRotation;
  final List<int?> slots;
  final int? serverNumber;
  final DateTime timestamp;
  int pointsWon;
  int pointsLost;

  RotationSnapshot({
    required this.rotationIndex,
    required this.slots,
    this.serverNumber,
    this.fromInitialRotation = 0,
    DateTime? timestamp,
    this.pointsWon = 0,
    this.pointsLost = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  int get totalPoints => pointsWon + pointsLost;
  double get effectiveness =>
      totalPoints > 0 ? (pointsWon / totalPoints) * 100 : 0;
}

class RotationStats {
  int pointsWon = 0;
  int pointsLost = 0;

  int get total => pointsWon + pointsLost;
  double get effectiveness => total > 0 ? (pointsWon / total) * 100 : 0;
  int get bestRotation => pointsWon > pointsLost ? 1 : 0;

  void recordPoint(bool won) {
    if (won) {
      pointsWon++;
    } else {
      pointsLost++;
    }
  }

  RotationStats copy() {
    final s = RotationStats();
    s.pointsWon = pointsWon;
    s.pointsLost = pointsLost;
    return s;
  }
}

class ServiceRecord {
  final int setNumber;
  final int playerNumber;
  final DateTime startTime;
  DateTime? endTime;
  int consecutivePoints;

  ServiceRecord({
    required this.setNumber,
    required this.playerNumber,
    required this.startTime,
    this.endTime,
    this.consecutivePoints = 0,
  });

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);
}
