enum CourtPerspective { right, left }

class CourtZone {
  final int zoneNumber;
  final int? athleteNumber;
  final bool isLibero;
  final bool isServing;

  const CourtZone({
    required this.zoneNumber,
    this.athleteNumber,
    this.isLibero = false,
    this.isServing = false,
  });

  bool get hasAthlete => athleteNumber != null;

  CourtZone copyWith({
    int? athleteNumber,
    bool? isLibero,
    bool? isServing,
  }) {
    return CourtZone(
      zoneNumber: zoneNumber,
      athleteNumber: athleteNumber ?? this.athleteNumber,
      isLibero: isLibero ?? this.isLibero,
      isServing: isServing ?? this.isServing,
    );
  }
}

class CourtState {
  final List<CourtZone> zones;
  final CourtPerspective perspective;

  CourtState({
    required this.zones,
    this.perspective = CourtPerspective.right,
  }) : assert(zones.length == 6);

  CourtZone zone(int number) => zones[number - 1];

  int zoneAtVisualPosition(int visualPos) {
    const rightMap = [4, 3, 2, 5, 6, 1];
    const leftMap = [2, 3, 4, 1, 6, 5];
    return perspective == CourtPerspective.right
        ? rightMap[visualPos]
        : leftMap[visualPos];
  }

  int visualPositionForZone(int zoneNumber) {
    for (int i = 0; i < 6; i++) {
      if (zoneAtVisualPosition(i) == zoneNumber) return i;
    }
    return zoneNumber - 1;
  }

  static CourtState empty() => CourtState(
        zones: List.generate(6, (i) => CourtZone(zoneNumber: i + 1)),
      );

  CourtState withPerspective(CourtPerspective p) =>
      CourtState(zones: zones, perspective: p);

  CourtState withZone(int zoneNumber, CourtZone updated) {
    final copy = List<CourtZone>.from(zones);
    copy[zoneNumber - 1] = updated;
    return CourtState(zones: copy, perspective: perspective);
  }
}
