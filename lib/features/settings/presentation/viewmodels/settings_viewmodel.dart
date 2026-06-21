import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../teams/presentation/viewmodels/club_viewmodel.dart';
import '../../data/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repository;
  final ThemeNotifier _themeNotifier;
  final AuthViewModel _authViewModel;
  final ClubViewModel _clubViewModel;

  bool _notificationsEnabled = true;
  bool _autoRotation = true;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSyncing = false;
  String? _lastBackupDate;

  SettingsViewModel({
    required SettingsRepository repository,
    required ThemeNotifier themeNotifier,
    required AuthViewModel authViewModel,
    required ClubViewModel clubViewModel,
  })  : _repository = repository,
        _themeNotifier = themeNotifier,
        _authViewModel = authViewModel,
        _clubViewModel = clubViewModel;

  // --- Getters ---
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoRotation => _autoRotation;
  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  bool get isSyncing => _isSyncing;
  String? get lastBackupDate => _lastBackupDate;

  // User info
  String get userName => _authViewModel.user?.nombre ?? 'Usuario';
  String get userEmail => _authViewModel.user?.email ?? '';

  // Theme
  ThemeMode get themeMode => _themeNotifier.mode;
  bool get isDark => _themeNotifier.isDark;
  bool get isLight => _themeNotifier.isLight;
  bool get isSystem => _themeNotifier.isSystem;

  // Club
  String get clubName => _clubViewModel.currentClub?.name ?? '';

  // --- Setters ---
  void setNotificationsEnabled(bool v) {
    _notificationsEnabled = v;
    notifyListeners();
  }

  void setAutoRotation(bool v) {
    _autoRotation = v;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeNotifier.setMode(mode);
    notifyListeners();
  }

  // --- Actions ---
  void logout() => _authViewModel.logout();

  void inviteMembers() {}

  Future<void> exportDatabase() async {
    _isExporting = true;
    notifyListeners();
    try {
      final json = await _repository.exportToJson();
      final date = DateTime.now().toIso8601String().split('T').first;
      final file = await _repository.saveTempFile(
          'libero360_backup_$date.json', json);
      await _repository.shareFile(file, text: 'Respaldo Libero360 - $date');
      _lastBackupDate = date;
    } catch (_) {
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> importDatabase() async {
    _isImporting = true;
    notifyListeners();
    try {
      final json = await _repository.pickJsonFile();
      if (json != null) {
        await _repository.importFromJson(json);
      }
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  /// Sincroniza datos con Firebase (placeholder — no implementado aún).
  Future<void> syncNow() async {
    _isSyncing = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Restaura base de datos desde un archivo JSON.
  Future<void> restoreBackup() async {
    await importDatabase();
  }

  static SettingsViewModel of(BuildContext context) {
    return context.read<SettingsViewModel>();
  }
}
