import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Configuración', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('General'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.language,
            title: 'Idioma',
            subtitle: 'Español',
          ),
          _SettingsTile(
            icon: Icons.palette,
            title: 'Tema',
            subtitle: 'Oscuro',
          ),
          const SizedBox(height: 24),
          _section('Partido'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.sync_alt,
            title: 'Sistema de rotaciones',
            subtitle: 'Activar rotación automática',
            trailing: Switch(
              value: true,
              onChanged: (v) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente disponible'), backgroundColor: AppColors.primary),
                );
              },
              activeColor: AppColors.accent,
            ),
          ),
          _SettingsTile(
            icon: Icons.access_time,
            title: 'Duración de sets',
            subtitle: '25 puntos, ventaja de 2',
          ),
          const SizedBox(height: 24),
          _section('Sincronización'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.cloud_upload,
            title: 'Sincronizar dispositivos',
            subtitle: 'No vinculado',
          ),
          _SettingsTile(
            icon: Icons.compare_arrows,
            title: 'Exportar datos',
            subtitle: 'JSON / CSV',
          ),
          const SizedBox(height: 24),
          _section('Acerca de'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline,
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
  final IconData icon;
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
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        onTap: trailing != null
            ? null
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente disponible'), backgroundColor: AppColors.primary),
                );
              },
      ),
    );
  }
}
