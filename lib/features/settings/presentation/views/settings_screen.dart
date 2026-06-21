import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../teams/presentation/viewmodels/club_viewmodel.dart';
import '../../data/settings_repository.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'account_section.dart';
import 'appearance_section.dart';
import 'club_section.dart';
import 'database_section.dart';
import 'notifications_section.dart';
import 'profiles_section.dart';
import 'sync_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(
        repository: SettingsRepository(),
        themeNotifier: context.read<ThemeNotifier>(),
        authViewModel: context.read<AuthViewModel>(),
        clubViewModel: context.read<ClubViewModel>(),
      ),
      child: _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 768;
            return SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 32 : 16),
              child: Center(
                child: SizedBox(
                  width: isWide ? 800 : double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide) ...[
                        const SizedBox(height: 8),
                        Text('Configuración',
                            style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                      ],
                      _sectionHeader(context, Icons.person_rounded, 'Cuenta'),
                      const SizedBox(height: 8),
                      const AccountSection(),
                      const SizedBox(height: 8),
                      _sectionHeader(
                          context, Icons.groups_2_rounded, 'Club'),
                      const SizedBox(height: 8),
                      const ClubSection(),
                      const SizedBox(height: 8),
                      _sectionHeader(context,
                          Icons.swap_horiz_rounded, 'Perfiles'),
                      const SizedBox(height: 8),
                      const ProfilesSection(),
                      const SizedBox(height: 8),
                      _sectionHeader(
                          context, Icons.notifications_rounded, 'Notificaciones'),
                      const SizedBox(height: 8),
                      const NotificationsSection(),
                      const SizedBox(height: 8),
                      _sectionHeader(
                          context, Icons.palette_rounded, 'Apariencia'),
                      const SizedBox(height: 8),
                      const AppearanceSection(),
                      const SizedBox(height: 8),
                      _sectionHeader(
                          context, Icons.cloud_sync_rounded, 'Sincronización'),
                      const SizedBox(height: 8),
                      const SyncSection(),
                      const SizedBox(height: 8),
                      _sectionHeader(
                          context, Icons.storage_rounded, 'Base de Datos'),
                      const SizedBox(height: 8),
                      const DatabaseSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
