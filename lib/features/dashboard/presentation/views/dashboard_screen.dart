import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/theme_provider/theme_notifier.dart';
import '../../../../core/widgets_globales/route_transitions.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../profiles/presentation/viewmodels/profile_viewmodel.dart';
import '../../../teams/presentation/viewmodels/club_viewmodel.dart';
import '../../../settings/presentation/widgets/settings_drawer.dart';
import '../../../asistencia/asistencia.dart';
import '../../../estadisticas/presentation/views/play_by_play_screen.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/header_section.dart';
import '../widgets/main_card_section.dart';
import '../widgets/athlete_of_month_card.dart';
import '../widgets/quick_summary_grid.dart';
import '../widgets/team_status_section.dart';
import '../widgets/last_match_banner.dart';
import '../widgets/recent_activity_timeline.dart';
import '../widgets/quick_access_row.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/animated_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  void _load() {
    final profileVm = context.read<ProfileViewModel>();
    final clubVm = context.read<ClubViewModel>();
    context.read<DashboardViewModel>().load(
      profileId: profileVm.currentProfile?.id,
      clubName: clubVm.currentClub?.name,
      clubMemberCount: clubVm.memberCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final vm = context.watch<DashboardViewModel>();
    final user = context.watch<AuthViewModel>().user;
    final profile = context.watch<ProfileViewModel>().currentProfile;
    final userName = user?.nombre.split(' ').first ?? 'Usuario';

    final bg = isDark ? AppColors.background : AppColors.lightBackground;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      endDrawer: const SettingsDrawer(),
      body: SafeArea(
        child: vm.loading && vm.data == null
            ? DashboardSkeleton(isDark: isDark)
            : vm.error != null && vm.data == null
                ? _errorState(vm, isDark)
                : RefreshIndicator(
                    onRefresh: () => vm.refresh(profileId: profile?.id),
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: AnimatedSection(
                          index: 0,
                          child: HeaderSection(
                            userName: userName,
                            teamInfo: vm.data!.teamInfo,
                            isDark: isDark,
                            onSettings: () => _scaffoldKey.currentState?.openEndDrawer(),
                          ),
                        )),
                        SliverToBoxAdapter(child: AnimatedCard(
                          child: AnimatedSection(
                            index: 1,
                            child: MainCardSection(
                              nextTraining: vm.data!.nextTraining,
                              nextMatch: vm.data!.nextMatch,
                              isDark: isDark,
                            ),
                          ),
                        )),
                        SliverToBoxAdapter(child: AnimatedCard(
                          child: AnimatedSection(
                            index: 2,
                            child: AthleteOfMonthCard(
                              athlete: vm.data!.athleteOfMonth,
                              isDark: isDark,
                            ),
                          ),
                        )),
                        SliverToBoxAdapter(child: AnimatedCard(
                          child: AnimatedSection(
                            index: 3,
                            child: QuickSummaryGrid(
                              summary: vm.data!.quickSummary,
                              isDark: isDark,
                            ),
                          ),
                        )),
                        SliverToBoxAdapter(child: AnimatedCard(
                          child: AnimatedSection(
                            index: 4,
                            child: TeamStatusSection(
                              status: vm.data!.teamStatus,
                              isDark: isDark,
                            ),
                          ),
                        )),
                        SliverToBoxAdapter(child: AnimatedCard(
                          child: AnimatedSection(
                            index: 5,
                            child: LastMatchBanner(
                              lastMatch: vm.data!.lastMatch,
                              isDark: isDark,
                            ),
                          ),
                        )),
                        SliverToBoxAdapter(child: AnimatedSection(
                          index: 6,
                          child: RecentActivityTimeline(
                            activities: vm.data!.recentActivity,
                            isDark: isDark,
                          ),
                        )),
                        SliverToBoxAdapter(child: AnimatedCard(
                          child: AnimatedSection(
                            index: 7,
                            child: QuickAccessRow(isDark: isDark),
                          ),
                        )),
                        if (vm.data!.quickSummary.athleteCount == 0)
                          SliverToBoxAdapter(child: AnimatedSection(
                            index: 8,
                            child: _emptyState(isDark, 'registerAthlete'),
                          )),
                        if (vm.data!.quickSummary.athleteCount > 0 &&
                            vm.data!.quickSummary.matchCount == 0)
                          SliverToBoxAdapter(child: AnimatedSection(
                            index: 8,
                            child: _emptyState(isDark, 'createMatch'),
                          )),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 32),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _errorState(DashboardViewModel vm, bool isDark) {
    final textPri = isDark ? Colors.white : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48,
                color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary),
            const SizedBox(height: 16),
            Text('Error al cargar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPri)),
            const SizedBox(height: 8),
            Text(vm.error!, style: TextStyle(fontSize: 12, color: textSec),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark, String type) {
    final textPri = isDark ? Colors.white : AppColors.textPrimary;
    final textSec = isDark ? AppColors.textSecondary : AppColors.textTertiary;
    final bg = isDark ? AppColors.surface : AppColors.lightCard;
    final borderClr = isDark ? AppColors.border : AppColors.lightBorder;

    if (type == 'registerAthlete') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderClr),
          ),
          child: Column(
            children: [
              Text('👥', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Aún no has registrado atletas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPri)),
              const SizedBox(height: 4),
              Text('Comienza agregando tu primer atleta al equipo',
                  style: TextStyle(fontSize: 12, color: textSec)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.pushSlide(const AthleteFormScreen()),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Registrar atleta'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (type == 'createMatch') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderClr),
          ),
          child: Column(
            children: [
              Text('🏐', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('No hay partidos registrados',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPri)),
              const SizedBox(height: 4),
              Text('Crea tu primer partido para ver estadísticas',
                  style: TextStyle(fontSize: 12, color: textSec)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.pushSlide(const PlayByPlayScreen()),
                icon: const Icon(Icons.sports_volleyball_rounded, size: 18),
                label: const Text('Crear partido'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
