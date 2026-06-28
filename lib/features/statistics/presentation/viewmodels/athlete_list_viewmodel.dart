import 'package:flutter/foundation.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../../features/estadisticas/data/models/models.dart';
import '../../../../features/estadisticas/data/stat_event_bus.dart';
import '../../data/statistics_models.dart';
import '../../data/statistics_service.dart';

class AthleteListViewModel extends ChangeNotifier {
  final StatisticsService _service;

  List<AthleteStats> _allAthletes = [];
  List<AthleteStats> _filteredAthletes = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  bool _loaded = false;
  VoidCallback? _eventBusHandler;

  AthleteListViewModel({StatisticsService? service})
      : _service = service ?? StatisticsService();

  List<AthleteStats> get athletes => _filteredAthletes;
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _allAthletes = await _service.loadAthleteStats();
      _applyFilter();
      _loading = false;
      _loaded = true;
      _subscribeToBus();
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }

    notifyListeners();
  }

  void _subscribeToBus() {
    _unsubscribeFromBus();
    _eventBusHandler = () {
      if (_loaded) load();
    };
    StatEventBus.instance.addListener(_eventBusHandler!);
  }

  void _unsubscribeFromBus() {
    if (_eventBusHandler != null) {
      StatEventBus.instance.removeListener(_eventBusHandler!);
      _eventBusHandler = null;
    }
  }

  void search(String q) {
    _query = q;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filteredAthletes = List.from(_allAthletes);
      return;
    }

    final lower = _query.toLowerCase();
    _filteredAthletes = _allAthletes.where((a) {
      final p = a.player;
      if (NameFormatter.playerDisplayName(p).toLowerCase().contains(lower)) return true;
      if (p.cedula.toLowerCase().contains(lower)) return true;
      if (p.numero?.toString() == _query) return true;
      if (p.numero?.toString().contains(_query) ?? false) return true;
      if (p.posicionLabel.toLowerCase().contains(lower)) return true;
      if (p.atletaStatus.label.toLowerCase().contains(lower)) return true;
      return false;
    }).toList();
  }

  @override
  void dispose() {
    _unsubscribeFromBus();
    super.dispose();
  }
}
