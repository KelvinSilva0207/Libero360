enum ClubRole { owner, entrenador, asistente }

enum MembershipStatus { active, pending }

class Club {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;

  const Club({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerId': ownerId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Club.fromMap(String id, Map<String, dynamic> map) => Club(
        id: id,
        name: map['name'] as String? ?? '',
        ownerId: map['ownerId'] as String? ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
      );
}

class ClubMember {
  final String id;
  final String userId;
  final String email;
  final String displayName;
  final ClubRole role;
  final MembershipStatus status;

  const ClubMember({
    required this.id,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
  });

  bool get isOwner => role == ClubRole.owner;
  bool get isActive => status == MembershipStatus.active;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'role': role.name,
        'status': status.name,
      };

  factory ClubMember.fromMap(String id, Map<String, dynamic> map) => ClubMember(
        id: id,
        userId: map['userId'] as String? ?? '',
        email: map['email'] as String? ?? '',
        displayName: map['displayName'] as String? ?? '',
        role: ClubRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => ClubRole.asistente,
        ),
        status: MembershipStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => MembershipStatus.pending,
        ),
      );

  ClubMember copyWith({
    String? id,
    String? userId,
    String? email,
    String? displayName,
    ClubRole? role,
    MembershipStatus? status,
  }) =>
      ClubMember(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        status: status ?? this.status,
      );
}

class ClubInvitation {
  final String id;
  final String clubId;
  final String clubName;
  final String inviterUserId;
  final String inviterDisplayName;
  final String inviteeEmail;
  final ClubRole role;
  final DateTime createdAt;

  const ClubInvitation({
    required this.id,
    required this.clubId,
    required this.clubName,
    required this.inviterUserId,
    required this.inviterDisplayName,
    required this.inviteeEmail,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'clubId': clubId,
        'clubName': clubName,
        'inviterUserId': inviterUserId,
        'inviterDisplayName': inviterDisplayName,
        'inviteeEmail': inviteeEmail,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ClubInvitation.fromMap(String id, Map<String, dynamic> map) =>
      ClubInvitation(
        id: id,
        clubId: map['clubId'] as String? ?? '',
        clubName: map['clubName'] as String? ?? '',
        inviterUserId: map['inviterUserId'] as String? ?? '',
        inviterDisplayName: map['inviterDisplayName'] as String? ?? '',
        inviteeEmail: map['inviteeEmail'] as String? ?? '',
        role: ClubRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => ClubRole.asistente,
        ),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
      );
}
