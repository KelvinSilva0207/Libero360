import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthRepository {
  final List<AppUser> _users = [];
  AppUser? _currentUser;
  final _uuid = const Uuid();

  Future<AppUser?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = _users.where((u) => u.email == email && u.password == password);
    if (user.isEmpty) return null;
    _currentUser = user.first;
    return _currentUser;
  }

  Future<String?> register(String nombre, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_users.any((u) => u.email == email)) {
      return 'El correo ya está registrado';
    }
    final user = AppUser(
      id: _uuid.v4(),
      nombre: nombre,
      email: email,
      password: password,
    );
    _users.add(user);
    _currentUser = user;
    return null;
  }

  void logout() {
    _currentUser = null;
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
}
