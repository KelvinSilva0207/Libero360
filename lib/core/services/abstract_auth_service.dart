import '../../features/auth/data/models/user_model.dart';

abstract class AbstractAuthService {
  Future<AppUser?> login(String email, String password);
  Future<String?> register(String nombre, String email, String password);
  Future<void> logout();
  Future<void> loadSession();
  AppUser? get currentUser;
  bool get isLoggedIn;
}
