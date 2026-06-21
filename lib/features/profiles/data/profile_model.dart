class ProfileModel {
  final String id;
  final String clubId;
  final String clubName;
  final String name;
  final String category;
  final String role;
  final bool isActive;

  const ProfileModel({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.name,
    required this.category,
    required this.role,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clubId': clubId,
        'clubName': clubName,
        'name': name,
        'category': category,
        'role': role,
        'isActive': isActive,
      };

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String? ?? '',
        clubId: json['clubId'] as String? ?? '',
        clubName: json['clubName'] as String? ?? '',
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        role: json['role'] as String? ?? 'viewer',
        isActive: json['isActive'] as bool? ?? false,
      );

  ProfileModel copyWith({
    String? id,
    String? clubId,
    String? clubName,
    String? name,
    String? category,
    String? role,
    bool? isActive,
  }) =>
      ProfileModel(
        id: id ?? this.id,
        clubId: clubId ?? this.clubId,
        clubName: clubName ?? this.clubName,
        name: name ?? this.name,
        category: category ?? this.category,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
      );

  String get displayLabel => '$clubName · $category';
  String get roleLabel {
    switch (role) {
      case 'owner':
        return 'Propietario';
      case 'coach':
        return 'Entrenador';
      case 'assistant':
        return 'Asistente';
      default:
        return 'Espectador';
    }
  }
}
