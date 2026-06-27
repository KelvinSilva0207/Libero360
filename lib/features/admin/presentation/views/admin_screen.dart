import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../../core/services/log_service.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../settings/presentation/views/account_section.dart';
import '../../../settings/presentation/views/club_section.dart';
import '../../../settings/presentation/views/staff_section.dart';
import '../../../settings/presentation/views/notifications_section.dart';
import '../../../settings/presentation/views/appearance_section.dart';
import '../../../settings/presentation/views/sync_section.dart';
import '../../../settings/presentation/views/database_section.dart';
import '../../../settings/data/backup_service.dart';

enum AdminSection {
  account,
  club,
  staff,
  notifications,
  sync,
  personalization,
  backups,
  data,
  about,
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  AdminSection _selected = AdminSection.account;
  bool _mobileOpen = false;
  final _backupService = BackupService.instance;

  @override
  void initState() {
    super.initState();
    _backupService.init();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final bg = isDark ? const Color(0xFF0A0E21) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: !isWide
          ? AppBar(
              backgroundColor: cs.surface,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => setState(() => _mobileOpen = !_mobileOpen),
              ),
              title: Text(_sectionTitle(_selected)),
            )
          : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide) _buildSidebar(cs, isDark),
            if (_mobileOpen && !isWide) _buildMobileOverlay(cs, isDark),
            Expanded(child: _buildContent(cs, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(ColorScheme cs, bool isDark) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      width: isWide ? 240 : MediaQuery.of(context).size.width * 0.75,
      height: double.infinity,
      color: isDark ? const Color(0xFF121226) : const Color(0xFFFFFFFF),
      child: Column(
        children: [
          _sidebarHeader(cs),
          Expanded(child: _navList(cs, isDark)),
          _sidebarFooter(cs),
        ],
      ),
    );
  }

  Widget _buildMobileOverlay(ColorScheme cs, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _mobileOpen = false),
      child: Container(
        color: Colors.black54,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: _buildSidebar(cs, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'Administrar',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarFooter(ColorScheme cs) {
    final user = context.watch<AuthViewModel>().user;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.accent,
            child: Text(
              user?.nombre.isNotEmpty == true ? user!.nombre[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              user?.nombre ?? 'Usuario',
              style: TextStyle(color: cs.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navList(ColorScheme cs, bool isDark) {
    final items = [
      (AdminSection.account, Icons.person_rounded, 'Cuenta'),
      (AdminSection.club, Icons.groups_2_rounded, 'Club'),
      (AdminSection.staff, Icons.badge_rounded, 'Staff'),
      (AdminSection.notifications, Icons.notifications_rounded, 'Notificaciones'),
      (AdminSection.sync, Icons.cloud_sync_rounded, 'Sincronización'),
      (AdminSection.personalization, Icons.palette_rounded, 'Personalización'),
      (AdminSection.backups, Icons.backup_rounded, 'Respaldos'),
      (AdminSection.data, Icons.storage_rounded, 'Datos'),
      (AdminSection.about, Icons.info_outline_rounded, 'Acerca de'),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: items.map((item) => _navItem(item.$1, item.$2, item.$3, cs)).toList(),
    );
  }

  Widget _navItem(AdminSection section, IconData icon, String label, ColorScheme cs) {
    final isSelected = _selected == section;
    final accentColor = section == AdminSection.backups
        ? const Color(0xFF22C55E)
        : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            setState(() {
              _selected = section;
              _mobileOpen = false;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 18,
                    color: isSelected ? accentColor : cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(cs, _selected),
              const SizedBox(height: 16),
              _sectionBody(cs, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(ColorScheme cs, AdminSection section) {
    final icons = {
      AdminSection.account: Icons.person_rounded,
      AdminSection.club: Icons.groups_2_rounded,
      AdminSection.staff: Icons.badge_rounded,
      AdminSection.notifications: Icons.notifications_rounded,
      AdminSection.sync: Icons.cloud_sync_rounded,
      AdminSection.personalization: Icons.palette_rounded,
      AdminSection.backups: Icons.backup_rounded,
      AdminSection.data: Icons.storage_rounded,
      AdminSection.about: Icons.info_outline_rounded,
    };
    final titles = {
      AdminSection.account: 'Cuenta',
      AdminSection.club: 'Club',
      AdminSection.staff: 'Staff Técnico',
      AdminSection.notifications: 'Notificaciones',
      AdminSection.sync: 'Sincronización',
      AdminSection.personalization: 'Personalización',
      AdminSection.backups: 'Respaldos',
      AdminSection.data: 'Datos',
      AdminSection.about: 'Acerca de',
    };
    return Row(
      children: [
        Icon(icons[section], size: 20, color: AppColors.accent),
        const SizedBox(width: 10),
        Text(
          titles[section] ?? '',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _sectionTitle(AdminSection section) {
    final titles = {
      AdminSection.account: 'Cuenta',
      AdminSection.club: 'Club',
      AdminSection.staff: 'Staff Técnico',
      AdminSection.notifications: 'Notificaciones',
      AdminSection.sync: 'Sincronización',
      AdminSection.personalization: 'Personalización',
      AdminSection.backups: 'Respaldos',
      AdminSection.data: 'Datos',
      AdminSection.about: 'Acerca de',
    };
    return titles[section] ?? 'Administrar';
  }

  Widget _sectionBody(ColorScheme cs, bool isDark) {
    switch (_selected) {
      case AdminSection.account:
        return const AccountSection();
      case AdminSection.club:
        return const ClubSection();
      case AdminSection.staff:
        return const StaffSection();
      case AdminSection.notifications:
        return const AdminNotificationSection();
      case AdminSection.sync:
        return const SyncSection();
      case AdminSection.personalization:
        return const AppearanceSection();
      case AdminSection.backups:
        return _backupSection(cs, isDark);
      case AdminSection.data:
        return const DatabaseSection();
      case AdminSection.about:
        return _aboutSection(cs);
    }
  }

  Widget _backupSection(ColorScheme cs, bool isDark) {
    final meta = _backupService.metadata;
    final user = context.watch<AuthViewModel>().user;
    final lastBackupStr = meta.lastBackup != null
        ? '${meta.lastBackup!.day.toString().padLeft(2, '0')}/'
            '${meta.lastBackup!.month.toString().padLeft(2, '0')}/'
            '${meta.lastBackup!.year.toString()} '
            '${meta.lastBackup!.hour.toString().padLeft(2, '0')}:'
            '${meta.lastBackup!.minute.toString().padLeft(2, '0')}'
        : 'Nunca';

    return Column(
      children: [
        _backupCard(cs, Icons.history_rounded, 'Último respaldo', lastBackupStr),
        const SizedBox(height: 8),
        _backupCard(cs, Icons.cloud_done_rounded, 'Estado', 'Local (Sembast)'),
        const SizedBox(height: 8),
        _backupCard(cs, Icons.person_rounded, 'Cuenta conectada',
            meta.connectedAccount ?? user?.email ?? 'No conectada'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: meta.isBackingUp ? null : _handleCreateBackup,
            icon: meta.isBackingUp
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.backup_rounded, size: 18),
            label: Text(meta.isBackingUp ? 'Creando respaldo...' : 'Crear respaldo'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: meta.isRestoring ? null : _handleRestoreBackup,
            icon: meta.isRestoring
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restore_rounded, size: 18),
            label: Text(meta.isRestoring ? 'Restaurando...' : 'Restaurar respaldo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.primary,
              side: BorderSide(color: cs.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _backupCard(ColorScheme cs, IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateBackup() async {
    final path = await _backupService.createBackup();
    if (path != null && mounted) {
      final user = context.read<AuthViewModel>().user;
      await _backupService.setConnectedAccount(user?.email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respaldo creado correctamente'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear respaldo'), backgroundColor: Colors.red),
      );
    }
    setState(() {});
  }

  Future<void> _handleRestoreBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs(ctx).surfaceContainerHighest,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text('Restaurar respaldo', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'Se reemplazarán TODOS los datos actuales.\n\n¿Estás seguro?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _backupService.restoreBackup();
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos restaurados correctamente'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al restaurar'), backgroundColor: Colors.red),
      );
    }
    setState(() {});
  }

  ColorScheme cs(BuildContext context) => Theme.of(context).colorScheme;

  Widget _aboutSection(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/logo_libero.png', width: 80, height: 80),
          ),
          const SizedBox(height: 16),
          Text('Libero360', style: TextStyle(color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Voleibol Intelligence', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 24),
          _aboutRow(cs, 'Versión', '1.0.0'),
          const SizedBox(height: 8),
          _aboutRow(cs, 'Motor', 'Sembast + Firebase'),
          const SizedBox(height: 8),
          _aboutRow(cs, 'Framework', 'Flutter 3.x'),
          const SizedBox(height: 8),
          _aboutRow(cs, 'Soporte', 'Android · Web · Windows'),
          const SizedBox(height: 24),
          Text('© 2026 Libero360. Todos los derechos reservados.',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _aboutRow(ColorScheme cs, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 13)),
        Text(value, style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class AdminNotificationSection extends StatelessWidget {
  const AdminNotificationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const NotificationsSection(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _LogsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.list_alt_rounded, size: 18),
            label: const Text('Ver registros del sistema'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogsScreen extends StatelessWidget {
  const _LogsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registros del sistema')),
      body: FutureBuilder<List<LogEntry>>(
        future: LogService.instance.getAll(limit: 200),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snap.data!;
          if (logs.isEmpty) {
            return const Center(child: Text('Sin registros'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final cs = Theme.of(context).colorScheme;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.icon, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.message, style: TextStyle(color: cs.onSurface, fontSize: 12)),
                          if (log.source != null)
                            Text(log.source!, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 10)),
                        ],
                      ),
                    ),
                    Text(
                      '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
