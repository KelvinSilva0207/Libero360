import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextScaleService {
  static const String _key = 'text_scale';
  static const String defaultLevel = 'normal';

  static const List<String> availableLevels = [
    'small',
    'normal',
    'large',
    'extraLarge',
  ];

  static const Map<String, String> levelLabels = {
    'small': 'Pequeño',
    'normal': 'Normal',
    'large': 'Grande',
    'extraLarge': 'Extra Grande',
  };

  static const Map<String, double> levelFactors = {
    'small': 0.9,
    'normal': 1.0,
    'large': 1.1,
    'extraLarge': 1.25,
  };

  static TextScaler textScalerFor(String level) {
    final factor = levelFactors[level] ?? 1.0;
    if (factor == 1.0) return TextScaler.noScaling;
    return TextScaler.linear(factor);
  }

  Future<String> loadLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key) ?? defaultLevel;
    } catch (_) {
      return defaultLevel;
    }
  }

  Future<void> saveLevel(String level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, level);
    } catch (_) {}
  }
}
