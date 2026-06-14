import '../../../../core/services/abstract_auth_service.dart';
import '../../../estadisticas/data/local_db/database_service.dart';
import '../models/user_model.dart';

class AuthRepository extends AbstractAuthService {
  AppUser? _currentUser;

  @override
  Future<AppUser?> login(String email, String password) async {
    await DatabaseService.instance.initialize();
    final user = await DatabaseService.instance.getUserByEmail(email);
    if (user == null || user.password != password) return null;
    _currentUser = user;
    await DatabaseService.instance.saveSessionUserId(user.id);
    return _currentUser;
  }

  @override
  Future<String?> register(String nombre, String email, String password) async {
    await DatabaseService.instance.initialize();
    final existing = await DatabaseService.instance.getUserByEmail(email);
    if (existing != null) {
      return 'El correo ya está registrado';
    }
    final user = AppUser(
      nombre: nombre,
      email: email,
      password: password,
    );
    final id = await DatabaseService.instance.saveUser(user);
    user.id = id;
    _currentUser = user;
    await DatabaseService.instance.saveSessionUserId(user.id);
    return null;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    await DatabaseService.instance.clearSession();
  }

  @override
  Future<void> loadSession() async {
    await DatabaseService.instance.initialize();
    final userId = await DatabaseService.instance.getSessionUserId();
    if (userId != null) {
      _currentUser = await DatabaseService.instance.getUserById(userId);
    }
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;
}
