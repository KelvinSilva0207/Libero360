import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

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
