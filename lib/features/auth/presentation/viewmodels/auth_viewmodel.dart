import 'package:flutter/material.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/abstract_auth_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/config.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/firebase_auth_repository.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  AbstractAuthService get _repository => ServiceLocator.instance.authService;

  AuthStatus _status = AuthStatus.uninitialized;
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final user = await _repository.login(email, password);
    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    }
    _error = 'Correo o contraseña incorrectos';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<AppUser?> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    AppUser? user;
    if (AppConfig.useFirebase && _repository is FirebaseAuthRepository) {
      user = await (_repository as FirebaseAuthRepository).signInWithGoogle();
    } else {
      user = await GoogleAuthService.instance.signIn();
    }

    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return user;
    }
    _error = 'Error al iniciar con Google';
    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<String?> register(String nombre, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final error = await _repository.register(nombre, email, password);
    if (error == null) {
      _user = _repository.currentUser;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return null;
    }
    _error = error;
    _isLoading = false;
    notifyListeners();
    return error;
  }

  void logout() {
    _repository.logout();
    if (!AppConfig.useFirebase) {
      GoogleAuthService.instance.signOut();
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    await _repository.loadSession();
    if (_repository.isLoggedIn) {
      _user = _repository.currentUser;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
