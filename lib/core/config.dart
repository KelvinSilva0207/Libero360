class AppConfig {
  AppConfig._();

  /// Cambia a true cuando Firebase esté configurado
  static bool get useFirebase => _useFirebase;
  static bool _useFirebase = false;

  /// Activar Firebase (llamado por setup script)
  static void enableFirebase() {
    _useFirebase = true;
  }
}
