import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/log_service.dart';
import '../../../features/estadisticas/data/local_db/database_service.dart';
import 'google_drive_service.dart';

class BackupMetadata {
  final DateTime? lastBackup;
  final String? connectedAccount;
  final bool isRestoring;
  final bool isBackingUp;
  final bool isDriveConnected;
  final DateTime? driveLastBackup;
  final int? driveFileSize;
  final String? driveAppVersion;
  final String? driveChecksum;
  final String? driveAccountEmail;
  final int driveVersionCount;
  final bool isAutoBackupEnabled;

  const BackupMetadata({
    this.lastBackup,
    this.connectedAccount,
    this.isRestoring = false,
    this.isBackingUp = false,
    this.isDriveConnected = false,
    this.driveLastBackup,
    this.driveFileSize,
    this.driveAppVersion,
    this.driveChecksum,
    this.driveAccountEmail,
    this.driveVersionCount = 0,
    this.isAutoBackupEnabled = false,
  });

  BackupMetadata copyWith({
    DateTime? lastBackup,
    String? connectedAccount,
    bool? isRestoring,
    bool? isBackingUp,
    bool? isDriveConnected,
    DateTime? driveLastBackup,
    int? driveFileSize,
    String? driveAppVersion,
    String? driveChecksum,
    String? driveAccountEmail,
    int? driveVersionCount,
    bool? isAutoBackupEnabled,
  }) =>
      BackupMetadata(
        lastBackup: lastBackup ?? this.lastBackup,
        connectedAccount: connectedAccount ?? this.connectedAccount,
        isRestoring: isRestoring ?? this.isRestoring,
        isBackingUp: isBackingUp ?? this.isBackingUp,
        isDriveConnected: isDriveConnected ?? this.isDriveConnected,
        driveLastBackup: driveLastBackup ?? this.driveLastBackup,
        driveFileSize: driveFileSize ?? this.driveFileSize,
        driveAppVersion: driveAppVersion ?? this.driveAppVersion,
        driveChecksum: driveChecksum ?? this.driveChecksum,
        driveAccountEmail: driveAccountEmail ?? this.driveAccountEmail,
        driveVersionCount: driveVersionCount ?? this.driveVersionCount,
        isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      );
}

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  final DatabaseService _db = DatabaseService.instance;
  final LogService _log = LogService.instance;
  final GoogleDriveService _drive = GoogleDriveService.instance;
  BackupMetadata _metadata = const BackupMetadata();
  Timer? _autoBackupTimer;

  BackupMetadata get metadata => _metadata;

  static const _lastBackupKey = 'backup_last_date';
  static const _connectedAccountKey = 'backup_connected_account';
  static const _autoBackupKey = 'backup_auto_enabled';
  static const _lastIncrementalKey = 'backup_last_incremental';
  static const _settingsSectionKey = 'appSettings';
  static const _appVersion = '1.0.0';
  static const _autoBackupInterval = Duration(hours: 24);

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
    final autoEnabled = prefs.getBool(_autoBackupKey) ?? false;
    _metadata = _metadata.copyWith(
      lastBackup: lastDateStr != null ? DateTime.tryParse(lastDateStr) : null,
      connectedAccount: prefs.getString(_connectedAccountKey),
      isAutoBackupEnabled: autoEnabled,
    );
    await _drive.refreshMetadata();
    _metadata = _metadata.copyWith(
      isDriveConnected: _drive.isConnected,
      driveLastBackup: _drive.metadata.lastBackup,
      driveFileSize: _drive.metadata.fileSize,
      driveAppVersion: _drive.metadata.appVersion,
      driveChecksum: _drive.metadata.checksum,
      driveAccountEmail: _drive.account?.email,
      driveVersionCount: _drive.metadata.versionHistory.length,
    );
    if (autoEnabled && _drive.isConnected) {
      _scheduleAutoBackup();
    }
  }

  void _scheduleAutoBackup() {
    _autoBackupTimer?.cancel();
    final lastBackup = _metadata.lastBackup ?? DateTime(2000);
    final nextBackup = lastBackup.add(_autoBackupInterval);
    if (DateTime.now().isAfter(nextBackup)) {
      _autoBackupTimer = Timer.periodic(_autoBackupInterval, (_) => _autoBackup());
    } else {
      final delay = nextBackup.difference(DateTime.now());
      _autoBackupTimer = Timer(delay, () {
        _autoBackup();
        _autoBackupTimer = Timer.periodic(_autoBackupInterval, (_) => _autoBackup());
      });
    }
  }

  void stopAutoBackup() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
  }

  Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
    _metadata = _metadata.copyWith(isAutoBackupEnabled: enabled);
    if (enabled && _drive.isConnected) {
      _scheduleAutoBackup();
    } else {
      stopAutoBackup();
    }
  }

  Future<void> _autoBackup() async {
    if (!_drive.isConnected) return;
    await _log.system('🔵 AUTO BACKUP — Iniciando respaldo automático', source: 'BackupService');
    await createBackup();
  }

  String? _computeChecksum(Map<String, dynamic> data) {
    try {
      final extracted = {...data};
      extracted.remove('checksum');
      extracted.remove(_settingsSectionKey);
      final reEncoded = const JsonEncoder.withIndent('  ').convert(extracted);
      return sha256.convert(utf8.encode(reEncoded)).toString();
    } catch (_) {
      return null;
    }
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

      final checksum = _computeChecksum(data);
      if (checksum != null) data['checksum'] = checksum;

      final enrichedJson = const JsonEncoder.withIndent('  ').convert(data);

      final date = DateTime.now().toIso8601String().split('T').first;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/libero360_backup_$date.json');
      await file.writeAsString(enrichedJson);

      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
      await prefs.setString(_lastIncrementalKey, DateTime.now().toIso8601String());
      _metadata = _metadata.copyWith(lastBackup: DateTime.now());
      await _log.system('🟢 EXPORT VERIFIED — Respaldo creado: libero360_backup_$date.json', source: 'BackupService');
      await _log.system('🔵 BACKUP SETTINGS — ${settings.length} preferencias respaldadas', source: 'BackupService');

      if (_drive.isConnected) {
        await _log.system('🔵 Subiendo respaldo a Google Drive...', source: 'BackupService');
        final driveErr = await _drive.uploadBackup(
          enrichedJson,
          checksum: checksum,
          appVersion: _appVersion,
        );
        if (driveErr != null) {
          await _log.error('🔴 Error al subir a Drive: $driveErr', source: 'BackupService');
        } else {
          await _log.auto('🟢 Backup subido a Drive', source: 'BackupService');
          _metadata = _metadata.copyWith(
            isDriveConnected: true,
            driveLastBackup: DateTime.now(),
            driveFileSize: enrichedJson.length,
            driveAppVersion: _appVersion,
            driveChecksum: checksum,
            driveAccountEmail: _drive.account?.email,
            driveVersionCount: _drive.metadata.versionHistory.length,
          );
        }
      }

      return file.path;
    } catch (e) {
      await _log.error('🔴 EXPORT FAILED — Error al crear respaldo: $e', source: 'BackupService');
      return null;
    } finally {
      _metadata = _metadata.copyWith(isBackingUp: false);
    }
  }

  Future<bool> restoreBackup({String? filePath, bool fromDrive = false, String? driveFileId}) async {
    _metadata = _metadata.copyWith(isRestoring: true);
    try {
      String jsonStr;

      if (fromDrive) {
        await _log.system('🔵 Descargando respaldo desde Google Drive...', source: 'BackupService');
        final driveJson = await _drive.downloadBackup(fileId: driveFileId);
        if (driveJson == null) {
          await _log.error('🔴 No se pudo descargar respaldo de Drive', source: 'BackupService');
          return false;
        }
        await _log.system('🟠 Verificando integridad del respaldo...', source: 'BackupService');
        final driveData = jsonDecode(driveJson) as Map<String, dynamic>;
        final driveChecksum = driveData['checksum'] as String?;
        final ok = await _drive.verifyIntegrity(driveJson, expectedChecksum: driveChecksum);
        if (!ok) {
          await _log.error('🔴 Backup corrupto — No se importará', source: 'BackupService');
          return false;
        }
        jsonStr = driveJson;
      } else if (filePath != null) {
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
      final storedChecksum = data['checksum'] as String?;

      if (storedChecksum != null) {
        final computed = _computeChecksum(data);
        if (computed == null || computed != storedChecksum) {
          await _log.error('🔴 Backup corrupto — Checksum no coincide. No se importará.', source: 'BackupService');
          return false;
        }
        await _log.system('🟠 Checksum verificado correctamente', source: 'BackupService');
      }

      final settings = data.remove(_settingsSectionKey) as Map<String, dynamic>?;
      final dbJson = const JsonEncoder.withIndent('  ').convert(data);

      await _db.initialize();
      final importOk = await _db.importFromJson(dbJson);

      if (importOk) {
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
        }
        await _log.auto('🟢 Backup restaurado correctamente', source: 'BackupService');
      } else {
        await _log.error('🔴 Error al restaurar: formato inválido', source: 'BackupService');
      }
      return importOk;
    } catch (e) {
      await _log.error('🔴 Error al restaurar respaldo: $e', source: 'BackupService');
      return false;
    } finally {
      _metadata = _metadata.copyWith(isRestoring: false);
    }
  }

  Future<List<Map<String, dynamic>>> listDriveVersions() async {
    return await _drive.listBackupVersions();
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

  void dispose() {
    stopAutoBackup();
  }
}
