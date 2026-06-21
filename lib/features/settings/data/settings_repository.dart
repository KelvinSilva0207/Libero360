import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../features/estadisticas/data/local_db/database_service.dart';

class SettingsRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<String> exportToJson() async {
    await _dbService.initialize();
    return _dbService.exportToJson();
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
    return _dbService.importFromJson(json);
  }
}
