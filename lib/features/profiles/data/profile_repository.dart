import '../../estadisticas/data/local_db/database_service.dart';
import 'profile_model.dart';

class ProfileRepository {
  static final ProfileRepository _instance = ProfileRepository._internal();
  static ProfileRepository get instance => _instance;
  ProfileRepository._internal();

  final DatabaseService _db = DatabaseService.instance;

  Future<List<ProfileModel>> loadProfiles() async {
    await _db.initialize();
    return _db.getAllProfiles();
  }

  Future<void> addProfile(ProfileModel profile) async {
    await _db.initialize();
    await _db.addProfile(profile);
  }

  Future<void> deleteProfile(String id) async {
    await _db.initialize();
    await _db.deleteProfile(id);
  }

  Future<String?> getActiveProfileId() async {
    await _db.initialize();
    return _db.getActiveProfileId();
  }

  Future<void> setActiveProfileId(String? id) async {
    await _db.initialize();
    await _db.setActiveProfileId(id);
  }
}
