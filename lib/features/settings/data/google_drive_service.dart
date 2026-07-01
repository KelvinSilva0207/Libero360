import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/log_service.dart';

class DriveMetadata {
  final String? fileId;
  final String? fileName;
  final DateTime? lastBackup;
  final int? fileSize;
  final String? appVersion;
  final String? checksum;
  final bool isConnected;
  final List<String> versionHistory; // fileIds of last N backups

  const DriveMetadata({
    this.fileId,
    this.fileName,
    this.lastBackup,
    this.fileSize,
    this.appVersion,
    this.checksum,
    this.isConnected = false,
    this.versionHistory = const [],
  });

  DriveMetadata copyWith({
    String? fileId,
    String? fileName,
    DateTime? lastBackup,
    int? fileSize,
    String? appVersion,
    String? checksum,
    bool? isConnected,
    List<String>? versionHistory,
  }) =>
      DriveMetadata(
        fileId: fileId ?? this.fileId,
        fileName: fileName ?? this.fileName,
        lastBackup: lastBackup ?? this.lastBackup,
        fileSize: fileSize ?? this.fileSize,
        appVersion: appVersion ?? this.appVersion,
        checksum: checksum ?? this.checksum,
        isConnected: isConnected ?? this.isConnected,
        versionHistory: versionHistory ?? this.versionHistory,
      );
}

