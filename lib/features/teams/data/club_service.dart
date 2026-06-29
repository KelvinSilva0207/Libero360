import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/log_service.dart';
import '../../estadisticas/data/local_db/database_service.dart';
import 'team_models.dart';

class ClubService {
  static final ClubService instance = ClubService._internal();
  ClubService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LogService _log = LogService.instance;
  final DatabaseService _db = DatabaseService.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference get _clubs => _firestore.collection('clubs');

  /// Validar nombre del club.
  String? validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'El nombre del club es obligatorio';
    if (trimmed.length < 3) return 'El nombre debe tener al menos 3 caracteres';
    if (trimmed.length > 50) return 'El nombre no puede exceder 50 caracteres';
    return null;
  }

  /// Verificar si ya existe un club con el mismo nombre (del mismo owner).
  Future<bool> nameExists(String name) async {
    final uid = _uid;
    if (uid == null) return false;
    final snap = await _clubs
        .where('name', isEqualTo: name.trim())
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Create a new club and add creator as owner member.
  Future<String> createClub(String name, {String description = '', String? photoUrl}) async {
    final uid = _uid;
    if (uid == null) {
      await _log.error('🔴 No authenticated user', source: 'ClubService');
      throw Exception('No hay usuario autenticado');
    }

    final nameError = validateName(name);
    if (nameError != null) {
      await _log.error('🔴 $nameError', source: 'ClubService');
      throw Exception(nameError);
    }

    final duplicate = await nameExists(name);
    if (duplicate) {
      await _log.error('🔴 Club duplicado: $name', source: 'ClubService');
      throw Exception('Ya tienes un club con ese nombre');
    }

    final doc = await _clubs.add({
      'name': name.trim(),
      'description': description,
      'photoUrl': photoUrl ?? '',
      'ownerId': uid,
      'memberCount': 1,
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
      'joinedAt': DateTime.now().toIso8601String(),
    });

    await _log.auto('🟢 Club creado: ${name.trim()}', source: 'ClubService');
    return doc.id;
  }

  /// Update club metadata.
  Future<void> updateClub(String clubId, {String? name, String? description, String? photoUrl}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (data.isNotEmpty) {
      await _clubs.doc(clubId).update(data);
    }
  }

  /// Get a single club (cached in Sembast for offline).
  Stream<Club?> clubStream(String clubId) =>
      _clubs.doc(clubId).snapshots().map((doc) {
        if (!doc.exists) return null;
        final club = Club.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        _db.cacheClub({'id': club.id, ...club.toMap()});
        return club;
      });

  /// Stream members of a club (cached in Sembast for offline).
  Stream<List<ClubMember>> membersStream(String clubId) => _clubs
      .doc(clubId)
      .collection('members')
      .snapshots()
      .map((snap) {
        final members = snap.docs
            .map((d) => ClubMember.fromMap(d.id, d.data()))
            .toList();
        _db.cacheMembers(clubId, snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
        return members;
      });

  /// Stream clubs where current user is a member (active only, cached in Sembast).
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
      final clubMaps = <Map<String, dynamic>>[];
      for (final memberDoc in snap.docs) {
        final clubDoc = await memberDoc.reference.parent.parent?.get();
        if (clubDoc != null && clubDoc.exists) {
          final club = Club.fromMap(clubDoc.id, clubDoc.data() as Map<String, dynamic>);
          clubs.add(club);
          clubMaps.add({'id': clubDoc.id, ...clubDoc.data() as Map<String, dynamic>});
        }
      }
      if (clubMaps.isNotEmpty) {
        _db.cacheClubs(clubMaps);
      }
      return clubs;
    });
  }

  /// Get cached clubs (offline fallback).
  Future<List<Club>> getCachedClubs() async {
    final cached = await _db.getAllCachedClubs();
    return cached
        .map((m) => Club.fromMap(m['id'] as String? ?? '', m))
        .toList();
  }

  /// Get cached members (offline fallback).
  Future<List<ClubMember>> getCachedMembers(String clubId) async {
    final cached = await _db.getCachedMembers(clubId);
    return cached
        .map((m) => ClubMember.fromMap(m['id'] as String? ?? '', m))
        .toList();
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
