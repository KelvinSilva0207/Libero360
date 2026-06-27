import 'package:flutter/material.dart';
import '../themes/app_typography.dart';
import 'typography_service.dart';

class TypographyViewModel extends ChangeNotifier {
  final TypographyService _service = TypographyService();
  String _currentFont = TypographyService.defaultFont;

  String get currentFont => _currentFont;
  String get currentLabel => TypographyService.fontLabels[_currentFont] ?? 'Sistema';

  TypographyViewModel() {
    _load();
  }

  Future<void> _load() async {
    _currentFont = await _service.loadFont();
    notifyListeners();
  }

  TextTheme get textTheme => AppTypography.forFont(_currentFont);

  Future<void> setFont(String font) async {
    if (font == _currentFont) return;
    _currentFont = font;
    await _service.saveFont(font);
    print('🔵 FONT CHANGED: $font');
    print('🟢 FONT APPLIED: ${TypographyService.fontLabels[font] ?? font}');
    notifyListeners();
  }
}
