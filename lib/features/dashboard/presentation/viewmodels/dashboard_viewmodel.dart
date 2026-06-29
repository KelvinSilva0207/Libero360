import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/log_service.dart';
import '../../data/dashboard_model.dart';
import '../../data/dashboard_repository.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../../../estadisticas/data/models/models.dart';
import '../../../estadisticas/data/stat_event_bus.dart';

class DashboardSectionNotifier extends ValueNotifier<int> {
  DashboardSectionNotifier() : super(0);
  void bump() => value++;
}

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();
  final DatabaseService _db = DatabaseService.instance;

  DashboardData? _data;
  bool _loading = true;
  bool _isRefreshing = false;
  String? _error;
  String? _clubName;
  int _clubMemberCount = 0;
  String? _category;
  StreamSubscription<List<Player>>? _playerSub;
  StreamSubscription<List<Match>>? _matchSub;
  VoidCallback? _eventBusHandler;
  Timer? _debounce;

  final headerSection = DashboardSectionNotifier();
  final mainCardSection = DashboardSectionNotifier();
  final athleteOfMonthSection = DashboardSectionNotifier();
  final quickSummarySection = DashboardSectionNotifier();
  final teamStatusSection = DashboardSectionNotifier();
  final lastMatchSection = DashboardSectionNotifier();
  final activityTimelineSection = DashboardSectionNotifier();
  final quickAccessSection = DashboardSectionNotifier();
  final skeletonSection = DashboardSectionNotifier();

  DashboardData? get data => _data;
  bool get loading => _loading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;

  Set<String> _categoryFilter = {};

  Set<String> get categoryFilter => _categoryFilter;

  void setCategoryFilter(Set<String> categories) {
    _categoryFilter = Set.from(categories);
  }

  void _bumpAllSections() {
    LogService.instance.auto('🔵 sección reconstruida — Dashboard');
    headerSection.bump();
    mainCardSection.bump();
    athleteOfMonthSection.bump();
    quickSummarySection.bump();
    teamStatusSection.bump();
    lastMatchSection.bump();
    activityTimelineSection.bump();
    quickAccessSection.bump();
  }

  Future<void> load({String? profileId, String? clubName, int clubMemberCount = 0, String? category}) async {
    _clubName = clubName;
    _clubMemberCount = clubMemberCount;
    _category = category;
    _loading = true;
    _error = null;
    skeletonSection.bump();
    notifyListeners();
    LogService.instance.auto('🟢 Dashboard abierto');

    try {
      await _db.initialize();
      _data = await _repository.load(
        profileId: profileId,
        clubName: _clubName,
        clubMemberCount: _clubMemberCount,
        categoryFilter: _categoryFilter.isNotEmpty ? _categoryFilter : null,
        category: _category,
      );
      _loading = false;
      _bumpAllSections();
      LogService.instance.auto('🟢 Loaded — Dashboard: ${_data!.quickSummary.athleteCount} atletas, ${_data!.quickSummary.matchCount} partidos');
      _subscribeToChanges(profileId);
    } catch (e) {
      _error = e.toString();
      _loading = false;
      skeletonSection.bump();
      LogService.instance.error('🔴 Error — Dashboard load: $e');
    }
    notifyListeners();
  }

  void _subscribeToChanges(String? profileId) {
    _playerSub?.cancel();
    _matchSub?.cancel();
    _unsubscribeFromBus();
    _playerSub = _db.watchAllPlayers().listen((_) => _scheduleRefresh(profileId));
    _matchSub = _db.watchMatchesByState(EstadoPartido.finalizado).listen((_) => _scheduleRefresh(profileId));
    _eventBusHandler = () => _scheduleRefresh(profileId);
    StatEventBus.instance.addListener(_eventBusHandler!);
  }

  void _unsubscribeFromBus() {
    if (_eventBusHandler != null) {
      StatEventBus.instance.removeListener(_eventBusHandler!);
      _eventBusHandler = null;
    }
  }

  void _scheduleRefresh(String? profileId) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _silentRefresh(profileId));
  }

  Future<void> _silentRefresh(String? profileId) async {
    _isRefreshing = true;
    notifyListeners();
    LogService.instance.auto('🔵 Refresh — Dashboard silencioso');
    try {
      _data = await _repository.load(
        profileId: profileId,
        clubName: _clubName,
        clubMemberCount: _clubMemberCount,
        categoryFilter: _categoryFilter.isNotEmpty ? _categoryFilter : null,
        category: _category,
      );
      _bumpAllSections();
      LogService.instance.auto('🟠 datos sincronizados — Dashboard refresh: ${_data!.quickSummary.athleteCount} atletas');
    } catch (e) {
      LogService.instance.error('🔴 Error — Dashboard silentRefresh: $e');
    }
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> refresh({String? profileId}) async {
    _error = null;
    LogService.instance.auto('🔵 Refresh — Dashboard manual');
    try {
      _data = await _repository.load(
        profileId: profileId,
        clubName: _clubName,
        clubMemberCount: _clubMemberCount,
        categoryFilter: _categoryFilter.isNotEmpty ? _categoryFilter : null,
        category: _category,
      );
      _bumpAllSections();
      LogService.instance.auto('🟢 Loaded — Dashboard refresh manual');
    } catch (e) {
      _error = e.toString();
      skeletonSection.bump();
      LogService.instance.error('🔴 Error — Dashboard refresh: $e');
    }
    notifyListeners();
  }

  void setProfile(String? profileId) {
    _playerSub?.cancel();
    _matchSub?.cancel();
    load(profileId: profileId, clubName: _clubName, clubMemberCount: _clubMemberCount);
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _matchSub?.cancel();
    _unsubscribeFromBus();
    _debounce?.cancel();
    headerSection.dispose();
    mainCardSection.dispose();
    athleteOfMonthSection.dispose();
    quickSummarySection.dispose();
    teamStatusSection.dispose();
    lastMatchSection.dispose();
    activityTimelineSection.dispose();
    quickAccessSection.dispose();
    skeletonSection.dispose();
    super.dispose();
  }
}
