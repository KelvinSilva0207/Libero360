class Season {
  int id = 0;
  String name = '';
  int year = DateTime.now().year;
  bool isActive = false;
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  DateTime createdAt = DateTime.now();

  Season({
    this.id = 0,
    required this.name,
    required this.year,
    this.isActive = false,
    required this.startDate,
    this.endDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get label => '$name $year';
  bool get isCurrentYear => year == DateTime.now().year;

  factory Season.create({required String name, int? year, DateTime? startDate}) {
    final y = year ?? DateTime.now().year;
    return Season(
      name: name,
      year: y,
      startDate: startDate ?? DateTime(y, 1, 1),
      endDate: DateTime(y, 12, 31),
    );
  }

  @override
  String toString() => 'Season(id: $id, $label)';
}
