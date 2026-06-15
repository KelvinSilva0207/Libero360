enum NotificationType {
  // Atletas
  athleteCreated,
  athleteEdited,
  categoryChanged,
  birthday,
  // Asistencia
  attendanceWarning,
  consecutiveAbsences,
  perfectAttendance,
  restPeriodEnded,
  injuryRegistered,
  // Partidos
  matchCreated,
  mvpRegistered,
  matchResultSaved,
  newLeague,
  newTournament,
  // Colaboración
  newCoach,
  invitationReceived,
  invitationAccepted,
}

enum NotificationCategory { atletas, asistencia, partidos, colaboracion }

extension NotificationTypeX on NotificationType {
  NotificationCategory get category {
    switch (this) {
      case NotificationType.athleteCreated:
      case NotificationType.athleteEdited:
      case NotificationType.categoryChanged:
      case NotificationType.birthday:
        return NotificationCategory.atletas;
      case NotificationType.attendanceWarning:
      case NotificationType.consecutiveAbsences:
      case NotificationType.perfectAttendance:
      case NotificationType.restPeriodEnded:
      case NotificationType.injuryRegistered:
        return NotificationCategory.asistencia;
      case NotificationType.matchCreated:
      case NotificationType.mvpRegistered:
      case NotificationType.matchResultSaved:
      case NotificationType.newLeague:
      case NotificationType.newTournament:
        return NotificationCategory.partidos;
      case NotificationType.newCoach:
      case NotificationType.invitationReceived:
      case NotificationType.invitationAccepted:
        return NotificationCategory.colaboracion;
    }
  }

  String get label {
    switch (this) {
      case NotificationType.athleteCreated: return 'Nuevo atleta registrado';
      case NotificationType.athleteEdited: return 'Atleta editado';
      case NotificationType.categoryChanged: return 'Cambio de categoría';
      case NotificationType.birthday: return 'Cumpleaños';
      case NotificationType.attendanceWarning: return 'Múltiples inasistencias';
      case NotificationType.consecutiveAbsences: return 'Faltas consecutivas';
      case NotificationType.perfectAttendance: return 'Asistencia perfecta';
      case NotificationType.restPeriodEnded: return 'Reposo finalizado';
      case NotificationType.injuryRegistered: return 'Lesión registrada';
      case NotificationType.matchCreated: return 'Nuevo partido';
      case NotificationType.mvpRegistered: return 'MVP registrado';
      case NotificationType.matchResultSaved: return 'Resultado guardado';
      case NotificationType.newLeague: return 'Nueva liga';
      case NotificationType.newTournament: return 'Nuevo torneo';
      case NotificationType.newCoach: return 'Nuevo entrenador';
      case NotificationType.invitationReceived: return 'Invitación recibida';
      case NotificationType.invitationAccepted: return 'Invitación aceptada';
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String? relatedAthleteId;
  final String? relatedMatchId;
  final String userId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    this.relatedAthleteId,
    this.relatedMatchId,
    required this.userId,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        createdAt: createdAt,
        read: read ?? this.read,
        relatedAthleteId: relatedAthleteId,
        relatedMatchId: relatedMatchId,
        userId: userId,
      );

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'relatedAthleteId': relatedAthleteId,
        'relatedMatchId': relatedMatchId,
        'userId': userId,
      };

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) =>
      AppNotification(
        id: id,
        type: NotificationType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => NotificationType.athleteCreated,
        ),
        title: map['title'] as String? ?? '',
        message: map['message'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        read: map['read'] as bool? ?? false,
        relatedAthleteId: map['relatedAthleteId'] as String?,
        relatedMatchId: map['relatedMatchId'] as String?,
        userId: map['userId'] as String? ?? '',
      );
}

class NotificationPreference {
  final Map<String, bool> enabledTypes;

  const NotificationPreference({required this.enabledTypes});

  bool isEnabled(NotificationType type) =>
      enabledTypes[type.name] ?? true;

  Map<String, dynamic> toMap() => enabledTypes;

  factory NotificationPreference.fromMap(Map<String, dynamic> map) =>
      NotificationPreference(
        enabledTypes: map.map((k, v) => MapEntry(k, v as bool)),
      );

  factory NotificationPreference.allEnabled() => NotificationPreference(
        enabledTypes: {
          for (final t in NotificationType.values) t.name: true,
        },
      );
}
