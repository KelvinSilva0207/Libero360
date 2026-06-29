import 'package:shared_preferences/shared_preferences.dart';
import '../../features/estadisticas/data/local_db/database_service.dart';
import '../../features/estadisticas/data/models/player.dart';

class GenderMigrationService {
  static const String _flagKey = 'migration_gender_fix_done';

  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_flagKey) == true) return;

    try {
      await DatabaseService.instance.initialize();
      final players = await DatabaseService.instance.getAllPlayers();

      if (players.isEmpty) {
        await prefs.setBool(_flagKey, true);
        return;
      }

      for (final player in players) {
        if (player.sexo == Sexo.masculino) {
          player.sexo = Sexo.femenino;
          await DatabaseService.instance.savePlayer(player);
        }
      }

      await prefs.setBool(_flagKey, true);
      print('🟢 MIGRATION: gender fix applied to ${players.length} players');
    } catch (e) {
      print('🔴 MIGRATION ERROR: $e');
    }
  }
}
