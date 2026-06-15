import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/asistencia/presentation/views/athlete_list_screen.dart';
import '../../../../features/settings/presentation/widgets/settings_drawer.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _selectedSection = 'cuenta';

  final List<_Section> _sections = [
    _Section('cuenta', Icons.person_rounded, 'Cuenta'),
    _Section('general', Icons.tune_rounded, 'General'),
    _Section('personalizacion', Icons.palette_rounded, 'Personalización'),
    _Section('sincronizacion', Icons.cloud_sync_rounded, 'Sincronización'),
    _Section('datos', Icons.storage_rounded, 'Base de Datos'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final theme = context.watch<ThemeNotifier>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: const Text('Administrar', style: TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Row(
              children: [
                if (isWide) _buildSidebar(),
                Expanded(
                  child: _buildContent(user, theme),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text('ADMINISTRAR', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          const Divider(color: AppColors.border),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _sections.map((s) => _sidebarItem(s)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(_Section s) {
    final selected = _selectedSection == s.id;
    return Container(
      color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(s.icon, size: 18, color: selected ? AppColors.accent : AppColors.textSecondary),
        title: Text(s.label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        onTap: () => setState(() => _selectedSection = s.id),
      ),
    );
  }

  Widget _buildContent(dynamic user, ThemeNotifier theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(),
            const SizedBox(height: 20),
            ..._buildSectionContent(user, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    final s = _sections.firstWhere((s) => s.id == _selectedSection);
    return Text(s.label, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold));
  }

  List<Widget> _buildSectionContent(dynamic user, ThemeNotifier theme) {
    switch (_selectedSection) {
      case 'cuenta': return _cuentaSection(user);
      case 'general': return _generalSection();
      case 'personalizacion': return _personalizacionSection(theme);
      case 'sincronizacion': return _sincronizacionSection();
      case 'datos': return _datosSection();
      default: return [];
    }
  }

  // ========== CUENTA ==========
  List<Widget> _cuentaSection(dynamic user) {
    return [
      _sectionCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingRow(Icons.person_rounded, 'Nombre del equipo', user?.nombre ?? 'Mi Equipo'),
            const Divider(color: AppColors.border),
            _buildSettingRow(Icons.email_rounded, 'Correo', user?.email ?? 'correo@ejemplo.com'),
            const Divider(color: AppColors.border),
            _buildSettingRow(Icons.lock_rounded, 'Contraseña', '********'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthViewModel>().logout();
                },
                icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                label: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildSettingRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ========== GENERAL ==========
  List<Widget> _generalSection() {
    return [
      _sectionCard(
        Column(
          children: [
            _buildSwitchRow(Icons.language_rounded, 'Idioma', 'Español', null),
            const Divider(color: AppColors.border),
            _buildSwitchRow(Icons.notifications_rounded, 'Notificaciones', 'Activado', true),
            const Divider(color: AppColors.border),
            _buildSwitchRow(Icons.save_rounded, 'Guardado automático', 'Cada 30s', true),
            const Divider(color: AppColors.border),
            _buildSwitchRow(Icons.backup_rounded, 'Respaldo automático', 'Desactivado', null),
          ],
        ),
      ),
    ];
  }

  // ========== PERSONALIZACIÓN ==========
  List<Widget> _personalizacionSection(ThemeNotifier theme) {
    return [
      _sectionCard(
        Column(
          children: [
            SwitchListTile(
              title: const Text('Modo oscuro', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(theme.isDark ? 'Oscuro' : 'Claro', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              value: theme.isDark,
              onChanged: (_) => theme.toggle(),
              activeColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(color: AppColors.border),
            _buildColorRow('Color acento', AppColors.accent),
            const Divider(color: AppColors.border),
            _buildSwitchRow(Icons.animation_rounded, 'Animaciones', 'Activado', true),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _sectionCard(
        Column(
          children: [
            _buildSwitchRow(Icons.desktop_windows_rounded, 'Diseño escritorio', 'Automático', null),
            const Divider(color: AppColors.border),
            _buildSwitchRow(Icons.phone_android_rounded, 'Diseño móvil', 'Automático', null),
          ],
        ),
      ),
    ];
  }

  // ========== SINCRONIZACIÓN ==========
  List<Widget> _sincronizacionSection() {
    return [
      _sectionCard(
        Column(
          children: [
            _buildSwitchRow(Icons.cloud_rounded, 'Firebase Sync', 'No vinculado', null),
            const Divider(color: AppColors.border),
            _buildActionRow(Icons.file_download_rounded, 'Exportar datos', 'Respaldo JSON'),
            const Divider(color: AppColors.border),
            _buildActionRow(Icons.file_upload_rounded, 'Importar datos', 'Restaurar desde JSON'),
          ],
        ),
      ),
    ];
  }

  // ========== BASE DE DATOS ==========
  List<Widget> _datosSection() {
    return [
      _sectionCard(
        Column(
          children: [
            _buildActionRow(Icons.people_rounded, 'Administrar atletas', 'Ver, editar o eliminar'),
            const Divider(color: AppColors.border),
            _buildActionRow(Icons.search_rounded, 'Buscar atletas', 'Buscar por nombre o número'),
            const Divider(color: AppColors.border),
            _buildActionRow(Icons.edit_rounded, 'Editar atletas', 'Modificar información'),
            const Divider(color: AppColors.border),
            _buildActionRow(Icons.delete_rounded, 'Eliminar atletas', 'Eliminar del registro'),
            const Divider(color: AppColors.border),
            _buildActionRow(Icons.restore_rounded, 'Restaurar base de datos', 'Desde respaldo JSON'),
          ],
        ),
      ),
    ];
  }

  // ========== HELPERS ==========

  Widget _sectionCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildSwitchRow(IconData icon, String label, String subtitle, bool? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (value != null)
            Switch(
              value: value,
              onChanged: (_) {},
              activeColor: AppColors.accent,
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, String subtitle) {
    return InkWell(
      onTap: label == 'Administrar atletas' || label == 'Buscar atletas' || label == 'Editar atletas'
          ? () => context.pushSlide(const AthleteListScreen())
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.palette_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const Spacer(),
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24)),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final String id;
  final IconData icon;
  final String label;
  const _Section(this.id, this.icon, this.label);
}
