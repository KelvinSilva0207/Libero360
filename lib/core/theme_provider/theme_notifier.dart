import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get isLight => _mode == ThemeMode.light;
  bool get isSystem => _mode == ThemeMode.system;

  ThemeNotifier() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_key) ?? 'dark';
      _mode = switch (value) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
      notifyListeners();
    } catch (_) {
      _mode = ThemeMode.dark;
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (_mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        _ => 'dark',
      };
      await prefs.setString(_key, value);
    } catch (_) {}
  }

  String get label => switch (_mode) {
    ThemeMode.light => 'Claro',
    ThemeMode.system => 'Sistema',
    _ => 'Oscuro',
  };

  void cycle() {
    _mode = switch (_mode) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
      ThemeMode.system => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
    notifyListeners();
    _save();
  }

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
    _save();
  }
}
