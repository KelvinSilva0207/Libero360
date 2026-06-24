import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'team_models.dart';

class InvitationService {
  static final InvitationService instance = InvitationService._internal();
  InvitationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<String?> sendInvitation({
    required String clubId,
    required String clubName,
    required String inviteeEmail,
    required ClubRole role,
  }) async {
    final uid = _uid;
    if (uid == null) return 'No autenticado';

    final inviterDoc = await _firestore.collection('users').doc(uid).get();
    final inviterName = inviterDoc.data()?['nombre'] as String? ?? '';

    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: inviteeEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      return 'No existe una cuenta con ese correo electrónico';
    }

    final inviteeUserId = userQuery.docs.first.id;

    final existingMember = await _firestore
        .collection('clubs')
        .doc(clubId)
        .collection('members')
        .doc(inviteeUserId)
        .get();

    if (existingMember.exists) {
      return 'Ese usuario ya es miembro del club';
    }

    final existingInvitations = await _firestore
        .collection('invitations')
        .where('inviteeEmail', isEqualTo: inviteeEmail)
        .where('clubId', isEqualTo: clubId)
        .where('status', isEqualTo: ClubInvitationStatus.pending.name)
        .get();

    if (existingInvitations.docs.isNotEmpty) {
      return 'Ya existe una invitación pendiente para este usuario';
    }

    await _firestore.collection('invitations').add({
      'clubId': clubId,
      'clubName': clubName,
      'inviterUserId': uid,
      'inviterDisplayName': inviterName,
      'inviteeEmail': inviteeEmail,
      'inviteeUserId': inviteeUserId,
      'role': role.name,
      'status': ClubInvitationStatus.pending.name,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return null;
  }

  Stream<List<ClubInvitation>> myInvitationsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('invitations')
        .where('inviteeUserId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClubInvitation.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<ClubInvitation>> pendingInvitationsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('invitations')
        .where('inviteeUserId', isEqualTo: uid)
        .where('status', isEqualTo: ClubInvitationStatus.pending.name)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClubInvitation.fromMap(d.id, d.data()))
            .toList());
  }

  Future<List<ClubInvitation>> getPendingInvitations() async {
    final uid = _uid;
    if (uid == null) return [];

    final snap = await _firestore
        .collection('invitations')
        .where('inviteeUserId', isEqualTo: uid)
        .where('status', isEqualTo: ClubInvitationStatus.pending.name)
        .get();

    return snap.docs
        .map((d) => ClubInvitation.fromMap(d.id, d.data()))
        .toList();
  }

  Future<String?> acceptInvitation(ClubInvitation invitation) async {
    final uid = _uid;
    if (uid == null) return 'No autenticado';

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final email = userDoc.data()?['email'] as String? ?? '';
      final displayName = userDoc.data()?['nombre'] as String? ?? '';

      await _firestore
          .collection('clubs')
          .doc(invitation.clubId)
          .collection('members')
          .doc(uid)
          .set({
        'userId': uid,
        'email': email,
        'displayName': displayName,
        'role': invitation.role.name,
        'status': MembershipStatus.active.name,
        'joinedAt': DateTime.now().toIso8601String(),
      });

      await _firestore.collection('invitations').doc(invitation.id).update({
        'status': ClubInvitationStatus.accepted.name,
      });

      await _firestore
          .collection('clubs')
          .doc(invitation.clubId)
          .update({
        'memberCount': FieldValue.increment(1),
      });

      return null;
    } catch (e) {
      return 'Error al aceptar invitación: $e';
    }
  }

  Future<String?> rejectInvitation(ClubInvitation invitation) async {
    try {
      await _firestore.collection('invitations').doc(invitation.id).update({
        'status': ClubInvitationStatus.rejected.name,
      });
      return null;
    } catch (e) {
      return 'Error al rechazar invitación: $e';
    }
  }

  Future<String?> cancelInvitation(String invitationId) async {
    try {
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': ClubInvitationStatus.expired.name,
      });
      return null;
    } catch (e) {
      return 'Error al cancelar invitación: $e';
    }
  }
}
