import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/log_service.dart';
import '../../../features/estadisticas/data/local_db/database_service.dart';

class BackupMetadata {
  final DateTime? lastBackup;
  final String? connectedAccount;
  final bool isRestoring;
  final bool isBackingUp;

  const BackupMetadata({
    this.lastBackup,
    this.connectedAccount,
    this.isRestoring = false,
    this.isBackingUp = false,
  });

  BackupMetadata copyWith({
    DateTime? lastBackup,
    String? connectedAccount,
    bool? isRestoring,
    bool? isBackingUp,
  }) =>
      BackupMetadata(
        lastBackup: lastBackup ?? this.lastBackup,
        connectedAccount: connectedAccount ?? this.connectedAccount,
        isRestoring: isRestoring ?? this.isRestoring,
        isBackingUp: isBackingUp ?? this.isBackingUp,
      );
}

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  final DatabaseService _db = DatabaseService.instance;
  final LogService _log = LogService.instance;
  BackupMetadata _metadata = const BackupMetadata();

  BackupMetadata get metadata => _metadata;

  static const _lastBackupKey = 'backup_last_date';
  static const _connectedAccountKey = 'backup_connected_account';
  static const _settingsSectionKey = 'appSettings';
  static const _appVersion = '1.0.0';

  static String get _platform {
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

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastBackupKey);
    _metadata = _metadata.copyWith(
      lastBackup: lastDateStr != null ? DateTime.tryParse(lastDateStr) : null,
      connectedAccount: prefs.getString(_connectedAccountKey),
    );
  }

  Future<String?> createBackup() async {
    _metadata = _metadata.copyWith(isBackingUp: true);
    try {
      await _db.initialize();
      await _log.system('🔵 EXPORT START — Iniciando respaldo completo', source: 'BackupService');

      final jsonStr = await _db.exportToJson(appVersion: _appVersion, devicePlatform: _platform);
      if (jsonStr == null) {
        await _log.error('🔴 EXPORT FAILED — Error de integridad al exportar datos', source: 'BackupService');
        return null;
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      final settings = <String, dynamic>{};
      for (final key in prefs.getKeys()) {
        final value = prefs.get(key);
        if (value != null) settings[key] = value;
      }
      data[_settingsSectionKey] = settings;

      final enrichedJson = const JsonEncoder.withIndent('  ').convert(data);

      final date = DateTime.now().toIso8601String().split('T').first;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/libero360_backup_$date.json');
      await file.writeAsString(enrichedJson);

      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
      _metadata = _metadata.copyWith(lastBackup: DateTime.now());
      await _log.system('🟢 EXPORT VERIFIED — Respaldo creado: libero360_backup_$date.json', source: 'BackupService');
      await _log.system('🔵 BACKUP SETTINGS — ${settings.length} preferencias respaldadas', source: 'BackupService');
      return file.path;
    } catch (e) {
      await _log.error('🔴 EXPORT FAILED — Error al crear respaldo: $e', source: 'BackupService');
      return null;
    } finally {
      _metadata = _metadata.copyWith(isBackingUp: false);
    }
  }

  Future<bool> restoreBackup({String? filePath}) async {
    _metadata = _metadata.copyWith(isRestoring: true);
    try {
      String jsonStr;
      if (filePath != null) {
        final file = File(filePath);
        jsonStr = await file.readAsString();
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (result == null || result.files.single.path == null) return false;
        final file = File(result.files.single.path!);
        jsonStr = await file.readAsString();
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final settings = data.remove(_settingsSectionKey) as Map<String, dynamic>?;

      // Re-encode DB data without settings for import
      final dbJson = const JsonEncoder.withIndent('  ').convert(data);

      await _db.initialize();
      final ok = await _db.importFromJson(dbJson);

      if (ok) {
        if (settings != null && settings.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          for (final entry in settings.entries) {
            final key = entry.key;
            final value = entry.value;
            if (value is String) {
              await prefs.setString(key, value);
            } else if (value is bool) {
              await prefs.setBool(key, value);
            } else if (value is int) {
              await prefs.setInt(key, value);
            } else if (value is double) {
              await prefs.setDouble(key, value);
            }
          }
          await _log.system('🟢 SETTINGS RESTORED — ${settings.length} preferencias restauradas', source: 'BackupService');
        } else {
          await _log.system('🔴 SETTINGS NOT FOUND — Usando valores por defecto', source: 'BackupService');
        }
        await _log.system('🟢 BACKUP VERIFIED — Respaldo restaurado correctamente', source: 'BackupService');
      } else {
        await _log.error('🔴 DATA LOSS DETECTED — Error al restaurar: formato inválido', source: 'BackupService');
      }
      return ok;
    } catch (e) {
      await _log.error('🔴 DATA LOSS DETECTED — Error al restaurar respaldo: $e', source: 'BackupService');
      return false;
    } finally {
      _metadata = _metadata.copyWith(isRestoring: false);
    }
  }

  Future<void> setConnectedAccount(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString(_connectedAccountKey, email);
    } else {
      await prefs.remove(_connectedAccountKey);
    }
    _metadata = _metadata.copyWith(connectedAccount: email);
  }
}
