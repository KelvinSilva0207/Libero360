import 'package:flutter/foundation.dart';
import '../../data/profile_model.dart';
import '../../data/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository.instance;

  List<ProfileModel> _profiles = [];
  ProfileModel? _currentProfile;
  bool _loading = false;
  String? _error;

  List<ProfileModel> get profiles => _profiles;
  ProfileModel? get currentProfile => _currentProfile;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasProfiles => _profiles.isNotEmpty;

  Future<void> loadProfiles() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _profiles = await _repository.loadProfiles();
      final activeId = await _repository.getActiveProfileId();
      if (activeId != null) {
        _currentProfile = _profiles.cast<ProfileModel?>().firstWhere(
              (p) => p?.id == activeId,
              orElse: () => null,
            );
      }
      if (_currentProfile == null && _profiles.isNotEmpty) {
        _currentProfile = _profiles.first;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectProfile(String id) async {
    final profile = _profiles.cast<ProfileModel?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
    if (profile == null) return;
    _currentProfile = profile;
    await _repository.setActiveProfileId(id);
    notifyListeners();
  }

  Future<ProfileModel> createProfile({
    required String clubId,
    required String clubName,
    required String name,
    required String category,
    required String role,
  }) async {
    final profile = ProfileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clubId: clubId,
      clubName: clubName,
      name: name,
      category: category,
      role: role,
      isActive: false,
    );
    await _repository.addProfile(profile);
    _profiles.add(profile);
    if (_profiles.length == 1) {
      _currentProfile = profile;
      await _repository.setActiveProfileId(profile.id);
    }
    notifyListeners();
    return profile;
  }

  Future<void> deleteProfile(String id) async {
    await _repository.deleteProfile(id);
    _profiles.removeWhere((p) => p.id == id);
    if (_currentProfile?.id == id) {
      _currentProfile = _profiles.isNotEmpty ? _profiles.first : null;
      await _repository.setActiveProfileId(_currentProfile?.id);
    }
    notifyListeners();
  }

  void clear() {
    _profiles = [];
    _currentProfile = null;
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
