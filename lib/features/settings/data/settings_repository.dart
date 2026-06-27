import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/log_service.dart';
import '../../../features/estadisticas/data/local_db/database_service.dart';

const _exportAppVersion = '1.0.0';

String get _exportPlatform {
  if (kIsWeb) return 'web';
  try {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
  } catch (_) {}
  return 'unknown';
}

class SettingsRepository {
  final DatabaseService _dbService = DatabaseService.instance;
  final LogService _log = LogService.instance;

  Future<String?> exportToJson() async {
    await _dbService.initialize();
    await _log.system('🔵 EXPORT START — Iniciando exportación de datos', source: 'SettingsRepository');
    final json = await _dbService.exportToJson(appVersion: _exportAppVersion, devicePlatform: _exportPlatform);
    if (json == null) {
      await _log.error('🔴 EXPORT FAILED — Error de integridad al exportar datos', source: 'SettingsRepository');
      return null;
    }
    await _log.system('🟢 EXPORT VERIFIED — Datos exportados correctamente', source: 'SettingsRepository');
    return json;
  }

  Future<File> saveTempFile(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  Future<void> shareFile(File file, {String? text}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: text ?? 'Respaldo Libero360',
    );
  }

  Future<String?> pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return null;
    final file = File(result.files.single.path!);
    return file.readAsString();
  }

  Future<bool> importFromJson(String json) async {
    await _dbService.initialize();
    final ok = await _dbService.importFromJson(json);
    if (ok) {
      await _log.system('🟢 IMPORT VERIFIED — Datos importados correctamente', source: 'SettingsRepository');
    } else {
      await _log.error('🔴 DATA LOSS DETECTED — Error al importar datos', source: 'SettingsRepository');
    }
    return ok;
  }
}
