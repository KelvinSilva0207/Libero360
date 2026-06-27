import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config.dart';
import 'notification_models.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String? _currentClubId;

  String? get currentClubId => _currentClubId;

  void setCurrentClub(String? clubId) {
    _currentClubId = clubId;
  }

  String? get _notifPath {
    if (!AppConfig.useFirebase || _currentClubId == null) return null;
    return 'clubs/$_currentClubId/notifications';
  }

  CollectionReference? get _notifRef {
    final path = _notifPath;
    if (path == null) return null;
    return _firestore.collection(path);
  }

  /// Stream notifications for the current club.
  Stream<List<AppNotification>> notificationsStream() {
    if (!AppConfig.useFirebase || _currentClubId == null) {
      return const Stream.empty();
    }
    return _notifRef!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  /// Create a notification.
  Future<void> createNotification({
    required NotificationType type,
    required String title,
    required String message,
    String? relatedAthleteId,
    String? relatedMatchId,
  }) async {
    if (_notifRef == null) return;
    await _notifRef!.add({
      'type': type.name,
      'title': title,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
      'relatedAthleteId': relatedAthleteId,
      'relatedMatchId': relatedMatchId,
      'userId': _uid ?? '',
    });
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notifId) async {
    if (_notifRef == null) return;
    await _notifRef!.doc(notifId).update({'read': true});
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    if (_notifRef == null) return;
    final snap = await _notifRef!.where('read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Get unread count stream.
  Stream<int> unreadCountStream() {
    if (!AppConfig.useFirebase || _currentClubId == null) {
      return const Stream.empty();
    }
    return _notifRef!
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Delete a notification.
  Future<void> deleteNotification(String notifId) async {
    if (_notifRef == null) return;
    await _notifRef!.doc(notifId).delete();
  }

  // ───── Smart generation helpers ─────

  /// Notify: new athlete registered.
  Future<void> notifyAthleteCreated(String athleteName, int athleteId) async {
    await createNotification(
      type: NotificationType.athleteCreated,
      title: 'Nuevo atleta',
      message: '$athleteName ha sido registrado en el equipo.',
      relatedAthleteId: athleteId.toString(),
    );
  }

  /// Notify: athlete category changed.
  Future<void> notifyCategoryChanged(
      String athleteName, String oldCat, String newCat) async {
    await createNotification(
      type: NotificationType.categoryChanged,
      title: 'Cambio de categoría',
      message: '$athleteName pasó de $oldCat a $newCat',
    );
  }

  /// Notify: birthday.
  Future<void> notifyBirthday(String athleteName) async {
    await createNotification(
      type: NotificationType.birthday,
      title: '🎂 Cumpleaños',
      message: '¡$athleteName está de cumpleaños hoy!',
    );
  }

  /// Notify: attendance warning (>X absences).
  Future<void> notifyAttendanceWarning(
      String athleteName, int absences) async {
    await createNotification(
      type: NotificationType.attendanceWarning,
      title: 'Inasistencias',
      message: '$athleteName acumula $absences inasistencias.',
    );
  }

  /// Notify: rest period ended.
  Future<void> notifyRestEnded(String athleteName) async {
    await createNotification(
      type: NotificationType.restPeriodEnded,
      title: 'Reposo finalizado',
      message: 'El período de reposo de $athleteName ha terminado.',
    );
  }

  /// Notify: match created.
  Future<void> notifyMatchCreated(
      String local, String visitor, int matchId) async {
    await createNotification(
      type: NotificationType.matchCreated,
      title: 'Nuevo partido',
      message: '$local vs $visitor ha sido creado.',
      relatedMatchId: matchId.toString(),
    );
  }

  /// Notify: MVP registered.
  Future<void> notifyMvpRegistered(
      String athleteName, String matchLabel) async {
    await createNotification(
      type: NotificationType.mvpRegistered,
      title: 'MVP',
      message: '$athleteName fue MVP en $matchLabel',
    );
  }

  /// Notify: consecutive absences.
  Future<void> notifyConsecutiveAbsences(String athleteName, int count) async {
    await createNotification(
      type: NotificationType.consecutiveAbsences,
      title: 'Faltas consecutivas',
      message: '$athleteName lleva $count faltas consecutivas.',
    );
  }

  /// Notify: rest period expiring soon.
  Future<void> notifyRestExpiringSoon(String athleteName, int daysLeft) async {
    await createNotification(
      type: NotificationType.restExpiringSoon,
      title: 'Reposo próximo a vencer',
      message: 'El reposo de $athleteName vence en $daysLeft día(s).',
    );
  }

  /// Notify: upcoming match.
  Future<void> notifyMatchUpcoming(String local, String visitor, int matchId, DateTime date) async {
    final dayStr = '${date.day}/${date.month}';
    await createNotification(
      type: NotificationType.matchUpcoming,
      title: 'Partido próximo',
      message: '$local vs $visitor el $dayStr.',
      relatedMatchId: matchId.toString(),
    );
  }

  /// Notify: new coach joined.
  Future<void> notifyNewCoach(String coachName) async {
    await createNotification(
      type: NotificationType.newCoach,
      title: 'Nuevo entrenador',
      message: '$coachName se unió al equipo técnico.',
    );
  }

  /// Notify: invitation accepted.
  Future<void> notifyInvitationAccepted(String memberName) async {
    await createNotification(
      type: NotificationType.invitationAccepted,
      title: 'Invitación aceptada',
      message: '$memberName aceptó la invitación al club.',
    );
  }

  /// Notify: sync completed.
  Future<void> notifySyncCompleted(String details) async {
    await createNotification(
      type: NotificationType.syncCompleted,
      title: 'Sincronización completada',
      message: details,
    );
  }

  // ───── Preference management ─────

  Future<NotificationPreference> loadPreferences() async {
    final uid = _uid;
    if (uid == null || _currentClubId == null) {
      return NotificationPreference.allEnabled();
    }
    try {
      final doc = await _firestore
          .collection('clubs')
          .doc(_currentClubId)
          .collection('notificationPrefs')
          .doc(uid)
          .get();
      if (doc.exists) {
        return NotificationPreference.fromMap(doc.data()!);
      }
    } catch (_) {}
    return NotificationPreference.allEnabled();
  }

  Future<void> savePreferences(NotificationPreference prefs) async {
    final uid = _uid;
    if (uid == null || _currentClubId == null) return;
    await _firestore
        .collection('clubs')
        .doc(_currentClubId)
        .collection('notificationPrefs')
        .doc(uid)
        .set(prefs.toMap());
  }
}
