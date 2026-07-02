import 'package:flutter/foundation.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../data/libero_config.dart';

class LiberoManager extends ChangeNotifier {
  final LiberoConfig config;
  final List<LiberoSwapRecord> history = [];
  final List<LiberoLogEntry> logs = [];

  // current court state: playerNumber -> isLibero on court
  final Set<int> _liberosOnCourt = {};

  LiberoManager({required this.config});

  bool get hasLiberos => config.hasLiberos;
  Set<int> get liberosOnCourt => Set.unmodifiable(_liberosOnCourt);

  bool isLibero(int playerNumber) => _liberosOnCourt.contains(playerNumber);

  bool canSwap(int playerNumber) {
    if (!hasLiberos) return false;
    if (config.changeMode == LiberoChangeMode.manual) return true;
    // Auto mode: check if player is associated
    return _isAssociated(playerNumber);
  }

  bool _isAssociated(int playerNumber) {
    if (config.associatedPlayer1?.numero == playerNumber) return true;
    if (config.associatedPlayer2?.numero == playerNumber) return true;
    return false;
  }

  Player? liberoFor(int playerNumber) {
    if (config.associatedPlayer1?.numero == playerNumber) return config.libero1;
    if (config.associatedPlayer2?.numero == playerNumber) return config.libero2;
    return null;
  }

  void performSwap({
    required int playerOutNumber,
    required String playerOutName,
    required int playerInNumber,
    required String playerInName,
    required int setNumber,
    required int rotationIndex,
    bool isManual = true,
  }) {
    // If putting libero in, remove from court set
    // If taking libero out, add back
    if (_liberosOnCourt.contains(playerOutNumber)) {
      _liberosOnCourt.remove(playerOutNumber);
    } else {
      _liberosOnCourt.add(playerInNumber);
    }

    final record = LiberoSwapRecord(
      liberoPlayerNumber: playerInNumber,
      liberoName: playerInName,
      associatedPlayerNumber: playerOutNumber,
      associatedPlayerName: playerOutName,
      setNumber: setNumber,
      rotationIndex: rotationIndex,
      isManual: isManual,
      isEntry: !_liberosOnCourt.contains(playerOutNumber),
    );
    history.add(record);

    logs.add(LiberoLogEntry(
      message: isManual
          ? 'LIBERO: cambio realizado — $playerInName (#$playerInNumber) ↔ $playerOutName'
          : 'LIBERO: sugerencia automática — $playerInName (#$playerInNumber)',
      level: isManual ? LiberoLogLevel.success : LiberoLogLevel.info,
    ));

    notifyListeners();
  }

  void cancelSwap({
    required int setNumber,
    required int rotationIndex,
    String reason = 'cambio cancelado',
  }) {
    logs.add(LiberoLogEntry(
      message: 'LIBERO: $reason',
      level: LiberoLogLevel.warning,
    ));
    notifyListeners();
  }

  void checkAutoZone({
    required List<int?> currentSlots,
    required int setNumber,
    required int rotationIndex,
    required void Function(int playerOutNumber, int playerInNumber) onSuggested,
  }) {
    if (config.changeMode != LiberoChangeMode.automatic) return;

    for (final slot in currentSlots) {
      if (slot == null) continue;
      if (_isAssociated(slot)) {
        // Check if associated player is in z5 (visual idx 3) or z6 (visual idx 4)
        // slots order is [z4, z3, z2, z5, z6, z1]
        final idx = currentSlots.indexOf(slot);
        if (idx == 3 || idx == 4) {
          final libero = liberoFor(slot);
          if (libero != null && !_liberosOnCourt.contains(libero.numero)) {
            onSuggested(slot, libero.numero ?? 0);
          }
        }
      }
    }
  }
}
