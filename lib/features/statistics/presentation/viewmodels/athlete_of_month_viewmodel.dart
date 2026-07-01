import 'package:flutter/foundation.dart';
import '../../../../core/services/category_service.dart';
import '../../data/athlete_ranking_service.dart';
import '../../data/statistics_models.dart';
import '../../../estadisticas/data/stat_event_bus.dart';

enum RankingPeriod { actual, mesAnterior, temporada, historico }

class AthleteOfMonthViewModel extends ChangeNotifier {
  final AthleteRankingService _service;

  List<AthleteRankingScore> _rankings = [];
  AthleteRankingScore? _winner;
  AthleteMonthlyAward? _currentMonthAward;
  List<AthleteMonthlyAward> _historicalAwards = [];
  bool _loading = true;
  String? _error;
  RankingPeriod _selectedPeriod = RankingPeriod.actual;
  String _selectedCategory = 'Todos';
  bool _loaded = false;
  VoidCallback? _eventBusHandler;
  List<String> _categorias = ['Todos'];

  AthleteOfMonthViewModel({AthleteRankingService? service})
      : _service = service ?? AthleteRankingService();

  List<AthleteRankingScore> get rankings => _rankings;
  AthleteRankingScore? get winner => _winner;
  AthleteMonthlyAward? get currentMonthAward => _currentMonthAward;
  List<AthleteMonthlyAward> get historicalAwards => _historicalAwards;
  bool get loading => _loading;
  String? get error => _error;
  RankingPeriod get selectedPeriod => _selectedPeriod;
  String get selectedCategory => _selectedCategory;
  List<String> get categorias => _categorias;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await CategoryService.instance.load();
      _categorias = ['Todos', ...CategoryService.instance.getAllNames()];

      final now = DateTime.now();
      DateTime? start;
      DateTime? end;

      switch (_selectedPeriod) {
        case RankingPeriod.actual:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        case RankingPeriod.mesAnterior:
          start = DateTime(now.year, now.month - 1, 1);
          end = DateTime(now.year, now.month, 0, 23, 59, 59);
        case RankingPeriod.temporada:
        case RankingPeriod.historico:
          break;
      }

      if (_selectedPeriod == RankingPeriod.historico) {
        _historicalAwards = await _service.getHistoricalAwards();
        _rankings = [];
        _winner = null;
      } else {
        _rankings = await _service.loadRankings(startDate: start, endDate: end);
        _winner = _rankings.isNotEmpty ? _rankings.first : null;

        if (_selectedPeriod == RankingPeriod.actual && _winner != null) {
          await _service.persistMonthRankings(_rankings);
        }
      }

      _currentMonthAward = await _service.getCurrentMonthAward();
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
      if (_loaded && _selectedPeriod == RankingPeriod.actual) load();
    };
    StatEventBus.instance.addListener(_eventBusHandler!);
  }

  void _unsubscribeFromBus() {
    if (_eventBusHandler != null) {
      StatEventBus.instance.removeListener(_eventBusHandler!);
      _eventBusHandler = null;
    }
  }

  void setPeriod(RankingPeriod period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    load();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  List<AthleteRankingScore> get filteredRankings {
    if (_selectedCategory == 'Todos') return _rankings;
    return _rankings;
  }

  @override
  void dispose() {
    _unsubscribeFromBus();
    super.dispose();
  }
}