class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._internal();
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );

  GoogleSignInAccount? _account;
  DriveMetadata _metadata = const DriveMetadata();
  static const int _maxVersions = 5;

  GoogleSignInAccount? get account => _account;
  DriveMetadata get metadata => _metadata;
  bool get isConnected => _account != null;

  static const _driveApi = 'https://www.googleapis.com/drive/v3';
  static const _uploadApi = 'https://www.googleapis.com/upload/drive/v3';
  static const _appFolderName = 'Libero360Backups';

  Future<GoogleSignInAccount?> signIn() async {
    try {
      _account = await _googleSignIn.signInSilently();
      _account ??= await _googleSignIn.signIn();
      if (_account != null) {
        await _findExistingBackups();
        _metadata = _metadata.copyWith(isConnected: true);
        LogService.instance
            .system('🔵 Google Drive conectado: ${_account!.email}', source: 'GoogleDriveService');
      }
      return _account;
    } catch (e) {
      LogService.instance.error('🔴 Error al conectar Google Drive: $e', source: 'GoogleDriveService');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
    _metadata = const DriveMetadata();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final auth = await _account!.authHeaders;
    return {'Authorization': auth['Authorization'] ?? '', 'Content-Type': 'application/json'};
  }

  Future<String?> _getAppFolderId() async {
    final headers = await _getAuthHeaders();
    final query = Uri.parse(_driveApi).replace(queryParameters: {
      'q': "name='$_appFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      'fields': 'files(id,name)',
      'pageSize': '1',
    });
    final res = await http.get(query, headers: headers);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    final files = data['files'] as List?;
    if (files != null && files.isNotEmpty) {
      return files[0]['id'] as String;
    }
    return await _createAppFolder(headers);
  }

  Future<String> _createAppFolder(Map<String, String> headers) async {
    final res = await http.post(
      Uri.parse('$_driveApi/files'),
      headers: headers,
      body: jsonEncode({
        'name': _appFolderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );
    if (res.statusCode != 200) throw Exception('Error al crear carpeta en Drive');
    return jsonDecode(res.body)['id'] as String;
  }

  Future<void> _findExistingBackups() async {
    try {
      final headers = await _getAuthHeaders();
      final folderId = await _getAppFolderId();
      if (folderId == null) return;

      final query = Uri.parse(_driveApi).replace(queryParameters: {
        'q': "'$folderId' in parents and name contains 'libero360_backup' and trashed=false",
        'fields': 'files(id,name,size,createdTime,appProperties)',
        'orderBy': 'createdTime desc',
        'pageSize': '$_maxVersions',
      });
      final res = await http.get(query, headers: headers);
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      final files = data['files'] as List?;
      if (files == null || files.isEmpty) return;

      final file = files[0] as Map<String, dynamic>;
      final history = files.map((f) => (f as Map<String, dynamic>)['id'] as String).toList();
      _metadata = _metadata.copyWith(
        fileId: file['id'] as String?,
        fileName: file['name'] as String?,
        lastBackup: file['createdTime'] != null
            ? DateTime.tryParse(file['createdTime'] as String)
            : null,
        fileSize: file['size'] != null ? int.tryParse(file['size'].toString()) : null,
        appVersion: (file['appProperties'] as Map?)?.containsKey('version') == true
            ? (file['appProperties'] as Map)['version'] as String?
            : null,
        checksum: (file['appProperties'] as Map?)?.containsKey('checksum') == true
            ? (file['appProperties'] as Map)['checksum'] as String?
            : null,
        versionHistory: history,
      );
    } catch (_) {}
  }

  Future<String?> pickBackupFromDrive() async {
    // Re-scan files for latest version list
    await _findExistingBackups();
    if (_metadata.fileId == null) return null;
    return _metadata.fileId;
  }

  Future<String?> uploadBackup(String jsonContent, {String? checksum, String? appVersion}) async {
    try {
      if (_account == null) return 'No hay cuenta conectada';
      final headers = await _getAuthHeaders();
      final folderId = await _getAppFolderId();
      if (folderId == null) return 'No se pudo crear carpeta en Drive';

      final date = DateTime.now().toIso8601String().split('T').first;
      final time = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'libero360_backup_${date}_$time.json';

      final metadata = {
        'name': fileName,
        'parents': [folderId],
        'appProperties': {
          if (checksum != null) 'checksum': checksum,
          if (appVersion != null) 'version': appVersion,
          'createdAt': DateTime.now().toIso8601String(),
        },
      };

      final boundary = 'boundary_${DateTime.now().millisecondsSinceEpoch}';
      final body = encodeMultipart(
        boundary: boundary,
        metadata: jsonEncode(metadata),
        data: jsonContent,
        mimeType: 'application/json',
      );

      final res = await http.post(
        Uri.parse('$_uploadApi/files?uploadType=multipart'),
        headers: {
          ...headers,
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: body,
      );

      if (res.statusCode != 200) {
        return 'Error al subir backup (${res.statusCode})';
      }

      final result = jsonDecode(res.body);
      final fileId = result['id'] as String;

      // Trim old backups
      final newHistory = [fileId, ..._metadata.versionHistory];
      if (newHistory.length > _maxVersions) {
        final toDelete = newHistory.sublist(_maxVersions);
        for (final oldId in toDelete) {
          try {
            await http.delete(Uri.parse('$_driveApi/files/$oldId'), headers: headers);
          } catch (_) {}
        }
        newHistory.removeRange(_maxVersions, newHistory.length);
      }

      _metadata = _metadata.copyWith(
        fileId: fileId,
        fileName: fileName,
        lastBackup: DateTime.now(),
        fileSize: jsonContent.length,
        checksum: checksum,
        appVersion: appVersion,
        versionHistory: newHistory,
      );

      LogService.instance.auto('🟢 Backup subido: $fileName', source: 'GoogleDriveService');
      return null;
    } catch (e) {
      LogService.instance.error('🔴 Error al subir backup a Drive: $e', source: 'GoogleDriveService');
      return 'Error al subir backup: $e';
    }
  }

  Future<String?> downloadBackup({String? fileId}) async {
    try {
      if (_account == null) return null;
      final targetId = fileId ?? _metadata.fileId;
      if (targetId == null) {
        LogService.instance.error('🔴 No hay backup en Drive', source: 'GoogleDriveService');
        return null;
      }

      final headers = await _getAuthHeaders();
      final res = await http.get(
        Uri.parse('$_driveApi/files/$targetId?alt=media'),
        headers: headers,
      );

      if (res.statusCode != 200) {
        LogService.instance.error('🔴 Error al descargar backup de Drive (${res.statusCode})', source: 'GoogleDriveService');
        return null;
      }

      LogService.instance.system('🟠 Backup descargado de Drive (${res.body.length} bytes)', source: 'GoogleDriveService');
      return res.body;
    } catch (e) {
      LogService.instance.error('🔴 Error al descargar backup de Drive: $e', source: 'GoogleDriveService');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> listBackupVersions() async {
    try {
      if (_account == null) return [];
      final headers = await _getAuthHeaders();
      final folderId = await _getAppFolderId();
      if (folderId == null) return [];

      final query = Uri.parse(_driveApi).replace(queryParameters: {
        'q': "'$folderId' in parents and name contains 'libero360_backup' and trashed=false",
        'fields': 'files(id,name,size,createdTime,appProperties)',
        'orderBy': 'createdTime desc',
        'pageSize': '$_maxVersions',
      });
      final res = await http.get(query, headers: headers);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      return (data['files'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> verifyIntegrity(String jsonContent, {String? expectedChecksum}) async {
    if (expectedChecksum == null) return true;
    try {
      final data = jsonDecode(jsonContent);
      final actualChecksum = data['checksum'] as String?;
      if (actualChecksum == null || actualChecksum != expectedChecksum) {
        LogService.instance.error('🔴 Checksum no coincide: esperado=$expectedChecksum, actual=$actualChecksum', source: 'GoogleDriveService');
        return false;
      }
      LogService.instance.system('🟠 Verificación de integridad exitosa', source: 'GoogleDriveService');
      return true;
    } catch (e) {
      LogService.instance.error('🔴 Error al verificar integridad: $e', source: 'GoogleDriveService');
      return false;
    }
  }

  Future<void> refreshMetadata() async {
    await _findExistingBackups();
  }
}

String encodeMultipart({
  required String boundary,
  required String metadata,
  required String data,
  String mimeType = 'application/json',
}) {
  final buffer = StringBuffer();
  buffer.writeln('--$boundary');
  buffer.writeln('Content-Type: application/json; charset=UTF-8');
  buffer.writeln();
  buffer.writeln(metadata);
  buffer.writeln('--$boundary');
  buffer.writeln('Content-Type: $mimeType');
  buffer.writeln();
  buffer.writeln(data);
  buffer.writeln('--$boundary--');
  return buffer.toString();
}
