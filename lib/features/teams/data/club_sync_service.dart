import 'package:flutter/foundation.dart';

enum SyncEvent { clubCreated, clubSynced, invitationSent, syncError }

class SyncLogEntry {
  final SyncEvent event;
  final String message;
  final DateTime timestamp;
  final String? clubId;

  const SyncLogEntry({
    required this.event,
    required this.message,
    required this.timestamp,
    this.clubId,
  });

  String get icon {
    switch (event) {
      case SyncEvent.clubCreated:
        return '🔵';
      case SyncEvent.clubSynced:
        return '🟢';
      case SyncEvent.invitationSent:
        return '🟡';
      case SyncEvent.syncError:
        return '🔴';
    }
  }
}

class ClubSyncService {
  static final ClubSyncService instance = ClubSyncService._internal();
  ClubSyncService._internal();

  final List<SyncLogEntry> _logs = [];
  List<SyncLogEntry> get logs => List.unmodifiable(_logs);

  void _log(SyncEvent event, String message, {String? clubId}) {
    final entry = SyncLogEntry(
      event: event,
      message: message,
      timestamp: DateTime.now(),
      clubId: clubId,
    );
    _logs.insert(0, entry);
    debugPrint('${entry.icon} $message');
  }

  void logClubCreated(String clubName, {String? clubId}) {
    _log(SyncEvent.clubCreated, 'CLUB creado: $clubName', clubId: clubId);
  }

  void logClubSynced(String clubName, {String? clubId}) {
    _log(SyncEvent.clubSynced, 'CLUB sincronizado: $clubName', clubId: clubId);
  }

  void logInvitationSent(String email, {String? clubId}) {
    _log(SyncEvent.invitationSent, 'INVITACIÓN enviada a $email', clubId: clubId);
  }

  void logSyncError(String error, {String? clubId}) {
    _log(SyncEvent.syncError, 'Error sincronización: $error', clubId: clubId);
  }

  Future<void> syncAthletes({String? clubId}) async {
    debugPrint('[ClubSync] syncAthletes stub — clubId: $clubId');
  }

  Future<void> syncAttendance({String? clubId}) async {
    debugPrint('[ClubSync] syncAttendance stub — clubId: $clubId');
  }

  Future<void> syncMatches({String? clubId}) async {
    debugPrint('[ClubSync] syncMatches stub — clubId: $clubId');
  }

  Future<void> syncStatistics({String? clubId}) async {
    debugPrint('[ClubSync] syncStatistics stub — clubId: $clubId');
  }

  Future<void> syncAll({String? clubId}) async {
    await syncAthletes(clubId: clubId);
    await syncAttendance(clubId: clubId);
    await syncMatches(clubId: clubId);
    await syncStatistics(clubId: clubId);
  }
}
