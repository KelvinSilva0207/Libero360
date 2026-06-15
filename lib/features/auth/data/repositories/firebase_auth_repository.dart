import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/abstract_auth_service.dart';
import '../models/user_model.dart';

class FirebaseAuthRepository extends AbstractAuthService {
  AppUser? _currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> login(String email, String password) async {
    try {
      final cred = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _fromFirebaseUser(cred.user);
    } on fb.FirebaseAuthException {
      return null;
    }
  }

  @override
  Future<String?> register(String nombre, String email, String password) async {
    try {
      final cred = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(nombre);
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'nombre': nombre,
        'email': email,
        'fechaRegistro': DateTime.now().toIso8601String(),
      });
      _currentUser = AppUser(
        id: 0,
        nombre: nombre,
        email: email,
        password: '',
      );
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    }
  }

  @override
  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await fb.FirebaseAuth.instance.signOut();
    _currentUser = null;
  }

  @override
  Future<void> loadSession() async {
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      _currentUser = _fromFirebaseUser(fbUser);
    }
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;

  Future<AppUser?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = result.user;
      if (fbUser == null) return null;

      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(fbUser.uid).set({
          'nombre': fbUser.displayName ?? fbUser.email?.split('@').first ?? '',
          'email': fbUser.email ?? '',
          'fechaRegistro': DateTime.now().toIso8601String(),
        });
      }

      _currentUser = _fromFirebaseUser(fbUser);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  AppUser? _fromFirebaseUser(fb.User? fbUser) {
    if (fbUser == null) return null;
    return AppUser(
      id: 0,
      nombre: fbUser.displayName ?? fbUser.email?.split('@').first ?? '',
      email: fbUser.email ?? '',
      password: '',
    );
  }

  String _mapAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'El correo ya está registrado';
      case 'invalid-email': return 'Correo inválido';
      case 'weak-password': return 'Contraseña muy débil (mínimo 6 caracteres)';
      case 'user-not-found': return 'Usuario no encontrado';
      case 'wrong-password': return 'Contraseña incorrecta';
      case 'too-many-requests': return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed': return 'Error de conexión';
      default: return 'Error: ${e.message ?? e.code}';
    }
  }
}
