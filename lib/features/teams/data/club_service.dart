import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'team_models.dart';

class ClubService {
  static final ClubService instance = ClubService._internal();
  ClubService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference get _clubs => _firestore.collection('clubs');

  /// Create a new club and add creator as owner member.
  Future<String> createClub(String name) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final doc = await _clubs.add({
      'name': name,
      'ownerId': uid,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final displayName = userDoc.data()?['nombre'] as String? ?? '';
    final email = userDoc.data()?['email'] as String? ?? '';

    await doc.collection('members').doc(uid).set({
      'userId': uid,
      'email': email,
      'displayName': displayName,
      'role': ClubRole.owner.name,
      'status': MembershipStatus.active.name,
    });

    return doc.id;
  }

  /// Get a single club.
  Stream<Club?> clubStream(String clubId) =>
      _clubs.doc(clubId).snapshots().map((doc) {
        if (!doc.exists) return null;
        return Club.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      });

  /// Stream members of a club.
  Stream<List<ClubMember>> membersStream(String clubId) => _clubs
      .doc(clubId)
      .collection('members')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => ClubMember.fromMap(d.id, d.data()))
          .toList());

  /// Stream clubs where current user is a member (active only).
  Stream<List<Club>> myClubsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: MembershipStatus.active.name)
        .snapshots()
        .asyncMap((snap) async {
      final clubs = <Club>[];
      for (final memberDoc in snap.docs) {
        final clubDoc = await memberDoc.reference.parent.parent?.get();
        if (clubDoc != null && clubDoc.exists) {
          clubs.add(
            Club.fromMap(clubDoc.id, clubDoc.data() as Map<String, dynamic>),
          );
        }
      }
      return clubs;
    });
  }

  /// Get a member's role in a club.
  Future<ClubRole?> getMemberRole(String clubId, String userId) async {
    final doc =
        await _clubs.doc(clubId).collection('members').doc(userId).get();
    if (!doc.exists) return null;
    return ClubMember.fromMap(doc.id, doc.data()!).role;
  }

  /// Update a member's role.
  Future<void> updateMemberRole(
      String clubId, String memberId, ClubRole newRole) async {
    await _clubs
        .doc(clubId)
        .collection('members')
        .doc(memberId)
        .update({'role': newRole.name});
  }

  /// Remove a member from a club.
  Future<void> removeMember(String clubId, String memberId) async {
    await _clubs.doc(clubId).collection('members').doc(memberId).delete();
  }

  /// Transfer ownership to another member.
  Future<void> transferOwnership(
      String clubId, String newOwnerId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final batch = _firestore.batch();
    final oldOwnerRef = _clubs.doc(clubId).collection('members').doc(uid);
    final newOwnerRef =
        _clubs.doc(clubId).collection('members').doc(newOwnerId);

    batch.update(oldOwnerRef, {'role': ClubRole.entrenador.name});
    batch.update(newOwnerRef, {'role': ClubRole.owner.name});
    batch.update(_clubs.doc(clubId), {'ownerId': newOwnerId});

    await batch.commit();
  }

  /// Delete a club and all subcollections.
  Future<void> deleteClub(String clubId) async {
    final members = await _clubs
        .doc(clubId)
        .collection('members')
        .get();
    for (final m in members.docs) {
      await m.reference.delete();
    }
    await _clubs.doc(clubId).delete();
  }
}
