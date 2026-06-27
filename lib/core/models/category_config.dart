class CategoryConfig {
  final int? id;
  final String name;
  final int minAge;
  final int maxAge;
  final int sortOrder;
  final bool isDefault;

  const CategoryConfig({
    this.id,
    required this.name,
    required this.minAge,
    required this.maxAge,
    required this.sortOrder,
    this.isDefault = false,
  });

  CategoryConfig copyWith({
    int? id,
    String? name,
    int? minAge,
    int? maxAge,
    int? sortOrder,
    bool? isDefault,
  }) => CategoryConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        minAge: minAge ?? this.minAge,
        maxAge: maxAge ?? this.maxAge,
        sortOrder: sortOrder ?? this.sortOrder,
        isDefault: isDefault ?? this.isDefault,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'minAge': minAge,
        'maxAge': maxAge,
        'sortOrder': sortOrder,
        'isDefault': isDefault ? 1 : 0,
      };

  factory CategoryConfig.fromMap(Map<String, dynamic> map, {int? id}) =>
      CategoryConfig(
        id: id,
        name: map['name'] as String? ?? '',
        minAge: map['minAge'] as int? ?? 0,
        maxAge: map['maxAge'] as int? ?? 99,
        sortOrder: map['sortOrder'] as int? ?? 0,
        isDefault: (map['isDefault'] as int? ?? 0) == 1,
      );

  bool matchesAge(int age) => age >= minAge && age <= maxAge;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryConfig &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategoryConfig(id: $id, name: $name, ages: $minAge-$maxAge)';
}
