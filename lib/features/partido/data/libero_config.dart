import '../../estadisticas/data/models/models.dart';

enum LiberoMode { none, one, two }

enum LiberoChangeMode { manual, automatic }

class LiberoConfig {
  LiberoMode count;
  LiberoChangeMode changeMode;
  Player? libero1;
  Player? libero2;
  Player? associatedPlayer1;
  Player? associatedPlayer2;
  Set<int> liberoPlayerIds;

  LiberoConfig({
    this.count = LiberoMode.none,
    this.changeMode = LiberoChangeMode.manual,
    this.libero1,
    this.libero2,
    this.associatedPlayer1,
    this.associatedPlayer2,
    Set<int>? liberoPlayerIds,
  }) : liberoPlayerIds = liberoPlayerIds ?? {};

  bool get hasLiberos => count != LiberoMode.none;
  int get liberoCount => count == LiberoMode.one ? 1 : (count == LiberoMode.two ? 2 : 0);

  bool isLibero(Player p) => liberoPlayerIds.contains(p.id);
}

class LiberoSwapRecord {
  final int liberoPlayerNumber;
  final String liberoName;
  final int? associatedPlayerNumber;
  final String? associatedPlayerName;
  final DateTime timestamp;
  final int setNumber;
  final int rotationIndex;
  final bool isManual;
  final bool isEntry;
  final String? reason;

  LiberoSwapRecord({
    required this.liberoPlayerNumber,
    required this.liberoName,
    this.associatedPlayerNumber,
    this.associatedPlayerName,
    DateTime? timestamp,
    required this.setNumber,
    required this.rotationIndex,
    this.isManual = true,
    this.isEntry = true,
    this.reason,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum LiberoLogLevel { info, success, warning }

class LiberoLogEntry {
  final String message;
  final LiberoLogLevel level;
  final DateTime timestamp;

  LiberoLogEntry({
    required this.message,
    this.level = LiberoLogLevel.info,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get icon {
    switch (level) {
      case LiberoLogLevel.success:
        return '🟢';
      case LiberoLogLevel.info:
        return '🔵';
      case LiberoLogLevel.warning:
        return '🔴';
    }
  }
}
