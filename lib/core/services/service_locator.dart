import 'abstract_auth_service.dart';
import 'abstract_data_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;
  ServiceLocator._internal();

  AbstractAuthService? _authService;
  AbstractDataService? _dataService;

  AbstractAuthService get authService {
    if (_authService == null) {
      throw StateError('AuthService not initialized. Call initialize() first.');
    }
    return _authService!;
  }

  AbstractDataService get dataService {
    if (_dataService == null) {
      throw StateError('DataService not initialized. Call initialize() first.');
    }
    return _dataService!;
  }

  void registerAuth(AbstractAuthService service) {
    _authService = service;
  }

  void registerData(AbstractDataService service) {
    _dataService = service;
  }

  bool get hasAuthService => _authService != null;
  bool get hasDataService => _dataService != null;
}
