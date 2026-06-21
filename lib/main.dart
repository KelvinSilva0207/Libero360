import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/themes/app_theme.dart';
import 'core/widgets_globales/route_transitions.dart';
import 'core/services/service_locator.dart';
import 'core/theme_provider/theme_notifier.dart';
import 'core/config.dart';
import 'features/auth/auth.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/teams/teams.dart';
import 'features/notifications/notifications.dart';
import 'features/partido/presentation/controllers/match_controller.dart';
import 'features/profiles/profiles.dart';
import 'ui/app_shell.dart';
import 'ui/dashboard_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AppConfig.enableFirebase();
  _initServices();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()..loadProfiles()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) {
          final vm = ClubViewModel();
          vm.init();
          return vm;
        }),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => MatchController()),
      ],
      child: const Libero360App(),
    ),
  );
}

void _initServices() {
  final locator = ServiceLocator.instance;
  if (AppConfig.useFirebase) {
    locator.registerAuth(FirebaseAuthRepository());
  } else {
    locator.registerAuth(AuthRepository());
  }
}

class Libero360App extends StatelessWidget {
  const Libero360App({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeNotifier>();
    return MaterialApp(
      title: 'Libero360',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.mode,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
      home: const AuthGate(),
      builder: (context, child) {
        return AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 250),
          child: child!,
        );
      },
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

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_libero.png', width: 100, height: 100),
                const SizedBox(height: 24),
                const Text(
                  'LIBERO360',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voleibol Intelligence',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 2),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF8C00),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
