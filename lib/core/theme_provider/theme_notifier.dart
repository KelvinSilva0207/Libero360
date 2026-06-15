import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../config.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeNotifier() {
    _load();
  }

  Future<void> _load() async {
    try {
      final service = ServiceLocator.instance.dataService;
      await service.initialize();
      _mode = ThemeMode.dark;
      notifyListeners();
    } catch (_) {
      _mode = ThemeMode.dark;
    }
  }

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
}
