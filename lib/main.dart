import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'core/widgets_globales/route_transitions.dart';
import 'core/services/service_locator.dart';
import 'core/config.dart';
import 'features/auth/auth.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'ui/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initServices();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const Libero360App(),
    ),
  );
}

void _initServices() {
  final locator = ServiceLocator.instance;
  if (!AppConfig.useFirebase) {
    locator.registerAuth(AuthRepository());
  }
}

class Libero360App extends StatelessWidget {
  const Libero360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Libero360',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
      home: const AuthGate(),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/welcome':
        return slideRightRoute(const WelcomeScreen());
      case '/login':
        return slideRightRoute(const LoginScreen());
      case '/register':
        return slideRightRoute(const RegisterScreen());
      default:
        return null;
    }
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        switch (vm.status) {
          case AuthStatus.authenticated:
            return const AppShell();
          case AuthStatus.uninitialized:
            return const _SplashScreen();
          case AuthStatus.unauthenticated:
            return const WelcomeScreen();
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_libero.png', width: 80, height: 80),
            const SizedBox(height: 20),
            const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFFF8C00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
