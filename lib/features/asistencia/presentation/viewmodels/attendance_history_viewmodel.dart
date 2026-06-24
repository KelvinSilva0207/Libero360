import 'package:flutter/foundation.dart';
import '../../data/attendance_history_model.dart';
import '../../data/attendance_history_repository.dart';

class AttendanceHistoryViewModel extends ChangeNotifier {
  final AttendanceHistoryRepository _repository = AttendanceHistoryRepository();

  List<DailyAttendanceSummary> _summaries = [];
  bool _loading = false;
  String? _error;

  int? _filterYear;
  int? _filterMonth;
  String? _filterCategory;
  String _searchQuery = '';

  List<DailyAttendanceSummary> get summaries => _summaries;
  bool get loading => _loading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  int get _defaultYear => DateTime.now().year;
  int get _defaultMonth => DateTime.now().month;

  Future<void> load({
    int? year,
    int? month,
    String? category,
  }) async {
    _loading = true;
    _error = null;
    _filterYear = year;
    _filterMonth = month;
    _filterCategory = category;
    notifyListeners();

    try {
      _summaries = await _repository.load(
        year: year ?? _defaultYear,
        month: month ?? _defaultMonth,
        category: category,
      );
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void setFilterYear(int? year) {
    if (year != _filterYear) {
      load(year: year, month: _filterMonth, category: _filterCategory);
    }
  }

  void setFilterMonth(int? month) {
    if (month != _filterMonth) {
      load(year: _filterYear, month: month, category: _filterCategory);
    }
  }

  void setFilterCategory(String? category) {
    if (category != _filterCategory) {
      load(year: _filterYear, month: _filterMonth, category: category);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void previousMonth() {
    final currentMonth = _filterMonth ?? _defaultMonth;
    final currentYear = _filterYear ?? _defaultYear;
    if (currentMonth == 1) {
      load(year: currentYear - 1, month: 12, category: _filterCategory);
    } else {
      load(year: currentYear, month: currentMonth - 1, category: _filterCategory);
    }
  }

  void nextMonth() {
    final currentMonth = _filterMonth ?? _defaultMonth;
    final currentYear = _filterYear ?? _defaultYear;
    if (currentMonth == 12) {
      load(year: currentYear + 1, month: 1, category: _filterCategory);
    } else {
      load(year: currentYear, month: currentMonth + 1, category: _filterCategory);
    }
  }

  int? get filterYear => _filterYear;
  int? get filterMonth => _filterMonth;

  String get currentMonthLabel {
    final m = _filterMonth ?? _defaultMonth;
    const names = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${names[m - 1]} ${_filterYear ?? _defaultYear}';
  }
}
