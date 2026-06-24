enum StaffRole {
  administrador,
  entrenador,
  asistente,
  analista,
  preparadorFisico;

  String get displayName {
    switch (this) {
      case StaffRole.administrador:
        return 'Administrador';
      case StaffRole.entrenador:
        return 'Entrenador';
      case StaffRole.asistente:
        return 'Asistente';
      case StaffRole.analista:
        return 'Analista';
      case StaffRole.preparadorFisico:
        return 'Preparador Físico';
    }
  }

  String get icon {
    switch (this) {
      case StaffRole.administrador:
        return '⚙';
      case StaffRole.entrenador:
        return '🏐';
      case StaffRole.asistente:
        return '📋';
      case StaffRole.analista:
        return '📊';
      case StaffRole.preparadorFisico:
        return '💪';
    }
  }
}

enum StaffStatus { activo, sinConexion, invitado }

enum ActivityType {
  matchStarted,
  attendanceRecorded,
  athleteAdded,
  settingsChanged,
  staffAdded,
  staffRemoved;

  String get icon {
    switch (this) {
      case ActivityType.matchStarted:
        return '🏐';
      case ActivityType.attendanceRecorded:
        return '📅';
      case ActivityType.athleteAdded:
        return '👥';
      case ActivityType.settingsChanged:
        return '⚙';
      case ActivityType.staffAdded:
        return '👤';
      case ActivityType.staffRemoved:
        return '🚫';
    }
  }
}

class StaffMember {
  int id;
  String nombre;
  String correo;
  String? fotoUrl;
  StaffRole role;
  StaffStatus status;
  String? profileId;
  String? clubId;
  DateTime createdAt;
  String? createdBy;

  StaffMember({
    this.id = 0,
    required this.nombre,
    required this.correo,
    this.fotoUrl,
    required this.role,
    this.status = StaffStatus.activo,
    this.profileId,
    this.clubId,
    DateTime? createdAt,
    this.createdBy,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive => status == StaffStatus.activo;

  StaffMember copyWith({
    int? id,
    String? nombre,
    String? correo,
    String? fotoUrl,
    StaffRole? role,
    StaffStatus? status,
    String? profileId,
    String? clubId,
    DateTime? createdAt,
    String? createdBy,
  }) =>
      StaffMember(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        correo: correo ?? this.correo,
        fotoUrl: fotoUrl ?? this.fotoUrl,
        role: role ?? this.role,
        status: status ?? this.status,
        profileId: profileId ?? this.profileId,
        clubId: clubId ?? this.clubId,
        createdAt: createdAt ?? this.createdAt,
        createdBy: createdBy ?? this.createdBy,
      );
}

class StaffInvitation {
  int id;
  String email;
  StaffRole role;
  String status;
  DateTime createdAt;
  String? createdBy;
  String? profileId;
  String? clubId;

  StaffInvitation({
    this.id = 0,
    required this.email,
    required this.role,
    this.status = 'pending',
    DateTime? createdAt,
    this.createdBy,
    this.profileId,
    this.clubId,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPending => status == 'pending';
}

class StaffActivity {
  int id;
  ActivityType type;
  String message;
  String createdBy;
  DateTime createdAt;
  String? profileId;
  String? clubId;

  StaffActivity({
    this.id = 0,
    required this.type,
    required this.message,
    required this.createdBy,
    DateTime? createdAt,
    this.profileId,
    this.clubId,
  }) : createdAt = createdAt ?? DateTime.now();
}
