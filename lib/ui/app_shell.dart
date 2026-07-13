import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../core/themes/app_colors.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/atleta/atleta.dart';
import '../features/asistencia/asistencia.dart' show AttendanceScreen;
import '../features/partido/presentation/views/match_list_screen.dart';
import '../features/statistics/presentation/views/statistics_screen.dart';
import '../features/admin/presentation/views/admin_screen.dart';
import '../features/teams/teams.dart';
import '../features/notifications/notifications.dart';
import '../features/profiles/profiles.dart';
import '../features/dashboard/dashboard.dart';

enum NavItem { dashboard, athletes, matches, stats, attendance, settings }

class AppShell extends StatefulWidget {
  final Widget? initialScreen;
  const AppShell({super.key, this.initialScreen});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [];
  bool _checkedInvitations = false;

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const DashboardScreen(),
      const AthleteListScreen(),
      const MatchListScreen(),
      const StatisticsScreen(),
      const AttendanceScreen(),
      const AdminScreen(),
    ]);
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final clubVm = context.watch<ClubViewModel>();
    final notifVm = context.watch<NotificationViewModel>();
    if (clubVm.currentClub != null) {
      notifVm.init(clubVm.currentClub!.id);
    }
    if (user != null && !_checkedInvitations) {
      _checkedInvitations = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkInvitations(context));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final isStatsTab = _selectedIndex == 3;
        // Forzar layout mobile en la pestaña de Estadísticas para que
        // Windows se vea EXACTAMENTE igual que Android
        final useMobileLayout = !isWide || isStatsTab;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBodyBehindAppBar: useMobileLayout,
          appBar: useMobileLayout
              ? AppBar(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  leading: null,
                  title: Row(
                    children: [
                      Image.asset('assets/images/logo_libero.png', width: 24, height: 24),
                      const SizedBox(width: 8),
                      const Text('Libero360', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actions: [
                    const NotificationBell(),
                    const ClubSwitcher(),
                    const ProfileSelector(),
                    _userMenu(context, user),
                  ],
                )
              : null,
          body: SafeArea(
            left: false,
            right: false,
            child: Column(
              children: [
                const InvitationBanner(),
                Expanded(
                  child: Row(
                    children: [
                      if (!useMobileLayout) _buildSidebar(context, user),
                      Expanded(
                        child: _ProfileCoordinator(
                          child: _screens[_selectedIndex],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: useMobileLayout
              ? _buildBottomNav()
              : null,
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context, dynamic user) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      color: colors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/logo_libero.png', width: 32, height: 32),
                ),
                const SizedBox(width: 10),
                Text('Libero360',
                  style: TextStyle(
                    color: colors.onSurface, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const ClubSwitcher(),
                const SizedBox(width: 8),
                const ProfileSelector(),
                const Spacer(),
                const NotificationBell(),
              ],
            ),
          ),
          Expanded(child: _navItems()),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: GestureDetector(
              onTap: () => _showUserMenu(context, user),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nombre ?? 'Usuario',
                          style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email,
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert_rounded, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItems() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _navItem(NavItem.dashboard, Icons.dashboard_rounded, 'Dashboard', 0),
        _navItem(NavItem.athletes, Icons.people_rounded, 'Atletas', 1),
        _navItem(NavItem.matches, Icons.sports_volleyball_rounded, 'Partidos', 2),
        _navItem(NavItem.stats, Icons.bar_chart_rounded, 'Estadísticas', 3),
        _navItem(NavItem.attendance, Icons.checklist_rounded, 'Asistencia', 4),
        _navItem(NavItem.settings, Icons.settings_rounded, 'Configuración', 5),
      ],
    );
  }

  Widget _navItem(NavItem item, IconData icon, String label, int index) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _selectTab(index),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 18, color: isSelected ? AppColors.accent : colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
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

  Widget _buildBottomNav() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: colors.onSurfaceVariant,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: _selectedIndex,
        onTap: (i) => _selectTab(i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Atletas'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_volleyball_rounded), label: 'Partidos'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Estadísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Asistencia'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Configuración'),
        ],
      ),
    );
  }

  Widget _userMenu(BuildContext context, dynamic user) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundColor: AppColors.accent,
        radius: 15,
        child: Text(
          user?.nombre.isNotEmpty == true ? user!.nombre[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      onSelected: (value) {
        if (value == 'logout') context.read<AuthViewModel>().logout();
        if (value == 'settings') setState(() => _selectedIndex = 5);
        if (value == 'team') setState(() => _selectedIndex = 1);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.nombre ?? 'Usuario', style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'team',
          child: Row(
            children: [
              Icon(Icons.shield_rounded, color: colors.onSurfaceVariant, size: 16),
              const SizedBox(width: 10),
              const Text('Mi equipo'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_rounded, color: colors.onSurfaceVariant, size: 16),
              const SizedBox(width: 10),
              const Text('Configuración'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 10),
              const Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
    );
  }

  void _showUserMenu(BuildContext context, dynamic user) {
    final loginVm = context.read<AuthViewModel>();
    final colors = Theme.of(context).colorScheme;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(0, 1000, 220, 0),
      color: colors.surface,
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(user?.nombre ?? 'Usuario', style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'team',
          child: Row(
            children: [
              Icon(Icons.shield_rounded, color: colors.onSurfaceVariant, size: 16),
              const SizedBox(width: 10),
              const Text('Mi equipo'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_rounded, color: colors.onSurfaceVariant, size: 16),
              const SizedBox(width: 10),
              const Text('Configuración'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 10),
              const Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
    ).then((v) {
      if (v == 'logout') loginVm.logout();
      if (v == 'team') setState(() => _selectedIndex = 1);
      if (v == 'settings') setState(() => _selectedIndex = 5);
    });
  }

  Future<void> _checkInvitations(BuildContext context) async {
    final clubVm = context.read<ClubViewModel>();
    final pending = await clubVm.checkPendingInvitations();
    if (pending.isEmpty || !context.mounted) return;
    _showInvitationDialog(context, clubVm, pending.first);
  }

  void _showInvitationDialog(
      BuildContext context, ClubViewModel clubVm, ClubInvitation inv) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.mail_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 10),
            Text('Invitación', style: TextStyle(color: colors.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Club: ${inv.clubName}',
                style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${inv.inviterDisplayName} te ha invitado a unirte.',
                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Text('Rol: ${_roleLabel(inv.role)}',
                style: TextStyle(color: AppColors.accent, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              clubVm.rejectInvitation(inv);
            },
            child: Text('Rechazar',
                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6))),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              clubVm.acceptInvitation(inv);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(ClubRole role) {
    switch (role) {
      case ClubRole.owner:
        return 'Propietario';
      case ClubRole.entrenador:
        return 'Entrenador';
      case ClubRole.asistente:
        return 'Asistente';
    }
  }
}

/// Watches [ProfileViewModel] and propagates profile changes to other
/// ViewModels (DashboardViewModel, ClubViewModel).  Placed high in the
/// widget tree so every profile‑select event reaches the data layer.
class _ProfileCoordinator extends StatefulWidget {
  final Widget child;
  const _ProfileCoordinator({required this.child});

  @override
  State<_ProfileCoordinator> createState() => _ProfileCoordinatorState();
}

class _ProfileCoordinatorState extends State<_ProfileCoordinator> {
  ProfileViewModel? _profileVm;
  String? _lastProfileId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileVm?.removeListener(_onProfileChanged);
    _profileVm = context.read<ProfileViewModel>();
    _profileVm!.addListener(_onProfileChanged);
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onProfileChanged());
    }
  }

  void _onProfileChanged() {
    final vm = _profileVm;
    if (vm == null) return;
    final profile = vm.currentProfile;
    if (profile?.id == _lastProfileId) return;
    _lastProfileId = profile?.id;
    try {
      context.read<DashboardViewModel>().setProfile(profile?.id);
      context.read<ClubViewModel>().setProfileFilter(profile?.id);
    } catch (_) {}
  }

  @override
  void dispose() {
    _profileVm?.removeListener(_onProfileChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
