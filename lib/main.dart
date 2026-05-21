import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth.dart';
import 'features/partido/partido.dart';
import 'features/asistencia/asistencia.dart';
import 'features/estadisticas/presentation/views/play_by_play_screen.dart';

void main() {
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
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
            return const AuthScreen();
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Libero360 - Gestión de Voleibol', style: TextStyle(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: const Color(0xFFFF8C00),
              child: Text(
                user?.nombre.isNotEmpty == true ? user!.nombre[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
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
                child: Text(user?.nombre ?? 'Usuario',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
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
                    Image.asset('assets/images/logo_libero.png', width: 100, height: 100),
                    const SizedBox(height: 20),
                    Text(
                      'Bienvenido, ${user?.nombre ?? "Usuario"}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'App de Gestión de Voleibol',
                      style: TextStyle(fontSize: 16, color: Colors.white54),
                    ),
                    const SizedBox(height: 40),
                    Wrap(
                      spacing: isWide ? 24 : 10,
                      runSpacing: isWide ? 16 : 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _FeatureButton(
                          icon: Icons.person,
                          label: 'Atletas',
                          isWide: isWide,
                          onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const AthleteListScreen()),
                          ),
                        ),
                        _FeatureButton(
                          icon: Icons.sports_score,
                          label: 'Partidos',
                          isWide: isWide,
                          onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const MatchScreen()),
                          ),
                        ),
                        _FeatureButton(
                          icon: Icons.analytics,
                          label: 'Estadísticas',
                          isWide: isWide,
                          onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const PlayByPlayScreen()),
                          ),
                        ),
                        _FeatureButton(
                          icon: Icons.check_circle,
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
      icon: Icon(icon, size: isWide ? 28 : 20),
      label: Text(label, style: TextStyle(fontSize: isWide ? 16 : 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: isWide ? 36 : 20, vertical: isWide ? 24 : 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}