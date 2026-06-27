import 'package:flutter/material.dart';
import 'text_scale_service.dart';

class TextScaleViewModel extends ChangeNotifier {
  final TextScaleService _service = TextScaleService();
  String _level = TextScaleService.defaultLevel;

  String get level => _level;
  double get factor => TextScaleService.levelFactors[_level] ?? 1.0;
  String get label => TextScaleService.levelLabels[_level] ?? 'Normal';
  TextScaler get textScaler => TextScaleService.textScalerFor(_level);

  TextScaleViewModel() {
    _load();
  }

  Future<void> _load() async {
    _level = await _service.loadLevel();
    notifyListeners();
  }

  Future<void> setLevel(String level) async {
    if (level == _level) return;
    _level = level;
    await _service.saveLevel(level);
    print('🔵 TEXT SCALE CHANGED: $level (${TextScaleService.levelLabels[level]})');
    notifyListeners();
  }
}
