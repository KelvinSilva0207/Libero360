import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'features/auth/auth.dart';
import 'features/partido/presentation/views/match_start_dialog.dart';
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
                    FaIcon(FontAwesomeIcons.rightFromBracket, color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 10),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${user?.nombre ?? "Usuario"}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              '¿Qué deseas hacer hoy?',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _HomeCard(
                    icon: FontAwesomeIcons.peopleGroup,
                    label: 'Atletas',
                    onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AthleteListScreen()),
                    ),
                  ),
                  _HomeCard(
                    icon: FontAwesomeIcons.volleyball,
                    label: 'Partidos',
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const MatchStartDialog(),
                    ),
                  ),
                  _HomeCard(
                    icon: FontAwesomeIcons.chartSimple,
                    label: 'Estadísticas',
                    onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const PlayByPlayScreen()),
                    ),
                  ),
                  _HomeCard(
                    icon: FontAwesomeIcons.clipboardCheck,
                    label: 'Asistencia',
                    onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback? onTap;

  const _HomeCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1F3D),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2D3361), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 40, color: const Color(0xFFFF8C00)),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
