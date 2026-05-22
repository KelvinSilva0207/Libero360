import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../ui/components/app_logo.dart';
import '../../../../ui/components/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF0F172A),
              Color(0xFF060A1A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const AppLogo(size: 100),
                    const SizedBox(height: 48),
                    _buildFeatureList(),
                    const SizedBox(height: 48),
                    AppButton(
                      label: 'Iniciar Sesión',
                      icon: Icons.login_rounded,
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Crear Cuenta',
                      icon: Icons.person_add_rounded,
                      type: AppButtonType.secondary,
                      onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                    ),
                    const SizedBox(height: 32),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      children: [
        _FeatureItem(
          icon: Icons.sports_volleyball_rounded,
          title: 'Gestión de Partidos',
          subtitle: 'Control en vivo con rotaciones y estadísticas',
        ),
        const SizedBox(height: 20),
        _FeatureItem(
          icon: Icons.analytics_rounded,
          title: 'Estadísticas en Tiempo Real',
          subtitle: 'Kills, bloqueos, saques y eficiencia por jugadora',
        ),
        const SizedBox(height: 20),
        _FeatureItem(
          icon: Icons.people_rounded,
          title: 'Plantilla y Asistencia',
          subtitle: 'Control de atletas, posiciones y asistencia',
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿Ya tienes cuenta? ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text(
                'Inicia sesión',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'v1.0.0',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
