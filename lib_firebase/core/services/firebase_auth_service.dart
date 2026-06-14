import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../lib/core/services/abstract_auth_service.dart';
import '../../../features/auth/data/models/user_model.dart';
import '../../../features/estadisticas/data/local_db/database_service.dart';

class FirebaseAuthService extends AbstractAuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  AppUser? _currentUser;

  @override
  Future<AppUser?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid ?? '';
      await DatabaseService.instance.initialize();
      final localUser = await DatabaseService.instance.getUserByEmail(email);
      if (localUser != null) {
        _currentUser = localUser;
        await DatabaseService.instance.saveSessionUserId(localUser.id);
        return _currentUser;
      }
      final user = AppUser(nombre: uid, email: email, password: password);
      final id = await DatabaseService.instance.saveUser(user);
      user.id = id;
      _currentUser = user;
      await DatabaseService.instance.saveSessionUserId(id);
      return _currentUser;
    } on fb.FirebaseAuthException {
      return null;
    }
  }

  @override
  Future<String?> register(String nombre, String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await DatabaseService.instance.initialize();
      final existing = await DatabaseService.instance.getUserByEmail(email);
      if (existing != null) {
        return 'El correo ya está registrado';
      }
      final user = AppUser(nombre: nombre, email: email, password: password);
      final id = await DatabaseService.instance.saveUser(user);
      user.id = id;
      _currentUser = user;
      await DatabaseService.instance.saveSessionUserId(id);
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return e.message ?? 'Error al registrar';
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    await DatabaseService.instance.clearSession();
  }

  @override
  Future<void> loadSession() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      await DatabaseService.instance.initialize();
      final email = fbUser.email ?? '';
      final localUser = await DatabaseService.instance.getUserByEmail(email);
      if (localUser != null) {
        _currentUser = localUser;
        await DatabaseService.instance.saveSessionUserId(localUser.id);
        return;
      }
      final userId = await DatabaseService.instance.getSessionUserId();
      if (userId != null) {
        _currentUser = await DatabaseService.instance.getUserById(userId);
      }
    } else {
      await DatabaseService.instance.initialize();
      final userId = await DatabaseService.instance.getSessionUserId();
      if (userId != null) {
        _currentUser = await DatabaseService.instance.getUserById(userId);
      }
    }
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;
}
