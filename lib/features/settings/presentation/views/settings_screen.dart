import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/themes/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('General'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: FontAwesomeIcons.language,
            title: 'Idioma',
            subtitle: 'Español',
          ),
          _SettingsTile(
            icon: FontAwesomeIcons.palette,
            title: 'Tema',
            subtitle: 'Oscuro',
          ),
          const SizedBox(height: 24),
          _section('Partido'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: FontAwesomeIcons.rotate,
            title: 'Sistema de rotaciones',
            subtitle: 'Activar rotación automática',
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeColor: AppColors.accent,
            ),
          ),
          _SettingsTile(
            icon: FontAwesomeIcons.clock,
            title: 'Duración de sets',
            subtitle: '25 puntos, ventaja de 2',
          ),
          const SizedBox(height: 24),
          _section('Sincronización'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: FontAwesomeIcons.cloudArrowUp,
            title: 'Sincronizar dispositivos',
            subtitle: 'No vinculado',
          ),
          _SettingsTile(
            icon: FontAwesomeIcons.arrowRightArrowLeft,
            title: 'Exportar datos',
            subtitle: 'JSON / CSV',
          ),
          const SizedBox(height: 24),
          _section('Acerca de'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: FontAwesomeIcons.circleInfo,
            title: 'Versión',
            subtitle: '1.0.0',
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.accent,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ListTile(
        leading: FaIcon(icon, color: AppColors.primary, size: 20),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: trailing ?? const FaIcon(FontAwesomeIcons.chevronRight, color: Colors.white24, size: 14),
        onTap: trailing != null ? null : () {},
      ),
    );
  }
}
