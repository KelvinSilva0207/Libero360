import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../core/themes/app_colors.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/asistencia/asistencia.dart';
import '../features/partido/presentation/views/match_start_dialog.dart';
import '../features/statistics/presentation/views/statistics_screen.dart';
import '../features/admin/presentation/views/admin_screen.dart';
import '../features/teams/teams.dart';
import '../features/notifications/notifications.dart';
import 'dashboard_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const DashboardScreen(),
      const AthleteListScreen(),
      const _MatchLauncherPlaceholder(),
      const StatisticsScreen(),
      const AttendanceScreen(),
      const AdminScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final clubVm = context.watch<ClubViewModel>();
    final notifVm = context.watch<NotificationViewModel>();
    if (clubVm.currentClub != null) {
      notifVm.init(clubVm.currentClub!.id);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final isStatsTab = _selectedIndex == 3;
        // Forzar layout mobile en la pestaña de Estadísticas para que
        // Windows se vea EXACTAMENTE igual que Android
        final useMobileLayout = !isWide || isStatsTab;
        return Scaffold(
          backgroundColor: AppColors.background,
          extendBodyBehindAppBar: useMobileLayout,
          appBar: useMobileLayout
              ? AppBar(
                  backgroundColor: AppColors.surface,
                  leading: _selectedIndex != 0
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => setState(() => _selectedIndex = 0),
                        )
                      : null,
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
                        child: _screens[_selectedIndex],
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
    return Container(
      width: 220,
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/logo_libero.png', width: 32, height: 32),
                ),
                const SizedBox(width: 10),
                const Text('Libero360',
                  style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ClubSwitcher(),
          ),
          Expanded(child: _navItems()),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
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
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 14),
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
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 18, color: isSelected ? AppColors.accent : AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
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
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textTertiary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Atletas'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_volleyball_rounded), label: 'Partidos'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Estadísticas'),
        ],
      ),
    );
  }

  Widget _userMenu(BuildContext context, dynamic user) {
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
        if (value == 'admin') setState(() => _selectedIndex = 5);
        if (value == 'team') setState(() => _selectedIndex = 1);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.nombre ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'team',
          child: Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 10),
              Text('Mi equipo'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'admin',
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 10),
              Text('Administrar'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 16),
              SizedBox(width: 10),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
    );
  }

  void _showUserMenu(BuildContext context, dynamic user) {
    final loginVm = context.read<AuthViewModel>();
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(0, 1000, 220, 0),
      color: AppColors.surfaceLight,
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(user?.nombre ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'team',
          child: Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 10),
              Text('Mi equipo'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'admin',
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 10),
              Text('Administrar'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 16),
              SizedBox(width: 10),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
    ).then((v) {
      if (v == 'logout') loginVm.logout();
      if (v == 'team') setState(() => _selectedIndex = 1);
      if (v == 'admin') setState(() => _selectedIndex = 5);
    });
  }
}

class _MatchLauncherPlaceholder extends StatelessWidget {
  const _MatchLauncherPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_volleyball_rounded, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text('Partidos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Inicia o gestiona tus partidos', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const MatchStartDialog(),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('Nuevo Partido'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
