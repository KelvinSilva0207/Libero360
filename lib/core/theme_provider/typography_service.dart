import 'package:shared_preferences/shared_preferences.dart';

class TypographyService {
  static const String _key = 'app_font';
  static const String defaultFont = 'system';

  static const List<String> availableFonts = [
    'system',
    'roboto',
    'inter',
    'openSans',
    'nunito',
  ];

  static const Map<String, String> fontLabels = {
    'system': 'Sistema',
    'roboto': 'Roboto',
    'inter': 'Inter',
    'openSans': 'Open Sans',
    'nunito': 'Nunito',
  };

  Future<String> loadFont() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key) ?? defaultFont;
    } catch (_) {
      return defaultFont;
    }
  }

  Future<void> saveFont(String font) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, font);
    } catch (_) {}
  }
}
