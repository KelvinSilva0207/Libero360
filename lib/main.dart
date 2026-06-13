import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'features/auth/auth.dart';
import 'ui/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const Libero360App(),
    ),
  );
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
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
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


