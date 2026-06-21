class SubstitutionRecord {
  final int playerOutNumber;
  final int playerInNumber;
  final String playerOutName;
  final String playerInName;
  final DateTime timestamp;
  final int setNumber;
  final int rotationIndex;

  SubstitutionRecord({
    required this.playerOutNumber,
    required this.playerInNumber,
    required this.playerOutName,
    required this.playerInName,
    required this.timestamp,
    required this.setNumber,
    required this.rotationIndex,
  });
}
