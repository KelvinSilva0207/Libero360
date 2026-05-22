import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'features/auth/auth.dart';
import 'features/partido/partido.dart';
import 'features/asistencia/asistencia.dart';
import 'features/estadisticas/presentation/views/play_by_play_screen.dart';

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
            return const HomeScreen();
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3D),
        title: const Text('Libero360'),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: const Color(0xFFFF8C00),
              radius: 18,
              child: Text(
                user?.nombre.isNotEmpty == true ? user!.nombre[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthViewModel>().logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.nombre ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    if (user?.email != null) Text(user!.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                    SizedBox(width: 10),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0081CF), Color(0xFFFF8C00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(45),
                        child: Image.asset('assets/images/logo_libero.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Bienvenido, ${user?.nombre ?? "Usuario"}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '¿Qué deseas hacer hoy?',
                      style: TextStyle(fontSize: 15, color: Colors.white54),
                    ),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: isWide ? 20 : 12,
                      runSpacing: isWide ? 16 : 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _FeatureButton(
                          icon: Icons.people_rounded,
                          label: 'Atletas',
                          isWide: isWide,
                          onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const AthleteListScreen()),
                          ),
                        ),
                        _FeatureButton(
                          icon: Icons.sports_volleyball_rounded,
                          label: 'Partidos',
                          isWide: isWide,
                          onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const MatchScreen()),
                          ),
                        ),
                        _FeatureButton(
                          icon: Icons.analytics_rounded,
                          label: 'Estadísticas',
                          isWide: isWide,
                          onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const PlayByPlayScreen()),
                          ),
                        ),
                        _FeatureButton(
                          icon: Icons.checklist_rounded,
                          label: 'Asistencia',
                          isWide: isWide,
                          onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isWide;

  const _FeatureButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: isWide ? 26 : 20),
      label: Text(label, style: TextStyle(fontSize: isWide ? 15 : 13, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1F3D),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 20, vertical: isWide ? 22 : 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2D3361), width: 0.5),
        ),
      ),
    );
  }
}
