import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _rotacion = true;

  void _showInfo(String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

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
            onTap: () => _showInfo('Idioma', 'El idioma se detecta automáticamente según la configuración del dispositivo.'),
          ),
          _SettingsTile(
            icon: Icons.palette,
            title: 'Tema',
            subtitle: 'Oscuro',
            onTap: () => _showInfo('Tema', 'Solo modo oscuro disponible en esta versión.'),
          ),
          const SizedBox(height: 24),
          _section('Partido'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.sync_alt,
            title: 'Sistema de rotaciones',
            subtitle: 'Activar rotación automática',
            trailing: Switch(
              value: _rotacion,
              onChanged: (v) => setState(() => _rotacion = v),
              activeColor: AppColors.accent,
            ),
          ),
          _SettingsTile(
            icon: Icons.access_time,
            title: 'Duración de sets',
            subtitle: '25 puntos, ventaja de 2',
            onTap: () => _showInfo('Duración de sets', 'Por defecto: 25 puntos con ventaja mínima de 2.'),
          ),
          const SizedBox(height: 24),
          _section('Sincronización'),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.cloud_upload,
            title: 'Sincronizar dispositivos',
            subtitle: 'No vinculado',
            onTap: () => _showInfo('Sincronizar', 'La sincronización entre dispositivos estará disponible en una próxima actualización.'),
          ),
          _SettingsTile(
            icon: Icons.compare_arrows,
            title: 'Exportar datos',
            subtitle: 'JSON / CSV',
            onTap: () => _showInfo('Exportar', 'Usa la opción Exportar datos en el menú de configuración del panel principal.'),
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
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
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
        onTap: onTap,
      ),
    );
  }
}
