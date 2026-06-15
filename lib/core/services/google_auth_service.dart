import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/estadisticas/data/local_db/database_service.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  static GoogleAuthService get instance => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '977265581819-lsf2k2370img9f2204v5n173oikvjhdv.apps.googleusercontent.com',
  );

  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;

  Future<void> initialize() async {
    try {
      _isAvailable = await _googleSignIn.isSignedIn() || true;
    } catch (_) {
      _isAvailable = false;
    }
  }

  Future<AppUser?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final email = account.email;
      final nombre = account.displayName ?? email.split('@').first;

      await DatabaseService.instance.initialize();
      var user = await DatabaseService.instance.getUserByEmail(email);

      if (user == null) {
        user = AppUser(
          nombre: nombre,
          email: email,
          password: '',
        );
        final id = await DatabaseService.instance.saveUser(user);
        user.id = id;
      }

      await DatabaseService.instance.saveSessionUserId(user.id);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
