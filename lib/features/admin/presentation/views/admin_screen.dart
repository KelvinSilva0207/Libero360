import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/asistencia/presentation/views/athlete_list_screen.dart';
import '../../../../features/teams/teams.dart';
import '../../../../features/notifications/notifications.dart';
import '../../../../features/settings/presentation/views/settings_screen.dart';
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
    _Section('notificaciones', Icons.notifications_rounded, 'Notificaciones'),
    _Section('general', Icons.tune_rounded, 'General'),
    _Section('personalizacion', Icons.palette_rounded, 'Personalización'),
    _Section('sincronizacion', Icons.cloud_sync_rounded, 'Sincronización'),
    _Section('datos', Icons.storage_rounded, 'Base de Datos'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final theme = context.watch<ThemeNotifier>();
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: const Text('Administrar'),
          ),
          body: SafeArea(
            child: Row(
              children: [
                if (isWide) _buildSidebar(cs),
                Expanded(
                  child: _buildContent(user, theme, cs),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(ColorScheme cs) {
    return Container(
      width: 220,
      color: cs.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text('ADMINISTRAR',
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
          ),
          Divider(color: cs.outlineVariant),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _sections.map((s) => _sidebarItem(cs, s)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(ColorScheme cs, _Section s) {
    final selected = _selectedSection == s.id;
    return Container(
      color: selected ? cs.primary.withValues(alpha: 0.15) : Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Icon(s.icon,
            size: 18,
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.6)),
        title: Text(s.label,
            style: TextStyle(
                color: selected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
        onTap: () => setState(() => _selectedSection = s.id),
      ),
    );
  }

  Widget _buildContent(dynamic user, ThemeNotifier theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(cs),
            const SizedBox(height: 20),
            ..._buildSectionContent(user, theme, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ColorScheme cs) {
    final s = _sections.firstWhere((s) => s.id == _selectedSection);
    return Text(s.label,
        style: TextStyle(
            color: cs.onSurface, fontSize: 22, fontWeight: FontWeight.bold));
  }

  List<Widget> _buildSectionContent(dynamic user, ThemeNotifier theme, ColorScheme cs) {
    switch (_selectedSection) {
      case 'cuenta':
        return _cuentaSection(cs, user);
      case 'equipo':
        return _equipoSection(cs);
      case 'notificaciones':
        return _notificacionesSection(cs);
      case 'general':
        return _generalSection(cs);
      case 'personalizacion':
        return _personalizacionSection(cs, theme);
      case 'sincronizacion':
        return _sincronizacionSection(cs);
      case 'datos':
        return _datosSection(cs);
      default:
        return [];
    }
  }

  // ========== CUENTA ==========
  List<Widget> _cuentaSection(ColorScheme cs, dynamic user) {
    return [
      _sectionCard(cs,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingRow(cs, Icons.person_rounded, 'Nombre del equipo',
                user?.nombre ?? 'Mi Equipo'),
            Divider(color: cs.outlineVariant),
            _buildSettingRow(cs, Icons.email_rounded, 'Correo',
                user?.email ?? 'correo@ejemplo.com'),
            Divider(color: cs.outlineVariant),
            _buildSettingRow(cs, Icons.lock_rounded, 'Contraseña', '********'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthViewModel>().logout();
                },
                icon: const Icon(Icons.logout_rounded,
                    size: 16, color: Colors.redAccent),
                label: const Text('Cerrar sesión',
                    style: TextStyle(color: Colors.redAccent)),
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

  Widget _buildSettingRow(
      ColorScheme cs, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6), fontSize: 11)),
              Text(value,
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ========== EQUIPO TÉCNICO ==========
  List<Widget> _equipoSection(ColorScheme cs) {
    return [
      _sectionCard(cs,
        Column(
          children: [
            _buildActionRow(cs, Icons.groups_2_rounded,
                'Gestionar equipo técnico', 'Invitar, roles, permisos'),
            Divider(color: cs.outlineVariant),
            _buildActionRow(cs, Icons.person_add_alt_1_rounded,
                'Invitar miembro del staff', 'Enviar invitación por correo'),
            Divider(color: cs.outlineVariant),
            _buildActionRow(cs, Icons.swap_horiz_rounded,
                'Cambiar de club', 'Seleccionar club activo'),
          ],
        ),
      ),
    ];
  }

  // ========== NOTIFICACIONES ==========
  List<Widget> _notificacionesSection(ColorScheme cs) {
    return [
      _sectionCard(cs,
        Column(
          children: [
            _buildActionRow(cs, Icons.notifications_rounded,
                'Ver notificaciones', 'Historial de notificaciones'),
            Divider(color: cs.outlineVariant),
            _buildActionRow(cs, Icons.settings_rounded,
                'Preferencias de notificaciones', 'Personalizar alertas'),
            Divider(color: cs.outlineVariant),
            _buildSwitchRow(cs, Icons.notifications_active_rounded,
                'Notificaciones', _notificacionesOn ? 'Activado' : 'Desactivado', true),
          ],
        ),
      ),
    ];
  }

  // ========== GENERAL ==========
  List<Widget> _generalSection(ColorScheme cs) {
    return [
      _sectionCard(cs,
        Column(
          children: [
            _buildSwitchRow(cs, Icons.language_rounded, 'Idioma', 'Español', null),
            Divider(color: cs.outlineVariant),
            _buildSwitchRow(cs, Icons.notifications_rounded, 'Notificaciones',
                _notificacionesOn ? 'Activado' : 'Desactivado', true),
            Divider(color: cs.outlineVariant),
            _buildSwitchRow(cs, Icons.save_rounded, 'Guardado automático',
                _autoSaveOn ? 'Cada 30s' : 'Desactivado', true),
            Divider(color: cs.outlineVariant),
            _buildSwitchRow(cs, Icons.backup_rounded, 'Respaldo automático',
                'Desactivado', null),
            Divider(color: cs.outlineVariant),
            _buildActionRow(cs, Icons.tune_rounded,
                'Preferencias de notificaciones', 'Personalizar alertas'),
          ],
        ),
      ),
    ];
  }

  // ========== PERSONALIZACIÓN ==========
  List<Widget> _personalizacionSection(ColorScheme cs, ThemeNotifier theme) {
    return [
      _sectionCard(cs,
        Column(
          children: [
            _buildThemeSelector(cs, theme),
            Divider(color: cs.outlineVariant),
            _buildColorRow(cs, 'Color acento', cs.primary),
            Divider(color: cs.outlineVariant),
            _buildSwitchRow(cs, Icons.animation_rounded, 'Animaciones',
                'Activado', true),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _sectionCard(cs,
        Column(
          children: [
            _buildSwitchRow(cs, Icons.desktop_windows_rounded, 'Diseño escritorio',
                'Automático', null),
            Divider(color: cs.outlineVariant),
            _buildSwitchRow(cs, Icons.phone_android_rounded, 'Diseño móvil',
                'Automático', null),
          ],
        ),
      ),
    ];
  }

  Widget _buildThemeSelector(ColorScheme cs, ThemeNotifier theme) {
    final isDark = theme.isDark;
    final isLight = theme.isLight;
    final isSystem = theme.isSystem;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.dark_mode_rounded,
              size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tema',
                    style: TextStyle(color: cs.onSurface, fontSize: 14)),
                Text('Oscuro / Claro / Sistema',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
          _themeChip(cs, theme, Icons.dark_mode_rounded, ThemeMode.dark, isDark),
          const SizedBox(width: 6),
          _themeChip(cs, theme, Icons.light_mode_rounded, ThemeMode.light, isLight),
          const SizedBox(width: 6),
          _themeChip(cs, theme, Icons.settings_brightness_rounded, ThemeMode.system, isSystem),
        ],
      ),
    );
  }

  Widget _themeChip(ColorScheme cs, ThemeNotifier theme, IconData icon,
      ThemeMode mode, bool selected) {
    return GestureDetector(
      onTap: () => theme.setMode(mode),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Icon(icon,
            size: 18,
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }

  // ========== SINCRONIZACIÓN ==========
  List<Widget> _sincronizacionSection(ColorScheme cs) {
    return [
      _sectionCard(cs,
        Column(
          children: [
            _buildSwitchRow(cs, Icons.cloud_rounded, 'Firebase Sync',
                'No vinculado', null),
            Divider(color: cs.outlineVariant),
            _buildActionRow(cs, Icons.file_download_rounded, 'Exportar datos',
                'Respaldo JSON'),
            Divider(color: cs.outlineVariant),
            _buildActionRow(cs, Icons.file_upload_rounded, 'Importar datos',
                'Restaurar desde JSON'),
          ],
        ),
      ),
    ];
  }

  // ========== BASE DE DATOS ==========
  List<Widget> _datosSection(ColorScheme cs) {
    return [
      _sectionCard(cs,
        Column(
          children: [
            _buildActionRow(
                cs, Icons.settings_rounded, 'Ajustes', 'Configuración avanzada'),
            Divider(color: cs.outlineVariant),
            _buildActionRow(
                cs, Icons.people_rounded, 'Administrar atletas', 'Ver, editar o eliminar'),
            Divider(color: cs.outlineVariant),
            _buildActionRow(cs, Icons.search_rounded, 'Buscar atletas',
                'Buscar por nombre o número'),
            Divider(color: cs.outlineVariant),
            _buildActionRow(
                cs, Icons.edit_rounded, 'Editar atletas', 'Modificar información'),
            Divider(color: cs.outlineVariant),
            _buildActionRow(cs, Icons.delete_rounded, 'Eliminar atletas',
                'Eliminar del registro'),
            Divider(color: cs.outlineVariant),
            _buildActionRow(cs, Icons.restore_rounded, 'Restaurar base de datos',
                'Desde respaldo JSON'),
          ],
        ),
      ),
    ];
  }

  // ========== HELPERS ==========

  Widget _sectionCard(ColorScheme cs, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _buildSwitchRow(ColorScheme cs, IconData icon, String label,
      String subtitle, bool? value) {
    bool getSwitchValue() {
      switch (label) {
        case 'Notificaciones':
          return _notificacionesOn;
        case 'Guardado automático':
          return _autoSaveOn;
        case 'Animaciones':
          return _animationsOn;
        default:
          return value ?? false;
      }
    }

    void onSwitchChanged(bool v) {
      setState(() {
        switch (label) {
          case 'Notificaciones':
            _notificacionesOn = v;
          case 'Guardado automático':
            _autoSaveOn = v;
          case 'Animaciones':
            _animationsOn = v;
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: cs.onSurface, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
          if (value != null)
            Switch(
              value: getSwitchValue(),
              onChanged: onSwitchChanged,
              activeColor: cs.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
      ColorScheme cs, IconData icon, String label, String subtitle) {
    return InkWell(
      onTap: () {
        switch (label) {
          case 'Ajustes':
            context.pushSlide(const SettingsScreen());
          case 'Administrar atletas':
          case 'Buscar atletas':
          case 'Editar atletas':
            context.pushSlide(const AthleteListScreen());
          case 'Eliminar atletas':
            _showDeleteAthletesDialog(context, cs);
          case 'Gestionar equipo técnico':
            context.pushSlide(const TeamManagementScreen());
          case 'Invitar miembro del staff':
            context.pushSlide(const InviteMemberScreen());
          case 'Cambiar de club':
            _showClubSwitcher(context, cs);
          case 'Exportar datos':
            _exportData(context);
          case 'Importar datos':
            _importData(context);
          case 'Restaurar base de datos':
            _importData(context);
          case 'Ver notificaciones':
            context.pushSlide(const NotificationsScreen());
          case 'Preferencias de notificaciones':
            context.pushSlide(const NotificationPreferencesScreen());
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(color: cs.onSurface, fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.6), fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: cs.onSurface.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }

  void _showDeleteAthletesDialog(BuildContext context, ColorScheme cs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        title: Text('Eliminar atletas', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Ve a la lista de atletas, busca el que deseas eliminar y usa la opción de eliminar en su perfil.',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pushSlide(const AthleteListScreen());
            },
            child: Text('Ir a atletas', style: TextStyle(color: cs.primary)),
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
        await Share.shareXFiles([XFile(file.path)],
            text: 'Respaldo Libero360');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al exportar: $e'),
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
          SnackBar(
              content: Text('Error al importar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showClubSwitcher(BuildContext context, ColorScheme cs) {
    final vm = context.read<ClubViewModel>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerHighest,
        title:
            Text('Seleccionar club', style: TextStyle(color: cs.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: vm.myClubs
                .map((club) => RadioListTile<String>(
                      title: Text(club.name,
                          style: TextStyle(
                            color: club.id == vm.currentClub?.id
                                ? cs.primary
                                : cs.onSurface,
                          )),
                      value: club.id,
                      groupValue: vm.currentClub?.id,
                      activeColor: cs.primary,
                      onChanged: (v) {
                        if (v != null) vm.setCurrentClub(v);
                        Navigator.pop(ctx);
                      },
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
                ctx, MaterialPageRoute(builder: (_) => const CreateClubScreen())),
            child: Text('Crear club', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(ColorScheme cs, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.palette_rounded,
              size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: cs.onSurface, fontSize: 14)),
          const Spacer(),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24)),
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
