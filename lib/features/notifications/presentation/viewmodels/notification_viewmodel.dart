import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/notification_models.dart';
import '../../data/notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service = NotificationService.instance;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;
  String? _error;
  bool _initialized = false;
  StreamSubscription? _notifSub;
  StreamSubscription? _unreadSub;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  String? get error => _error;

  void init(String clubId) {
    if (_initialized && _service.currentClubId == clubId) return;

    if (_initialized && _service.currentClubId != clubId) {
      _notifSub?.cancel();
      _unreadSub?.cancel();
      _service.setCurrentClub(clubId);
      _listen();
      return;
    }

    _initialized = true;
    _service.setCurrentClub(clubId);
    _listen();
  }

  void _listen() {
    final stream = _service.notificationsStream();
    _notifSub = stream.listen((list) {
      _notifications = list;
      _loading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }, onDone: () {
      if (_loading) {
        _loading = false;
        notifyListeners();
      }
    });

    final unreadStream = _service.unreadCountStream();
    _unreadSub = unreadStream.listen((count) {
      _unreadCount = count;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }, onDone: () {
      if (_unreadSub != null) {
        _unreadCount = 0;
        notifyListeners();
      }
    });
  }

  Future<void> markAsRead(String notifId) async {
    await _service.markAsRead(notifId);
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
  }

  Future<void> deleteNotification(String notifId) async {
    await _service.deleteNotification(notifId);
  }

  Future<NotificationPreference> loadPreferences() =>
      _service.loadPreferences();

  Future<void> savePreferences(NotificationPreference prefs) =>
      _service.savePreferences(prefs);

  @override
  void dispose() {
    _notifSub?.cancel();
    _unreadSub?.cancel();
    super.dispose();
  }
}
