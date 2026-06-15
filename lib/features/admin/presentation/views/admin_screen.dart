import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/asistencia/presentation/views/athlete_list_screen.dart';
import '../../../../features/teams/teams.dart';
import '../../../../features/notifications/notifications.dart';
import '../../../../features/estadisticas/data/local_db/database_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _selectedSection = 'cuenta';
  bool _notificacionesOn = true;
  bool _autoSaveOn = true;
  bool _animationsOn = true;

  final List<_Section> _sections = [
    _Section('cuenta', Icons.person_rounded, 'Cuenta'),
    _Section('equipo', Icons.groups_2_rounded, 'Equipo Técnico'),
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
      case 'equipo': return _equipoSection();
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

  // ========== EQUIPO TÉCNICO ==========
  List<Widget> _equipoSection() {
    return [
      _sectionCard(
        Column(
          children: [
            _buildActionRow(Icons.groups_2_rounded, 'Gestionar equipo técnico', 'Invitar, roles, permisos'),
            const Divider(color: AppColors.border),
            _buildActionRow(Icons.person_add_alt_1_rounded, 'Invitar entrenador', 'Enviar invitación por correo'),
            const Divider(color: AppColors.border),
            _buildActionRow(Icons.swap_horiz_rounded, 'Cambiar de club', 'Seleccionar club activo'),
          ],
        ),
      ),
    ];
  }

  // ========== GENERAL ==========
  List<Widget> _generalSection() {
    return [
      _sectionCard(
        Column(
          children: [
            _buildSwitchRow(Icons.language_rounded, 'Idioma', 'Español', null),
            const Divider(color: AppColors.border),
            _buildSwitchRow(Icons.notifications_rounded, 'Notificaciones', _notificacionesOn ? 'Activado' : 'Desactivado', true),
            const Divider(color: AppColors.border),
            _buildSwitchRow(Icons.save_rounded, 'Guardado automático', _autoSaveOn ? 'Cada 30s' : 'Desactivado', true),
            const Divider(color: AppColors.border),
            _buildSwitchRow(Icons.backup_rounded, 'Respaldo automático', 'Desactivado', null),
            const Divider(color: AppColors.border),
            _buildActionRow(Icons.tune_rounded, 'Preferencias de notificaciones', 'Personalizar alertas'),
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
    bool getSwitchValue() {
      switch (label) {
        case 'Notificaciones': return _notificacionesOn;
        case 'Guardado automático': return _autoSaveOn;
        case 'Animaciones': return _animationsOn;
        default: return value ?? false;
      }
    }

    void onSwitchChanged(bool v) {
      setState(() {
        switch (label) {
          case 'Notificaciones': _notificacionesOn = v;
          case 'Guardado automático': _autoSaveOn = v;
          case 'Animaciones': _animationsOn = v;
        }
      });
    }

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
              value: getSwitchValue(),
              onChanged: onSwitchChanged,
              activeColor: AppColors.accent,
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, String subtitle) {
    return InkWell(
      onTap: () {
        switch (label) {
          case 'Administrar atletas':
          case 'Buscar atletas':
          case 'Editar atletas':
            context.pushSlide(const AthleteListScreen());
            break;
          case 'Eliminar atletas':
            _showDeleteAthletesDialog(context);
            break;
          case 'Gestionar equipo técnico':
            context.pushSlide(const TeamManagementScreen());
            break;
          case 'Invitar entrenador':
            context.pushSlide(const InviteMemberScreen());
            break;
          case 'Cambiar de club':
            _showClubSwitcher(context);
            break;
          case 'Exportar datos':
            _exportData(context);
            break;
          case 'Importar datos':
            _importData(context);
            break;
          case 'Restaurar base de datos':
            _importData(context);
            break;
          case 'Preferencias de notificaciones':
            context.pushSlide(const NotificationPreferencesScreen());
            break;
        }
      },
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

  void _showDeleteAthletesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3D),
        title: const Text('Eliminar atletas',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Ve a la lista de atletas, busca el que deseas eliminar y usa la opción de eliminar en su perfil.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pushSlide(const AthleteListScreen());
            },
            child: const Text('Ir a atletas',
                style: TextStyle(color: Color(0xFFFF8C00))),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final db = DatabaseService.instance;
      final json = await db.exportToJson();
      final file = await _saveTempFile('libero360_backup.json', json);
      if (file != null) {
        await Share.shareXFiles([XFile(file.path)], text: 'Respaldo Libero360');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<File?> _saveTempFile(String name, String content) async {
    final dir = await Directory.systemTemp.createTemp('libero360_');
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final json = await file.readAsString();
      final db = DatabaseService.instance;
      await db.importFromJson(json);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Datos restaurados correctamente'),
              backgroundColor: Color(0xFF4CAF50)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showClubSwitcher(BuildContext context) {
    final vm = context.read<ClubViewModel>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3D),
        title: const Text('Seleccionar club',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: vm.myClubs.map((club) =>
                RadioListTile<String>(
                  title: Text(club.name,
                      style: TextStyle(
                        color: club.id == vm.currentClub?.id
                            ? const Color(0xFFFF8C00)
                            : Colors.white,
                      )),
                  value: club.id,
                  groupValue: vm.currentClub?.id,
                  activeColor: const Color(0xFFFF8C00),
                  onChanged: (v) {
                    if (v != null) vm.setCurrentClub(v);
                    Navigator.pop(ctx);
                  },
                ),
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const CreateClubScreen())),
            child: const Text('Crear club',
                style: TextStyle(color: Color(0xFFFF8C00))),
          ),
        ],
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
